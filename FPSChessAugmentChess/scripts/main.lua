local Config = require("AugmentConfig")
local Catalog = require("AugmentCatalog")
local MatchSync = require("MatchSync")
local CardView = require("CardView")
local InputState=require("InputState")
local Hub=require("ModHub")
local StatSync=require("StatSync")
local hub,inputState
-- Isolation build: disable every combat-time UE4SS hook. The previous crash
-- still occurred with native card UI removed, so the remaining suspect is a
-- hook callback touching an object during AI combat startup.
-- Keep combat-event hooks disabled until each callback has been proven safe
-- against the game's AI spawn / combat transition lifecycle. These hooks run
-- immediately before the first card UI is drawn, when Blueprint objects can
-- still be only partially constructed.
local SAFE_COMBAT_HOOKS=false
rawset(_G,"__FPSChessDisableCombatHooks",not SAFE_COMBAT_HOOKS)

-- Fail closed even if a future edit accidentally calls RegisterHook without
-- checking SAFE_COMBAT_HOOKS first.  This local wrapper leaves the console
-- command hook available, but blocks every callback that can run while the
-- AI pawn is being spawned or the first card offer is about to open.
local nativeRegisterHook=RegisterHook
local function isCombatHookPath(path)
    path=tostring(path or "")
    return path:find("/Game/Blueprints/Killcam/",1,true)==1
        or path:find("/Game/Blueprints/Characters/",1,true)==1
        or path=="/Script/Engine.Character:PlayAnimMontage"
        or path=="/Script/Engine.Actor:ReceiveAnyDamage"
        or path=="/Script/Engine.Actor:ReceivePointDamage"
end
local function RegisterHook(path,...)
    if not SAFE_COMBAT_HOOKS and isCombatHookPath(path) then return end
    return nativeRegisterHook(path,...)
end

local function valid(object)
    local ok,value=pcall(function() return object and object:IsValid() end)
    return ok and value==true
end
local function read(object,field)
    if not valid(object) then return nil end
    local ok,value=pcall(function() return object[field] end)
    if ok then return value end
    return nil
end
local function call(object,method,...)
    if not valid(object) then return nil end
    local args=table.pack(...)
    local ok,value=pcall(function() return object[method](object,table.unpack(args,1,args.n)) end)
    if ok then return value end
    return nil
end
local function log(text) print("[AugmentChess] "..text.."\n") end
local function clamp(value,minimum,maximum,default)
    value=tonumber(value)
    if not value then return default end
    return math.min(maximum,math.max(minimum,math.floor(value)))
end
local settings={
    enabled=Config.Enabled ~= false,
    start=Config.DrawAtBattleStart ~= false,
    interval=clamp(Config.DrawIntervalSeconds,30,300,60),
    maximum=clamp(Config.MaxOwnedCards,1,10,3),
    count=clamp(Config.CardsPerOffer,1,5,3),
    selection=clamp(Config.SelectionSeconds,10,300,60),
}
local cachedController=nil
local localPieceDiagnosticLogged=false
local function localController()
    if valid(cachedController) and call(cachedController,"IsLocalController")==true then return cachedController end
    cachedController=nil
    for _,controller in ipairs(FindAllOf("PlayerController") or {}) do
        if valid(controller) and call(controller,"IsLocalController") == true then cachedController=controller; return controller end
    end
end
local function objectClassName(object)
    local class=valid(object) and call(object,"GetClass") or nil
    local ok,name=pcall(function() return valid(class) and class:GetFName():ToString() or "" end)
    return ok and name or ""
end
local function looksLikePieceClass(name)
    return tostring(name):find("PieceChar",1,true)~=nil
        or tostring(name):find("PawnChar",1,true)~=nil
        or tostring(name):find("KnightChar",1,true)~=nil
        or tostring(name):find("BishopChar",1,true)~=nil
        or tostring(name):find("RookChar",1,true)~=nil
        or tostring(name):find("QueenChar",1,true)~=nil
        or tostring(name):find("KingChar",1,true)~=nil
