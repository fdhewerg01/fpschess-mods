local Limits={}
local positive={Health=1,MaxHealth=1,AllyMaxHealth=1,ShootDelay=0.01,
    AllyFiringSpeed=0.01,ReloadDelay=0.01,SwingDelay=0.01,SwordSwingDelay=0.01,
    MeleeAttackDelay=0.01,AttackDelay=0.01,ChargeTime=0.01,FullChargeArrowTime=0.01,
    MinimumArrowPullTime=0.01,FullChargeTime=0.01,["Minimum Charge Shot Time"]=0.01}
function Limits.minimum(field) return positive[field.id] or 0 end
function Limits.clamp(field,value)
    value=math.max(Limits.minimum(field),value)
    if field.id:find("Count") or field.id:find("Charges") or field.id=="Shotgun_Count" then
        value=math.floor(value+0.5)
    end
    return value
end
return Limits

