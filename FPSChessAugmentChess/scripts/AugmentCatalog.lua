local Catalog = {}

local cards = {
    {id="swift_1", rarity="일반", title="빠른 발걸음 I", text="기본 이동 속도가 10% 증가합니다.", kind="move", amount=0.10},
    {id="powder_1", rarity="일반", title="고급 화약 I", text="피해량이 10% 증가합니다.", kind="damage", amount=0.10},
    {id="reinforce_1", rarity="일반", title="보강 I", text="체력과 최대 체력이 10% 증가합니다.", kind="health", amount=0.10},
    {id="steel_skin_1", rarity="일반", title="강철 피부 I", text="받는 피해가 10% 감소합니다.", kind="damage_reduction", amount=0.10},
    {id="reload_1", rarity="일반", title="빠른 재장전 I", text="공격 속도가 10% 빨라집니다.", kind="attack_speed", amount=0.10},
    {id="cooldown_1", rarity="일반", title="쿨타임 감소 I", text="스킬 쿨타임이 10% 감소합니다.", kind="cooldown", amount=0.10},
    {id="climb_1", rarity="일반", title="암벽 등반 I", text="벽타기 속도가 10% 증가합니다.", kind="climb", amount=0.10},
    {id="healing_factor_1", rarity="일반", title="힐링 팩터 I", text="체력 재생량이 10% 증가합니다.", kind="regen_rate", amount=0.10},
    {id="fast_regen_1", rarity="일반", title="고속 재생 I", text="재생 대기 시간이 10% 감소합니다.", kind="regen_cooldown", amount=0.10},
    {id="swift_2", rarity="레어", title="빠른 발걸음 II", text="기본 이동 속도가 30% 증가합니다.", kind="move", amount=0.30},
    {id="powder_2", rarity="레어", title="고급 화약 II", text="피해량이 30% 증가합니다.", kind="damage", amount=0.30},
    {id="reinforce_2", rarity="레어", title="보강 II", text="체력과 최대 체력이 30% 증가합니다.", kind="health", amount=0.30},
    {id="steel_skin_2", rarity="레어", title="강철 피부 II", text="받는 피해가 30% 감소합니다.", kind="damage_reduction", amount=0.30},
    {id="reload_2", rarity="레어", title="빠른 재장전 II", text="공격 속도가 30% 빨라집니다.", kind="attack_speed", amount=0.30},
    {id="cooldown_2", rarity="레어", title="쿨타임 감소 II", text="스킬 쿨타임이 30% 감소합니다.", kind="cooldown", amount=0.30},
    {id="climb_2", rarity="레어", title="암벽 등반 II", text="벽타기 속도가 30% 증가합니다.", kind="climb", amount=0.30},
    {id="healing_factor_2", rarity="레어", title="힐링 팩터 II", text="체력 재생량이 30% 증가합니다.", kind="regen_rate", amount=0.30},
    {id="fast_regen_2", rarity="레어", title="고속 재생 II", text="재생 대기 시간이 30% 감소합니다.", kind="regen_cooldown", amount=0.30},
    {id="swift_3", rarity="에픽", title="빠른 발걸음 III", text="기본 이동 속도가 50% 증가합니다.", kind="move", amount=0.50},
    {id="powder_3", rarity="에픽", title="고급 화약 III", text="피해량이 50% 증가합니다.", kind="damage", amount=0.50},
    {id="reinforce_3", rarity="에픽", title="보강 III", text="체력과 최대 체력이 50% 증가합니다.", kind="health", amount=0.50},
    {id="steel_skin_3", rarity="에픽", title="강철 피부 III", text="받는 피해가 50% 감소합니다.", kind="damage_reduction", amount=0.50},
    {id="reload_3", rarity="에픽", title="빠른 재장전 III", text="공격 속도가 50% 빨라집니다.", kind="attack_speed", amount=0.50},
    {id="cooldown_3", rarity="에픽", title="쿨타임 감소 III", text="스킬 쿨타임이 50% 감소합니다.", kind="cooldown", amount=0.50},
    {id="climb_3", rarity="에픽", title="암벽 등반 III", text="벽타기 속도가 50% 증가합니다.", kind="climb", amount=0.50},
    {id="healing_factor_3", rarity="에픽", title="힐링 팩터 III", text="체력 재생량이 50% 증가합니다.", kind="regen_rate", amount=0.50},
    {id="fast_regen_3", rarity="에픽", title="고속 재생 III", text="재생 대기 시간이 50% 감소합니다.", kind="regen_cooldown", amount=0.50},
    {id="cooldown_4", rarity="히든", title="쿨타임 감소 IV", text="스킬 쿨타임이 100% 감소합니다.", kind="cooldown", amount=1.00},
    {id="healing_factor_4", rarity="히든", title="힐링 팩터 IV", text="체력 재생량이 100% 증가합니다.", kind="regen_rate", amount=1.00},
    {id="fast_regen_4", rarity="히든", title="고속 재생 IV", text="재생 대기 시간이 100% 감소합니다.", kind="regen_cooldown", amount=1.00},
    {id="swift_4", rarity="히든", title="빠른 발걸음 IV", text="기본 이동 속도가 100% 증가합니다.", kind="move", amount=1.00},
    {id="powder_4", rarity="히든", title="고급 화약 IV", text="피해량이 100% 증가합니다.", kind="damage", amount=1.00},
    {id="reinforce_4", rarity="히든", title="보강 IV", text="체력과 최대 체력이 100% 증가합니다.", kind="health", amount=1.00},
    {id="steel_skin_4", rarity="히든", title="강철 피부 IV", text="받는 피해가 99% 감소합니다.", kind="damage_reduction", amount=0.99},
    {id="reload_4", rarity="히든", title="빠른 재장전 IV", text="공격 속도가 100% 빨라집니다.", kind="attack_speed", amount=1.00},
    {id="climb_4", rarity="히든", title="암벽 등반 IV", text="벽타기 속도가 100% 증가합니다.", kind="climb", amount=1.00},
}

