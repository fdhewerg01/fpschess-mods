-- Host-authoritative card round transport.  Start and resume states are
-- replicated through invisible TargetPoint actors.  Each start marker belongs
-- to one player's pawn and carries a private card seed in its spawn location.
local Sync={}
Sync.__index=Sync
local MAGIC,START,RESUME,CANCEL=271828.0,1,2,3
local CHOICE_PREFIX="FPSChessAugmentChoice:"
local CHOICE_RETRY_INTERVAL=0.35
local CHOICE_MAX_ATTEMPTS=6
local SIDE_ZERO_X_BIT,SIDE_ONE_X_BIT=0.125,0.375
local function now() return os.clock() end

local function unwrapMessage(value)
    if type(value)=="string" then return value end
    if value==nil then return nil end
    -- UE4SS versions expose FString/StrProperty hook arguments in slightly
    -- different wrappers.  Accept the direct value, a named parameter table,
    -- and the common wrapper accessors so the server hook sees the same
    -- payload that the client sent.
    if type(value)=="table" then
        for _,key in ipairs({"Msg","Message","message",1}) do
            local nested=value[key]
            if type(nested)=="string" then return nested end
        end
    end
    local function normalize(result)
        if type(result)=="string" then return result end
        if result==nil then return nil end
        local ok,text=pcall(function() return result:ToString() end)
        return ok and type(text)=="string" and text or nil
    end
    local ok,result=pcall(function() return value:get() end)
    result=normalize(result)
    if result then return result end
    for _,field in ipairs({"Value","Msg","Message","message"}) do
        ok,result=pcall(function() return value[field] end)
        result=normalize(result)
        if result then return result end
    end
    ok,result=pcall(function() return value:ToString() end)
    if ok and type(result)=="string" then return result end
    return nil
end

local function hookController(context)
    local ok,controller=pcall(function() return context:get() end)
    return ok and controller or nil
end

function Sync.new(api,catalog,settings,callbacks)
    local self=setmetatable({api=api,catalog=catalog,settings=settings,callbacks=callbacks,
        active=nil,round=0,seenStart={},seenResume={},signals={},markers={}},Sync)
    -- This RPC only receives an already-selected card from a remote player.
    -- Unlike damage/ability hooks it does not run during AI pawn creation,
    -- so keep multiplayer choice delivery enabled in combat-hook safe mode.
    if rawget(_G,"__FPSChessDisableNetworkHooks") then return self end
    RegisterHook("/Script/Engine.PlayerController:ServerExecRPC",function(context,message)
        -- ServerExecRPC is shared by unrelated game traffic. Filter the
        -- payload and active round before dereferencing the UObject context;
        -- only our exact choice message needs controller/authority checks.
        if not self.active then return end
        local text=unwrapMessage(message)
        if not text then return end
        local roundText,choiceText=text:match("^FPSChessAugmentChoice:(%d+):(%d+)$")
        if not roundText then return end
        local round,choice=tonumber(roundText),tonumber(choiceText)
        if not round or not choice or self.active.round~=round
            or choice<1 or choice>self.settings.count then return end
        local controller=hookController(context)
        if not api.valid(controller) or not api.authority(controller) then return end
        if not self.active or self.active.round~=round then return end
        local key=api.identity(controller)
        if self.active.members[key] and not self.active.choices[key] then
            self.signals[key]={choice=choice,round=round,untilAt=now()+0.10}
            self.api.log("카드 RPC 수신: round="..round..", choice="..choice)
        end
    end)
    return self
end
function Sync:remember(marker)
    if self.api.valid(marker) then self.markers[self.api.identity(marker)]={marker=marker,created=now()} end
    return marker
