
local _, addonTable = ...

--- @type MaxDps
if not MaxDps then return end

local Evoker = addonTable.Evoker
local MaxDps = MaxDps
local UnitPower = UnitPower
local UnitHealth = UnitHealth
local UnitAura = UnitAura
local GetSpellDescription = GetSpellDescription
local UnitHealthMax = UnitHealthMax
local UnitPowerMax = UnitPowerMax
local PowerTypeEssence = Enum.PowerType.Essence

local fd
local cooldown
local buff
local debuff
local talents
local targets
local essence
local targetHP
local targetmaxHP
local targethealthPerc
local curentHP
local maxHP
local healthPerc

local className, classFilename, classId = UnitClass('player')
local currentSpec = GetSpecialization()
local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or "None"
local classtable

--setmetatable(classtable, Warrior.spellMeta)

function Evoker:Preservation()
    fd = MaxDps.FrameData
    cooldown = fd.cooldown
    buff = fd.buff
    debuff = fd.debuff
    talents = fd.talents
    targets = 1 --MaxDps:SmartAoe()
    essence = UnitPower('player', PowerTypeEssence)
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP / targetmaxHP) * 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    classtable = MaxDps.SpellTable
    classtable.LeapingFlamesBuff = 370901
    if targets > 2  then
        return Evoker:PreservationMultiTarget()
    end
    return Evoker:PreservationSingleTarget()
end

--optional abilities list

--Single-Target Rotation
function Evoker:PreservationSingleTarget()
    --Cast Fire Breath on cooldown and at max rank.
    if cooldown[classtable.FireBreath].up then
        return classtable.FireBreath
    end
    --Consume the Leaping Flames buff by casting Living Flame.
    if buff[classtable.LeapingFlamesBuff].up and cooldown[classtable.LivingFlame].up then
        return classtable.LivingFlame
    end
    --Spend Essence on Disintegrate.
    if essence >= 3 and cooldown[classtable.Disintegrate].up then
        return classtable.Disintegrate
    end
    --Cast Living Flame.
    if cooldown[classtable.LivingFlame].up then
        return classtable.LivingFlame
    end
end

--Multiple-Target Rotation
function Evoker:PreservationMultiTarget()
    --Cast Fire Breath on cooldown and at max rank.
    if cooldown[classtable.FireBreath].up then
        return classtable.FireBreath
    end
    --Consume the Leaping Flames buff by casting Living Flame.
    if buff[classtable.LeapingFlamesBuff].up and cooldown[classtable.LivingFlame].up then
        return classtable.LivingFlame
    end
    --Cast Azure Strike on 3+ targets.
    if cooldown[classtable.AzureStrike].up then
        return classtable.AzureStrike
    end
    --Spend Essence on Disintegrate.
    if essence >= 3 and cooldown[classtable.Disintegrate].up then
        return classtable.Disintegrate
    end
    --Cast Living Flame.
    if cooldown[classtable.LivingFlame].up then
        return classtable.LivingFlame
    end
end
