-- FPS Chess does not replicate every combat-timing property.  In particular,
-- ShootDelay and the two ability cooldown defaults are consulted on the
-- owning player's client.  This bridge sends those values through replicated,
-- invisible TargetPoint actors.  It deliberately does not use chat, HUD
-- values, or an ability as a transport channel.
local Sync = {}
local Limits=require("StatLimits")
Sync.__index = Sync

local MAGIC_X = 314159.0
local SPECIAL_MAGIC_OFFSET = 1000.0
-- Keep this table in a fixed order.  The numeric code is sent over the
-- network, so two clients with the same mod version resolve it identically.
-- It contains every numeric field exposed by the editor from the base,
-- Shiny, and Wood piece data, not just attack timing.
local FIELD_LIST = {
    {id="Health"}, {id="MaxHealth"}, {id="ShootDamage"}, {id="ShootDelay"},
    {id="DefaultWalkSpeed", movement=true}, {id="JumpZVelocity", component="CharacterMovement"},
    {id="MainAbilityCooldown"}, {id="MovementAbilityCooldown"}, {id="BulletSpeed"},
    {id="BulletStrength"}, {id="HitscanRange"}, {id="Accuracy"}, {id="HitmarkerDelay"},
    {id="blockRefreshRate"}, {id="blockCooldown"}, {id="HealthRegenRate"},
    {id="HealthRegenCooldown"}, {id="MaxBlockedDamage"}, {id="AccumulatedVentDistance"},
    {id="AllyFiringSpeed"}, {id="AllyMaxCount"}, {id="AllyMaxHealth"}, {id="AllyShootDamage"}, {id="AllyWalkSpeed"},
    {id="ArrowMaxDamage"}, {id="BaseWalkSpeed"}, {id="BeamPullSpeed"}, {id="BeamPushSpeed"},
    {id="blockedDamage"}, {id="BurstCount"}, {id="ChargeDamage"}, {id="ChargeSpeed"},
    {id="ClimbSpeed"}, {id="CloseRange"}, {id="crosshairDistance"}, {id="CurrentBurstCount"},
    {id="CurrentGlideSpeed"}, {id="CurrentGrappleDistance"}, {id="DamageFalloffRate"},
    {id="DoneChargingSpeed"}, {id="FlyingSpeedMultiplier"}, {id="GatlingDamage"},
    {id="GlideExplosionDamage"}, {id="GlidingDamageMultiplier"}, {id="GrappleDistance"},
    {id="GrappleLaunchSpeed"}, {id="GrappleRange"}, {id="GrappleSpeed"},
    {id="GrenadeExplosionStrength"}, {id="GrenadeLaunchStrength"}, {id="HazardCooldown"},
    {id="HazardCount"}, {id="HelicopterDamage"}, {id="JumpCharges"}, {id="JumpCurrentCount"},
    {id="JumpCurrentCountPreJump"}, {id="JumpDistance"}, {id="JumpMaxCount"},
    {id="LaserInstantDamage"}, {id="LaserTickCount"}, {id="MaxAllyCount"},
    {id="MaxAllyWalkSpeed"}, {id="maxDamage"}, {id="MaxDamageRange"}, {id="MaxHazardCount"},
    {id="MaxJumpCharges"}, {id="MaxSlamRange"}, {id="MaxVentCount"}, {id="MaxWallCount"},
    {id="MaxWallCount_0"}, {id="MinDamage"}, {id="MinHazardDistance"}, {id="MinLedgeDistance"},
    {id="NetCullDistanceSquared"}, {id="PiecePullSpeed"}, {id="ReloadDelay"},
    {id="RocketLaunchStrength"}, {id="ShotCount"}, {id="Shotgun_Count"}, {id="ShotMaxDamage"},
    {id="SprintSpeed"}, {id="StartJuicingCooldown"}, {id="SwordPushStrength"},
    {id="ThrowableRange"}, {id="ThrowDamage"}, {id="VentCount"}, {id="WallDistance"}, {id="WallZDistance"},
    {id="ChargeTime"}, {id="FullChargeArrowTime"}, {id="MinimumArrowPullTime"},
    {id="FullChargeTime"}, {id="Minimum Charge Shot Time"}, {id="ChargeAccel"},
    {id="ArrowMaxPower"}, {id="GrenadeUpDirection"}, {id="GlideDamping"},
    {id="GlideAccelForce"}, {id="StopVelocity"}, {id="AccelDecayRate"},
    {id="ScopedSensitivity"}, {id="ScopedMultiplier"}, {id="UnscopedAccuracy"},
    {id="GrappleForce"}, {id="GrappleTimeout"}, {id="UpWallZRate"}, {id="MaxUpWallZ"},
    {id="ChargeCollisionPower"}, {id="ChargePieceMultiplier"}, {id="PlayerHitZOverride"},
    {id="CameraArrowAlpha"}, {id="FlightTime"}, {id="FlightForce"},
    {id="FlightInitialForce"}, {id="ThrowVelocity"}, {id="ThrowOffsetZ"},
    {id="BeamTime"}, {id="BeamDPS"}, {id="SwingInvincibleTime"}, {id="SlamHeight"},
    {id="SlamPeakHeight"}, {id="SlamVelocity"}, {id="SlamLedgeHeight"},
    {id="SwingDelay"}, {id="SwordSwingDelay"}, {id="MeleeAttackDelay"}, {id="AttackDelay"},
}
local FIELD_CODES, CODE_FIELDS = {}, {}
for code, definition in ipairs(FIELD_LIST) do
    FIELD_CODES[definition.id] = code
    CODE_FIELDS[code] = definition