end
local knownPieceClasses={
    "BP_PawnChar_C","BP_KnightChar_C","BP_BishopChar_C","BP_RookChar_C","BP_QueenChar_C","BP_KingChar_C",
    "BP_WoodPawnChar_C","BP_WoodKnightChar_C","BP_WoodBishopChar_C","BP_WoodRookChar_C","BP_WoodQueenChar_C","BP_WoodKingChar_C",
    "BP_BSidePawnChar_C","BP_BSideKnightChar_C","BP_BSideBishopChar_C","BP_BSideRookChar_C","BP_BSideQueenChar_C","BP_BSideKingChar_C",
}
local lastPieceScanSignature=nil
local allPiecesCacheAt=-math.huge
local allPiecesCache={}
local function allPieces()
    local now=os.clock()
    if now-allPiecesCacheAt<2 then
        local cached={}
        for _,object in ipairs(allPiecesCache) do
            if valid(object) then cached[#cached+1]=object end
        end
        return cached
    end
    local result,seen={},{}
    local counts={}
    local function add(object)
        if not valid(object) or seen[object:GetAddress()] then return end
        seen[object:GetAddress()]=true
        result[#result+1]=object
    end
    for _,className in ipairs(knownPieceClasses) do
        local objects=FindAllOf(className) or {}
        counts[#counts+1]=className.."="..tostring(#objects)
        for _,object in ipairs(objects) do add(object) end
    end
    local baseObjects=FindAllOf("BP_PieceChar_C") or {}
    counts[#counts+1]="BP_PieceChar_C="..tostring(#baseObjects)
    for _,object in ipairs(baseObjects) do add(object) end
    -- Do not fall back to FindAllOf("Actor") during startup.  UE4SS's
    -- UObject cache can be incomplete while the first world is constructing,
    -- and enumerating every Actor at that point can crash the game before a
    -- playable pawn exists.  The concrete piece classes above are sufficient
    -- once the board has spawned them.
    local signature=table.concat(counts,",")..";total="..tostring(#result)
    if signature~=lastPieceScanSignature then
        lastPieceScanSignature=signature
        log("기물 클래스 탐색: "..signature)
    end
    allPiecesCacheAt=now
    allPiecesCache=result
    return result
end
local function isPiece(piece)
    if not valid(piece) then return false end
    if call(piece,"IsA","/Game/Blueprints/Characters/BP_PieceChar.BP_PieceChar_C")==true then return true end
    return looksLikePieceClass(objectClassName(piece))
end
local function sameObject(left,right)
    return valid(left) and valid(right) and left:GetAddress()==right:GetAddress()
end
local fallbackPiece=nil
local fallbackPieceScanAt=0
local function pieceForController(controller)
    local piece=read(controller,"Pawn") or call(controller,"GetPawn")
    if valid(piece) then
        if not localPieceDiagnosticLogged and call(controller,"IsLocalController")==true then
            localPieceDiagnosticLogged=true
            log("로컬 Pawn 확인: 클래스="..objectClassName(piece)..", 기물판정="..tostring(isPiece(piece)))
        end
        if isPiece(piece) then return piece end
    end
    -- The controller's Pawn is briefly unavailable during killcam/death
    -- cleanup. Avoid scanning every known piece class on every 350 ms tick.
    local scanNow=os.clock()
    if scanNow-fallbackPieceScanAt<1.0 and (fallbackPiece==nil or valid(fallbackPiece)) then
        return fallbackPiece
    end
    fallbackPieceScanAt=scanNow
    local world=valid(controller) and call(controller,"GetWorld") or nil
    local fallback=nil
    for _,candidate in ipairs(allPieces()) do
        if valid(candidate) and read(candidate,"Dead")~=true then
            local candidateWorld=call(candidate,"GetWorld")
            if valid(world) and valid(candidateWorld) and candidateWorld:GetAddress()==world:GetAddress() then
                fallback=fallback or candidate
                local owner=read(candidate,"OwningPlayer") or call(candidate,"GetOwner")
                local playerState=read(controller,"PlayerState")
                if valid(owner) and (sameObject(owner,controller)
                    or valid(playerState) and sameObject(owner,playerState)) then
                    fallbackPiece=candidate
                    return candidate
                end
            end
        end
    end
    if call(controller,"IsLocalController")==true then
        fallbackPiece=fallback
        return fallback
    end
end
local function localPiece() return pieceForController(localController()) end
local function localControlledPiece(controller)
    controller=controller or localController()
    if not valid(controller) then return nil end
    local piece=read(controller,"Pawn")
    if not valid(piece) then piece=call(controller,"GetPawn") end
    if isPiece(piece) then return piece end
end
local api={
    valid=valid, read=read, call=call, isPiece=isPiece,
    className=function(object)
        return objectClassName(object)
    end,
    classDefault=function(object)
        local class=valid(object) and call(object,"GetClass") or nil
        if not valid(class) then return nil end
        local ok,default=pcall(function() return class:GetCDO() end)
        return ok and default or nil
    end,
    write=function(object,field,value) return pcall(function() object[field]=value end) end,
    enableHealthRegen=function(piece)
        pcall(function() piece.CanRegenHealth=true end)
        call(piece,"EnableHealthRegen")
    end,
    refresh=function(piece)
        call(piece,"ForceNetUpdate")
        call(piece,"UpdateCooldownHUD")
        call(piece,"UpdateMovementCooldownHUD")
    end,
    identity=function(object) return valid(object) and object:GetFullName().."@"..tostring(object:GetAddress()) or "" end,
    authority=function(object) return call(object,"HasAuthority") == true end,
    world=function(object) return valid(object) and call(object,"GetWorld") or nil end,
    findClass=function(path) return StaticFindObject(path) end,
    findAll=function(class) return FindAllOf(class) end,
    log=log,
}

local function hookValue(parameter)
    if parameter==nil then return nil end
    local ok,value=pcall(function() return parameter:get() end)
    return ok and value or parameter
end
api.unwrap=hookValue

-- FPS Chess attaches a KillcamRecorder component to pieces, projectiles, and
-- destructible actors. Its transform recording is expensive during death
-- cleanup, while augment rounds do not use the stock replay.
local killcamLogged=false
local function disableKillcamRecorder(recorder)
    if not valid(recorder) then return false end
    local changed=false
    local function setIfPossible(field,value)
        local ok=pcall(function() recorder[field]=value end)
        if ok then changed=true end
    end
    setIfPossible("AutoRecordTransform",false)
    setIfPossible("NoSpawn",true)
    call(recorder,"SetComponentTickEnabled",false)
    return changed
end
local function disableKillcamRecorders()
    local count=0
    for _,recorder in ipairs(FindAllOf("KillcamRecorder_C") or {}) do
        if disableKillcamRecorder(recorder) then count=count+1 end
    end
    if count>0 and not killcamLogged then
        killcamLogged=true
        log("킬캠 녹화 비활성화: KillcamRecorder "..tostring(count).."개")
    end
end
local killcamHookKey="__FPSChessAugmentKillcamHooksInstalled"
local killcamHookRegistry=rawget(_G,"__FPSChessAugmentKillcamHookRegistry") or {}
rawset(_G,"__FPSChessAugmentKillcamHookRegistry",killcamHookRegistry)
local killcamHookPaths={
    "/Game/Blueprints/Killcam/KillcamRecorder.KillcamRecorder_C:ReceiveBeginPlay",
    "/Game/Blueprints/Killcam/KillcamRecorder.KillcamRecorder_C:SendTransformEvent",
    "/Game/Blueprints/Killcam/KillcamRecorder.KillcamRecorder_C:RecordEvent",
}
local function installKillcamHooks()
    local waiting=0
    for _,path in ipairs(killcamHookPaths) do
        if not killcamHookRegistry[path] then
            local ok,err=pcall(function()
                local functionObject=StaticFindObject(path)
                if not valid(functionObject) then error("function is not loaded") end
                RegisterHook(path,function(context)
                    disableKillcamRecorder(hookValue(context))
                end)
            end)
            if ok then killcamHookRegistry[path]=true else waiting=waiting+1 end
        end
    end
    if waiting==0 then
        rawset(_G,killcamHookKey,"AugmentChess")
        return true
    end
    return false
end
if SAFE_COMBAT_HOOKS and not rawget(_G,killcamHookKey) then
    pcall(installKillcamHooks)
end
local killcamHookRetryCount=0
LoopAsync(1000,function()
    if not SAFE_COMBAT_HOOKS or rawget(_G,killcamHookKey) or killcamHookRetryCount>=30 then return end
    killcamHookRetryCount=killcamHookRetryCount+1
    ExecuteInGameThread(function()
        local complete=installKillcamHooks()
        if not complete and killcamHookRetryCount>=30 then
            log("킬캠 레코더 훅 대기 시간 초과: 레코더 주기 차단만 사용")
        elseif complete then
            log("킬캠 레코더 훅 준비 완료")
        end
    end)
end)
LoopAsync(1000,function()
    if not SAFE_COMBAT_HOOKS then return end
    ExecuteInGameThread(function()
        pcall(disableKillcamRecorders)
    end)
end)

-- ShootDelay controls when another sword attack may begin, while the montage
-- controls when the swing and its hitbox finish.  Speed both together so a
-- melee attack-speed card is visible and does not remain animation-limited.
local meleeHookKey="__FPSChessMeleeAnimationSpeedHookInstalled"
if SAFE_COMBAT_HOOKS and not rawget(_G,meleeHookKey) then
    local meleeHookOk,meleeHookError=pcall(function()
        RegisterHook("/Script/Engine.Character:PlayAnimMontage",function(context,montage,playRate)
            local piece=hookValue(context)
            local multiplier=Catalog.meleeAnimationRate(api,piece)
            if not multiplier or multiplier<=1.0001 or playRate==nil then return end

            local montageObject=hookValue(montage)
            local montageName=""
            if valid(montageObject) then
                pcall(function() montageName=montageObject:GetFullName():lower() end)
            end
            local meleeMontage=montageName:find("swing",1,true)
                or montageName:find("sword",1,true)
                or montageName:find("slash",1,true)
                or montageName:find("helicopter",1,true)
            if read(piece,"Swinging")~=true and not meleeMontage then return end

            local base=tonumber(hookValue(playRate)) or 1
            pcall(function() playRate:set(base*multiplier) end)
        end)
    end)
    if meleeHookOk then
        rawset(_G,meleeHookKey,"AugmentChess")
        log("근접 공격 애니메이션 속도 훅 준비 완료")
    else
        log("근접 공격 애니메이션 속도 훅 등록 실패: "..tostring(meleeHookError))
    end
else
    log("공유 근접 공격 애니메이션 속도 훅 사용")
end

-- Steel Skin changes the damage value at the engine damage event that this
-- build actually exposes.  AActor:TakeDamage is not present in this game's
-- reflected function table, while ReceiveAnyDamage is the common event for
-- point, radial, ability, and melee damage.  Hooking the common event avoids
-- applying the same reduction twice when point/radial damage also broadcasts
-- their more specific events.
local damageReductionHookKey="__FPSChessAugmentDamageReductionHookInstalled"
if SAFE_COMBAT_HOOKS and not rawget(_G,damageReductionHookKey) then
    local damageHookOk,damageHookError=pcall(function()
        RegisterHook("/Script/Engine.Actor:ReceiveAnyDamage",function(context,damageAmount,...)
            local actor=hookValue(context)
            if damageAmount==nil then return end
            local base=tonumber(hookValue(damageAmount))
            if not base or base<=0 then return end
            local reduced=Catalog.adjustIncomingDamage(api,actor,base,...)
            if not reduced or math.abs(reduced-base)<0.0001 then return end
            pcall(function() damageAmount:set(reduced) end)
            return reduced
        end)
    end)
    if damageHookOk then
        rawset(_G,damageReductionHookKey,"AugmentChess")
        log("강철 피부 피해 감소 훅 준비 완료: Actor:ReceiveAnyDamage")
    else
        log("강철 피부 피해 감소 훅 등록 실패(Actor:ReceiveAnyDamage): "..tostring(damageHookError))
    end
end

-- Point damage is the only reflected damage event that carries BoneName.
-- Register it separately for headhunter and let ReceiveAnyDamage handle the
-- common reduction path.  The event is also useful for future cards that need
-- HitInfo without replacing the game's damage pipeline.
local pointDamageHookKey="__FPSChessAugmentPointDamageHookInstalled"
if SAFE_COMBAT_HOOKS and not rawget(_G,pointDamageHookKey) then
    local pointHookOk,pointHookError=pcall(function()
        RegisterHook("/Script/Engine.Actor:ReceivePointDamage",function(context,damageAmount,damageType,hitLocation,hitNormal,hitComponent,boneName,shotFromDirection,instigatedBy,damageCauser,hitInfo)
            local actor=hookValue(context)
            if damageAmount==nil then return end
            local base=tonumber(hookValue(damageAmount))
            if not base or base<=0 then return end
            local adjusted=Catalog.adjustPointDamage(api,actor,base,boneName,hookValue(instigatedBy),hookValue(damageCauser),hookValue(hitInfo))
            if not adjusted or math.abs(adjusted-base)<0.0001 then return end
            pcall(function() damageAmount:set(adjusted) end)
            return adjusted
        end)
    end)
    if pointHookOk then
        rawset(_G,pointDamageHookKey,"AugmentChess")
        log("헤드샷/피격 본 훅 준비 완료: Actor:ReceivePointDamage")
    else
        log("헤드샷/피격 본 훅 등록 실패(Actor:ReceivePointDamage): "..tostring(pointHookError))
    end
end

-- UE4SS can load Actor's reflected damage functions after the Lua mod starts.
-- The first RegisterHook call above is intentionally kept for early builds,
-- but a failed registration must be retried after the functions are loaded.
local damageHookRetryCount=0
local function installDamageHooks()
    if not SAFE_COMBAT_HOOKS then return true end
    local waiting=0
    if SAFE_COMBAT_HOOKS and not rawget(_G,damageReductionHookKey) then
        local ok,err=pcall(function()
            local functionObject=StaticFindObject("/Script/Engine.Actor:ReceiveAnyDamage")
            if not valid(functionObject) then error("function is not loaded") end
            RegisterHook("/Script/Engine.Actor:ReceiveAnyDamage",function(context,damageAmount,...)
                local actor=hookValue(context)
                if damageAmount==nil then return end
                local base=tonumber(hookValue(damageAmount))
                if not base or base<=0 then return end
                local reduced=Catalog.adjustIncomingDamage(api,actor,base,...)
                if not reduced or math.abs(reduced-base)<0.0001 then return end
                pcall(function() damageAmount:set(reduced) end)
                return reduced
            end)
        end)
        if ok then
            rawset(_G,damageReductionHookKey,"AugmentChess")
            log("강철 피부 피해 감소 훅 지연 등록 완료: Actor:ReceiveAnyDamage")
        else
            waiting=waiting+1
            if damageHookRetryCount==0 or damageHookRetryCount%5==0 then
                log("강철 피부 피해 감소 훅 대기: "..tostring(err))
            end
        end
    end
    if SAFE_COMBAT_HOOKS and not rawget(_G,pointDamageHookKey) then
        local ok,err=pcall(function()
            local functionObject=StaticFindObject("/Script/Engine.Actor:ReceivePointDamage")
            if not valid(functionObject) then error("function is not loaded") end
            RegisterHook("/Script/Engine.Actor:ReceivePointDamage",function(context,damageAmount,damageType,hitLocation,hitNormal,hitComponent,boneName,shotFromDirection,instigatedBy,damageCauser,hitInfo)
                local actor=hookValue(context)
                if damageAmount==nil then return end
                local base=tonumber(hookValue(damageAmount))
                if not base or base<=0 then return end
                local adjusted=Catalog.adjustPointDamage(api,actor,base,boneName,hookValue(instigatedBy),hookValue(damageCauser),hookValue(hitInfo))
                if not adjusted or math.abs(adjusted-base)<0.0001 then return end
                pcall(function() damageAmount:set(adjusted) end)
                return adjusted
            end)
        end)
        if ok then
            rawset(_G,pointDamageHookKey,"AugmentChess")
            log("피격 본 훅 지연 등록 완료: Actor:ReceivePointDamage")
        else
            waiting=waiting+1
            if damageHookRetryCount==0 or damageHookRetryCount%5==0 then
                log("피격 본 훅 대기: "..tostring(err))
            end
        end
    end
    return waiting==0
end
installDamageHooks()

-- Card special effects are stateful, so merely changing a Blueprint field is
-- insufficient.  These are the concrete ability entry points present in the
-- current FPS Chess dump.  Hook both the original and the Wood/BSide paths so
-- the same card works for every visual variant of a piece.
local abilityHookKey="__FPSChessAugmentAbilityHooksInstalled"
local abilityPaths={
        {"/Game/Blueprints/Characters/BP_PieceChar.BP_PieceChar_C:MovementAbility","MovementAbility"},
        {"/Game/Blueprints/Characters/BP_PieceChar.BP_PieceChar_C:MainAbility","MainAbility"},
        {"/Game/Blueprints/Characters/BP_PieceChar.BP_PieceChar_C:MainAbilityMulti","MainAbility"},
        {"/Game/Blueprints/Characters/BP_PieceChar.BP_PieceChar_C:MainAbilityServer","MainAbility"},
        {"/Game/Blueprints/Characters/BP_PieceChar.BP_PieceChar_C:MovementAbilityMulti","MovementAbility"},
        {"/Game/Blueprints/Characters/BP_PieceChar.BP_PieceChar_C:MovementAbilityServer","MovementAbility"},
        {"/Game/Blueprints/Characters/BP_PieceChar.BP_PieceChar_C:MovementAbilityAll","MovementAbility"},
        {"/Game/Blueprints/Characters/BP_PieceChar.BP_PieceChar_C:MainAbilityAll","MainAbility"},
        {"/Game/Blueprints/Characters/BP_KnightChar.BP_KnightChar_C:StartCharge","StartCharge"},
        {"/Game/Blueprints/Characters/BP_KnightChar.BP_KnightChar_C:FinishCharge","FinishCharge"},
        {"/Game/Blueprints/Characters/BP_KnightChar.BP_KnightChar_C:ReleaseArrow","ReleaseArrow"},
        {"/Game/Blueprints/Characters/BP_KnightChar.BP_KnightChar_C:ReleaseArrowServer","ReleaseArrow"},
        {"/Game/Blueprints/Characters/Wood/BP_WoodKnightChar.BP_WoodKnightChar_C:StartCharge","StartCharge"},
        {"/Game/Blueprints/Characters/Wood/BP_WoodKnightChar.BP_WoodKnightChar_C:FinishCharge","FinishCharge"},
        {"/Game/Blueprints/Characters/Wood/BP_WoodKnightChar.BP_WoodKnightChar_C:ReleaseArrow","ReleaseArrow"},
        {"/Game/Blueprints/Characters/Wood/BP_WoodKnightChar.BP_WoodKnightChar_C:ReleaseArrowServer","ReleaseArrow"},
        {"/Game/Blueprints/Characters/BSide/BP_BSideKnightChar.BP_BSideKnightChar_C:MovementAbility","MovementAbility"},
        {"/Game/Blueprints/Characters/BSide/BP_BSideKnightChar.BP_BSideKnightChar_C:MainAbility","MainAbility"},
        {"/Game/Blueprints/Characters/BP_RookChar.BP_RookChar_C:LaunchGrapplingHook","LaunchGrapplingHook"},
        {"/Game/Blueprints/Characters/BP_RookChar.BP_RookChar_C:Grapple","Grapple"},
        {"/Game/Blueprints/Characters/BP_QueenChar.BP_QueenChar_C:HoldPiece","HoldPiece"},
        {"/Game/Blueprints/Characters/BP_QueenChar.BP_QueenChar_C:ReleasePiece","ReleasePiece"},
        {"/Game/Blueprints/Characters/BP_QueenChar.BP_QueenChar_C:Throw Piece","Throw"},
        {"/Game/Blueprints/Characters/Wood/BP_WoodQueenChar.BP_WoodQueenChar_C:HoldPiece","HoldPiece"},
        {"/Game/Blueprints/Characters/Wood/BP_WoodQueenChar.BP_WoodQueenChar_C:ReleasePiece","ReleasePiece"},
        {"/Game/Blueprints/Characters/Wood/BP_WoodQueenChar.BP_WoodQueenChar_C:Throw Piece","Throw"},
        {"/Game/Blueprints/Characters/BSide/BP_BSideQueenChar.BP_BSideQueenChar_C:ThrowPiece","Throw"},
        {"/Game/Blueprints/Characters/BP_BishopChar.BP_BishopChar_C:ThrowGrenade","ThrowGrenade"},
        {"/Game/Blueprints/Characters/BP_KingChar.BP_KingChar_C:FireBeam","FireBeam"},
        {"/Game/Blueprints/Characters/BP_KingChar.BP_KingChar_C:ProjectSlam","ProjectSlam"},
        {"/Game/Blueprints/Characters/BP_KingChar.BP_KingChar_C:SwingingEvent","SwingingEvent"},
        {"/Game/Blueprints/Characters/Wood/BP_WoodKingChar.BP_WoodKingChar_C:FireBeam","FireBeam"},
        {"/Game/Blueprints/Characters/Wood/BP_WoodKingChar.BP_WoodKingChar_C:ProjectSlam","ProjectSlam"},
        {"/Game/Blueprints/Characters/Wood/BP_WoodKingChar.BP_WoodKingChar_C:SwingingEvent","SwingingEvent"},
        -- Piece-specific event paths are needed for cards that change the
        -- represented piece or replace a spawned projectile.  The base
        -- BP_PieceChar hooks remain as a fallback for original variants.
        {"/Game/Blueprints/Characters/BP_PawnChar.BP_PawnChar_C:MainAbility","MainAbility"},
        {"/Game/Blueprints/Characters/BP_PieceChar.BP_PieceChar_C:Set Winner","Set Winner"},
        {"/Game/Blueprints/Characters/BP_PieceChar.BP_PieceChar_C:DeathCleanup","DeathCleanup"},
        {"/Game/Blueprints/Characters/BP_PieceChar.BP_PieceChar_C:EndCombat","EndCombat"},
        {"/Game/Blueprints/Characters/BP_BishopChar.BP_BishopChar_C:MainAbility","MainAbility"},
        {"/Game/Blueprints/Characters/BP_PieceChar.BP_PieceChar_C:ShootObject","ShootObject"},
        {"/Game/Blueprints/Characters/BP_PieceChar.BP_PieceChar_C:ShootObjectServer","ShootObject"},
        {"/Game/Blueprints/Characters/BP_PieceChar.BP_PieceChar_C:ShootObjectMulti","ShootObject"},
        {"/Game/Blueprints/Characters/BP_PieceChar.BP_PieceChar_C:ShootObjectAll","ShootObject"},
        {"/Game/Blueprints/Characters/Wood/BP_WoodPawnChar.BP_WoodPawnChar_C:MainAbility","MainAbility"},
        {"/Game/Blueprints/Characters/BSide/BP_BSidePawnChar.BP_BSidePawnChar_C:MainAbility","MainAbility"},
        {"/Game/Blueprints/Characters/BSide/BP_BSidePawnChar.BP_BSidePawnChar_C:DeathCleanup","DeathCleanup"},
        {"/Game/Blueprints/Characters/Wood/BP_WoodQueenChar.BP_WoodQueenChar_C:MainAbility","MainAbility"},
        {"/Game/Blueprints/Characters/Wood/BP_WoodQueenChar.BP_WoodQueenChar_C:DeathCleanup","DeathCleanup"},
        {"/Game/Blueprints/Characters/BSide/BP_BSideQueenChar.BP_BSideQueenChar_C:MainAbility","MainAbility"},
        {"/Game/Blueprints/Characters/BSide/BP_BSideBishopChar.BP_BSideBishopChar_C:MainAbility","MainAbility"},
        {"/Game/Blueprints/Characters/Wood/BP_WoodBishopChar.BP_WoodBishopChar_C:MainAbility","MainAbility"},
        {"/Game/Blueprints/Characters/Wood/BP_WoodKingChar.BP_WoodKingChar_C:MainAbility","MainAbility"},
        {"/Game/Blueprints/Characters/Wood/BP_WoodKingChar.BP_WoodKingChar_C:DeathCleanup","DeathCleanup"},
        {"/Game/Blueprints/Characters/BSide/BP_BSideKingChar.BP_BSideKingChar_C:MainAbility","MainAbility"},
        {"/Game/Blueprints/Characters/Wood/BP_WoodRookChar.BP_WoodRookChar_C:MainAbility","MainAbility"},
        {"/Game/Blueprints/Characters/Wood/BP_WoodRookChar.BP_WoodRookChar_C:DeathCleanup","DeathCleanup"},
        {"/Game/Blueprints/Characters/BSide/BP_BSideRookChar.BP_BSideRookChar_C:MainAbility","MainAbility"},
        {"/Game/Blueprints/Characters/Wood/BP_WoodKnightChar.BP_WoodKnightChar_C:MainAbility","MainAbility"},
}
local abilityHookRegistry=rawget(_G,"__FPSChessAugmentAbilityHookRegistry") or {}
rawset(_G,"__FPSChessAugmentAbilityHookRegistry",abilityHookRegistry)
local function installAbilityHooks()
    if not SAFE_COMBAT_HOOKS then return true end
    local installed,failed,waiting=0,0,0
    for _,entry in ipairs(abilityPaths) do
        local path,name=entry[1],entry[2]
        if not abilityHookRegistry[path] then
            -- RegisterHook itself raises while a function is not reflected
            -- yet; the retry loop installs those hooks once they load.  A
            -- StaticFindObject pre-check used to drop every registration in
            -- environments whose function wrapper lacks IsValid.
            local ok,err=pcall(function()
                RegisterHook(path,function(context,...)
                    local piece=hookValue(context)
                    local args=table.pack(...)
                    local called,callError=pcall(function()
                        Catalog.onAbility(api,piece,name,table.unpack(args,1,args.n))
                        if Catalog.onCombatEvent then Catalog.onCombatEvent(api,piece,name,table.unpack(args,1,args.n)) end
                    end)
                    if not called then log("능력 효과 처리 실패("..name.."): "..tostring(callError)) end
                end)
            end)
            if ok then abilityHookRegistry[path]=true; installed=installed+1 else waiting=waiting+1 end
        end
    end
    if installed>0 then log(string.format("증강 능력 훅 등록: %d개 추가, %d개 대기",installed,waiting)) end
    if waiting==0 then rawset(_G,abilityHookKey,"AugmentChess") end
    return waiting==0
end
installAbilityHooks()
api.networked=function()
    for _,board in ipairs(FindAllOf("BP_ChessBoard_C") or {}) do
        local solo,localMatch=read(board,"Singleplayer"),read(board,"LocalMultiplayer")
        if solo==true or localMatch==true then return false end
        if solo==false and localMatch==false then return true end
    end
    return nil
end

-- Card rounds are only valid during an active piece-vs-piece fight.  The game
-- keeps the pawn/controller alive while showing the chessboard or a killcam,
-- so checking only Pawn and Dead lets a scheduled draw leak into those screens.
local function nameOf(object)
    local ok,name=pcall(function()
        local class=object and object:GetClass()
        return class and class:GetFName():ToString() or ""
    end)
    return ok and tostring(name):lower() or ""
end
local killcamStateFields={
    "IsKillcamActive","bIsKillcamActive","KillcamActive","bKillcamActive",
    "IsPlayingKillcam","bPlayingKillcam","ReplayActive","bReplayActive",
}
local function hasKillcamName(object)
    if not valid(object) then return false end
    local names={nameOf(object)}
    local ok,fullName=pcall(function() return object:GetFullName():lower() end)
    if ok then names[#names+1]=tostring(fullName) end
    for _,value in ipairs(names) do
        local name=tostring(value):lower()
        if name:find("killcam",1,true) or name:find("deathcam",1,true)
            or name:find("replay",1,true) then return true end
    end
    return false
end
local killcamUiScanAt=-math.huge
local killcamUiScanResult=true
local killcamUiScanWidget=nil
local killcamUiScanRecorder=nil
local KILLCAM_UI_RESCAN_SECONDS=3
local function killcamScreenActive(controller,own,includeUi,forceUiScan)
    if not valid(controller) then return true end
    local target=read(controller,"ViewTarget") or call(controller,"GetViewTarget")
    if hasKillcamName(target) then return true end
    local function hasActiveFlag(object)
        if not valid(object) then return false end
        for _,field in ipairs(killcamStateFields) do
            if read(object,field)==true then return true end
        end
        return false
    end
    if hasActiveFlag(controller) or hasActiveFlag(target) or hasActiveFlag(own) then return true end
    if not includeUi then return false end
    local now=os.clock()
    -- Once a matching killcam object is found, inspect that one object instead
    -- of repeatedly enumerating every UserWidget during the replay.
    if valid(killcamUiScanWidget)
        and call(killcamUiScanWidget,"IsInViewport")==true
        and hasKillcamName(killcamUiScanWidget) then
        killcamUiScanAt=now
        killcamUiScanResult=true
        return true
    end
    if valid(killcamUiScanRecorder) then
        for _,field in ipairs({"Playing","IsPlaying","ReplayActive"}) do
            if read(killcamUiScanRecorder,field)==true then
                killcamUiScanAt=now
                killcamUiScanResult=true
                return true
            end
        end
    end
    local hadCachedObject=killcamUiScanWidget~=nil or killcamUiScanRecorder~=nil
    killcamUiScanWidget=nil
    killcamUiScanRecorder=nil
    if not forceUiScan and not hadCachedObject and now-killcamUiScanAt<KILLCAM_UI_RESCAN_SECONDS then
        return killcamUiScanResult
    end
    -- The full widget enumeration is expensive. Throttle negative scans and
    -- retain the exact matching object after a positive scan. Probe the
    -- dedicated recorder class first so playback usually avoids widget scans.
    local ok,kind,detectedObject=pcall(function()
        for _,recorder in ipairs(FindAllOf("KillcamRecorder_C") or {}) do
            if valid(recorder) then
                for _,field in ipairs({"Playing","IsPlaying","ReplayActive"}) do
                    if read(recorder,field)==true then return "recorder",recorder end
                end
            end
        end
        for _,widget in ipairs(FindAllOf("UserWidget") or {}) do
            if valid(widget) and call(widget,"IsInViewport")==true and hasKillcamName(widget) then
                return "widget",widget
            end
        end
        return nil,nil
    end)
    -- If UI state cannot be inspected safely, suppress the choice for this
    -- transition instead of risking a card overlay over the killcam.
    killcamUiScanAt=now
    if ok and kind=="widget" then killcamUiScanWidget=detectedObject end
    if ok and kind=="recorder" then killcamUiScanRecorder=detectedObject end
    killcamUiScanResult=not ok or kind=="widget" or kind=="recorder"
    return killcamUiScanResult
end
-- Widget, replay-recorder, and board scans are expensive on the AI transition
-- screen.  They do not need to run on every 350 ms scheduler tick: cache the
-- result briefly while still reacting to an actual screen change within half
-- a second.
local combatScreenCacheAt=-math.huge
local combatScreenCacheValue=false
local killcamUiSuppressed=false
local function inspectCombatScreenActive()
    local controller=localController()
    local own=localControlledPiece(controller)
    -- No possessed live chess piece means menu, transition, death, or killcam.
    if not valid(controller) or not valid(own) or read(own,"Dead")==true then return false end
    if killcamScreenActive(controller,own,false) then
        killcamUiSuppressed=true
        return false
    end
    local sawBoardState=false
    for _,board in ipairs(FindAllOf("BP_ChessBoard_C") or {}) do
        if valid(board) then
            local inCombat=read(board,"InCombat")
            if type(inCombat)=="boolean" then
                sawBoardState=true
                if inCombat then return true end
            end
        end
    end
    -- Some game builds do not expose InCombat. In that case retain the old
    -- pawn-based behavior rather than falsely disabling the mod everywhere.
    return not sawBoardState
end
local function combatScreenActive()
    local now=os.clock()
    if now-combatScreenCacheAt<0.5 then return combatScreenCacheValue end
    combatScreenCacheAt=now
    local ok,active=pcall(inspectCombatScreenActive)
    combatScreenCacheValue=ok and active==true
    return combatScreenCacheValue
end
api.combatScreenActive=combatScreenActive
local function cardOfferAllowed(forceUiScan)
    local controller=localController()
    local own=localControlledPiece(controller)
    if not valid(controller) or not valid(own) or read(own,"Dead")==true then return false end
    if killcamScreenActive(controller,own,false) then
        killcamUiSuppressed=true
        return false
    end
    if not combatScreenActive() then return false end
    killcamUiSuppressed=killcamScreenActive(controller,own,true,forceUiScan)
    return not killcamUiSuppressed
end
api.gameMode=function() return call(StaticFindObject("/Script/Engine.Default__GameplayStatics"),"GetGameMode",localController()) end
local statSync=StatSync.new(api,314559.0,Catalog)
local pendingAudits={}
local ownedRecords={}
local function statValue(value)
    return type(value)=="number" and string.format("%.6g",value) or tostring(value)
end
local statLabels={
    ShootDamage="피해량",Health="체력",MaxHealth="최대 체력",
    ShootDelay="공격 간격",MaxWalkSpeed="이동 속도",BaseWalkSpeed="기본 이동 속도",
    DefaultWalkSpeed="기본 이동 속도",ClimbSpeed="벽타기 속도",
    MainAbilityCooldown="주 능력 쿨타임",MovementAbilityCooldown="이동 능력 쿨타임",
    HealthRegenRate="체력 재생량",HealthRegenCooldown="재생 대기 시간",
    ChargeTime="차지 시간",FullChargeArrowTime="완전 충전 시간",
    MinimumArrowPullTime="최소 당기기 시간",ArrowMaxDamage="화살 피해량",
    ChargeDamage="돌진 피해량",ChargeSpeed="돌진 속도",
}
local function statLabel(field) return statLabels[field] or tostring(field) end
local function rememberOwnedCard(piece,card,writes)
    if not valid(piece) or not card then return end
    local localPieceObject=localPiece()
    if not valid(localPieceObject) or api.identity(piece)~=api.identity(localPieceObject) then return end
    ownedRecords[#ownedRecords+1]={
        piece=piece, pieceKey=api.identity(piece), pieceType=Catalog.pieceType(api,piece),
        variant=Catalog.variant(api,piece), card=card, writes=writes or {},
        damageBefore=writes and writes.damageBefore or nil,
        damageAfter=writes and writes.damageAfter or nil,
    }
end
api.auditAugment=function(piece,card,writes,applied)
    local title=card.title.." ["..card.id.."] "..api.className(piece)
    log("스탯 검증: "..title.." 적용="..tostring(applied))
    if applied then rememberOwnedCard(piece,card,writes) end
    if applied and card.special and api.networked()==true and api.authority(piece) then
        statSync:publishSpecial(piece,card.special)
    end
    for _,entry in ipairs(writes) do
        local actual=read(entry.object,entry.field)
        local matches=entry.written and type(actual)=="number" and
            math.abs(actual-entry.expected)<=math.max(0.0001,math.abs(entry.expected)*0.00001)
        log(string.format("  %s: %s -> 요청 %s / 실제 %s [%s]",entry.field,
            statValue(entry.before),statValue(entry.expected),statValue(actual),matches and "일치" or "불일치"))
        if matches and api.networked()==true then
            local field={id=entry.field}
            if api.identity(entry.object)~=api.identity(piece) then
                if field.id=="MaxWalkSpeed" then field={id="DefaultWalkSpeed",movement=true}
                else field.component="CharacterMovement" end
            end
            statSync:publish(piece,field,actual)
        end
    end
    pendingAudits[#pendingAudits+1]={title=title,writes=writes,at=os.clock()+2}
end
local function checkAudits()
    for i=#pendingAudits,1,-1 do
        local audit=pendingAudits[i]
        if os.clock()>=audit.at then
            for _,entry in ipairs(audit.writes) do
                log("스탯 재확인: "..audit.title.." | "..entry.field.."="..
                    statValue(read(entry.object,entry.field)).." (적용 요청 "..statValue(entry.expected)..")")
            end
            table.remove(pendingAudits,i)
        end
    end
end

local opened=false
local screen="cards"
local offered,selected,owned={},1,{}
local ownedByPlayer,pendingCard,pendingRound={},nil,nil
local settingsIndex=1
local deadline,nextDraw=nil,nil
local panel,text,message,panelSlot,textSlot,host
local drawTimerHost,drawTimerRoot,drawTimerWidget,drawTimerLabel,drawTimerSlot,drawTimerSignature
local inputController,previousMouse,previousClick,previousHover
local widgetLibrary=StaticFindObject("/Script/UMG.Default__WidgetBlueprintLibrary")
local layoutLibrary=StaticFindObject("/Script/UMG.Default__WidgetLayoutLibrary")
local gameplayStatics=StaticFindObject("/Script/Engine.Default__GameplayStatics")
local warnings={}
local suppressEscapeMenuUntil=0
local match
local cardView
local captureInput
local uiWaitStarted=nil
local runtimeDiagnosticLogged=false
local runtimeCoverageLogged={}
local catalogValid,catalogErrors,catalogCounts=Catalog.validate()
if catalogValid then
    log(string.format("카탈로그 검증 통과: 전체 %d장, 공용 %d장, 기물별 %d/%d/%d/%d/%d/%d장",
        catalogCounts.total,catalogCounts.generic,
        catalogCounts.pieces.pawn,catalogCounts.pieces.knight,catalogCounts.pieces.rook,
        catalogCounts.pieces.bishop,catalogCounts.pieces.queen,catalogCounts.pieces.king))
    local selfTestOk,selfTestTotal,selfTestPassed,selfTestErrors=Catalog.selfTest()
    if selfTestOk then
        log(string.format("카드 적용 회귀 검증 통과: %d/%d장, 우드/샤이니 전용 카드 차단 통과",selfTestPassed,selfTestTotal))
    else
        settings.enabled=false
        log(string.format("카드 적용 회귀 검증 실패: %d/%d장, 증강 기능을 안전하게 중단합니다.",selfTestPassed,selfTestTotal))
        for _,message in ipairs(selfTestErrors) do log("카드 적용 오류: "..message) end
    end
else
    settings.enabled=false
    log("카탈로그 검증 실패: 증강 기능을 안전하게 중단합니다.")
    for _,message in ipairs(catalogErrors) do log("카탈로그 오류: "..message) end
end
local function logRuntimeCoverage(piece)
    local report=Catalog.runtimeCoverage(api,piece)
    local key=tostring(api.identity(piece) or piece)
    if runtimeCoverageLogged[key] then return end
    runtimeCoverageLogged[key]=true
    if #report.missing==0 then
        log(string.format("기물별 증강 필드 검증 통과: %s (%d/%d)",tostring(report.piece),report.covered,report.total))
    else
        log(string.format("기물별 증강 필드 검증: %s (%d/%d), 확인 필요=%s",
            tostring(report.piece),report.covered,report.total,table.concat(report.missing,", ")))
    end
end
local function warnOnce(key,message) if not warnings[key] then warnings[key]=true; log(message) end end

local function consoleString(value)
    if value==nil then return "" end
    if type(value)=="string" then return value end
    local ok,result=pcall(function() return value:get() end)
    if ok and result~=nil then return tostring(result) end
    if type(value)=="table" then
        for _,key in ipairs({"Msg","Command","Value","value"}) do
            if value[key]~=nil then return consoleString(value[key]) end
        end
    end
    return tostring(value)
end

local function consoleReply(message)
    log("콘솔: "..tostring(message))
end
local function removePanel()
    if valid(text) then call(text,"RemoveFromParent") end
    if valid(panel) then call(panel,"RemoveFromParent") end
    panel,text,message,panelSlot,textSlot,host=nil,nil,nil,nil,nil,nil
end
local function restoreInput()
    if valid(inputController) then
        call(inputController,"SetIgnoreMoveInput",false)
        call(inputController,"SetIgnoreLookInput",false)
        local inCombat=type(inputState)=="table" and inputState.combat==true
        local function restoreFlag(name,previous,fallback)
            local value=previous
            if type(value)~="boolean" then value=fallback end
            if type(value)=="boolean" then
                pcall(function() inputController[name]=value end)
            end
        end
        restoreFlag("bShowMouseCursor",previousMouse,not inCombat)
        restoreFlag("bEnableClickEvents",previousClick,not inCombat)
        restoreFlag("bEnableMouseOverEvents",previousHover,not inCombat)
    end
    -- Card mode no longer switches the engine input mode. Restoring it via
    -- UMG's SetInputMode_* during HUD teardown can dereference the same stale
    -- widget that caused the crash, so only restore the controller flags here.
    inputState=nil
    inputController,previousMouse,previousClick,previousHover=nil,nil,nil,nil
end
local function close()
    Hub.setLocked(false)
    opened=false
    screen="cards"
    deadline=nil
    uiWaitStarted=nil
    removePanel()
    if cardView then cardView:destroy() end
    restoreInput()
end
local pauseState=nil
local function setWorldPaused(controller,paused)
    local mode=call(gameplayStatics,"GetGameMode",controller)
    local pauseable=read(mode,"bPauseable")
    -- Temporarily allow only the synchronous card pause operation, then
    -- restore the game's pause setting.
    if type(pauseable)=="boolean" then api.write(mode,"bPauseable",true) end
    local result=call(gameplayStatics,"SetGamePaused",controller,paused)
    if type(pauseable)=="boolean" then api.write(mode,"bPauseable",pauseable) end
    return result==true
end
local function freezeWorld()
    if pauseState then return end
    Hub.setLocked(true)
    if match and not match:isStandalone() then
        -- Keep networking running while each combat pawn is frozen.
        pauseState={actors={}}
        local seen={}
        for _,member in ipairs(match:members()) do
            local piece=member.piece
            local key=api.identity(piece)
            local dilation=read(piece,"CustomTimeDilation")
            if not seen[key] and type(dilation)=="number" then
                seen[key]=true
                pauseState.actors[#pauseState.actors+1]={piece=piece,value=dilation}
                api.write(piece,"CustomTimeDilation",0)
            end
        end
        return
    end
    if not api.authority(localPiece()) then return end
    local controller=localController()
    local wasPaused=call(gameplayStatics,"IsGamePaused",controller)
    if type(wasPaused)~="boolean" then error("Cannot read world pause state") end
    pauseState={controller=controller,wasPaused=wasPaused}
    if not wasPaused and not setWorldPaused(controller,true) then
        pauseState=nil
        error("Cannot pause card round")
    end
end
local function resumeWorld()
    local state=pauseState
    pauseState=nil
    if state and state.actors then
        for _,entry in ipairs(state.actors) do if valid(entry.piece) then api.write(entry.piece,"CustomTimeDilation",entry.value) end end
    elseif state and not state.wasPaused and valid(state.controller) then
        if not setWorldPaused(state.controller,false) then log("전투 일시정지 해제 실패") end
    end
end
local function suppressEscapeMenu()
    local controller=localController()
    if valid(controller) and not Hub.locked() and InputState.combat(api,controller) then
        call(controller,"SetPause",false)
        if valid(gameplayStatics) then call(gameplayStatics,"SetGamePaused",controller,false) end
    end
    for _,widget in ipairs(FindAllOf("UserWidget") or {}) do
        if valid(widget) and call(widget,"IsInViewport")==true then
            local name=widget:GetClass():GetFName():ToString():lower()
            if name:find("pause",1,true) or name:find("escmenu",1,true) then call(widget,"RemoveFromParent") end
        end
    end
end
local function newObject(class,outer)
    local object=StaticConstructObject(StaticFindObject("/Script/UMG."..class),outer)
    assert(valid(object),class.." creation failed")
    return object
end
local function messageWidget(controller)
    local class=StaticFindObject("/Game/Blueprints/UI/HUD/UMG_ChatMessage.UMG_ChatMessage_C")
    local library=StaticFindObject("/Script/UMG.Default__WidgetBlueprintLibrary")
    local widget=library:Create(controller,class,controller)
    local label=read(widget,"ChatMessage")
    assert(valid(widget) and valid(label),"chat label unavailable")
    local sender=read(widget,"PlayerName")
    if valid(sender) then sender:SetText(FText("")) end
    return widget,label
end
local function wrapHudText(content,width)
    -- This game build does not expose a dependable UMG wrap property for the
    -- chat label used by the mod. Add explicit breaks before assigning text.
    local result,used={},0
    -- The chat label has internal padding and a slightly wider Korean glyph
    -- than its desired-size estimate.  A conservative limit keeps the last
    -- character inside the panel at every resolution.
    local limit=math.max(18,math.floor(width/30))
    for _,code in utf8.codes(tostring(content or "")) do
        local char=utf8.char(code)
        local units=code<128 and 0.55 or 1
        if char=="\n" then
            result[#result+1]="\n"; used=0
        else
            if used+units>limit and used>0 then result[#result+1]="\n"; used=0 end
            result[#result+1]=char; used=used+units
        end
    end
    return table.concat(result)
end
api.localController=localController
api.localPiece=localPiece
api.pieceForController=pieceForController
cardView=CardView.new(api,messageWidget)
local function buildPanel()
    if valid(panel) and valid(text) and valid(message) then return true end
    local controller=localController()
    if not valid(controller) then return false end
    for _,widget in ipairs(FindAllOf("UserWidget") or {}) do
        if valid(widget) and call(widget,"IsInViewport") == true then
            local tree=read(widget,"WidgetTree")
            if valid(tree) then
                local root=read(tree,"RootWidget")
                if valid(root) and api.className(root)=="CanvasPanel" then
                    host=widget
                    local border,newMessage=messageWidget(controller)
                    if valid(border) and valid(newMessage) then
                        panel=border
                        text=newMessage
                        panel:SetBrushColor({R=0.035,G=0.045,B=0.08,A=0.97})
                        panelSlot=root:AddChildToCanvas(panel)
                        panelSlot:SetPosition({X=36,Y=48})
                        panelSlot:SetSize({X=930,Y=560})
                        panelSlot:SetZOrder(10020)
                        textSlot=root:AddChildToCanvas(text)
                        textSlot:SetPosition({X=58,Y=70})
                        textSlot:SetAutoSize(false)
                        textSlot:SetSize({X=886,Y=516})
                        textSlot:SetZOrder(10021)
                        panel:SetVisibility(4)
                        text:SetVisibility(4)
                        return true
                    end
                end
            end
        end
    end
    return false
end
local function readPieceField(piece,field)
    local value=read(piece,field)
    if value~=nil then return value end
    local movement=read(piece,"CharacterMovement")
    return read(movement,field)
end
local function signedChange(before,after)
    if type(before)~="number" or type(after)~="number" then return "" end
    local delta=after-before
    if math.abs(delta)<0.000001 then return "변화 없음" end
    return (delta>0 and "+" or "")..statValue(delta)
end
local function inventoryLines()
    local lines={"보유 카드  |  C / Esc 닫기", "카드 적용 전 → 적용 시 값 · 현재 최종값", ""}
    if #ownedRecords==0 then
        lines[#lines+1]="아직 적용된 카드가 없습니다."
        lines[#lines+1]="콘솔에서 fpschess_augment get <카드ID>로 시험할 수 있습니다."
        return lines
    end
    local piece=localPiece()
    for index,record in ipairs(ownedRecords) do
        local card=record.card
        lines[#lines+1]=string.format("%d. [%s] %s",index,tostring(card.rarity or ""),tostring(card.title or card.id))
        lines[#lines+1]="   "..tostring(card.text or "")
        local shown=0
        for _,entry in ipairs(record.writes or {}) do
            if entry.field and not tostring(entry.field):find("^__",1) then
                local final=read(entry.object,entry.field)
                if type(final)~="number" then final=entry.actual end
                local expected=entry.expected
                local before=entry.before
                if type(before)=="number" and type(expected)=="number" then
                    lines[#lines+1]=string.format("   %s: %s → %s (%s) | 최종 %s",
                        statLabel(entry.field),statValue(before),statValue(expected),signedChange(before,expected),statValue(final))
                else
                    lines[#lines+1]=string.format("   %s | 최종 %s",statLabel(entry.field),statValue(final))
                end
                shown=shown+1
            end
        end
        if card.kind=="damage_reduction" then
            local before=record.damageBefore or 1
            local after=record.damageAfter or Catalog.damageMultiplier(api,piece)
            local final=Catalog.damageMultiplier(api,piece)
            lines[#lines+1]=string.format("   받는 피해 배율: %s%% → %s%% | 최종 %s%%",
                statValue(before*100),statValue(after*100),statValue(final*100))
            shown=shown+1
        elseif shown==0 and card.special then
            local active=valid(piece) and Catalog.hasSpecial(api,piece,card.special)
            lines[#lines+1]="   특수 효과 상태: "..(active and "활성" or "확인 대기")
            shown=1
        elseif shown==0 then
            local fields={}
            for _,effect in ipairs(card.effects or {}) do
                for _,field in ipairs(effect.fields or {}) do fields[#fields+1]=field end
            end
            local seen={}
            for _,field in ipairs(fields) do
                if not seen[field] then
                    seen[field]=true
                    local value=readPieceField(piece,field)
                    if value~=nil then
                        lines[#lines+1]=string.format("   최종 %s: %s",statLabel(field),statValue(value))
                        shown=shown+1
                    end
                end
            end
        end
        lines[#lines+1]=""
    end
    lines[#lines+1]="카드로 변경된 값은 다음 카드 효과가 반영된 현재 기물 기준으로 표시됩니다."
    return lines
end
local function hideDrawTimer()
    if valid(drawTimerWidget) then call(drawTimerWidget,"RemoveFromParent") end
    drawTimerHost,drawTimerRoot,drawTimerWidget,drawTimerLabel,drawTimerSlot,drawTimerSignature=nil,nil,nil,nil,nil,nil
end
local function ensureDrawTimer()
    if valid(drawTimerWidget) and valid(drawTimerRoot) then return true end
    local controller=localController()
    if not valid(controller) then return false end
    local candidates={}
    local own=read(localPiece(),"PieceHUD")
    if valid(own) then candidates[#candidates+1]=own end
    for _,kind in ipairs({"PieceHUD_C","UserWidget"}) do
        for _,widget in ipairs(api.findAll(kind) or {}) do candidates[#candidates+1]=widget end
    end
    for _,hostCandidate in ipairs(candidates) do
        if valid(hostCandidate) and call(hostCandidate,"IsInViewport")==true then
            local tree=read(hostCandidate,"WidgetTree")
            local root=read(tree,"RootWidget")
            if valid(root) and api.className(root)=="CanvasPanel" then
                local widget,label=messageWidget(controller)
                if not valid(widget) or not valid(label) then return false end
                widget:SetVisibility(3)
                widget:SetRenderTransformPivot({X=0,Y=0})
                local slot=root:AddChildToCanvas(widget)
                slot:SetAutoSize(false)
                slot:SetPosition({X=36,Y=24})
                slot:SetSize({X=420,Y=44})
                slot:SetZOrder(11000)
                drawTimerHost,drawTimerRoot=hostCandidate,root
                drawTimerWidget,drawTimerLabel,drawTimerSlot=widget,label,slot
                return true
            end
        end
    end
    return false
end
local function renderDrawTimer()
    -- Keep the draw deadline internal, but do not create a transient UMG
    -- widget during combat. This is the same HUD-rebuild window that caused
    -- the native 0x10 access violation; the card fallback logs the remaining
    -- time when a round opens instead.
    hideDrawTimer()
end
local function renderInventory()
    if not buildPanel() then warnOnce("inventory-ui","보유 카드 화면을 붙일 게임 HUD가 없습니다."); return end
    local layout=StaticFindObject("/Script/UMG.Default__WidgetLayoutLibrary")
    local viewport=call(layout,"GetViewportSize",localController()) or {X=1280,Y=720}
    local viewportWidth=viewport.X or 1280
    local viewportHeight=viewport.Y or 720
    local lines=inventoryLines()
    local widest=0
    for _,line in ipairs(lines) do
        local units=0
        for _,code in utf8.codes(tostring(line)) do units=units+(code<128 and 0.55 or 1) end
        widest=math.max(widest,units)
    end
    local logicalWidth=math.max(900,math.min(1450,widest*28+72))
    local scale=math.min(1,(viewportWidth-48)/logicalWidth,(viewportHeight-48)/860)
    local content=wrapHudText(table.concat(lines,"\n"),logicalWidth-72)
    local lineCount=1
    for _ in content:gmatch("\n") do lineCount=lineCount+1 end
    local logicalHeight=math.min(860,math.max(300,76+lineCount*29))
    local panelWidth=logicalWidth*scale
    local panelHeight=logicalHeight*scale
    local x=(viewportWidth-panelWidth)/2
    local y=(viewportHeight-panelHeight)/2
    if valid(panelSlot) then panelSlot:SetPosition({X=x,Y=y}); panelSlot:SetSize({X=panelWidth,Y=panelHeight}) end
    if valid(textSlot) then
        textSlot:SetPosition({X=x+36*scale,Y=y+28*scale})
        textSlot:SetSize({X=(logicalWidth-72)*scale,Y=(logicalHeight-56)*scale})
    end
    message:SetText(FText(content))
    call(text,"ForceLayoutPrepass")
    local desired=call(text,"GetDesiredSize") or {X=1,Y=1}
    local fit=math.min(1,(logicalWidth-72)*scale/math.max(1,desired.X),(logicalHeight-56)*scale/math.max(1,desired.Y))
    call(text,"SetRenderScale",{X=fit,Y=fit})
end
local function render()
    if not opened then
        renderDrawTimer()
        return
    end
    hideDrawTimer()
    if screen=="cards" or screen=="waiting" then
        local remaining=deadline and math.max(0,math.ceil(deadline-os.clock())) or -1
        if not cardView:render(offered,selected,screen=="waiting",remaining,#owned,settings.maximum) then
            warnOnce("card-ui","카드 화면을 붙일 HUD를 기다리는 중입니다.")
            uiWaitStarted=uiWaitStarted or os.clock()
            if os.clock()-uiWaitStarted>=5 then
                log("카드 화면 표시 실패: 선택을 취소하고 조작을 복구합니다.")
                match:cancel(); close()
            end
            return
        end
        uiWaitStarted=nil
        -- CardView uses key binds only. Touching PlayerController input flags
        -- while combat HUD is rebuilt can crash outside Lua's protected call.
        cardView.inputAttached=true
        return
    end
    if not buildPanel() then warnOnce("ui","증강 카드 UI를 붙일 게임 HUD가 없습니다."); return end
    if screen=="inventory" then
        renderInventory()
        return
    end
    local remaining=math.max(0,math.ceil((deadline or os.clock())-os.clock()))
    if screen=="settings" then
        local rows={
            {"증강 체스",settings.enabled and "켜짐" or "꺼짐"},
            {"시작 카드 드로우",settings.start and "켜짐" or "꺼짐"},
            {"카드 드로우 주기",settings.interval.."초"},
            {"보유 카드 최대",settings.maximum.."장"},
            {"한 번에 제안할 카드",settings.count.."장"},
            {"카드 선택 시간",settings.selection.."초"},
            {"즉시 카드 뽑기","주기·보유 한도 무시"},
        }
        local lines={"증강 체스  |  설정", "W / S 항목 · A / D 값 조절 · Space 실행 · F8 닫기", ""}
        for index,row in ipairs(rows) do
            lines[#lines+1]=(index==settingsIndex and "▶ " or "   ")..row[1].." : "..row[2]
        end
        lines[#lines+1]=""
        lines[#lines+1]="설정은 현재 게임에 즉시 적용됩니다. 즉시 카드 뽑기는 보유 한도를 넘어도 실행됩니다."
        local viewport=valid(layoutLibrary) and call(layoutLibrary,"GetViewportSize",localController()) or nil
        local viewportWidth=viewport and viewport.X or 1280
        local viewportHeight=viewport and viewport.Y or 720
        local function units(source)
            local total=0
            for _,code in utf8.codes(tostring(source or "")) do total=total+(code<128 and 0.55 or 1) end
            return total
        end
        local widest=0
        for _,line in ipairs(lines) do widest=math.max(widest,units(line)) end
        local logicalWidth=math.max(760,math.min(1040,widest*30+72))
        local scale=math.min(1,(viewportWidth-48)/logicalWidth,(viewportHeight-48)/760)
        local content=wrapHudText(table.concat(lines,"\n"),logicalWidth-72)
        local lineCount=1
        for _ in content:gmatch("\n") do lineCount=lineCount+1 end
        local logicalHeight=math.min(760,math.max(300,76+lineCount*32))
        local panelWidth=logicalWidth*scale
        local panelHeight=logicalHeight*scale
        local x=(viewportWidth-panelWidth)/2
        local y=(viewportHeight-panelHeight)/2
        if valid(panelSlot) then
            panelSlot:SetPosition({X=x,Y=y})
            panelSlot:SetSize({X=panelWidth,Y=panelHeight})
        end
        if valid(textSlot) then
            textSlot:SetPosition({X=x+36*scale,Y=y+28*scale})
            textSlot:SetSize({X=(logicalWidth-72)*scale,Y=(logicalHeight-56)*scale})
        end
        message:SetText(FText(content))
        call(text,"ForceLayoutPrepass")
        local desired=call(text,"GetDesiredSize") or {X=1,Y=1}
        local fit=math.min(1,(logicalWidth-72)*scale/math.max(1,desired.X),(logicalHeight-56)*scale/math.max(1,desired.Y))
        call(text,"SetRenderScale",{X=fit,Y=fit})
        return
    end
end
captureInput=function()
    local currentOk,currentValid=pcall(valid,inputController)
    if currentOk and currentValid then return end
    local controllerOk,controller=pcall(localController)
    if not controllerOk then
        inputController=nil
        log("입력 상태 저장 건너뜀: PlayerController 조회 실패: "..tostring(controller))
        return
    end
    inputController=controller
    local validOk,controllerValid=pcall(valid,inputController)
    if not validOk or not controllerValid then
        inputController=nil
        log("입력 상태 저장 건너뜀: 유효한 PlayerController 없음")
        return
    end
    local stateOk,state=pcall(function() return InputState.capture(api,inputController) end)
    if not stateOk or type(state)~="table" then
        inputController=nil
        log("입력 상태 저장 건너뜀: 상태 캡처 실패: "..tostring(state))
        return
    end
    inputState=state
    local function safeRead(name)
        local ok,value=pcall(read,inputController,name)
        if ok then return value end
    end
    previousMouse=safeRead("bShowMouseCursor")
    previousClick=safeRead("bEnableClickEvents")
    previousHover=safeRead("bEnableMouseOverEvents")
    call(inputController,"SetIgnoreMoveInput",true)
    call(inputController,"SetIgnoreLookInput",true)
    pcall(function() inputController.bShowMouseCursor=true end)
    pcall(function() inputController.bEnableClickEvents=true end)
    pcall(function() inputController.bEnableMouseOverEvents=true end)
end
-- Declared before openLocalOffer: the earlier card-open path calls this,
-- and a forward reference would resolve to a nil global at runtime.
local function laptopPlacement()
    local pawn=read(localController(),"Pawn")
    return valid(pawn) and not isPiece(pawn)
end
local function resolveBlockedOffer()
    if not match then return end
    local ok,standalone=pcall(function() return match:isStandalone() end)
    if ok and standalone then
        pcall(function() match:cancel() end)
    else
        -- In an online round, submit the existing timeout fallback so peers are
        -- not left frozen waiting for a player who is in the killcam.
        pcall(function() match:submit(1) end)
    end
end

local function openLocalOffer(round,cards)
    -- The host already filtered players at their card cap.  Do not apply the
    -- local cap again here: a forced draw intentionally bypasses it.
    if opened and screen~="settings" then return end
    if not cardOfferAllowed(true) then
        log("카드 선택 차단: 사망/킬캠/비전투 상태")
        resolveBlockedOffer()
        return
    end
    if hub then hub:close() end
    if opened then close() end
    if laptopPlacement() then return end
    local piece=localControlledPiece()
    if not valid(piece) then return end

    offered=cards or Catalog.offer(settings.count,api,piece)
    selected=1
    deadline=match:isStandalone() and os.clock()+settings.selection or nil
    Hub.setLocked(true)
    opened=true
    screen="cards"
    pendingRound=round
    log("카드 제안 열림")
    render()
end
local function validLocalPiece()
    local piece=localPiece()
    if not valid(piece) then return false end
    if read(piece,"Dead")==true then return false end
    local own=read(piece,"PieceHUD")
    if not valid(own) then return false end
    return true
end

local function openOffer(reason,forced)
    local result=false
    if not settings.enabled then return false end
        if not cardOfferAllowed(true) then
        log("카드 드로우 차단: 사망/킬캠/비전투 상태")
        resolveBlockedOffer()
        return false
    end
    local piece=localControlledPiece()
    if not valid(piece) then return false end
    if laptopPlacement() then return false end
    if match then
        -- The periodic draw clock is paused while the choice modal is open.
        -- A successful card round resets it from the resume callback instead
        -- of allowing the old deadline to expire behind the UI.
        result=match:begin(reason,forced)
        if result then nextDraw=nil end
    end
    log("카드 드로우 요청: "..tostring(reason)..", 결과="..tostring(result)..", 강제="..tostring(forced==true))
    return result
end
local function prepareNavigation()
    -- C/F8 are global navigation keys: dismiss the shared F3 panel instead
    -- of letting the panel's busy flag swallow these always-on bindings.
    if Hub.busy() then Hub.dismiss() end
    if opened and (screen=="cards" or screen=="waiting") then
        if match then pcall(function() match:cancel() end) end
        close()
    elseif Hub.locked() then
        -- Recover a shared lock left behind when a round is interrupted
        -- during a combat/HUD transition so C and F8 remain usable.
        if match and match.active then pcall(function() match:cancel() end) end
        Hub.setLocked(false)
    end
    return true
end

local function openSettings()
    if not prepareNavigation() then return end
    if opened and screen~="settings" then return end
    if opened then close(); return end
    opened=true
    screen="settings"
    settingsIndex=1
    deadline=nil
    captureInput()
end
local function openInventory()
    if not prepareNavigation() then return end
    if opened and (screen=="cards" or screen=="waiting" or screen=="settings") then return end
    if opened and screen=="inventory" then close(); return end
    opened=true
    screen="inventory"
    deadline=nil
    Hub.setLocked(true)
    captureInput()
end
local function adjustSetting(delta)
    if screen~="settings" then return end
    if settingsIndex==1 then settings.enabled=not settings.enabled
    elseif settingsIndex==2 then settings.start=not settings.start
    elseif settingsIndex==3 then settings.interval=clamp(settings.interval+delta*30,30,300,60)
    elseif settingsIndex==4 then settings.maximum=clamp(settings.maximum+delta,1,10,3)
    elseif settingsIndex==5 then settings.count=clamp(settings.count+delta,1,5,3)
    elseif settingsIndex==6 then settings.selection=clamp(settings.selection+delta*10,10,300,60)
    end
end
local function settingsConfirm()
    if screen~="settings" then return end
    if settingsIndex==7 then
        close()
        openOffer("설정 강제 드로우",true)
    end
end
local function choose()
    if not opened or screen~="cards" or not cardView.layout then return end
    if not cardOfferAllowed(true) then
        resolveBlockedOffer()
        if opened then close() end
        return
    end
    local card=offered[selected]
    local piece=localControlledPiece()
    if not card or not valid(piece) then close(); return end
    if match then
        pendingCard=card
        screen="waiting"
        if not match:submit(selected) then screen="cards"; pendingCard=nil end
        render()
        return
    end
    local ok,message=Catalog.apply(api,piece,card)
    if ok then
        owned[#owned+1]=card
        nextDraw=os.clock()+settings.interval
        log(message)
    else
        log("카드 적용 실패: "..message)
    end
    close()
end
api.localController=localController
api.localPiece=localPiece
match=MatchSync.new(api,Catalog,settings,{
    ownedCount=function(key) return ownedByPlayer[key] or 0 end,
    freeze=function() freezeWorld() end,
    open=function(round,cards) openLocalOffer(round,cards) end,
    waiting=function() end,
    grant=function(key,card)
        ownedByPlayer[key]=(ownedByPlayer[key] or 0)+1
        if key==api.identity(localController()) then owned[#owned+1]=card end
    end,
    resume=function(round,granted)
        -- Host records cards only after successful application in grant().
        if granted==true and not api.authority(localController()) and pendingRound==round and pendingCard then
            owned[#owned+1]=pendingCard
            rememberOwnedCard(localPiece(),pendingCard,nil)
        end
        pendingCard,pendingRound=nil,nil
        resumeWorld()
        if opened then close() end
        log("카드 선택 종료: 전투 입력 복구")
        nextDraw=os.clock()+settings.interval    end,
})
rawset(_G,"__augment_test_refs",{api=api,match=match,settings=settings,Catalog=Catalog})

-- UE4's in-game console reaches PlayerController:SendToConsole.  This is

-- deliberately a small command surface instead of a general Lua evaluator:
-- it can list the cards valid for the current piece and grant one by id/title.
-- The same Catalog.apply path as the normal card UI is used, so a console
-- result cannot bypass piece filtering or the write/audit checks.
local function handleConsoleCommand(rawCommand)
    local text=consoleString(rawCommand):gsub("\r"," "):gsub("\n"," ")
    local action,argument=text:match("^%s*fpschess_augment%s*(%S*)%s*(.-)%s*$")
    if not action then return end
    action=action:lower()
    argument=argument or ""
    local piece=localPiece()
    local pieceType=valid(piece) and Catalog.pieceType(api,piece) or nil
    local variant=valid(piece) and Catalog.variant(api,piece) or nil
    if action=="help" or action=="?" or action=="" then
        consoleReply("사용법: fpschess_augment list | fpschess_augment get <카드ID>")
        consoleReply("예: fpschess_augment get pawn_headhunter (현재 기물에 적용)")
        return
    end
    if action=="list" then
        local available=Catalog.cardsForPiece(pieceType,variant)
        consoleReply("현재 기물="..tostring(pieceType).." ("..tostring(variant).."), 사용 가능한 카드="..tostring(#available))
        for _,card in ipairs(available) do
            consoleReply(card.id.." | "..card.title)
        end
        return
    end
    if action~="get" and action~="give" and action~="apply" then
        -- Also accept `fpschess_augment <id>` for quick testing.
        argument=table.concat({action,argument}," "):gsub("^%s+",""):gsub("%s+$","")
    end
    if action=="get" or action=="give" or action=="apply" then
        if argument=="" then
            consoleReply("카드 ID가 필요합니다. 먼저 fpschess_augment list를 입력하세요.")
            return
        end
    end
    if not valid(piece) or not api.isPiece(piece) then
        consoleReply("현재 전투 기물을 찾지 못했습니다.")
        return
    end
    if api.networked and api.networked()==true and not api.authority(piece) then
        consoleReply("온라인에서는 호스트만 콘솔 카드 지급을 실행할 수 있습니다.")
        return
    end
    local card=Catalog.findCard(argument,pieceType,variant)
    if not card then
        consoleReply("현재 기물에 맞는 카드를 찾지 못했습니다: "..argument)
        return
    end
    if opened then match:cancel(); close() end
    local ok,message=Catalog.apply(api,piece,card)
    if not ok then
        consoleReply("카드 적용 실패: "..tostring(message).." ["..card.id.."]")
        return
    end
    owned[#owned+1]=card
    local ownerKey=api.identity(localController())
    ownedByPlayer[ownerKey]=(ownedByPlayer[ownerKey] or 0)+1
    consoleReply("카드 지급 완료: "..card.title.." ["..card.id.."] — "..tostring(message))
end

-- Unreal's console owns the input buffer and the Tab key.  Registering
-- FAutoCompleteCommand entries with ConsoleSettings lets the native console
-- perform completion without stealing the key or trying to edit Slate's
-- private text box from Lua.  The command handler above remains the authority
-- for validation, so a completion entry can never bypass piece filtering.
local consoleAutocompleteKey="__FPSChessAugmentConsoleAutocompleteInstalled"
local function installConsoleAutocomplete()
    if rawget(_G,consoleAutocompleteKey) then return true end

    -- The ConsoleSettings array is owned by Unreal.  Do not resize or mutate
    -- its reflected TArray from Lua at runtime: this build exposes the array's
    -- storage but not a safe SetNum/Add operation.  The entries are supplied
    -- by Config/DefaultEngine.ini before UConsole builds its Tab tree, and we
    -- only verify that the expected merged count is present here.
    local configuredSettings=StaticFindObject("/Script/EngineSettings.Default__ConsoleSettings")
    local configuredList=valid(configuredSettings) and read(configuredSettings,"ManualAutoCompleteList") or nil
    local configuredCount=0
    local countOk=pcall(function() configuredCount=configuredList:GetArrayNum() end)
    local sampleIndex,sampleType,sampleValueType="?","?","?"
    local sampleOk=pcall(function()
        configuredList:ForEach(function(index,element)
            sampleIndex=index
            sampleType=type(element)
            local valueOk,value=pcall(function() return element:get() end)
            if valueOk then sampleValueType=type(value) end
            return true
        end)
    end)
    log("콘솔 Tab 배열 래퍼 확인: count="..tostring(configuredCount)..", foreach="..tostring(sampleOk)..", index="..tostring(sampleIndex)..", element="..tostring(sampleType)..", value="..tostring(sampleValueType))
    local entries={
        {Command="fpschess_augment",Desc="증강 체스 콘솔 명령"},
        {Command="fpschess_augment help",Desc="증강 체스 콘솔 명령 사용법"},
        {Command="fpschess_augment list",Desc="현재 기물에 허용된 카드 목록"},
        {Command="fpschess_augment get",Desc="현재 기물에 카드 지급: get <카드ID>"},
        {Command="fpschess_augment give",Desc="현재 기물에 카드 지급: give <카드ID>"},
        {Command="fpschess_augment apply",Desc="현재 기물에 카드 지급: apply <카드ID>"},
    }
    for _,card in ipairs(Catalog.allCards()) do
        entries[#entries+1]={Command="fpschess_augment get "..card.id,Desc="증강 카드 ID: "..card.id}
    end
    if not countOk or configuredCount<#entries then
        log("콘솔 Tab 자동완성 등록 실패: 배열 용량 부족 또는 접근 실패")
        return false
    end

    local firstIndex=nil
    local writeOk,writeError=pcall(function()
        configuredList:ForEach(function(index,element)
            if firstIndex==nil then firstIndex=index end
            local slot=index-firstIndex+1
            if slot<=#entries then
                local value=element:get()
                value.Command=entries[slot].Command
                value.Desc=entries[slot].Desc
            end
        end)
    end)
    if not writeOk then
        log("콘솔 Tab 자동완성 등록 실패: "..tostring(writeError))
        return false
    end
    pcall(function() configuredSettings.bDisplayHelpInAutoComplete=true end)
    local firstCommand,lastCommand="?","?"
    local function commandText(value)
        local ok,text=pcall(function() return value:ToString() end)
        if ok then return tostring(text) end
        return tostring(value)
    end
    pcall(function()
        configuredList:ForEach(function(index,element)
            local slot=index-firstIndex+1
            if slot==1 or slot==#entries then
                local value=element:get()
                if slot==1 then firstCommand=commandText(value.Command) end
                if slot==#entries then lastCommand=commandText(value.Command) end
            end
        end)
    end)
    rawset(_G,consoleAutocompleteKey,"AugmentChess")
    log("콘솔 Tab 자동완성 등록 완료: "..tostring(#entries).."개 항목, 첫 항목="..firstCommand..", 마지막 항목="..lastCommand)
    return true
end
--[[

    local settingsObject=StaticFindObject("/Script/EngineSettings.Default__ConsoleSettings")
    if not valid(settingsObject) then
        log("콘솔 자동완성 대기: ConsoleSettings를 아직 찾지 못했습니다")
        return false
    end

    local entries={}
    local seen={}
    local function add(command,description)
        command=tostring(command or "")
        if command=="" or seen[command] then return end
        seen[command]=true
        entries[#entries+1]={Command=command,Desc=tostring(description or "")}
    end

    -- Preserve entries supplied by the game when the reflected array can be
    -- enumerated as a Lua table.  UE4SS exposes this property as TArray in
    -- this build, so the final write below uses the array's existing storage.
    local existing=read(settingsObject,"ManualAutoCompleteList")
    if type(existing)=="table" then
        for _,entry in ipairs(existing) do
            if type(entry)=="table" then
                add(entry.Command or entry.command,entry.Desc or entry.desc)
            end
        end
    end

    add("fpschess_augment","증강 체스 콘솔 명령")
    add("fpschess_augment help","증강 체스 콘솔 명령 사용법")
    add("fpschess_augment list","현재 기물에 허용된 카드 목록")
    add("fpschess_augment get","현재 기물에 카드 지급: get <카드ID>")
    add("fpschess_augment give","현재 기물에 카드 지급: give <카드ID>")
    add("fpschess_augment apply","현재 기물에 카드 지급: apply <카드ID>")

    -- Register every known ID so typing `fpschess_augment get ` and pressing
    -- Tab cycles through card IDs.  Catalog.findCard still checks the current
    -- piece and variant when the completed command is executed.
    for _,card in ipairs(Catalog.allCards()) do
        add("fpschess_augment get "..card.id,card.title.." ["..card.id.."]")
    end

    local listOk,listError=false,nil
    if type(existing)=="userdata" then
        local arrayCount
        local countOk,countError=pcall(function() arrayCount=existing:GetArrayNum() end)
        if countOk and type(arrayCount)=="number" and #entries<=arrayCount then
            listOk=true
            for index,entry in ipairs(entries) do
                local elementOk,elementError=pcall(function()
                    local element=existing[index-1]
                    element.Command=entry.Command
                    element.Desc=entry.Desc
                end)
                if not elementOk then
                    listOk=false
                    listError=elementError
                    break
                end
            end
            -- Clear the unused tail.  This keeps old engine entries from
            -- appearing after the mod's command list while retaining the
            -- TArray allocation owned by ConsoleSettings.
            if listOk then
                for index=#entries,arrayCount-1 do
                    pcall(function()
                        local element=existing[index]
                        element.Command=""
                        element.Desc=""
                    end)
                end
            end
        else
            listError=countError or "ManualAutoCompleteList capacity is too small"
        end
    else
        listOk,listError=pcall(function()
            settingsObject.ManualAutoCompleteList=entries
        end)
    end
    if not listOk then
        log("콘솔 자동완성 목록 대입 실패: type="..type(listError).." value="..tostring(listError))
        return false
    end
    local helpOk,helpError=pcall(function()
        settingsObject.bDisplayHelpInAutoComplete=true
    end)
    if not helpOk then
        log("콘솔 자동완성 도움말 옵션 대입 실패: type="..type(helpError).." value="..tostring(helpError))
        return false
    end

    rawset(_G,consoleAutocompleteKey,"AugmentChess")
    log("콘솔 Tab 자동완성 등록 완료: "..tostring(#entries).."개 항목")
    return true
end

local consoleHookKey="__FPSChessAugmentConsoleCommandHookInstalled"
if not rawget(_G,consoleHookKey) then
    local consoleHookOk,consoleHookError=pcall(function()
        RegisterHook("/Script/Engine.PlayerController:SendToConsole",function(context,command)
            handleConsoleCommand(command)
        end)
    end)
    if consoleHookOk then
        rawset(_G,consoleHookKey,"AugmentChess")
        log("콘솔 카드 명령 준비 완료: fpschess_augment list|get <카드ID>")
    else
        log("콘솔 카드 명령 훅 등록 실패: "..tostring(consoleHookError))
    end
]]
installConsoleAutocomplete()

-- The command handler must be connected to the engine console separately
-- from the autocomplete list.  Keep the hook idempotent because UE4SS may
-- reload this Lua file without restarting the process.
local consoleHookKey="__FPSChessAugmentConsoleCommandHookInstalled"
if not rawget(_G,consoleHookKey) then
    local consoleHookOk,consoleHookError=pcall(function()
        RegisterHook("/Script/Engine.PlayerController:SendToConsole",function(context,command)
            handleConsoleCommand(command)
        end)
    end)
    if consoleHookOk then
        rawset(_G,consoleHookKey,"AugmentChess")
        log("콘솔 카드 명령 훅 등록 완료: fpschess_augment list|get <카드ID>")
    else
        log("콘솔 카드 명령 훅 등록 실패: "..tostring(consoleHookError))
    end
end

local function bind(key,action,always)
    RegisterKeyBind(key,function()
        ExecuteInGameThread(function()
            if not opened and not always then return end
            if Hub.busy() and not always then return end
            if key==0x43 or key==0x77 then log("전역 단축키 입력 감지: VK="..tostring(key)) end
            local stage="action"
            local ok,errorValue=pcall(action)
            if ok then
                stage="render"
                ok,errorValue=pcall(render)
            end
            if not ok then
                local detail=tostring(errorValue)
                if type(errorValue)=="function" and debug and type(debug.getinfo)=="function" then
                    local infoOk,info=pcall(function() return debug.getinfo(errorValue,"nS") end)
                    if infoOk and type(info)=="table" then
                        detail=detail.." [함수명="..tostring(info.name)..",종류="..tostring(info.what)..",소스="..tostring(info.short_src)..",줄="..tostring(info.linedefined).."]"
                    end
                end
                warnOnce("input-error-"..tostring(key),"증강 단축키 오류: VK="..tostring(key)..", 단계="..stage..", 오류형="..type(errorValue)..", 내용="..detail)
                if opened then pcall(close) end
            end
        end)
    end)
end
local function moveSelection(delta)
    if screen=="settings" then adjustSetting(delta)
    elseif screen=="cards" and #offered>0 then selected=((selected-1+delta)%#offered)+1 end
end
bind(0x41,function() moveSelection(-1) end)
bind(0x44,function() moveSelection(1) end)
bind(0x25,function() moveSelection(-1) end)
bind(0x27,function() moveSelection(1) end)
bind(0x01,function()
    if screen~="cards" then return end
    local index=cardView:hit(false)
    if index then selected=index; choose() end
end)
bind(0x57,function() if screen=="settings" then settingsIndex=((settingsIndex-2)%7)+1 end end)
bind(0x53,function() if screen=="settings" then settingsIndex=(settingsIndex%7)+1 end end)
bind(0x20,function() if screen=="settings" then settingsConfirm() else choose() end end)
bind(0x77,openSettings,true)
bind(0x43,openInventory,true)
bind(0x1B,function()
    if opened then
        if screen=="settings" or screen=="inventory" then close() end
        suppressEscapeMenuUntil=os.clock()+0.4
        suppressEscapeMenu()
    end
end,true)
local started,seeded=false,false
local abilityHookRetryCount=0
LoopAsync(1000,function()
    if not SAFE_COMBAT_HOOKS or (rawget(_G,damageReductionHookKey) and rawget(_G,pointDamageHookKey)) or damageHookRetryCount>=30 then return end    damageHookRetryCount=damageHookRetryCount+1
    ExecuteInGameThread(function()
        local complete=installDamageHooks()
        if not complete and damageHookRetryCount>=30 then
            log("피해 훅 대기 시간 초과: 이번 실행에서 피해 감소/헤드샷 보정 일부 비활성")
        end
    end)
end)
LoopAsync(1000,function()
    if not SAFE_COMBAT_HOOKS or rawget(_G,abilityHookKey) or abilityHookRetryCount>=30 then return end
    abilityHookRetryCount=abilityHookRetryCount+1
    ExecuteInGameThread(function()
        local complete=installAbilityHooks()
        if not complete and abilityHookRetryCount>=30 then
            log("증강 능력 훅 대기 시간 초과: 일부 특수 효과는 이번 실행에서 비활성")
        end
    end)
end)
local battleIdentity=nil
local cardPhaseFailed=false
LoopAsync(350,function()
    ExecuteInGameThread(function()
      if cardPhaseFailed then return end
      local cardStage="combat screen"
      local ok,err=xpcall(function()
        local screenActive=combatScreenActive()
        if killcamUiSuppressed then screenActive=cardOfferAllowed() end
        if not screenActive then
            hideDrawTimer()
            if opened and (screen=="cards" or screen=="waiting") then
                resolveBlockedOffer()
                if opened then close() end
            elseif match and match.active then
                resolveBlockedOffer()
            end
            if match then match:tick() end
            started=false
            seeded=false
            battleIdentity=nil
            nextDraw=nil
            return
        end
        if opened and (screen=="cards" or screen=="waiting") and not cardOfferAllowed() then
            hideDrawTimer()
            resolveBlockedOffer()
            if opened then close() end
            if match then match:tick() end
            started=false
            seeded=false
            battleIdentity=nil
            nextDraw=nil
            return
        end
        local piece=localPiece()
        if not runtimeDiagnosticLogged then
            runtimeDiagnosticLogged=true
            log("카드 런타임 확인: piece="..tostring(valid(piece))..", isPiece="..tostring(api.isPiece(piece))..", dead="..tostring(read(piece,"Dead"))..", authority="..tostring(api.authority(piece))..", enabled="..tostring(settings.enabled)..", start="..tostring(settings.start))
        end
        if not valid(piece) or read(piece,"Dead")==true then
            hideDrawTimer()
            if battleIdentity then
                match:cancel()
                close()
                started=false; seeded=false; battleIdentity=nil
                nextDraw=nil
                owned,ownedByPlayer={},{}
                ownedRecords={}
            end
            -- Keep marker cleanup lightweight while no live combat pawn exists.
            match:cleanupMarkers()
            if opened and screen=="settings" then render() end
            return
        end
        cardStage="audit"
        checkAudits()
        cardStage="stat sync"
        statSync:receive()
        cardStage="runtime coverage"
        logRuntimeCoverage(piece)
        cardStage="battle identity"
        local currentIdentity=api.identity(piece)
        if battleIdentity and battleIdentity~=currentIdentity then
            hideDrawTimer()
            match:cancel(); close(); started=false; seeded=false; nextDraw=nil; owned,ownedByPlayer={},{}
            ownedRecords={}
        end
        battleIdentity=currentIdentity
        if not seeded then
            local address=tostring(piece:GetAddress())
            local seed=os.time()
            for index=1,#address do seed=seed+index*string.byte(address,index) end
            math.randomseed(seed)
            seeded=true
        end
        local now=os.clock()
        -- Submit the visible highlighted card before the host resolves expiry.
        if opened and screen=="cards" and deadline and now>=deadline then choose() end
        cardStage="match sync"
        match:tick()
        cardStage="special effects"
        Catalog.tick(api)
        cardStage="card draw"
        if not started then
            started=opened or not (settings.enabled and settings.start)
            if not opened and settings.enabled and settings.start and laptopPlacement()~=true and validLocalPiece() then
                started=openOffer("전투 시작")==true
                if not started then nextDraw=now+settings.interval end
            elseif not opened and not laptopPlacement() and validLocalPiece() then
                nextDraw=now+settings.interval
            end
        elseif opened and screen=="cards" and deadline and now>=deadline then
            choose()
        elseif settings.enabled and not opened and #owned<settings.maximum and nextDraw and now>=nextDraw then
            openOffer("주기 드로우")
        end
        cardStage="render"
        render()
      end,function(err)
        local detail="단계="..cardStage..", 오류유형="..type(err)..", 내용="..tostring(err)
        -- UE4SS does not always return a string from debug.traceback; keep the stage readable.
        local traceOk,trace=pcall(function() return debug.traceback(detail,2) end)
        return traceOk and type(trace)=="string" and trace or detail
      end)
      if not ok then
        warnOnce(tostring(err),"카드 단계 오류: "..tostring(err))
        cardPhaseFailed=true
        settings.enabled=false
        if match and match.active then pcall(function() match:cancel() end) end
        if opened then pcall(close) end
      end
    end)
end)
local hoverQueued=false
LoopAsync(33,function()
    if not opened or screen~="cards" or hoverQueued then return end
    hoverQueued=true
    ExecuteInGameThread(function()
        local ok,err=pcall(function()
            if not opened or screen~="cards" then return end
            local index=cardView:hit(true)
            if index and index~=selected then selected=index; render() end
        end)
        hoverQueued=false
        if not ok then warnOnce("hover",tostring(err)) end
    end)
end)
LoopAsync(80,function()
    if os.clock()<suppressEscapeMenuUntil then
        ExecuteInGameThread(function() suppressEscapeMenu() end)
    end
end)
hub=Hub.new("augment",api,messageWidget,{
    close=function() if opened and screen=="settings" then close() end end,
    suppressEscape=suppressEscapeMenu,
    rows=function() return {
        {label="증강 체스",value=settings.enabled and "켜짐" or "꺼짐",kind="toggle"},
        {label="전투 시작 카드",value=settings.start and "켜짐" or "꺼짐",kind="toggle"},
        {label="드로우 주기 (초)",value=settings.interval},
        {label="최대 보유 카드",value=settings.maximum},
        {label="제안 카드 수",value=settings.count},
        {label="AI 선택 제한시간 (초)",value=settings.selection},
        {label="즉시 카드 뽑기",value="실행",kind="launch"},
    } end,
    apply=function(index,delta,value)
        if index==1 then settings.enabled=not settings.enabled
        elseif index==2 then settings.start=not settings.start
        elseif index==3 then settings.interval=clamp(value or settings.interval+delta*30,30,300,60)
        elseif index==4 then settings.maximum=clamp(value or settings.maximum+delta,1,10,3)
        elseif index==5 then settings.count=clamp(value or settings.count+delta,1,5,3)
        elseif index==6 then settings.selection=clamp(value or settings.selection+delta*10,10,300,60)
        elseif index==7 then openOffer("F3 강제 드로우",true) end
    end,
})
log(string.format("Loaded [card-ui-v4]. 시작 드로우=%s, 주기=%d초, 보유 최대=%d, 제안=%d장",tostring(settings.start),settings.interval,settings.maximum,settings.count))
