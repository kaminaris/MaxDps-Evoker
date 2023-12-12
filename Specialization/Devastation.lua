
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
local timetodie
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

function Evoker:Devastation()
    fd = MaxDps.FrameData
    cooldown = fd.cooldown
    buff = fd.buff
    debuff = fd.debuff
    talents = fd.talents
    timetodie = fd.timeToDie
    targets = MaxDps:SmartAoe()
    essence = UnitPower('player', PowerTypeEssence)
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP / targetmaxHP) * 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    classtable = MaxDps.SpellTable
    classtable.BurnoutBuff = 375802
    classtable.EssenceBurstBuff = 359618
    classtable.IridescenceBlue = 386399

    MaxDps:GlowCooldown(classtable.Dragonrage, cooldown[classtable.TiptheScales].ready)

    MaxDps:GlowCooldown(classtable.TiptheScales, cooldown[classtable.TiptheScales].ready)

    --setmetatable(classtable, Warrior.spellMeta)
    if targets > 2  then
        return Evoker:DevastationMultiTarget()
    end
    return Evoker:DevastationSingleTarget()
end

--Single-Target Rotation
function Evoker:DevastationSingleTarget()
    --Cast Fire Breath at empower level 1. If Dragonrage is available soon, skip this step as you will need to save it.
    if talents[classtable.Dragonrage] and cooldown[classtable.Dragonrage].duration >= 5 and cooldown[classtable.FireBreath].ready then
        return classtable.FireBreath
    end
    --If the targets will not live for the full duration of the Fire Breath DoT then cast Fire Breath at a higher empowerment to not lose any DPS.
    --Cast Shattering Star.
    if talents[classtable.ShatteringStar] and cooldown[classtable.ShatteringStar].ready then
        return classtable.ShatteringStar
    end
    --Cast Eternity Surge at empower level 1. If Dragonrage is available soon, skip this step as you will need to save it.
    if talents[classtable.EternitySurge] and cooldown[classtable.EternitySurge].duration >= 5 and cooldown[classtable.EternitySurge].ready then
        return classtable.EternitySurge
    end
    --Aim to have 1 Essence Burst stack for when Shattering Star comes off cooldown to have your Disintegrate deal even more damage.
    --Cast Living Flame to consume Burnout procs.
    if talents[classtable.Burnout] and buff[classtable.BurnoutBuff].up and cooldown[classtable.LivingFlame].ready then
        return classtable.LivingFlame
    end
    --Spend all of your Essence on Disintegrate.
    if (essence >= 3 or buff[classtable.EssenceBurstBuff].up) and cooldown[classtable.Disintegrate].ready then
        return classtable.Disintegrate
    end
    --Cast Living Flame to consume Burnout procs.
    if talents[classtable.Burnout] and buff[classtable.BurnoutBuff].up and cooldown[classtable.LivingFlame].ready then
        return classtable.LivingFlame
    end
    --Cast Living Flame as a filler ability until you have enough Essence for Disintegrate.
    if cooldown[classtable.LivingFlame].ready then
        return classtable.LivingFlame
    end
    --Avoid using Azure Strike whilst the Iridescence Blue buff is up to ensure that Disintegrate is empowered.
    if talents[classtable.Iridescence] and not buff[classtable.IridescenceBlue] and cooldown[classtable.AzureStrike].ready then
        return classtable.AzureStrike
    end
    --If you need to move while casting, use Hover. If you have no charges of Hover left, then use Azure Strike.
end

--Multi-Target Rotation
function Evoker:DevastationMultiTarget()
    --Cast Fire Breath at empower level 1.
    if cooldown[classtable.FireBreath].ready then
        return classtable.FireBreath
    end
    --If the targets will not live for the full duration of the Fire Breath DoT then cast Fire Breath at a higher empowerment to not lose any DPS.
    --Cast Shattering Star.
    if talents[classtable.ShatteringStar] and cooldown[classtable.ShatteringStar].ready then
        return classtable.ShatteringStar
    end
    --Cast Eternity Surge at higher empower levels, depending on your target count.
    if talents[classtable.EternitySurge] and cooldown[classtable.EternitySurge].ready then
        return classtable.EternitySurge
    end
    --Cast Azure Strike to generate Essence Burst procs.
    if not buff[classtable.EssenceBurstBuff] and cooldown[classtable.AzureStrike].ready then
        return classtable.AzureStrike
    end
    --Cast Pyre as your Essence spender on 3 targets with otherwise cast Disintegrate.
    if (essence >= 2 or buff[classtable.EssenceBurstBuff].up) and cooldown[classtable.Pyre].ready then
        return classtable.Pyre
    end
    --Cast Firestorm.
    if talents[classtable.Firestorm] and cooldown[classtable.Firestorm].ready then
        return classtable.Firestorm
    end
    --Cast Living Flame to consume the Burnout procs to try and get a Snapfire proc.
    if talents[classtable.Burnout] and buff[classtable.BurnoutBuff].up and cooldown[classtable.LivingFlame].ready then
        return classtable.LivingFlame
    end
    --Cast Shattering Star when it comes off cooldown.
    if talents[classtable.ShatteringStar] and cooldown[classtable.ShatteringStar].ready then
        return classtable.ShatteringStar
    end
    if cooldown[classtable.LivingFlame].ready then
        return classtable.LivingFlame
    end
end