end

local function finite(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

function Sync.new(api,channel,catalog)
    local self=setmetatable({
        api = api,
        magic=channel or MAGIC_X,
        catalog=catalog,
        revisions = {},
        lastReceived = {},
        markers = {},
        specialCodes = {},
        specialNames = {},
    }, Sync)
    -- Special-card state is not a reflected property, so it needs its own
    -- deterministic numeric code on the same replicated TargetPoint bridge.
    -- Derive the table from the catalog order so every mod copy agrees.
    if catalog and catalog.allCards then
        local nextCode=0
        for _,card in ipairs(catalog.allCards() or {}) do
            if card.special and not self.specialCodes[card.special] then
                nextCode=nextCode+1
                self.specialCodes[card.special]=nextCode
                self.specialNames[nextCode]=card.special
            end
        end
    end
    return self
end

function Sync:cleanupMarkers()
    local now = os.clock()
    for key, entry in pairs(self.markers) do
        local marker = entry.marker
        if not self.api.valid(marker) then
            self.markers[key] = nil
        elseif now - entry.created >= 15 and self.api.authority(marker) then
            -- A marker exists only to carry one replicated update.  Keeping
            -- every historical update forever leaks actors into the match.
            self.api.call(marker, "K2_DestroyActor")
            self.markers[key] = nil
        end
    end
end

function Sync:fieldCode(field)
    return field and FIELD_CODES[field.id] or nil
end

function Sync:markerKey(piece, code)
    return self.api.identity(piece) .. ":" .. tostring(code)
end

function Sync:location(code, value, revision)
    -- Each code occupies its own exact X coordinate.  Y carries the value;
    -- Z is a monotonically increasing revision.  Each update gets a fresh
    -- actor, so we never depend on a movement RPC being exposed by this game.
    return { X = self.magic + code, Y = value, Z = revision }
end

function Sync:specialLocation(code, revision)
    return { X = self.magic + SPECIAL_MAGIC_OFFSET + code, Y = 0, Z = revision }
end

function Sync:decode(location)
    local ok, x, value, revision = pcall(function() return location.X, location.Y, location.Z end)
    if not ok or not finite(x) or not finite(value) or not finite(revision) then return nil end
    local code = math.floor((x - self.magic) + 0.5)
    if math.abs(x - (self.magic + code)) > 0.01 then return nil end
    return CODE_FIELDS[code], value, math.floor(revision + 0.5)
end

function Sync:decodeSpecial(location)
    local ok,x,revision=pcall(function() return location.X,location.Z end)
    if not ok or not finite(x) or not finite(revision) then return nil end
    local code=math.floor((x-(self.magic+SPECIAL_MAGIC_OFFSET))+0.5)
    if math.abs(x-(self.magic+SPECIAL_MAGIC_OFFSET+code))>0.01 then return nil end
    return self.specialNames[code],math.floor(revision+0.5)
end

function Sync:spawn(piece, code, value, revision)
    local world = self.api.world(piece)
    local targetPoint = self.api.findClass("/Script/Engine.TargetPoint")
    if not self.api.valid(world) or not self.api.valid(targetPoint) then
        return nil, "복제 동기화 클래스를 찾지 못했습니다."
    end
    local marker, spawnError
    local ok, result = pcall(function()
        return world:SpawnActor(targetPoint, self:location(code, value, revision), { Pitch = 0, Yaw = 0, Roll = 0 })
    end)
    if ok then marker = result else spawnError = result end
    if not self.api.valid(marker) then
        return nil, "복제 동기화 액터 생성 실패: " .. tostring(spawnError or "알 수 없는 오류")
    end
    -- TargetPoint has no mesh.  These calls keep it invisible, always relevant
    -- for the peer, and ensure movement updates carry later values.
    self.api.call(marker, "SetOwner", piece)
    self.api.call(marker, "SetActorHiddenInGame", true)
    self.api.call(marker, "SetReplicates", true)
    self.api.write(marker, "bAlwaysRelevant", true)
    self.api.call(marker, "ForceNetUpdate")
    return marker
end

function Sync:spawnSpecial(piece, code, revision)
    -- Reuse the normal replicated TargetPoint setup; the offset keeps this
    -- packet outside the numeric-field range while preserving owner/revision.
    return self:spawn(piece,SPECIAL_MAGIC_OFFSET+code,0,revision)
end

function Sync:publish(piece, field, value)
    self:cleanupMarkers()
    local code = self:fieldCode(field)
    if not code or not self.api.authority(piece) then return true end
    local key = self:markerKey(piece, code)
    local revision = (self.revisions[key] or 0) + 1
    -- A fresh actor is intentional.  Spawn location is part of the network
    -- spawn packet, whereas this UE4SS build cannot safely rely on a reflected
    -- SetActorLocation overload.  The revision lets peers discard old actors.
    local marker, errorText = self:spawn(piece, code, value, revision)
    if not self.api.valid(marker) then return false, errorText end
    self.revisions[key] = revision
    self.markers[key] = { marker = marker, created = os.clock() }
    self.api.log("온라인 동기화 전송: " .. field.id .. " = " .. string.format("%g", value) .. " (#" .. revision .. ")")
    return true
end

function Sync:publishSpecial(piece, special)
    self:cleanupMarkers()
    local code=self.specialCodes[special]
    if not code or not self.api.authority(piece) then return true end
    local key=self:markerKey(piece,"special:"..tostring(code))
    local revision=(self.revisions[key] or 0)+1
    local marker,errorText=self:spawnSpecial(piece,code,revision)
    if not self.api.valid(marker) then return false,errorText end
    self.revisions[key]=revision
    self.markers[key]={marker=marker,created=os.clock()}
    self.api.log("온라인 특수 효과 동기화 전송: "..tostring(special).." (#"..revision..")")
    return true
end

function Sync:receive()
    self:cleanupMarkers()
    local markers = self.api.findAll("TargetPoint") or {}
    for _, marker in ipairs(markers) do
        if self.api.valid(marker) then
            local location=self.api.call(marker, "K2_GetActorLocation") or self.api.call(marker, "GetActorLocation")
            local special,specialRevision=self:decodeSpecial(location)
            local target = self.api.call(marker, "GetOwner")
            if special and self.api.valid(target) and not self.api.authority(target) then
                local code=self.specialCodes[special]
                local key=self:markerKey(target,"special:"..tostring(code))
                local previous=self.lastReceived[key]
                if not previous or specialRevision>previous.revision then
                    if self.catalog and self.catalog.addSpecial and self.catalog.addSpecial(self.api,target,special) then
                        self.lastReceived[key]={revision=specialRevision,value=special}
                        self.api.log("온라인 특수 효과 동기화: "..tostring(special))
                    end
                end
            end
            local definition, value, revision = self:decode(location)
            if not special and definition and finite(value) and self.api.valid(target) and not self.api.authority(target) then
                value=Limits.clamp(definition,value)
                local key = self:markerKey(target, FIELD_CODES[definition.id])
                local previous = self.lastReceived[key]
                if not previous or revision > previous.revision then
                    local owner = definition.component and self.api.read(target, definition.component) or target
                    local ok = self.api.valid(owner) and self.api.write(owner, definition.id, value)
                    if ok then
                        if definition.movement then
                            local movement = self.api.read(target, "CharacterMovement")
                            if self.api.valid(movement) then self.api.write(movement, "MaxWalkSpeed", value) end
                            self.api.write(target, "BaseWalkSpeed", value)
                        end
                        if (definition.id == "Health" or definition.id == "MaxHealth") and self.api.enableHealthRegen then
                            self.api.enableHealthRegen(target)
                        end
                        self.api.refresh(target)
                        self.lastReceived[key] = { revision = revision, value = value }
                        self.api.log("온라인 동기화: " .. definition.id .. " = " .. string.format("%g", value))
                    end
                end
            end
        end
    end
end

return Sync