end
function Sync:cleanupMarkers()
    local current=now()
    for key,entry in pairs(self.markers) do
        if not self.api.valid(entry.marker) then
            self.markers[key]=nil
        elseif not self.active and current-entry.created>=15 and self.api.authority(entry.marker) then
            -- Card round markers are one-shot network packets.  Destroying
            -- them after every peer has had time to receive them prevents a
            -- long match from accumulating invisible actors.
            self.api.call(entry.marker,"K2_DestroyActor")
            self.markers[key]=nil
        end
    end
end

function Sync:piece(controller)
    if self.api.pieceForController then return self.api.pieceForController(controller) end
    return self.api.read(controller,"Pawn") or self.api.call(controller,"GetPawn")
end
function Sync:isStandalone()
    if self.api.networked then
        local online=self.api.networked()
        if online~=nil then return not online end
    end
    local own=self.api.localPiece()
    local world=self.api.world(own)
    local rawMode=self.api.call(world,"GetNetMode")
    local mode=tonumber(rawMode)
    if mode ~= nil then return mode == 0 end
    return self.api.authority(own) and #self:members()<=1
end
function Sync:members()
    local result={}
    for _,controller in ipairs(self.api.findAll("PlayerController") or {}) do
        local piece=self:piece(controller)
        if self.api.valid(controller) and self.api.isPiece(piece) then
            result[#result+1]={controller=controller,piece=piece,key=self.api.identity(controller)}
        end
    end
    return result
end
function Sync:spawn(kind,owner,a,b)
    local world,cls=self.api.world(owner),self.api.findClass("/Script/Engine.TargetPoint")
    if not self.api.valid(world) or not self.api.valid(cls) then return nil end
    local ok,marker=pcall(function() return world:SpawnActor(cls,{X=MAGIC+kind,Y=a,Z=b},{Pitch=0,Yaw=0,Roll=0}) end)
    if not ok or not self.api.valid(marker) then return nil end
    self.api.call(marker,"SetOwner",owner)
    self.api.call(marker,"SetActorHiddenInGame",true)
    self.api.call(marker,"SetReplicates",true)
    self.api.call(marker,"SetReplicateMovement",true)
    self.api.write(marker,"bAlwaysRelevant",true)
    self.api.call(marker,"ForceNetUpdate")
    return marker
end

function Sync:begin(reason,forced)
    local own=self.api.localPiece()
    if self.active or self.settings.enabled==false or not self.api.valid(own) then return false end
    self.round=self.round+1
    self.signals={}
    local standalone=self:isStandalone()
    local active={round=self.round,deadline=now()+self.settings.selection,members={},offers={},choices={},standalone=standalone}
    if standalone then
        local controller=self.api.localController()
        if not self.api.valid(controller) then return false end
        local key=self.api.identity(controller)
        if not forced and self.callbacks.ownedCount(key)>=self.settings.maximum then return false end
        local seed=math.random(100000,8000000)
        active.members[key]={controller=controller,piece=own,key=key}
        active.offers[key]=self.catalog.offerSeeded(self.settings.count,seed,self.api,own)
        self.active=active
        self.callbacks.freeze()
        self.callbacks.open(active.round,active.offers[key])
        self.api.log("로컬 AI 카드 단계 시작: "..reason)
        return true
    end
    if not self.api.authority(own) then return false end
    -- Enumerating PlayerController also resolves each pawn; perform that
    -- potentially expensive lookup once for a single card-round start.
    local members=self:members()
    if #members<2 then return false end -- wait for the other combat pawn
    for _,member in ipairs(members) do
        if forced or self.callbacks.ownedCount(member.key)<self.settings.maximum then
            -- Keep the legacy Z side bit representable in float32. Above
            -- 2^22, adding 0.25 can round away; the X bit below is the primary
            -- side fallback while this cap keeps older clients compatible.
            local seed=math.random(100000,4000000)
            active.members[member.key]=member
            active.offers[member.key]=self.catalog.offerSeeded(self.settings.count,seed,self.api,member.piece)
            -- Put the target side into the replicated float as a fallback.
            -- On some UE4SS builds GetOwner() on a client is a different
            -- wrapper (or nil) even though the TargetPoint arrived.  Black is
            -- replicated on the chess piece and lets the guest identify its
            -- own marker without relying on Lua wrapper identity.
            local side=self:sideCode(member.piece)
            -- Older clients recover the side from Z. New clients also recover
            -- it from a sub-integer X bit, where float32 has much finer spacing
            -- than it does for multi-million-sized seeds.
            local wireSeed=seed+(side==1 and 0.25 or 0)
            -- Own the marker with the controller, not only the pawn.  A
            -- replicated pawn can be reconstructed with a different Lua
            -- wrapper on the guest, while the owning controller is the stable
            -- local-player identity used by the card input path.
            local sideXBit=side==0 and SIDE_ZERO_X_BIT or side==1 and SIDE_ONE_X_BIT or 0
            local marker=self:spawn(START+self.settings.count*10+sideXBit,member.controller,self.round,wireSeed)
            if not self.api.valid(marker) then self.api.log("카드 시작 신호 생성 실패"); self:cancel(); return false end
            self:remember(marker)
        end
    end
    if not next(active.members) then return false end
    self.active=active
    -- Disable the engine's ordinary pause path while the controlled card
    -- round owns
    -- the pause state, so the confirmation cannot open a pause menu.
    local world=self.api.world(own)
    local gameMode=self.api.gameMode and self.api.gameMode() or self.api.call(world,"GetAuthGameMode")
    if self.api.valid(gameMode) then
        self.gameMode,self.previousPauseable=gameMode,self.api.read(gameMode,"bPauseable")
        self.api.write(gameMode,"bPauseable",false)
    end
    self.callbacks.freeze()
    local key=self.api.identity(self.api.localController())
    if active.offers[key] then
        self.seenStart[active.round]=true
        self.callbacks.open(active.round,active.offers[key])
    end
    self.api.log("공동 카드 단계 시작: "..reason)
    return true
end

function Sync:sideCode(piece)
    if not self.api.valid(piece) then return nil end
    local black=self.api.read(piece,"Black")
    if type(black)=="boolean" then return black and 1 or 0 end
    local side=self.api.read(piece,"Side") or self.api.read(piece,"TeamIndex")
    side=tonumber(side)
    if side~=nil then return (math.floor(side+0.5)%2) end
    return nil
end

function Sync:receive()
    self:cleanupMarkers()
    local own=self.api.localPiece()
    local localController=self.api.localController and self.api.localController() or nil
    local function belongsToLocalPlayer(owner)
        if not self.api.valid(owner) then return false end
        if self.api.valid(localController) then
            if self.api.identity(owner)==self.api.identity(localController)
                or self.api.call(owner,"IsLocalController")==true then return true end
            local localState=self.api.read(localController,"PlayerState")
            if self.api.valid(localState) and self.api.identity(owner)==self.api.identity(localState) then return true end
        end
        if self.api.valid(own) and self.api.identity(owner)==self.api.identity(own) then return true end
        local ownedPawn=self.api.read(owner,"Pawn") or self.api.call(owner,"GetPawn")
        if self.api.valid(own) and self.api.valid(ownedPawn)
            and self.api.identity(ownedPawn)==self.api.identity(own) then return true end
        local ownerController=self.api.read(owner,"Controller") or self.api.call(owner,"GetController")
        return self.api.valid(localController) and self.api.valid(ownerController)
            and self.api.identity(ownerController)==self.api.identity(localController)
    end
    local function markerTargetsLocalPlayer(markerOwner,targetCode)
        if belongsToLocalPlayer(markerOwner) then return true end
        return targetCode~=nil and targetCode==self:sideCode(own)
    end
    for _,marker in ipairs(self.api.findAll("TargetPoint") or {}) do
        if self.api.valid(marker) then
            local location=self.api.call(marker,"K2_GetActorLocation") or self.api.call(marker,"GetActorLocation")
            local ok,x,y,z=pcall(function() return location.X,location.Y,location.Z end)
            local rawCode=ok and (x-MAGIC) or -1
            local encoded=rawCode>=0 and math.floor(rawCode+0.5) or -1
            local kind=encoded>=0 and encoded%10 or -1
            local count=math.floor(encoded/10)
            local round=ok and math.floor(y+0.5) or -1
            if kind==START then
                local owner=self.api.call(marker,"GetOwner")
                local wireSeed=ok and tonumber(z) or -1
                local integerSeed=wireSeed>=0 and math.floor(wireSeed) or -1
                local fraction=wireSeed>=0 and (wireSeed-integerSeed) or -1
                local xFraction=encoded>=0 and (rawCode-encoded) or -1
                local xTargetCode=(xFraction>=0.0625 and xFraction<0.1875) and 0
                    or (xFraction>=0.3125 and xFraction<0.4375) and 1 or nil
                -- Preserve reception of older markers, whose X coordinate has
                -- no side bit and whose Z fraction carries the side instead.
                local legacyTargetCode=(fraction>=0.125 and fraction<0.375) and 1
                    or (fraction>=-0.01 and fraction<0.125) and 0 or nil
                local targetCode=xTargetCode
                if targetCode==nil then targetCode=legacyTargetCode end
                if markerTargetsLocalPlayer(owner,targetCode) and not self.seenStart[round] then
                    self.seenStart[round]=true
                    self.clientRound=round
                    self.clientCount=(count>=1 and count<=5) and count or self.settings.count
                    self.callbacks.freeze()
                    -- The fraction is only the target-side bit; the integer
                    -- part is the exact seed selected by the host.
                    local seed=math.floor(z+0.5)
                    self.callbacks.open(round,self.catalog.offerSeeded(self.clientCount,seed,self.api,own))
                    self.api.log("상대 카드 시작 신호 수신: "..round)
                end
            elseif (kind==RESUME or kind==CANCEL) and self.clientRound==round and not self.seenResume[round] then
                self.seenResume[round]=true
                self.clientRound=nil
                self.pendingChoice=nil
                self.callbacks.resume(round,kind==RESUME)
            end
        end
    end
end

function Sync:sendChoice(round,choice,attempt)
    local controller=self.api.localController()
    if not self.api.valid(controller) or self.api.authority(controller) then return false end
    local payload=CHOICE_PREFIX..tostring(round)..":"..tostring(choice)
    -- Call the reflected RPC directly so api.call's defensive error wrapper
    -- cannot hide an invalid parameter shape.  UE4SS accepts a Lua string for
    -- FString; the named-parameter form is retained as a compatibility
    -- fallback for builds that expose the generated function wrapper that way.
    local ok,err=pcall(function() return controller.ServerExecRPC(controller,payload) end)
    if not ok then
        ok,err=pcall(function() return controller.ServerExecRPC(controller,{Msg=payload}) end)
    end
    if ok then
        self.api.log("카드 선택 RPC 전송: round="..round..", choice="..choice..", attempt="..attempt)
        return true
    end
    self.api.log("카드 선택 RPC 전송 실패: "..tostring(err))
    return false
end

function Sync:submit(choice)
    local controller=self.api.localController()
    choice=math.max(1,math.min(self.clientCount or self.settings.count,math.floor(tonumber(choice) or 1)))
    if self.api.valid(controller) and self.api.authority(controller) and self.active then
        local key=self.api.identity(controller)
        if not self.active.members[key] or self.active.choices[key] then return false end
        self.active.choices[key]=choice
    elseif self.clientRound and self.api.valid(controller) and not self.api.authority(controller) then
        local round=self.clientRound
        if not self:sendChoice(round,choice,1) then
            return false
        end
        self.pendingChoice={round=round,choice=choice,attempts=1,nextAt=now()+CHOICE_RETRY_INTERVAL}
    else return false end
    self.callbacks.waiting()
    return true
end

function Sync:restorePause()
    if self.api.valid(self.gameMode) and type(self.previousPauseable)=="boolean" then
        self.api.write(self.gameMode,"bPauseable",self.previousPauseable)
    end
    self.gameMode,self.previousPauseable=nil,nil
end

function Sync:cancel()
    local active=self.active
    local clientRound=self.clientRound
    self.clientRound=nil
    self.active=nil
    self.signals={}
    self:restorePause()
    for _,entry in pairs(self.markers) do
        if self.api.valid(entry.marker) and self.api.authority(entry.marker) then self.api.call(entry.marker,"K2_DestroyActor") end
    end
    self.markers={}
    if active then
        self:remember(self:spawn(CANCEL,self.api.localController and self.api.localController() or self.api.localPiece(),active.round,0))
        self.callbacks.resume(active.round,false)
    elseif clientRound then self.callbacks.resume(clientRound,false) end
end

function Sync:finish()
    local active=self.active
    if not active then return end
    local allApplied=true
    for key,member in pairs(active.members) do
        local card=active.offers[key][active.choices[key] or 1]
        if card then
            local ok,message=self.catalog.apply(self.api,member.piece,card)
            if ok then self.callbacks.grant(key,card) else self.api.log("카드 적용 실패: "..tostring(message)) end
            if not ok then allApplied=false end
        else
            allApplied=false
        end
    end
    self:remember(self:spawn(RESUME,self.api.localController and self.api.localController() or self.api.localPiece(),active.round,0))
    -- Host handles the result immediately, so do not handle its own replicated
    -- resume marker again on the next poll (it would close a newly opened UI).
    self.seenResume[active.round]=true
    self.active=nil
    self.signals={}
    self:restorePause()
    self.callbacks.resume(active.round,allApplied)
end

function Sync:tick()
    self:receive()
    -- A client can lose one RPC packet without losing the card UI state.  A
    -- bounded retry window makes the selection reliable without returning to
    -- the old ServerPause flood that caused ConnectionLost.
    local pending=self.pendingChoice
    if pending and self.clientRound==pending.round then
        if pending.attempts<CHOICE_MAX_ATTEMPTS and now()>=pending.nextAt then
            pending.attempts=pending.attempts+1
            self:sendChoice(pending.round,pending.choice,pending.attempts)
            pending.nextAt=now()+CHOICE_RETRY_INTERVAL
        end
    elseif pending and self.clientRound~=pending.round then
        self.pendingChoice=nil
    end
    if not self.active then return end
    if not self.active.standalone then
        -- Keep the round alive while a replicated pawn/controller is briefly
        -- unavailable.  The deadline path below resolves a real disconnect
        -- with a default choice instead of leaving both UIs stuck forever.
        local present={}; for _,member in ipairs(self:members()) do present[member.key]=true end
        for key in pairs(self.active.members) do
            if not present[key] and not self.active.missingLogged then
                self.active.missingLogged=true
                self.api.log("카드 선택 중 참가자 상태 갱신 대기")
            end
        end
    end
    for key,signal in pairs(self.signals) do
        if now()>=signal.untilAt then
            if signal.round==self.active.round and signal.choice>=1 and signal.choice<=self.settings.count
                and self.active.members[key] and not self.active.choices[key] then self.active.choices[key]=signal.choice end
            self.signals[key]=nil
        end
    end
    local complete=true
    for key,_ in pairs(self.active.members) do if not self.active.choices[key] then complete=false break end end
    if not complete and now()>=self.active.deadline then
        for key in pairs(self.active.members) do
            if not self.active.choices[key] then
                self.active.choices[key]=1
                self.api.log("카드 선택 시간 만료: 기본 카드 적용")
            end
        end
        complete=true
    end
    if complete then self:finish() end
end
return Sync