-- Cards from the Obsidian `증강 체스/일반` folder.  `piece` is deliberately
-- a chess-piece family (not an Unreal class); the normal variant receives
-- these cards, while Shiny/Wood/B-side variants receive only shared cards.
local function addPieceCards(piece, entries)
    for _,card in ipairs(entries) do
        card.id=piece.."_"..card.id
        card.piece=piece
        cards[#cards+1]=card
    end
end

addPieceCards("pawn",{
    {id="dash_1",rarity="일반",title="가속",text="이동 능력의 속도가 10% 빨라집니다.",kind="fields",effects={{fields={"SprintSpeed"},op="increase",amount=.10}}},
    {id="bodyshot",rarity="일반",title="총알 강화",text="몸샷의 데미지가 20% 증가합니다.",kind="fields",effects={{fields={"ShootDamage"},op="increase",amount=.20}}},
    {id="dash_2",rarity="일반",title="토끼뜀",text="이동 능력의 속도가 30% 증가합니다.",kind="fields",effects={{fields={"SprintSpeed"},op="increase",amount=.30}}},
    {id="headhunter",rarity="레어",title="헤드헌터",text="헤드샷 데미지가 50% 증가하지만 몸샷 데미지가 75% 감소합니다.",kind="special",special="pawn_headhunter"},
    {id="clone_upgrade",rarity="레어",title="분신 강화",text="최대 분신 수가 1 증가하고 분신 능력의 쿨타임이 50% 감소합니다.",kind="fields",effects={{fields={"AllyMaxCount","MaxAllyCount"},op="add",amount=1},{fields={"MainAbilityCooldown"},op="decrease",amount=.50}}},
    {id="swap",rarity="레어",title="바꿔치기",text="소환된 폰이 있을 때 E를 다시 누르면 가장 먼 분신과 위치를 교환합니다.",kind="special",special="pawn_swap"},
    {id="modern_rifle",rarity="에픽",title="현대식 소총",text="공격 속도가 2배 빨라집니다.",kind="fields",effects={{fields={"ShootDelay"},op="duration_faster",amount=1.00}}},
    {id="fair_duel",rarity="에픽",title="공정한 결투",text="자신과 대상의 E스킬을 사용할 수 없게 합니다.",kind="special",special="pawn_fair_duel"},
    {id="promotion",rarity="에픽",title="강제 승진",text="전투에서 이기면 상대 기물로 승진합니다.",kind="special",special="pawn_promotion"},
    {id="sorrow",rarity="히든",title="폰의 서러움",text="상대 기물 가치에 비례해 피해·체력이 증가하고 공격 속도가 감소합니다.",kind="special",special="pawn_sorrow"},
    {id="army",rarity="히든",title="군대",text="분신 발사 간격이 절반이 되고 분신 최대 수가 5 증가합니다.",kind="fields",effects={{fields={"AllyFiringSpeed"},op="duration_faster",amount=1.00},{fields={"AllyMaxCount","MaxAllyCount"},op="add",amount=5}}},
    {id="water_ghost",rarity="히든",title="물귀신",text="패배하면 상대 기물을 폰으로 바꿉니다.",kind="special",special="pawn_water_ghost"},
})

addPieceCards("knight",{
    {id="charge_speed",rarity="일반",title="차징 속도 감소",text="화살 완전 충전 시간이 20% 감소합니다.",kind="fields",effects={{fields={"FullChargeArrowTime","MinimumArrowPullTime"},op="decrease",amount=.20}}},
    {id="sharp_arrow",rarity="일반",title="날카로운 화살촉",text="완전히 충전된 화살의 피해가 20% 증가합니다.",kind="fields",effects={{fields={"ArrowMaxDamage"},op="increase",amount=.20}}},
    {id="acceleration",rarity="일반",title="가속",text="돌진 거리가 30% 증가합니다.",kind="fields",effects={{fields={"ChargeSpeed"},op="increase",amount=.30}}},
    {id="headbutt_dinosaur",rarity="레어",title="박치기 공룡",text="돌진 쿨타임이 20% 증가하고 데미지와 거리가 40% 증가합니다.",kind="fields",effects={{fields={"MovementAbilityCooldown"},op="scale",amount=1.20},{fields={"ChargeDamage","ChargeSpeed"},op="increase",amount=.40}}},
    {id="fire_arrow",rarity="레어",title="불화살",text="명중한 대상에게 3초 동안 화살 기본 피해의 1/10만큼 지속 피해를 줍니다.",kind="special",special="knight_fire_arrow"},
    {id="self_destruct",rarity="레어",title="자폭?",text="돌진 명중 시 대상 위치에 돌진 피해 절반의 폭발을 일으킵니다.",kind="special",special="knight_self_destruct"},
    {id="focus",rarity="에픽",title="초집중",text="화살 완전 충전 시간은 3배가 되고 최대 피해는 2.5배가 됩니다.",kind="fields",effects={{fields={"FullChargeArrowTime"},op="scale",amount=3},{fields={"ArrowMaxDamage"},op="scale",amount=2.5}}},
    {id="chain_dash",rarity="에픽",title="연속 질주",text="이동 스킬을 연속으로 3번 사용할 수 있습니다.",kind="special",special="knight_chain_dash"},
    {id="arrow_rain",rarity="에픽",title="화살비",text="화살 명중 시 대상 위로 화살비를 내립니다.",kind="special",special="knight_arrow_rain"},
    {id="horse_sprint",rarity="히든",title="명마의 질주",text="돌진 거리·속도·피해·지속시간이 2배, 쿨타임은 50% 감소합니다.",kind="fields",effects={{fields={"ChargeTime","ChargeSpeed","ChargeDamage"},op="scale",amount=2},{fields={"MovementAbilityCooldown"},op="decrease",amount=.50}}},
    {id="homing_arrow",rarity="히든",title="유도 화살",text="모든 화살이 유도 효과를 가집니다.",kind="special",special="knight_homing_arrow"},
    {id="split_arrow",rarity="히든",title="분열 화살",text="화살 발사 시 작은 화살 2개가 추가로 발사됩니다.",kind="special",special="knight_split_arrow"},
})

addPieceCards("rook",{
    {id="outpost",rarity="일반",title="전초 기지",text="벽 개수 제한이 2 증가합니다.",kind="fields",effects={{fields={"MaxWallCount","MaxWallCount_0"},op="add",amount=2}}},
    {id="rope_extension",rarity="일반",title="로프 확장",text="그래플링 훅의 제한 거리가 1.5배가 됩니다.",kind="fields",effects={{fields={"GrappleRange"},op="scale",amount=1.5}}},
    {id="wall",rarity="일반",title="벽",text="체력이 30% 증가합니다.",kind="health",amount=.30},
    {id="cannonball",rarity="레어",title="대포알",text="그래플링 훅으로 적을 맞히면 날아가 피해와 넉백을 줍니다.",kind="special",special="rook_cannonball"},
    {id="steel_wall",rarity="레어",title="강철 벽",text="체력이 60% 증가합니다.",kind="health",amount=.60},
    {id="slow_attack",rarity="레어",title="무거운 장전",text="룩의 공격 속도가 20% 감소합니다.",kind="fields",effects={{fields={"ShootDelay"},op="duration_slower",amount=.20}}},
    {id="ghost",rarity="에픽",title="신출귀몰",text="이동 속도·점프력·벽 등반 속도가 4배가 됩니다.",kind="fields",effects={{fields={"MaxWalkSpeed","BaseWalkSpeed","DefaultWalkSpeed","ClimbSpeed","JumpZVelocity"},op="scale",amount=4}}},
    {id="castle_wall",rarity="에픽",title="성벽",text="체력이 150% 증가합니다.",kind="health",amount=1.50},
    {id="no_melee",rarity="에픽",title="근접전은 싫어",text="가까운 상대일수록 상대의 피해를 감소시킵니다.",kind="special",special="rook_no_melee"},
    {id="anti_materiel",rarity="히든",title="50구경 대물 저격총",text="데미지가 10배 증가합니다.",kind="fields",effects={{fields={"ShootDamage"},op="scale",amount=10}}},
    {id="spiderman",rarity="히든",title="스파이더맨",text="그래플링 훅 사거리 제한이 없어지고 쿨타임이 없어집니다.",kind="fields",effects={{fields={"GrappleRange"},op="set",amount=1000000000},{fields={"MovementAbilityCooldown"},op="set",amount=.01}}},
    {id="steady_scope",rarity="히든",title="고정 조준",text="룩의 비조준 탄퍼짐이 없어집니다.",kind="fields",effects={{fields={"UnscopedAccuracy"},op="set",amount=1}}},
})

addPieceCards("bishop",{
    {id="strong_explosion",rarity="일반",title="더 강한 폭발",text="폭탄의 데미지와 폭발력이 15% 증가합니다.",kind="fields",effects={{fields={"GrenadeExplosionStrength","GlideExplosionDamage"},op="increase",amount=.15}}},
    {id="shotgun",rarity="일반",title="샷건",text="가까운 대상에게 주는 데미지가 최대 30% 증가합니다.",kind="special",special="bishop_close_shotgun"},
    {id="missile",rarity="일반",title="미사일",text="폭탄 속도가 30% 증가합니다.",kind="fields",effects={{fields={"GrenadeLaunchStrength","RocketLaunchStrength"},op="increase",amount=.30}}},
    {id="choke",rarity="레어",title="초크",text="총의 탄퍼짐이 50% 감소합니다.",kind="fields",effects={{fields={"Shotgun_Spread"},op="decrease",amount=.50}}},
    {id="bomb_factory",rarity="레어",title="폭탄 제조 업체",text="폭탄 쿨타임이 30% 감소합니다.",kind="fields",effects={{fields={"MainAbilityCooldown"},op="decrease",amount=.30}}},
    {id="light_bomb",rarity="레어",title="가벼운 폭탄",text="폭탄 피해는 0이 되지만 쿨타임은 80% 감소하고 폭발력은 50% 증가합니다.",kind="fields",effects={{fields={"MainAbilityCooldown"},op="decrease",amount=.80},{fields={"GrenadeExplosionStrength"},op="increase",amount=.50}}},
    {id="enhanced_shotgun",rarity="에픽",title="강화 샷건",text="데미지·사거리가 30% 증가하고 탄 수가 2배가 됩니다.",kind="fields",effects={{fields={"ShootDamage","MaxDamageRange"},op="increase",amount=.30},{fields={"Shotgun_Count"},op="scale",amount=2}}},
    {id="freedom",rarity="에픽",title="자유",text="비행 중 발생하는 모든 비행 속도 감소가 사라집니다.",kind="fields",effects={{fields={"GlideDamping","AccelDecayRate"},op="set",amount=0}}},
    {id="ghost",rarity="에픽",title="신출귀몰",text="이동 속도·점프력·벽 등반 속도가 4배가 됩니다.",kind="fields",effects={{fields={"MaxWalkSpeed","BaseWalkSpeed","DefaultWalkSpeed","ClimbSpeed","JumpZVelocity"},op="scale",amount=4}}},
    {id="shiny_bishop",rarity="히든",title="샤이니 비숍",text="기본 공격이 총알 대신 폭탄을 발사합니다.",kind="special",special="bishop_grenade_shot"},
    {id="sniper_shotgun",rarity="히든",title="샷건을 든 저격수",text="사거리가 크게 증가하고 탄퍼짐이 없어집니다.",kind="fields",effects={{fields={"MaxDamageRange","HitscanRange"},op="set",amount=1000000000},{fields={"Shotgun_Spread"},op="set",amount=0}}},
    {id="big_shotgun",rarity="히든",title="BIG샷건",text="데미지·탄퍼짐이 50% 증가하고 공격 속도는 40% 느려지며 탄 수가 10배가 됩니다.",kind="fields",effects={{fields={"ShootDamage","Shotgun_Spread"},op="increase",amount=.50},{fields={"ShootDelay"},op="duration_slower",amount=.40},{fields={"Shotgun_Count"},op="scale",amount=10}}},
})

addPieceCards("queen",{
    {id="damage",rarity="일반",title="데미지 증가",text="데미지가 20% 증가합니다.",kind="damage",amount=.20},
    {id="rotation",rarity="일반",title="회전 속도 증가",text="공격 속도가 20% 감소합니다.",kind="fields",effects={{fields={"ShootDelay"},op="duration_slower",amount=.20}}},
    {id="quick_move",rarity="일반",title="빠른 이동",text="이동 스킬 쿨타임이 20% 감소합니다.",kind="fields",effects={{fields={"MovementAbilityCooldown"},op="decrease",amount=.20}}},
    {id="gun",rarity="레어",title="총",text="E스킬로 던지는 기물의 속도가 50% 증가합니다.",kind="fields",effects={{fields={"ThrowVelocity"},op="increase",amount=.50}}},
    {id="quick_telekinesis",rarity="레어",title="빠른 염동력",text="E스킬 쿨타임이 40% 감소합니다.",kind="fields",effects={{fields={"MainAbilityCooldown"},op="decrease",amount=.40}}},
    {id="long_flight",rarity="레어",title="장기 체공",text="비행 지속 시간이 2배가 됩니다.",kind="fields",effects={{fields={"FlightTime"},op="scale",amount=2}}},
    {id="bomb_throw",rarity="에픽",title="폭탄 투척",text="던진 기물이 벽이나 상대에 닿으면 40 피해 폭발을 일으킵니다.",kind="special",special="queen_bomb_throw"},
    {id="space_swap",rarity="에픽",title="공간 교환",text="던진 기물이 벽이나 바닥에 닿은 뒤 E를 다시 쓰면 그 위치로 이동합니다.",kind="special",special="queen_space_swap"},
    {id="queen_shield",rarity="에픽",title="여왕의 방패",text="E로 기물을 들고 있는 동안 전방 투사체를 막습니다.",kind="special",special="queen_shield"},
    {id="auto_track",rarity="히든",title="자동 추적",text="E로 날린 기물이 5초 동안 적을 유도합니다.",kind="special",special="queen_auto_track"},
    {id="royal_dignity",rarity="히든",title="왕족의 위엄",text="상대가 자신을 보고 있으면 화면을 아래로 보게 합니다.",kind="special",special="royal_dignity"},
    {id="ricochet",rarity="히든",title="도탄 명령",text="던진 기물이 벽에 부딪히면 적 기물에게 다시 유도됩니다.",kind="special",special="queen_ricochet"},
})

addPieceCards("king",{
    {id="long_beam",rarity="일반",title="오래 지속되는 빔",text="빔 지속 시간이 20% 증가합니다.",kind="fields",effects={{fields={"BeamTime"},op="increase",amount=.20}}},
    {id="strong_beam",rarity="일반",title="강력한 빔",text="빔 끌어당김 힘이 20% 증가합니다.",kind="fields",effects={{fields={"BeamPullSpeed","BeamPushSpeed"},op="increase",amount=.20}}},
    {id="quick_slam",rarity="일반",title="빠른 강타",text="강타 하강 속도가 20% 증가합니다.",kind="fields",effects={{fields={"SlamVelocity"},op="increase_abs",amount=.20}}},
    {id="overheated_beam",rarity="레어",title="과열된 빔",text="빔 초당 피해가 40% 증가합니다.",kind="fields",effects={{fields={"BeamDPS"},op="increase",amount=.40}}},
    {id="sword_roar",rarity="레어",title="검의 포효",text="검을 휘두르면 전방 충격파가 발생해 피해와 넉백을 줍니다.",kind="special",special="king_sword_roar"},
    {id="ground_lock",rarity="레어",title="지면 봉쇄",text="강타 끝 위치에 적 이동 속도를 늦추는 영역을 만듭니다.",kind="special",special="king_ground_lock"},
    {id="judgment",rarity="에픽",title="왕의 심판",text="빔에 맞은 적에게 빔 종료 때 30의 추가 피해를 줍니다.",kind="special",special="king_judgment"},
    {id="sky_strike",rarity="에픽",title="천공의 일격",text="검에 적중한 적을 공중으로 띄웁니다.",kind="fields",effects={{fields={"SwordPushStrength"},op="increase",amount=1.00}}},
    {id="mark",rarity="에픽",title="왕의 낙인",text="빔에 오래 맞은 적에게 낙인을 남기고 다음 검·강타에 추가 피해를 줍니다.",kind="special",special="king_mark"},
    {id="royal_dignity",rarity="히든",title="왕족의 위엄",text="상대가 자신을 보고 있으면 화면을 아래로 보게 합니다.",kind="special",special="royal_dignity"},
    {id="reflect_sword",rarity="히든",title="반사 검무",text="검을 휘두르는 동안 전방 탄환과 투사체를 막고 피해를 반사합니다.",kind="special",special="king_reflect_sword"},
    {id="immortal",rarity="히든",title="불사왕",text="처음 죽을 피해를 받으면 체력을 30% 회복하고 3초 동안 무적이 됩니다.",kind="special",special="king_immortal"},
})

local pools = { ["일반"]={}, ["레어"]={}, ["에픽"]={}, ["히든"]={} }
for _, card in ipairs(cards) do pools[card.rarity][#pools[card.rarity]+1] = card end

local function finite(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- The design rule says an n% numeric bonus uses the larger of the percentage
-- change and n/10.  This keeps small damage values meaningful.  Cooldown is
-- a duration, and attack speed is the inverse of ShootDelay, so both are
-- converted before applying that same rule.
-- The n% rule compares a percentage change with n/10 in a stat-specific
-- unit. Whole-number stats keep the original unit; short durations and rates
-- use hundredths so a small native value is not overwhelmed by a flat bonus.
local fallbackUnit = {
    ShootDamage=1, Health=1, MaxHealth=1,
    MaxWalkSpeed=1, BaseWalkSpeed=1, DefaultWalkSpeed=1, ClimbSpeed=1,
    HealthRegenRate=1,
    ShootDelay=0.01, MainAbilityCooldown=0.01,
    MovementAbilityCooldown=0.01, HealthRegenCooldown=0.01,
    ReloadDelay=0.01, AllyFiringSpeed=0.01,
    SwingDelay=0.01, SwordSwingDelay=0.01,
    MeleeAttackDelay=0.01, AttackDelay=0.01,
    ChargeTime=0.01, FullChargeArrowTime=0.01,
    MinimumArrowPullTime=0.01, FullChargeTime=0.01,
    ["Minimum Charge Shot Time"]=0.01,
}

local function unitFor(field)
    return fallbackUnit[field] or 1
end

local function scalarIncrease(value, amount, unit)
    unit=unit or 1
    return value + math.max(math.abs(value) * amount, amount * 10 * unit)
end
local function scalarDecrease(value, amount, unit)
    unit=unit or 1
    return math.max(0, value - math.max(math.abs(value) * amount, amount * 10 * unit))
end

local function write(api, object, field, value)
    if api.valid(object) and finite(value) then return api.write(object, field, value) end
    return false
end

local function readNumber(api, object, field)
    local value = api.read(object, field)
    return finite(value) and value or nil
end

-- Damage reduction is a gameplay effect rather than a native piece property.
-- Keep the multiplier by replicated piece identity so the authoritative host
-- can apply it to both its own piece and the replicated opponent piece.
local damageMultipliers={}
local specialStates={}
local function stateFor(api,piece)
    local key=api.identity and api.identity(piece) or tostring(piece)
    local state=specialStates[key]
    if not state then state={}; specialStates[key]=state end
    return state
end

function Catalog.addSpecial(api,piece,name)
    if not api.valid(piece) or not api.isPiece(piece) then return false end
    local state=stateFor(api,piece)
    state[name]=(tonumber(state[name]) or 0)+1
    return true
end

function Catalog.hasSpecial(api,piece,name)
    if not api.valid(piece) or not api.isPiece(piece) then return false end
    local key=api.identity and api.identity(piece) or tostring(piece)
    return specialStates[key] and (tonumber(specialStates[key][name]) or 0)>0 or false
end
function Catalog.addDamageReduction(api,piece,amount)
    if not api.valid(piece) or not api.isPiece(piece) then return false end
    local key=api.identity and api.identity(piece) or tostring(piece)
    local reduction=math.max(0,math.min(0.99,tonumber(amount) or 0))
    local current=damageMultipliers[key] or 1
    damageMultipliers[key]=math.max(0.01,current*(1-reduction))
    return true
end

function Catalog.damageMultiplier(api,piece)
    if not api.valid(piece) or not api.isPiece(piece) then return 1 end
    local key=api.identity and api.identity(piece) or tostring(piece)
    return damageMultipliers[key] or 1
end

local sourcePiece,distanceBetween

-- All damage reduction, the one-time Unbroken King rescue and the sword
-- reflection guard use the same server-side damage entry point.  The latter
-- deliberately cancels only the verified incoming damage path; it never
-- fabricates a projectile on a client.
function Catalog.adjustIncomingDamage(api,piece,amount,...)
    local base=tonumber(amount)
    if not base or base<=0 or not api.valid(piece) or not api.isPiece(piece) then return amount end
    local state=stateFor(api,piece)
    local now=os.clock()
    if (tonumber(state.invulnerableUntil) or 0)>now then return 0 end
    if (tonumber(state.queen_shield) or 0)>0 and api.read(piece,"HoldingPiece")==true then return 0 end
    if (tonumber(state.king_reflect_sword) or 0)>0 and api.read(piece,"Swinging")==true then
        local attacker=sourcePiece and sourcePiece(api,piece,...) or nil
        if attacker then
            local health=readNumber(api,attacker,"Health")
            if health then write(api,attacker,"Health",math.max(0,health-base)) end
        end
        return 0
    end
    local attacker=sourcePiece and sourcePiece(api,piece,...) or nil
    if attacker then
        local attackerState=stateFor(api,attacker)
        local distance=distanceBetween and distanceBetween(api,attacker,piece) or nil
        if (tonumber(attackerState.bishop_close_shotgun) or 0)>0 and distance and distance<=4000 then
            base=base*(1+.30*(1-distance/4000))
        end
        if (tonumber(attackerState.knight_self_destruct) or 0)>0
            and (tonumber(attackerState.selfDestructArmedUntil) or 0)>now then
            base=base+(readNumber(api,attacker,"ChargeDamage") or 0)/2
        end
        if (tonumber(attackerState.knight_arrow_rain) or 0)>0
            and (tonumber(attackerState.arrowRainArmedUntil) or 0)>now then
            base=base+(readNumber(api,attacker,"ArrowMaxDamage") or 0)
        end
        if (tonumber(attackerState.knight_split_arrow) or 0)>0
            and (tonumber(attackerState.splitArrowArmedUntil) or 0)>now then base=base*3 end
        if (tonumber(attackerState.queen_bomb_throw) or 0)>0
            and (tonumber(attackerState.bombThrowArmedUntil) or 0)>now then base=base+40 end
        if (tonumber(attackerState.king_sword_roar) or 0)>0 and api.read(attacker,"Swinging")==true then base=base+20 end
        if (tonumber(attackerState.knight_fire_arrow) or 0)>0 then
            state.burnUntil=now+3
            state.burnNext=now+.5
            state.burnDamage=math.max(1,(readNumber(api,attacker,"ArrowMaxDamage") or base)/10)
        end
        if (tonumber(attackerState.king_judgment) or 0)>0 and api.read(attacker,"FiringBeam")==true then
            attackerState.judgmentOwner=attacker
            attackerState.judgmentTargets=attackerState.judgmentTargets or {}
            attackerState.judgmentTargets[api.identity(piece)]=piece
        end
        if (tonumber(attackerState.king_mark) or 0)>0 then
            attackerState.marked=attackerState.marked or {}
            local key=api.identity(piece)
            if api.read(attacker,"FiringBeam")==true then attackerState.marked[key]={target=piece,at=now}
            elseif attackerState.marked[key] and (api.read(attacker,"Swinging")==true or api.read(attacker,"Slamming")==true) then
                base=base+30
                attackerState.marked[key]=nil
            end
        end
        if (tonumber(attackerState.king_sky_strike) or 0)>0 and api.read(attacker,"Swinging")==true then
            api.call(piece,"LaunchCharacter",{X=0,Y=0,Z=2200},true,true)
        end
        if (tonumber(attackerState.king_sword_roar) or 0)>0 and api.read(attacker,"Swinging")==true then
            api.call(piece,"LaunchCharacter",{X=0,Y=0,Z=700},true,true)
        end
        if (tonumber(attackerState.rook_cannonball) or 0)>0
            and (tonumber(attackerState.cannonballArmedUntil) or 0)>now then
            base=base+50
            api.call(piece,"LaunchCharacter",{X=0,Y=0,Z=900},true,true)
        end
        if (tonumber(attackerState.king_ground_lock) or 0)>0 and api.read(attacker,"Slamming")==true then
            local movement=api.read(piece,"CharacterMovement")
            local speed=readNumber(api,movement,"MaxWalkSpeed")
            if speed and not state.groundLockSpeed then
                state.groundLockSpeed=speed
                write(api,movement,"MaxWalkSpeed",speed*.70)
                state.groundLockUntil=now+3
            end
        end
        if (tonumber(state.rook_no_melee) or 0)>0 and distance then
            base=base*math.max(0,math.min(1,distance/4000))
        end
    end
    local reduced=base*Catalog.damageMultiplier(api,piece)
    if (tonumber(state.king_immortal) or 0)>0 and not state.immortalUsed then
        local health=readNumber(api,piece,"Health") or 0
        if health>0 and reduced>=health then
            state.immortalUsed=true
            state.invulnerableUntil=now+3
            local maximum=readNumber(api,piece,"MaxHealth") or health
            write(api,piece,"Health",math.max(1,maximum*.30))
            if api.enableHealthRegen then api.enableHealthRegen(piece) end
            if api.refresh then api.refresh(piece) end
            return 0
        end
    end
    return math.max(0,reduced)
end

-- Point damage carries the hit bone while ReceiveAnyDamage does not.  Keep
-- headhunter on this more specific path so its body/head split is applied
-- exactly once before the common damage reduction hook sees the value.
function Catalog.adjustPointDamage(api,piece,amount,boneName,...)
    local base=tonumber(amount)
    if not base or base<=0 or not api.valid(piece) or not api.isPiece(piece) then return amount end
    local attacker=sourcePiece and sourcePiece(api,piece,...) or nil
    if not attacker then return amount end
    local state=stateFor(api,attacker)
    if (tonumber(state.pawn_headhunter) or 0)<=0 then return amount end
    local rawBone=boneName
    if api.unwrap then
        local ok,value=pcall(api.unwrap,boneName)
        if ok and value~=nil then rawBone=value end
    end
    local bone=tostring(rawBone or ""):lower()
    if bone:find("head",1,true) or bone:find("neck",1,true) then return base*1.50 end
    return base*.25
end

function Catalog.onAbility(api,piece,name)
    if not api.valid(piece) or not api.isPiece(piece) then return end
    local state=stateFor(api,piece)
    local now=os.clock()
    if name=="MovementAbility" and (tonumber(state.knight_chain_dash) or 0)>0 then
        api.write(piece,"HasMovementAbilityCharges",true)
        api.call(piece,"SetMovementAbilityCharges",3)
    elseif (name=="Grapple" or name=="LaunchGrapplingHook")
        and (tonumber(state.rook_cannonball) or 0)>0 then
        state.cannonballArmedUntil=now+4
    elseif (name=="ReleasePiece" or name=="Throw")
        and (tonumber(state.queen_bomb_throw) or 0)>0 then
        state.bombThrowArmedUntil=now+5
    elseif (name=="FinishCharge" or name=="ChargeClient")
        and (tonumber(state.knight_self_destruct) or 0)>0 then
        state.selfDestructArmedUntil=now+2
    elseif (name=="ReleaseArrow" or name=="ReleaseArrowServer") then
        if (tonumber(state.knight_arrow_rain) or 0)>0 then state.arrowRainArmedUntil=now+2 end
        if (tonumber(state.knight_split_arrow) or 0)>0 then state.splitArrowArmedUntil=now+2 end
    end
end

local function applyMove(api, piece, amount)
    local changed = 0
    local movement = api.read(piece, "CharacterMovement")
    for _, entry in ipairs({{movement,"MaxWalkSpeed"},{piece,"BaseWalkSpeed"},{piece,"DefaultWalkSpeed"}}) do
        local value = readNumber(api, entry[1], entry[2])
        if value and write(api, entry[1], entry[2], scalarIncrease(value, amount, unitFor(entry[2]))) then changed=changed+1 end
    end
    return changed
end

local function applyHealth(api, piece, amount)
    local changed = 0
    for _, field in ipairs({"MaxHealth","Health"}) do
        local value = readNumber(api, piece, field)
        if value and write(api, piece, field, scalarIncrease(value, amount, unitFor(field))) then changed=changed+1 end
    end
    if changed > 0 and api.enableHealthRegen then api.enableHealthRegen(piece) end
    return changed
end

-- UE4SS cannot safely rewrite the transient Damage parameter of Actor damage
-- events in this game.  Model mitigation as equivalent effective health
-- instead: a reduction of r turns both current and maximum health into
-- health / (1-r).  This keeps the intended time-to-kill for every damage
-- source without registering a native damage callback during combat startup.
local function applyDamageReduction(api, piece, amount)
    local reduction=math.max(0,math.min(0.99,tonumber(amount) or 0))
    local factor=1/math.max(0.01,1-reduction)
    local changed=0
    for _,field in ipairs({"MaxHealth","Health"}) do
        local value=readNumber(api,piece,field)
        if value and write(api,piece,field,value*factor) then changed=changed+1 end
    end
    if changed>0 then
        Catalog.addDamageReduction(api,piece,reduction)
        if api.enableHealthRegen then api.enableHealthRegen(piece) end
    end
    return changed
end

local function applyHealthRegen(api, piece, field, amount, decrease)
    local value=readNumber(api,piece,field)
    if not value then return 0 end
    local unit=unitFor(field)
    -- The Blueprint regen timer does not accept an exact zero cooldown. A
    -- 100% reduction used to write 0 here, which stops native regeneration.
    local nextValue
    if decrease then
        local minimumCooldown=math.max(unit,0.01)
        nextValue=amount>=1 and minimumCooldown
            or math.max(minimumCooldown,scalarDecrease(value,amount,unit))
    else
        nextValue=scalarIncrease(value,amount,unit)
    end
    if not write(api,piece,field,nextValue) then return 0 end
    -- These cards change the next recovery cycle as well as the displayed
    -- value. Re-open the Blueprint regen gate if the piece currently permits
    -- regeneration, matching health edits in the stat editor.
    if api.enableHealthRegen then api.enableHealthRegen(piece) end
    return 1
end

local function applyCooldown(api, piece, amount)
    local changed = 0
    for _, field in ipairs({"MainAbilityCooldown","MovementAbilityCooldown"}) do
        local value = readNumber(api, piece, field)
        if value then
        local nextValue = amount >= 1 and 0 or scalarDecrease(value, amount, unitFor(field))
            if write(api, piece, field, nextValue) then changed=changed+1 end
        end
    end
    return changed
end

local function fasterDuration(value, amount, unit)
    if value <= 0 then return value end
    -- Charge speed is the inverse of charge duration.  Convert, apply the
    -- shared n%/n/10 rule to the speed, then convert back to seconds.
    return 1 / scalarIncrease(1 / value, amount, unit)
end

local function applyFieldEffect(api,piece,effect)
    local changed=0
    for _,field in ipairs(effect.fields or {}) do
        local target=piece
        if field=="MaxWalkSpeed" or field=="JumpZVelocity" then target=api.read(piece,"CharacterMovement") end
        local value=readNumber(api,target,field)
        if value then
            local op=effect.op or "increase"
            local amount=tonumber(effect.amount) or 0
            local nextValue=nil
            if op=="increase" then nextValue=scalarIncrease(value,amount,unitFor(field))
            elseif op=="decrease" then nextValue=scalarDecrease(value,amount,unitFor(field))
            elseif op=="scale" then nextValue=value*amount
            elseif op=="add" then nextValue=value+amount
            elseif op=="set" then nextValue=amount
            elseif op=="increase_abs" then nextValue=value*(1+amount)
            elseif op=="duration_faster" then nextValue=fasterDuration(value,amount,unitFor(field))
            elseif op=="duration_slower" then nextValue=value/math.max(.01,1-amount)
            end
            if nextValue and write(api,target,field,nextValue) then changed=changed+1 end
        end
    end
    return changed
end

local function applyFields(api,piece,effects)
    local changed=0
    for _,effect in ipairs(effects or {}) do changed=changed+applyFieldEffect(api,piece,effect) end
    return changed
end

-- The sword users do not expose one shared animation-rate variable.  Their
-- Blueprint attack gate is ShootDelay, and some variants additionally expose
-- one of these explicit delay properties.  Update every real numeric delay
-- that exists, rather than writing a guessed animation property.
local function isMeleePiece(api, piece)
    local name=api.className and api.className(piece) or ""
    return name:find("BP_KingChar",1,true) ~= nil
        or name:find("BP_WoodKingChar",1,true) ~= nil
        or name:find("BP_BSideKingChar",1,true) ~= nil
        or name:find("BP_BSidePawnChar",1,true) ~= nil
end

local function applyMeleeAttackSpeed(api, piece, amount)
    local changed=0
    for _,field in ipairs({"SwingDelay","SwordSwingDelay","MeleeAttackDelay","AttackDelay","ShootDelay"}) do
        local value=readNumber(api,piece,field)
        if value and write(api,piece,field,fasterDuration(value,amount,unitFor(field))) then changed=changed+1 end
    end
    return changed
end

local function applyAttackSpeed(api, piece, amount)
    -- These are the actual charge-duration properties found in the regular
    -- and Wood charge-capable pieces.  A runtime ChargeTimer is intentionally
    -- excluded: shortening it mid-action would corrupt an active ability.
    local chargeFields={
        "ChargeTime", "FullChargeArrowTime", "MinimumArrowPullTime",
        "FullChargeTime", "Minimum Charge Shot Time",
    }
    local changed=0
    for _,field in ipairs(chargeFields) do
        local value=readNumber(api,piece,field)
        if value and write(api,piece,field,fasterDuration(value,amount,unitFor(field))) then changed=changed+1 end
    end
    -- Hybrid pieces such as Wood King have both a charge shot and a sword.
    -- Their attack-speed card must update both paths instead of returning
    -- after the first charge-duration property is found.
    if isMeleePiece(api,piece) then changed=changed+applyMeleeAttackSpeed(api,piece,amount) end
    if changed>0 then return changed end
    local value=readNumber(api,piece,"ShootDelay")
        if value and write(api,piece,"ShootDelay",fasterDuration(value,amount,unitFor("ShootDelay"))) then return 1 end
    return 0
end

-- Sword attacks are gated by ShootDelay, but their visible/hitbox timing is
-- driven by an animation montage.  Derive the montage rate from the class
-- default and the replicated live delay so the same result works on both
-- peers without a second custom network value.
function Catalog.meleeAnimationRate(api,piece)
    if not api.valid(piece) or not isMeleePiece(api,piece) then return nil end
    local current=readNumber(api,piece,"ShootDelay")
    local default=api.classDefault and api.classDefault(piece) or nil
    local original=readNumber(api,default,"ShootDelay")
    if not current or not original or current<=0 or original<=0 then return nil end
    return math.max(0.01,math.min(100,original/current))
end

function Catalog.pieceScore(api, piece)
    local name=api.className and api.className(piece) or ""
    if name:find("Pawn",1,true) then return 1 end
    if name:find("Knight",1,true) or name:find("Bishop",1,true) then return 3 end
    if name:find("Rook",1,true) then return 5 end
    if name:find("Queen",1,true) then return 9 end
    if name:find("King",1,true) then return 10 end
    return nil
end

function Catalog.pieceType(api,piece)
    local name=(api and api.className and api.className(piece) or ""):lower()
    if name:find("pawn",1,true) then return "pawn" end
    if name:find("knight",1,true) then return "knight" end
    if name:find("bishop",1,true) then return "bishop" end
    if name:find("rook",1,true) then return "rook" end
    if name:find("queen",1,true) then return "queen" end
    if name:find("king",1,true) then return "king" end
    return nil
end

-- Cards with a `piece` field come from the ordinary-piece folders.  Shiny,
-- Wood, and B-side variants keep the same family name for stat lookup, but
-- must only receive the shared cards (the cards without `piece`).
function Catalog.variant(api,piece)
    local name=(api and api.className and api.className(piece) or ""):lower()
    if name:find("wood",1,true) then return "wood" end
    if name:find("bside",1,true) or name:find("shiny",1,true) then return "shiny" end
    return "normal"
end

function Catalog.allowed(card,pieceType,variant)
    if not card then return false end
    if card.piece==nil then return true end
    return pieceType~=nil and card.piece==pieceType and (variant==nil or variant=="normal")
end

function Catalog.cardsForPiece(pieceType,variant)
    local result={}
    for _,card in ipairs(cards) do
        if Catalog.allowed(card,pieceType,variant) then result[#result+1]=card end
    end
    return result
end

local function normalizedQuery(value)
    return tostring(value or ""):lower():gsub("%s+","_")
end

-- Console and automated regression tests use the same catalog lookup as the
-- visible offer.  An unprefixed id such as `headhunter` resolves to the
-- current piece family first; common cards keep their original id.
function Catalog.findCard(query,pieceType,variant)
    local wanted=normalizedQuery(query)
    if wanted=="" then return nil end
    local family=normalizedQuery(pieceType)
    local fallback=nil
    for _,card in ipairs(cards) do
        if Catalog.allowed(card,pieceType,variant) then
            local id=normalizedQuery(card.id)
            local title=normalizedQuery(card.title)
            if id==wanted then return card end
            if family~="" and id==family.."_"..wanted then fallback=card end
            if title==wanted then fallback=fallback or card end
        end
    end
    return fallback
end

function Catalog.allCards()
    return cards
end

-- Validate the catalog before a match can depend on it.  This is deliberately
-- a pure check: it never touches an actor and never changes a stat.  The
-- runtime check below handles reflected properties, while this check catches
-- the easy-to-miss data errors (duplicate ids, unknown kinds/operations,
-- malformed effects, and missing special-effect registrations).
function Catalog.validate()
    local errors={}
    local knownRarity={ ["일반"]=true, ["레어"]=true, ["에픽"]=true, ["히든"]=true }
    local knownKind={
        move=true, damage=true, health=true, damage_reduction=true,
        attack_speed=true, cooldown=true, regen_rate=true,
        regen_cooldown=true, climb=true, fields=true, special=true,
    }
    local knownOp={
        increase=true, decrease=true, scale=true, add=true, set=true,
        increase_abs=true, duration_faster=true, duration_slower=true,
    }
    local knownPiece={pawn=true, knight=true, rook=true, bishop=true, queen=true, king=true}
    local specialHandlers={
        bishop_close_shotgun=true, bishop_grenade_shot=true,
        king_ground_lock=true, king_immortal=true, king_judgment=true,
        king_mark=true, king_reflect_sword=true, king_sword_roar=true,
        knight_arrow_rain=true, knight_chain_dash=true, knight_fire_arrow=true,
        knight_homing_arrow=true, knight_self_destruct=true, knight_split_arrow=true,
        pawn_fair_duel=true, pawn_headhunter=true, pawn_promotion=true,
        pawn_sorrow=true, pawn_swap=true, pawn_water_ghost=true,
        queen_auto_track=true, queen_bomb_throw=true, queen_ricochet=true,
        queen_shield=true, queen_space_swap=true, rook_cannonball=true,
        rook_no_melee=true, royal_dignity=true,
    }
    local seen={}
    local genericCount=0
    local pieceCounts={pawn=0,knight=0,rook=0,bishop=0,queen=0,king=0}
    for index,card in ipairs(cards) do
        local prefix=string.format("카드 #%d",index)
        if type(card.id)~="string" or card.id=="" then errors[#errors+1]=prefix.." ID 없음" end
        if seen[card.id] then errors[#errors+1]=prefix.." 중복 ID: "..tostring(card.id) end
        seen[card.id]=true
        if not knownRarity[card.rarity] then errors[#errors+1]=prefix.." 등급 오류: "..tostring(card.rarity) end
        if type(card.title)~="string" or card.title=="" then errors[#errors+1]=prefix.." 이름 없음" end
        if type(card.text)~="string" or card.text=="" then errors[#errors+1]=prefix.." 설명 없음" end
        if not knownKind[card.kind] then errors[#errors+1]=prefix.." 효과 종류 오류: "..tostring(card.kind) end
        local piece=type(card.piece)=="string" and card.piece or nil
        if piece then
            if not knownPiece[piece] then errors[#errors+1]=prefix.." 기물군 오류: "..piece end
            if pieceCounts[piece] then pieceCounts[piece]=pieceCounts[piece]+1 end
        else
            genericCount=genericCount+1
        end
        if card.kind=="special" then
            if not card.special or not specialHandlers[card.special] then
                errors[#errors+1]=prefix.." 특수 효과 등록 누락: "..tostring(card.special)
            end
        elseif card.kind=="fields" then
            if type(card.effects)~="table" or #card.effects==0 then
                errors[#errors+1]=prefix.." 필드 효과 없음"
            else
                for effectIndex,effect in ipairs(card.effects) do
                    if type(effect.fields)~="table" or #effect.fields==0 then
                        errors[#errors+1]=prefix.." 필드 목록 없음 (#"..effectIndex..")"
                    end
                    if not knownOp[effect.op] then
                        errors[#errors+1]=prefix.." 연산 오류: "..tostring(effect.op)
                    end
                    if type(effect.amount)~="number" or effect.amount~=effect.amount
                        or effect.amount==math.huge or effect.amount==-math.huge then
                        errors[#errors+1]=prefix.." 수치 오류"
                    end
                end
            end
        elseif card.amount~=nil and (type(card.amount)~="number" or card.amount~=card.amount) then
            errors[#errors+1]=prefix.." 수치 오류"
        end
    end
    if genericCount~=36 then errors[#errors+1]="공용 카드 수가 36이 아님: "..genericCount end
    for piece,count in pairs(pieceCounts) do
        if count~=12 then errors[#errors+1]=piece.." 일반 폴더 카드 수가 12가 아님: "..count end
    end
    return #errors==0,errors,{total=#cards,generic=genericCount,pieces=pieceCounts}
end

-- Non-mutating runtime coverage check.  A card is covered when at least one
-- real reflected property used by its application path is present on the
-- current piece (or its CharacterMovement component).  Alternative fields
-- intentionally count as one group: different color/side blueprints expose
-- different names for the same mechanic.
function Catalog.runtimeCoverage(api,piece)
    local pieceType=Catalog.pieceType(api,piece)
    local variant=Catalog.variant(api,piece)
    local report={piece=pieceType,total=0,covered=0,missing={}}
    if not pieceType then return report end
    local function hasField(field)
        local target=piece
        if field=="MaxWalkSpeed" or field=="JumpZVelocity" then target=api.read(piece,"CharacterMovement") end
        return readNumber(api,target,field)~=nil
    end
    local function hasAny(fields)
        for _,field in ipairs(fields or {}) do if hasField(field) then return true end end
        return false
    end
    local function hasKind(kind)
        if kind=="move" then
            return hasAny({"SprintSpeed","BaseWalkSpeed","DefaultWalkSpeed","MaxWalkSpeed"})
        elseif kind=="damage" then return hasField("ShootDamage")
        elseif kind=="health" then return hasAny({"Health","MaxHealth"})
        elseif kind=="attack_speed" then
            return hasAny({"ChargeTime","FullChargeArrowTime","MinimumArrowPullTime","FullChargeTime","Minimum Charge Shot Time","ShootDelay","SwingDelay","SwordSwingDelay","MeleeAttackDelay","AttackDelay"})
        elseif kind=="cooldown" then return hasAny({"MainAbilityCooldown","MovementAbilityCooldown"})
        elseif kind=="regen_rate" then return hasField("HealthRegenRate")
        elseif kind=="regen_cooldown" then return hasField("HealthRegenCooldown")
        elseif kind=="climb" then return hasField("ClimbSpeed")
        elseif kind=="damage_reduction" or kind=="special" then return true
        end
        return false
    end
    for _,card in ipairs(Catalog.cardsForPiece(pieceType,variant)) do
        report.total=report.total+1
        local covered=false
        if card.kind=="fields" then
            for _,effect in ipairs(card.effects or {}) do
                if hasAny(effect.fields) then covered=true; break end
            end
        else
            covered=hasKind(card.kind)
        end
        if covered then report.covered=report.covered+1
        else report.missing[#report.missing+1]=card.id end
    end
    return report
end

-- Exercise every card through Catalog.apply without touching the game.  The
-- mock deliberately exposes the same API surface used by applyEffects, so a
-- typo in a kind, operation, field path, or special-card branch fails during
-- mod startup instead of waiting for a rare card to appear in a match.
function Catalog.selfTest()
    local failures={}
    local total=0
    local passed=0
    local function makePiece(pieceType,id)
        local piece={
            id=id,className="BP_"..pieceType:gsub("^%l",string.upper).."Char_C",isPiece=true,
            Health=100,MaxHealth=100,ShootDamage=20,ShootDelay=1,
            BaseWalkSpeed=600,DefaultWalkSpeed=600,ClimbSpeed=400,
            HealthRegenRate=2,HealthRegenCooldown=5,
            MainAbilityCooldown=10,MovementAbilityCooldown=10,
            SprintSpeed=800,AllyMaxCount=2,MaxAllyCount=2,AllyFiringSpeed=2,
            FullChargeArrowTime=2,MinimumArrowPullTime=1,ChargeTime=2,
            ChargeSpeed=1200,ChargeDamage=40,ArrowMaxDamage=30,
            GrappleRange=4000,MaxWallCount=3,MaxWallCount_0=3,
            GrenadeExplosionStrength=1,GrenadeLaunchStrength=1200,
            RocketLaunchStrength=1200,GlideExplosionDamage=20,
            Shotgun_Spread=1,Shotgun_Count=4,MaxDamageRange=4000,
            HitscanRange=4000,GlideDamping=1,AccelDecayRate=1,
            ThrowVelocity=1000,FlightTime=3,
            BeamTime=4,BeamDPS=20,BeamPullSpeed=500,BeamPushSpeed=500,
            SlamVelocity=1000,SwordPushStrength=1000,UnscopedAccuracy=.5,
            CharacterMovement={MaxWalkSpeed=600,JumpZVelocity=600},
        }
        return piece
    end
    local opponent=makePiece("queen","self-test-opponent")
    local controllers={{Pawn=opponent,id="self-test-controller"}}
    local api={}
    api.valid=function(object) return type(object)=="table" end
    api.isPiece=function(object) return type(object)=="table" and object.isPiece==true end
    api.identity=function(object) return object and object.id end
    api.className=function(object) return object and object.className or "" end
    api.read=function(object,field) return object and object[field] end
    api.write=function(object,field,value) if not object then return false end object[field]=value; return true end
    api.refresh=function() end
    api.enableHealthRegen=function() end
    api.findAll=function(className) if className=="PlayerController" then return controllers end return {} end
    api.call=function(object,method)
        if method=="GetPawn" then return object and object.Pawn end
        return nil
    end
    api.authority=function() return true end
    for _,pieceType in ipairs({"pawn","knight","rook","bishop","queen","king"}) do
        local piece=makePiece(pieceType,"self-test-"..pieceType)
        controllers[1].Pawn=pieceType=="pawn" and opponent or opponent
        for _,card in ipairs(Catalog.cardsForPiece(pieceType,"normal")) do
            total=total+1
            local resolved=Catalog.findCard(card.id,pieceType,"normal")
            if resolved~=card then
                failures[#failures+1]=card.id..": 콘솔 조회 결과 불일치"
            end
            local ok,message=Catalog.apply(api,piece,card)
            if ok and resolved==card then passed=passed+1
            else failures[#failures+1]=card.id..": "..tostring(message) end
        end
        local normalCards=Catalog.cardsForPiece(pieceType,"normal")
        local sharedCount=0
        for _,card in ipairs(normalCards) do if card.piece==nil then sharedCount=sharedCount+1 end end
        for _,variant in ipairs({"wood","shiny"}) do
            local variantCards=Catalog.cardsForPiece(pieceType,variant)
            if #variantCards~=sharedCount then
                failures[#failures+1]=pieceType.."/"..variant..": 공용 카드 수 오류"
            end
            for _,card in ipairs(variantCards) do
                if card.piece~=nil then
                    failures[#failures+1]=pieceType.."/"..variant..": 전용 카드 노출 "..card.id
                end
            end
            for _,card in ipairs(normalCards) do
                if card.piece and Catalog.findCard(card.id,pieceType,variant)~=nil then
                    failures[#failures+1]=pieceType.."/"..variant..": 전용 카드 조회 허용 "..card.id
                end
            end
        end
    end
    return #failures==0 and passed==total,total,passed,failures
end

local function opponentPiece(api,piece)
    if not api.findAll then return nil end
    for _,controller in ipairs(api.findAll("PlayerController") or {}) do
        local other=api.read(controller,"Pawn") or api.call(controller,"GetPawn")
        if api.valid(other) and api.isPiece(other) and other~=piece then return other end
    end
    return nil
end

local function unwrap(api,value)
    if api.unwrap then
        local ok,result=pcall(api.unwrap,value)
        if ok and result~=nil then return result end
    end
    return value
end

sourcePiece=function(api,victim,...)
    for index=1,select("#",...) do
        local candidate=unwrap(api,select(index,...))
        for _=1,3 do
            if api.valid(candidate) and api.isPiece(candidate) then
                if candidate~=victim then return candidate end
                break
            end
            local owner=api.call and api.call(candidate,"GetOwner") or nil
            if not api.valid(owner) or owner==candidate then break end
            candidate=owner
        end
    end
    return nil
end

distanceBetween=function(api,first,second)
    local a=api.call(first,"K2_GetActorLocation") or api.call(first,"GetActorLocation")
    local b=api.call(second,"K2_GetActorLocation") or api.call(second,"GetActorLocation")
    local ok,dx,dy,dz=pcall(function() return (a.X-b.X),(a.Y-b.Y),(a.Z-b.Z) end)
    if not ok then return nil end
    return math.sqrt(dx*dx+dy*dy+dz*dz)
end

local function directDamage(api,piece,amount)
    local health=readNumber(api,piece,"Health")
    if not health or amount<=0 then return false end
    return write(api,piece,"Health",math.max(0,health-amount))
end

function Catalog.tick(api)
    -- No timed effect exists until a card creates state. Avoid enumerating
    -- transient PlayerController/Pawn objects during combat startup.
    if not next(specialStates) then return end
    if not api.findAll then return end
    local now=os.clock()
    for _,controller in ipairs(api.findAll("PlayerController") or {}) do
        local piece=api.read(controller,"Pawn") or api.call(controller,"GetPawn")
        if api.valid(piece) and api.isPiece(piece) and api.authority(piece) then
            local state=stateFor(api,piece)
            if state.burnUntil and now>=state.burnUntil then
                state.burnUntil,state.burnNext,state.burnDamage=nil,nil,nil
            elseif state.burnNext and now>=state.burnNext then
                directDamage(api,piece,tonumber(state.burnDamage) or 0)
                state.burnNext=now+.5
            end
            if state.groundLockUntil and now>=state.groundLockUntil then
                local movement=api.read(piece,"CharacterMovement")
                if api.valid(movement) and state.groundLockSpeed then write(api,movement,"MaxWalkSpeed",state.groundLockSpeed) end
                state.groundLockUntil,state.groundLockSpeed=nil,nil
            end
        end
    end
    for _,state in pairs(specialStates) do
        if state.judgmentTargets and state.judgmentOwner and api.valid(state.judgmentOwner)
            and api.read(state.judgmentOwner,"FiringBeam")~=true then
            for _,target in pairs(state.judgmentTargets) do
                if api.valid(target) and api.authority(target) then directDamage(api,target,30) end
            end
            state.judgmentTargets=nil
        end
    end
end

local function applySpecial(api,piece,card)
    local changed=Catalog.addSpecial(api,piece,card.special) and 1 or 0
    if card.special=="pawn_fair_duel" then
        local other=opponentPiece(api,piece)
        local own=applyFields(api,piece,{{fields={"MainAbilityCooldown"},op="set",amount=3600}})
        local theirs=other and applyFields(api,other,{{fields={"MainAbilityCooldown"},op="set",amount=3600}}) or 0
        changed=changed+own+theirs
    elseif card.special=="pawn_sorrow" then
        local score=Catalog.pieceScore(api,opponentPiece(api,piece)) or 1
        local bonus=math.max(0,score-1)
        if bonus>0 then
            changed=changed+applyFields(api,piece,{
                {fields={"ShootDamage","Health","MaxHealth"},op="scale",amount=1+bonus},
                {fields={"ShootDelay"},op="duration_slower",amount=math.min(.9,bonus*.10)},
            })
        end
    end
    return changed
end

local function offerWithRandom(count, random, pieceType,variant)
    local result = {}
    for _=1,count do
        local roll = random() * 100
        local rarity = roll <= 45 and "일반" or roll <= 80 and "레어" or "에픽"
        local hiddenChance = rarity == "일반" and 1 or (rarity == "레어" and 3 or 5)
        if random() * 100 <= hiddenChance then rarity = "히든" end
        local pool = {}
        for _,card in ipairs(pools[rarity]) do
            if Catalog.allowed(card,pieceType,variant) then pool[#pool+1]=card end
        end
        -- Every rarity has common cards, but keep the generator total if a
        -- future configuration temporarily removes one of those pools.
        if #pool==0 then
            for _,card in ipairs(cards) do
                if Catalog.allowed(card,pieceType,variant) then pool[#pool+1]=card end
            end
        end
        result[#result+1] = pool[math.floor(random() * #pool) + 1]
    end
    return result
end

function Catalog.offer(count, api, piece)
    return offerWithRandom(count,math.random,Catalog.pieceType(api,piece),Catalog.variant(api,piece))
end

-- A local PRNG prevents one player's cards from affecting another player's
-- RNG sequence while identical mod copies resolve a host-provided seed alike.
function Catalog.offerSeeded(count, seed, api, piece)
    local state=math.floor(tonumber(seed) or 1) % 2147483647
    if state<=0 then state=1 end
    local function random()
        state=(state*48271) % 2147483647
        return state / 2147483647
    end
    return offerWithRandom(count,random,Catalog.pieceType(api,piece),Catalog.variant(api,piece))
end

local function applyEffects(api, piece, card)
    if not api.valid(piece) or api.read(piece,"Dead") == true then return false, "전투 기물을 찾을 수 없습니다." end
    if not Catalog.allowed(card,Catalog.pieceType(api,piece),Catalog.variant(api,piece)) then return false,"이 기물 전용 증강이 아닙니다." end
    local changed = 0
    if card.kind == "move" then changed = applyMove(api,piece,card.amount)
    elseif card.kind == "damage" then
        local value=readNumber(api,piece,"ShootDamage")
        if value and write(api,piece,"ShootDamage",scalarIncrease(value,card.amount,unitFor("ShootDamage"))) then changed=1 end
    elseif card.kind == "health" then changed=applyHealth(api,piece,card.amount)
    elseif card.kind == "damage_reduction" then
        changed=applyDamageReduction(api,piece,card.amount)
    elseif card.kind == "attack_speed" then changed=applyAttackSpeed(api,piece,card.amount)
    elseif card.kind == "cooldown" then changed=applyCooldown(api,piece,card.amount)
    elseif card.kind == "regen_rate" then changed=applyHealthRegen(api,piece,"HealthRegenRate",card.amount,false)
    elseif card.kind == "regen_cooldown" then changed=applyHealthRegen(api,piece,"HealthRegenCooldown",card.amount,true)
    elseif card.kind == "climb" then
        local value=readNumber(api,piece,"ClimbSpeed")
        if value and write(api,piece,"ClimbSpeed",scalarIncrease(value,card.amount,unitFor("ClimbSpeed"))) then changed=1 end
    elseif card.kind == "fields" then changed=applyFields(api,piece,card.effects)
    elseif card.kind == "special" then changed=applySpecial(api,piece,card)
    end
    if changed == 0 then return false, "이 기물에 적용할 수 있는 속성을 찾지 못했습니다." end
    api.refresh(piece)
    return true, card.title .. " 적용"
end

function Catalog.apply(api,piece,card)
    local writes={}
    local tracked=setmetatable({}, {__index=api})
    tracked.write=function(object,field,value)
        local before=api.read(object,field)
        local ok,err=api.write(object,field,value)
        writes[#writes+1]={object=object,field=field,before=before,expected=value,
            actual=api.read(object,field),written=ok==true}
        return ok,err
    end
    local damageBefore=Catalog.damageMultiplier(api,piece)
    local ok,message=applyEffects(tracked,piece,card)
    writes.damageBefore=damageBefore
    writes.damageAfter=Catalog.damageMultiplier(api,piece)
    if api.auditAugment then api.auditAugment(piece,card,writes,ok) end
    return ok,message
end

-- Runtime handlers for effects that need an actor event rather than a
-- replicated numeric property.  These helpers are deliberately defensive:
-- different FPS Chess variants expose slightly different reflected names.
local function runtimeCall(api, object, method, ...)
    if not api or not api.call or not object then return nil end
    return api.call(object, method, ...)
end

local function runtimeRead(api, object, field)
    if not api or not api.read or not object then return nil end
    return api.read(object, field)
end

local function runtimeValid(api, object)
    return api and api.valid and object and api.valid(object) == true
end

local function sameRuntimeActor(api, first, second)
    if not first or not second then return false end
    if first == second then return true end
    if api.identity then
        local okA,a=pcall(api.identity,first)
        local okB,b=pcall(api.identity,second)
        return okA and okB and a~=nil and a==b
    end
    return false
end

local function actorLocation(api, object)
    if not runtimeValid(api,object) then return nil end
    return runtimeCall(api,object,"K2_GetActorLocation")
        or runtimeCall(api,object,"GetActorLocation")
        or runtimeRead(api,object,"Location")
end

local function setActorLocation(api, object, location)
    if not runtimeValid(api,object) or not location then return false end
    local result=runtimeCall(api,object,"K2_SetActorLocation",location,true,true,true)
    if result~=nil then return result~=false end
    result=runtimeCall(api,object,"SetActorLocation",location,true,true,true)
    return result~=false and result~=nil
end

local function vecLength(vector)
    if type(vector)~="table" then return nil end
    local x=tonumber(vector.X) or 0
    local y=tonumber(vector.Y) or 0
    local z=tonumber(vector.Z) or 0
    return math.sqrt(x*x+y*y+z*z)
end

local function direction(from,to)
    if not from or not to then return nil end
    local x=(tonumber(to.X) or 0)-(tonumber(from.X) or 0)
    local y=(tonumber(to.Y) or 0)-(tonumber(from.Y) or 0)
    local z=(tonumber(to.Z) or 0)-(tonumber(from.Z) or 0)
    local length=math.sqrt(x*x+y*y+z*z)
    if length<0.001 then return nil end
    return {X=x/length,Y=y/length,Z=z/length}
end

local function steerActor(api, actor, target)
    local from=actorLocation(api,actor)
    local to=actorLocation(api,target)
    local unit=direction(from,to)
    if not unit then return false end

    local velocity=runtimeCall(api,actor,"GetVelocity") or runtimeRead(api,actor,"Velocity")
    local speed=vecLength(velocity) or 3000
    if speed<1 then speed=3000 end
    local nextVelocity={X=unit.X*speed,Y=unit.Y*speed,Z=unit.Z*speed}
    local movement=runtimeRead(api,actor,"ProjectileMovement")
        or runtimeRead(api,actor,"ProjectileMovementComponent")
    if movement and api.write then api.write(movement,"Velocity",nextVelocity) end
    if api.write then api.write(actor,"Velocity",nextVelocity) end

    local horizontal=math.sqrt(unit.X*unit.X+unit.Y*unit.Y)
    local rotation={
        Pitch=math.deg(math.atan(unit.Z,math.max(0.001,horizontal))),
        Yaw=math.deg(math.atan(unit.Y,unit.X)),
        Roll=0,
    }
    runtimeCall(api,actor,"K2_SetActorRotation",rotation,true)
    runtimeCall(api,actor,"SetActorRotation",rotation,true)
    return true
end

local function actorOwner(api, actor)
    return runtimeCall(api,actor,"GetOwner")
        or runtimeRead(api,actor,"Owner")
        or runtimeCall(api,actor,"GetInstigator")
        or runtimeRead(api,actor,"Instigator")
end

local function ownedActors(api, owner, classes)
    local result={}
    if not api.findAll then return result end
    for _,className in ipairs(classes or {}) do
        for _,actor in ipairs(api.findAll(className) or {}) do
            if runtimeValid(api,actor) and sameRuntimeActor(api,actorOwner(api,actor),owner) then
                result[#result+1]=actor
            end
        end
    end
    return result
end

local function allyList(api,piece)
    local result={}
    local allies=runtimeRead(api,piece,"Allies")
    if type(allies)=="table" then
        for _,ally in ipairs(allies) do
            if runtimeValid(api,ally) then result[#result+1]=ally end
        end
    elseif allies then
        local count=runtimeCall(api,allies,"Num") or runtimeCall(api,allies,"Length")
        for index=0,(tonumber(count) or 0)-1 do
            local ally=runtimeCall(api,allies,"Get",index)
            if runtimeValid(api,ally) then result[#result+1]=ally end
        end
    end
    if #result==0 and api.findAll then
        for _,className in ipairs({"BP_PawnAlly_C","BP_PawnAllyChar_C","BP_AllyPawn_C"}) do
            for _,ally in ipairs(api.findAll(className) or {}) do
                if runtimeValid(api,ally) and sameRuntimeActor(api,actorOwner(api,ally),piece) then
                    result[#result+1]=ally
                end
            end
        end
    end
    return result
end

local function swapPawnAndAlly(api,piece)
    local origin=actorLocation(api,piece)
    if not origin then return false end
    local farthest=nil
    local farthestDistance=-1
    for _,ally in ipairs(allyList(api,piece)) do
        local location=actorLocation(api,ally)
        if location then
            local dx=(location.X or 0)-(origin.X or 0)
            local dy=(location.Y or 0)-(origin.Y or 0)
            local dz=(location.Z or 0)-(origin.Z or 0)
            local distance=dx*dx+dy*dy+dz*dz
            if distance>farthestDistance then farthest,farthestDistance=ally,distance end
        end
    end
    if not farthest then return false end
    local destination=actorLocation(api,farthest)
    if not destination then return false end
    local first=setActorLocation(api,piece,destination)
    local second=setActorLocation(api,farthest,origin)
    return first and second
end

local function representedValue(api,piece)
    return runtimeRead(api,piece,"RepresentedPiece")
        or runtimeRead(api,piece,"RepresentedPieceType")
        or runtimeRead(api,piece,"PieceType")
end

local function setRepresentedValue(api,piece,value)
    if not runtimeValid(api,piece) or value==nil then return false end
    local changed=false
    for _,field in ipairs({"RepresentedPiece","RepresentedPieceType","PieceType"}) do
        local current=runtimeRead(api,piece,field)
        if current~=nil or field=="RepresentedPiece" then
            if api.write and api.write(piece,field,value) then changed=true end
        end
    end
    if changed then
        runtimeCall(api,piece,"OnRep_RepresentedPiece")
        runtimeCall(api,piece,"UpdateRepresentedPiece")
        runtimeCall(api,piece,"ForceNetUpdate")
    end
    return changed
end

local function closestOpponent(api,piece)
    return opponentPiece(api,piece)
end

local function trackThrownPiece(api,piece,state)
    local target=runtimeRead(api,piece,"HeldPiece")
        or runtimeRead(api,piece,"CollidingObj")
    if runtimeValid(api,target) and not sameRuntimeActor(api,target,piece) then
        state.thrownPiece=target
        return target
    end
    return state.thrownPiece
end

local function applyRoyalDignity(api,piece,state)
    local targetLocation=actorLocation(api,piece)
    if not targetLocation or not api.findAll then return end
    state.dignityControllers=state.dignityControllers or {}
    for _,controller in ipairs(api.findAll("PlayerController") or {}) do
        if runtimeValid(api,controller) and runtimeCall(api,controller,"IsLocalController")~=true then
            local pawn=runtimeRead(api,controller,"Pawn") or runtimeCall(api,controller,"GetPawn")
            local pawnLocation=actorLocation(api,pawn)
            local rotation=runtimeCall(api,controller,"GetControlRotation")
                or runtimeRead(api,controller,"ControlRotation")
            local directionToTarget=direction(pawnLocation,targetLocation)
            local looksAt=false
            if directionToTarget and rotation then
                local pitch=math.rad(tonumber(rotation.Pitch) or 0)
                local yaw=math.rad(tonumber(rotation.Yaw) or 0)
                local forward={X=math.cos(pitch)*math.cos(yaw),Y=math.cos(pitch)*math.sin(yaw),Z=math.sin(pitch)}
                local dot=forward.X*directionToTarget.X+forward.Y*directionToTarget.Y+forward.Z*directionToTarget.Z
                looksAt=dot>=0.72
            end
            local key=api.identity and api.identity(controller) or tostring(controller)
            if looksAt and rotation then
                if not state.dignityControllers[key] then
                    state.dignityControllers[key]=rotation
                end
                local forced={Pitch=89,Yaw=rotation.Yaw or 0,Roll=rotation.Roll or 0}
                runtimeCall(api,controller,"SetControlRotation",forced)
            elseif state.dignityControllers[key] then
                runtimeCall(api,controller,"SetControlRotation",state.dignityControllers[key])
                state.dignityControllers[key]=nil
            end
        end
    end
end

local function spawnActor(api, owner, classPaths, location, rotation)
    if not api.world or not api.findClass then return nil end
    local world=api.world(owner)
    if not runtimeValid(api,world) then return nil end
    for _,path in ipairs(classPaths or {}) do
        local class=api.findClass(path)
        if class then
            local actor=runtimeCall(api,world,"SpawnActor",class,location,rotation)
            if runtimeValid(api,actor) then
                runtimeCall(api,actor,"SetOwner",owner)
                runtimeCall(api,actor,"SetInstigator",owner)
                return actor
            end
        end
    end
    return nil
end

local function spawnGrenadeShot(api,piece,state)
    local location=runtimeRead(api,piece,"GunTip") or runtimeRead(api,piece,"Weapon")
    if location and runtimeCall(api,location,"GetComponentLocation") then
        location=runtimeCall(api,location,"GetComponentLocation")
    else
        location=actorLocation(api,piece)
    end
    if not location then return 0 end
    local forward=runtimeCall(api,piece,"GetActorForwardVector") or {X=1,Y=0,Z=0}
    local rotation={Pitch=0,Yaw=math.deg(math.atan(forward.Y or 0,forward.X or 1)),Roll=0}
    local count=math.max(1,math.floor(tonumber(runtimeRead(api,piece,"Shotgun_Count")) or 1))
    local spawned=0
    for index=1,count do
        local grenade=spawnActor(api,piece,{
            "/Game/Blueprints/Abilities/BP_HolyGrenade.BP_HolyGrenade_C",
            "/Game/Blueprints/BP_Explosive.BP_Explosive_C",
        },location,rotation)
        if grenade then
            local velocity={X=(forward.X or 1)*1500,Y=(forward.Y or 0)*1500,Z=(forward.Z or 0)*1500}
            api.write(grenade,"Velocity",velocity)
            local movement=runtimeRead(grenade,"ProjectileMovement") or runtimeRead(grenade,"ProjectileMovementComponent")
            if movement then api.write(movement,"Velocity",velocity) end
            spawned=spawned+1
        end
    end
    if spawned>0 then state.grenadeShotSpawned=(tonumber(state.grenadeShotSpawned) or 0)+spawned end
    return spawned
end

local function setProjectileDamage(api,projectile,damage)
    if not api.write or not damage then return end
    for _,field in ipairs({"Damage","ArrowDamage","BaseDamage","ShootDamage"}) do
        if runtimeRead(api,projectile,field)~=nil then api.write(projectile,field,damage) end
    end
end

local function projectileVelocity(api,projectile)
    local velocity=runtimeCall(api,projectile,"GetVelocity") or runtimeRead(api,projectile,"Velocity")
    if vecLength(velocity) and vecLength(velocity)>1 then return velocity end
    local forward=runtimeCall(api,projectile,"GetActorForwardVector") or {X=1,Y=0,Z=0}
    return {X=(forward.X or 1)*3000,Y=(forward.Y or 0)*3000,Z=(forward.Z or 0)*3000}
end

local function spawnSplitArrows(api,piece,state)
    local original=ownedActors(api,piece,{"BP_Arrow_C","BP_L_Arrow_C"})
    state.splitProcessed=state.splitProcessed or {}
    local created=0
    for _,arrow in ipairs(original) do
        local key=api.identity and api.identity(arrow) or tostring(arrow)
        if not state.splitProcessed[key] then
            state.splitProcessed[key]=true
            local location=actorLocation(api,arrow)
            local velocity=projectileVelocity(api,arrow)
            local speed=vecLength(velocity) or 3000
            local baseAngle=math.atan(velocity.Y or 0,velocity.X or 1)
            for _,offset in ipairs({-0.18,0.18}) do
                local angle=baseAngle+offset
                local splitVelocity={X=math.cos(angle)*speed*.45,Y=math.sin(angle)*speed*.45,Z=(velocity.Z or 0)*.45}
                local split=spawnActor(api,piece,{
                    "/Game/Blueprints/BP_Arrow.BP_Arrow_C",
                    "/Game/Blueprints/BP_L_Arrow.BP_L_Arrow_C",
                },location,{Pitch=0,Yaw=math.deg(angle),Roll=0})
                if split then
                    api.write(split,"Velocity",splitVelocity)
                    local movement=runtimeRead(split,"ProjectileMovement") or runtimeRead(split,"ProjectileMovementComponent")
                    if movement then api.write(movement,"Velocity",splitVelocity) end
                    setProjectileDamage(api,split,(readNumber(api,piece,"ArrowMaxDamage") or 1)/3)
                    created=created+1
                end
            end
        end
    end
    if created>0 then state.splitPhysical=true end
    return created
end

local function spawnArrowRain(api,attacker,target,state)
    local location=actorLocation(api,target)
    if not location then return 0 end
    local created=0
    for index=1,3 do
        local spawnLocation={X=location.X+(index-2)*120,Y=location.Y+(index-2)*80,Z=location.Z+1200}
        local arrow=spawnActor(api,attacker,{
            "/Game/Blueprints/BP_Arrow.BP_Arrow_C",
            "/Game/Blueprints/BP_L_Arrow.BP_L_Arrow_C",
        },spawnLocation,{Pitch=-90,Yaw=0,Roll=0})
        if arrow then
            local velocity={X=0,Y=0,Z=-2600}
            api.write(arrow,"Velocity",velocity)
            local movement=runtimeRead(arrow,"ProjectileMovement") or runtimeRead(arrow,"ProjectileMovementComponent")
            if movement then api.write(movement,"Velocity",velocity) end
            setProjectileDamage(api,arrow,readNumber(api,attacker,"ArrowMaxDamage") or 1)
            created=created+1
        end
    end
    if created>0 then state.rainPhysical=true end
    return created
end

local previousRuntimeAdjustIncoming=Catalog.adjustIncomingDamage
Catalog.adjustIncomingDamage=function(api,piece,amount,...)
    local now=os.clock()
    local attacker=sourcePiece and sourcePiece(api,piece,...) or nil
    local attackerState=attacker and stateFor(api,attacker) or nil
    local splitPhysical=attackerState and attackerState.splitPhysical==true
    local rainPhysical=false
    if attackerState and (tonumber(attackerState.knight_arrow_rain) or 0)>0
        and (tonumber(attackerState.arrowRainArmedUntil) or 0)>now
        and not attackerState.rainSpawning
        and (tonumber(attackerState.rainCooldownUntil) or 0)<=now then
        attackerState.rainSpawning=true
        local created=spawnArrowRain(api,attacker,piece,attackerState)
        attackerState.rainSpawning=false
        if created>0 then
            rainPhysical=true
            attackerState.rainCooldownUntil=now+.15
        end
    end
    local splitCount=attackerState and attackerState.knight_split_arrow or nil
    local rainCount=attackerState and attackerState.knight_arrow_rain or nil
    if splitPhysical and attackerState then attackerState.knight_split_arrow=0 end
    if rainPhysical and attackerState then attackerState.knight_arrow_rain=0 end
    local result=previousRuntimeAdjustIncoming(api,piece,amount,...)
    if splitPhysical and attackerState then attackerState.knight_split_arrow=splitCount end
    if rainPhysical and attackerState then attackerState.knight_arrow_rain=rainCount end
    return result
end

local previousRuntimeOnAbility=Catalog.onAbility
Catalog.onAbility=function(api,piece,name,...)
    previousRuntimeOnAbility(api,piece,name,...)
    if not runtimeValid(api,piece) or not api.isPiece(piece) then return end
    local state=stateFor(api,piece)
    local now=os.clock()
    if name=="MainAbility" or name=="MainAbilityMulti" or name=="MainAbilityServer" or name=="MainAbilityAll" then
        if (tonumber(state.pawn_swap) or 0)>0 then
            swapPawnAndAlly(api,piece)
        end
        if (tonumber(state.queen_space_swap) or 0)>0 and runtimeValid(api,state.thrownPiece) then
            local location=actorLocation(api,state.thrownPiece)
            if location and setActorLocation(api,piece,location) then state.thrownPiece=nil end
        end
    end
    if name=="ReleasePiece" or name=="Throw" or name=="ThrowPiece" then
        if (tonumber(state.queen_auto_track) or 0)>0 then state.autoTrackUntil=now+5 end
        if (tonumber(state.queen_ricochet) or 0)>0 then state.ricochetActive=true end
        trackThrownPiece(api,piece,state)
    end
    if name=="ShootObject" or name=="StartShooting" then
        if (tonumber(state.bishop_grenade_shot) or 0)>0 then
            state.grenadeShotSpawned=tonumber(state.grenadeShotSpawned) or 0
            spawnGrenadeShot(api,piece,state)
            -- ShootObject is the server-side damage path in the original
            -- piece.  Keep the original damage for variants that do not
            -- expose a reflected projectile class; when the field exists,
            -- suppress only this shot and restore it on the next tick.
            if runtimeRead(api,piece,"ShootDamage")~=nil and state.grenadeDamageRestore==nil then
                state.grenadeDamageRestore=runtimeRead(api,piece,"ShootDamage")
                state.grenadeDamageRestoreAt=now+0.10
                if api.write then api.write(piece,"ShootDamage",0) end
            end
        end
    end
    if name=="ReleaseArrow" or name=="ReleaseArrowServer" then
        if (tonumber(state.knight_homing_arrow) or 0)>0 then state.homingUntil=now+8 end
        if (tonumber(state.knight_split_arrow) or 0)>0 then state.splitUntil=now+2 end
    end
end

function Catalog.onCombatEvent(api,piece,name,...)
    if not runtimeValid(api,piece) or not api.isPiece(piece) then return end
    local state=stateFor(api,piece)
    local lower=tostring(name or ""):lower()
    local other=opponentPiece(api,piece)
    if lower:find("set winner",1,true) or lower:find("endcombat",1,true) then
        if (tonumber(state.pawn_promotion) or 0)>0 and runtimeValid(api,other) then
            setRepresentedValue(api,piece,representedValue(api,other))
        end
    end
    if lower:find("deathcleanup",1,true) or lower:find("die",1,true) then
        if (tonumber(state.pawn_water_ghost) or 0)>0 and runtimeValid(api,other) then
            local pawnValue=representedValue(api,piece)
            if pawnValue==nil and api.findAll then
                for _,pawn in ipairs(api.findAll("BP_PawnChar_C") or {}) do
                    pawnValue=representedValue(api,pawn)
                    if pawnValue~=nil then break end
                end
            end
            setRepresentedValue(api,other,pawnValue)
        end
    end
end

local previousRuntimeTick=Catalog.tick
Catalog.tick=function(api)
    previousRuntimeTick(api)
    if not api.findAll then return end
    local now=os.clock()
    for _,controller in ipairs(api.findAll("PlayerController") or {}) do
        local piece=runtimeRead(api,controller,"Pawn") or runtimeCall(api,controller,"GetPawn")
        if runtimeValid(api,piece) and api.isPiece(piece) and api.authority(piece) then
            local state=stateFor(api,piece)
            if state.grenadeDamageRestore~=nil and now>=(tonumber(state.grenadeDamageRestoreAt) or 0) then
                if api.write then api.write(piece,"ShootDamage",state.grenadeDamageRestore) end
                state.grenadeDamageRestore=nil
                state.grenadeDamageRestoreAt=nil
            end
            if (tonumber(state.knight_homing_arrow) or 0)>0 and (tonumber(state.homingUntil) or 0)>=now then
                local target=closestOpponent(api,piece)
                for _,arrow in ipairs(ownedActors(api,piece,{"BP_Arrow_C","BP_L_Arrow_C"})) do
                    steerActor(api,arrow,target)
                end
            end
            if (tonumber(state.knight_split_arrow) or 0)>0 and (tonumber(state.splitUntil) or 0)>=now then
                spawnSplitArrows(api,piece,state)
            end
            if (tonumber(state.queen_auto_track) or 0)>0 and (tonumber(state.autoTrackUntil) or 0)>=now then
                local thrown=trackThrownPiece(api,piece,state)
                local target=closestOpponent(api,piece)
                if runtimeValid(api,thrown) and runtimeValid(api,target) then steerActor(api,thrown,target) end
            end
            if (tonumber(state.queen_ricochet) or 0)>0 and state.ricochetActive then
                local thrown=trackThrownPiece(api,piece,state)
                local target=closestOpponent(api,piece)
                if runtimeValid(api,thrown) and runtimeValid(api,target) then steerActor(api,thrown,target) end
            end
            if (tonumber(state.queen_space_swap) or 0)>0 and not runtimeValid(api,state.thrownPiece) then
                local colliding=runtimeRead(api,piece,"CollidingObj")
                if runtimeValid(api,colliding) then state.thrownPiece=colliding end
            end
            if (tonumber(state.royal_dignity) or 0)>0 then applyRoyalDignity(api,piece,state) end
        end
    end
end

return Catalog
