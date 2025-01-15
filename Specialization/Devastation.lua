local _, addonTable = ...
local Evoker = addonTable.Evoker
local MaxDps = _G.MaxDps
if not MaxDps then return end
local setSpell

local UnitPower = UnitPower
local UnitHealth = UnitHealth
local UnitAura = C_UnitAuras.GetAuraDataByIndex
local UnitAuraByName = C_UnitAuras.GetAuraDataBySpellName
local UnitHealthMax = UnitHealthMax
local UnitPowerMax = UnitPowerMax
local SpellHaste
local SpellCrit
local GetSpellInfo = C_Spell.GetSpellInfo
local GetSpellCooldown = C_Spell.GetSpellCooldown
local GetSpellCount = C_Spell.GetSpellCastCount

local ManaPT = Enum.PowerType.Mana
local RagePT = Enum.PowerType.Rage
local FocusPT = Enum.PowerType.Focus
local EnergyPT = Enum.PowerType.Energy
local ComboPointsPT = Enum.PowerType.ComboPoints
local RunesPT = Enum.PowerType.Runes
local RunicPowerPT = Enum.PowerType.RunicPower
local SoulShardsPT = Enum.PowerType.SoulShards
local LunarPowerPT = Enum.PowerType.LunarPower
local HolyPowerPT = Enum.PowerType.HolyPower
local MaelstromPT = Enum.PowerType.Maelstrom
local ChiPT = Enum.PowerType.Chi
local InsanityPT = Enum.PowerType.Insanity
local ArcaneChargesPT = Enum.PowerType.ArcaneCharges
local FuryPT = Enum.PowerType.Fury
local PainPT = Enum.PowerType.Pain
local EssencePT = Enum.PowerType.Essence
local RuneBloodPT = Enum.PowerType.RuneBlood
local RuneFrostPT = Enum.PowerType.RuneFrost
local RuneUnholyPT = Enum.PowerType.RuneUnholy

local fd
local ttd
local timeShift
local gcd
local cooldown
local buff
local debuff
local talents
local targets
local targetHP
local targetmaxHP
local targethealthPerc
local curentHP
local maxHP
local healthPerc
local timeInCombat
local className, classFilename, classId = UnitClass('player')
local currentSpec = GetSpecialization()
local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or 'None'
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local Essence
local EssenceMax
local EssenceDeficit
local EssenceTimeToMax
local Mana
local ManaMax
local ManaDeficit

local Devastation = {}

local trinket_1_buffs
local trinket_2_buffs
local trinket_1_sync
local trinket_2_sync
local trinket_1_manual
local trinket_2_manual
local trinket_1_ogcd_cast
local trinket_2_ogcd_cast
local trinket_1_exclude
local trinket_2_exclude
local trinket_priority
local damage_trinket_priority
local r1_cast_time
local dr_prep_time_aoe = 4
local dr_prep_time_st = 8
local has_external_pi
local next_dragonrage
local pool_for_id = false
local bombardment_clause
function Devastation:precombat()
    r1_cast_time = 1.0 * SpellHaste
    dr_prep_time_aoe = 4
    dr_prep_time_st = 8
    has_external_pi = cooldown[classtable.InvokePowerInfusion0].duration >0
    --if (MaxDps:CheckSpellUsable(classtable.VerdantEmbrace, 'VerdantEmbrace')) and (talents[classtable.ScarletAdaptation]) and cooldown[classtable.VerdantEmbrace].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.VerdantEmbrace end
    --end
    if (MaxDps:CheckSpellUsable(classtable.Firestorm, 'Firestorm') and talents[classtable.Firestorm]) and (talents[classtable.Firestorm] and ( not talents[classtable.Engulf] or not talents[classtable.RubyEmbers] )) and cooldown[classtable.Firestorm].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Firestorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.LivingFlame, 'LivingFlame')) and (not talents[classtable.Firestorm] or talents[classtable.Engulf] and talents[classtable.RubyEmbers]) and cooldown[classtable.LivingFlame].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.LivingFlame end
    end
end
function Devastation:aoe()
    if (MaxDps:CheckSpellUsable(classtable.ShatteringStar, 'ShatteringStar') and talents[classtable.ShatteringStar]) and (cooldown[classtable.Dragonrage].ready and talents[classtable.ArcaneVigor] or talents[classtable.EternitysSpan] and targets <= 3) and cooldown[classtable.ShatteringStar].ready then
        if not setSpell then setSpell = classtable.ShatteringStar end
    end
    if (MaxDps:CheckSpellUsable(classtable.Hover, 'Hover')) and (math.huge <6 and not buff[classtable.HoverBuff].up and gcd >= 0.5 and ( buff[classtable.MassDisintegrateStacksBuff].up and talents[classtable.MassDisintegrate] or targets <= 4 )) and cooldown[classtable.Hover].ready then
        if not setSpell then setSpell = classtable.Hover end
    end
    if (MaxDps:CheckSpellUsable(classtable.Firestorm, 'Firestorm') and talents[classtable.Firestorm]) and (buff[classtable.SnapfireBuff].up) and cooldown[classtable.Firestorm].ready then
        if not setSpell then setSpell = classtable.Firestorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.Firestorm, 'Firestorm') and talents[classtable.Firestorm]) and (talents[classtable.FeedtheFlames]) and cooldown[classtable.Firestorm].ready then
        if not setSpell then setSpell = classtable.Firestorm end
    end
    if (talents[classtable.Dragonrage] and cooldown[classtable.Dragonrage].ready and talents[classtable.Iridescence] or (MaxDps.Spells[classtable.FireBreath] and cooldown[classtable.FireBreath].ready and targets >=3)) then
        Devastation:fb()
    end
    if (MaxDps:CheckSpellUsable(classtable.DeepBreath, 'DeepBreath')) and (talents[classtable.Maneuverability] and talents[classtable.MeltArmor]) and cooldown[classtable.DeepBreath].ready then
        MaxDps:GlowCooldown(classtable.DeepBreath, cooldown[classtable.DeepBreath].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Dragonrage, 'Dragonrage') and talents[classtable.Dragonrage]) and cooldown[classtable.Dragonrage].ready then
        MaxDps:GlowCooldown(classtable.Dragonrage, cooldown[classtable.Dragonrage].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.TiptheScales, 'TiptheScales')) and (buff[classtable.DragonrageBuff].up and ( ( targets <= 3 + 3 * (talents[classtable.EternitysSpan] and talents[classtable.EternitysSpan] or 0) and not talents[classtable.Engulf] ) or not cooldown[classtable.FireBreath].ready )) and cooldown[classtable.TiptheScales].ready then
        MaxDps:GlowCooldown(classtable.TiptheScales, cooldown[classtable.TiptheScales].ready)
    end
    if (( not talents[classtable.Dragonrage] or buff[classtable.DragonrageBuff].up or cooldown[classtable.Dragonrage].remains >dr_prep_time_aoe or not talents[classtable.Animosity] ) and ( ttd >= 8 or ttd <30 )) then
        Devastation:fb()
    end
    if (( not talents[classtable.Dragonrage] or buff[classtable.DragonrageBuff].up or cooldown[classtable.Dragonrage].remains >dr_prep_time_aoe or not talents[classtable.Animosity] ) and ( ttd >= 8 or ttd <30 ) or (MaxDps.Spells[classtable.EternitySurge] and cooldown[classtable.EternitySurge].ready and targets <3)) then
        Devastation:es()
    end
    if (MaxDps:CheckSpellUsable(classtable.DeepBreath, 'DeepBreath')) and (not buff[classtable.DragonrageBuff].up and EssenceDeficit >3) and cooldown[classtable.DeepBreath].ready then
        MaxDps:GlowCooldown(classtable.DeepBreath, cooldown[classtable.DeepBreath].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ShatteringStar, 'ShatteringStar') and talents[classtable.ShatteringStar]) and (buff[classtable.EssenceBurstBuff].count <1 and talents[classtable.ArcaneVigor] or talents[classtable.EternitysSpan] and targets <= 3) and cooldown[classtable.ShatteringStar].ready then
        if not setSpell then setSpell = classtable.ShatteringStar end
    end
    if (MaxDps:CheckSpellUsable(classtable.Engulf, 'Engulf') and talents[classtable.Engulf]) and (debuff[classtable.FireBreathDamageDeBuff].up and ( not talents[classtable.ShatteringStar] or debuff[classtable.ShatteringStarDebuffDeBuff].up ) and cooldown[classtable.Dragonrage].remains >= 27) and cooldown[classtable.Engulf].ready then
        if not setSpell then setSpell = classtable.Engulf end
    end
    if (MaxDps:CheckSpellUsable(classtable.Disintegrate, 'Disintegrate')) and (buff[classtable.MassDisintegrateStacksBuff].up and talents[classtable.MassDisintegrate] and ( buff[classtable.ChargedBlastBuff].count <10 or not talents[classtable.ChargedBlast] )) and cooldown[classtable.Disintegrate].ready then
        if not setSpell then setSpell = classtable.Disintegrate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pyre, 'Pyre')) and (( targets >= 4 or talents[classtable.Volatility] ) and ( cooldown[classtable.Dragonrage].remains >gcd * 4 or not talents[classtable.ChargedBlast] or talents[classtable.Engulf] and ( not talents[classtable.ArcaneIntensity] or not talents[classtable.EternitysSpan] ) ) and not pool_for_id) and cooldown[classtable.Pyre].ready then
        if not setSpell then setSpell = classtable.Pyre end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pyre, 'Pyre')) and (buff[classtable.ChargedBlastBuff].count >= 12 and cooldown[classtable.Dragonrage].remains >gcd * 4) and cooldown[classtable.Pyre].ready then
        if not setSpell then setSpell = classtable.Pyre end
    end
    if (MaxDps:CheckSpellUsable(classtable.LivingFlame, 'LivingFlame')) and (( not talents[classtable.Burnout] or buff[classtable.BurnoutBuff].up or cooldown[classtable.FireBreath].remains <= gcd * 5 or buff[classtable.ScarletAdaptationBuff].up or buff[classtable.AncientFlameBuff].up ) and buff[classtable.LeapingFlamesBuff].up and not buff[classtable.EssenceBurstBuff].up and EssenceDeficit >1) and cooldown[classtable.LivingFlame].ready then
        if not setSpell then setSpell = classtable.LivingFlame end
    end
    if (MaxDps:CheckSpellUsable(classtable.Disintegrate, 'Disintegrate')) and (( math.huge >2 or buff[classtable.HoverBuff].up ) and not pool_for_id) and cooldown[classtable.Disintegrate].ready then
        if not setSpell then setSpell = classtable.Disintegrate end
    end
    if (MaxDps:CheckSpellUsable(classtable.LivingFlame, 'LivingFlame')) and (talents[classtable.Snapfire] and buff[classtable.BurnoutBuff].up) and cooldown[classtable.LivingFlame].ready then
        if not setSpell then setSpell = classtable.LivingFlame end
    end
    if (talents[classtable.AncientFlame] and not buff[classtable.AncientFlameBuff].up and not buff[classtable.DragonrageBuff].up) then
        Devastation:green()
    end
    if (MaxDps:CheckSpellUsable(classtable.AzureStrike, 'AzureStrike')) and cooldown[classtable.AzureStrike].ready then
        if not setSpell then setSpell = classtable.AzureStrike end
    end
end
function Devastation:es()
    if (MaxDps:CheckSpellUsable(classtable.EternitySurge, 'EternitySurge')) and (targets <= 1 + (talents[classtable.EternitysSpan] and talents[classtable.EternitysSpan] or 0) or buff[classtable.DragonrageBuff].remains <1.75 * SpellHaste and buff[classtable.DragonrageBuff].remains >= 1 * SpellHaste or buff[classtable.DragonrageBuff].up and ( targets >( 3 + (talents[classtable.FontofMagic] and talents[classtable.FontofMagic] or 0) ) * ( 1 + (talents[classtable.EternitysSpan] and talents[classtable.EternitysSpan] or 0) ) ) or targets >= 6 and not talents[classtable.EternitysSpan]) and cooldown[classtable.EternitySurge].ready then
        if not setSpell then setSpell = classtable.EternitySurge end
    end
    if (MaxDps:CheckSpellUsable(classtable.EternitySurge, 'EternitySurge')) and (targets <= 2 + 2 * (talents[classtable.EternitysSpan] and talents[classtable.EternitysSpan] or 0) or buff[classtable.DragonrageBuff].remains <2.5 * SpellHaste and buff[classtable.DragonrageBuff].remains >= 1.75 * SpellHaste) and cooldown[classtable.EternitySurge].ready then
        if not setSpell then setSpell = classtable.EternitySurge end
    end
    if (MaxDps:CheckSpellUsable(classtable.EternitySurge, 'EternitySurge')) and (targets <= 3 + 3 * (talents[classtable.EternitysSpan] and talents[classtable.EternitysSpan] or 0) or not talents[classtable.FontofMagic] or buff[classtable.DragonrageBuff].remains <= 3.25 * SpellHaste and buff[classtable.DragonrageBuff].remains >= 2.5 * SpellHaste) and cooldown[classtable.EternitySurge].ready then
        if not setSpell then setSpell = classtable.EternitySurge end
    end
    if (MaxDps:CheckSpellUsable(classtable.EternitySurge, 'EternitySurge')) and cooldown[classtable.EternitySurge].ready then
        if not setSpell then setSpell = classtable.EternitySurge end
    end
end
function Devastation:fb()
    if (MaxDps:CheckSpellUsable(classtable.FireBreath, 'FireBreath')) and (( buff[classtable.DragonrageBuff].remains <1.75 * SpellHaste and buff[classtable.DragonrageBuff].remains >= 1 * SpellHaste ) or targets == 1 or talents[classtable.ScorchingEmbers] and not debuff[classtable.FireBreathDamageDeBuff].up) and cooldown[classtable.FireBreath].ready then
        if not setSpell then setSpell = classtable.FireBreath end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBreath, 'FireBreath')) and (targets == 2 or ( buff[classtable.DragonrageBuff].remains <2.5 * SpellHaste and buff[classtable.DragonrageBuff].remains >= 1.75 * SpellHaste ) or talents[classtable.ScorchingEmbers]) and cooldown[classtable.FireBreath].ready then
        if not setSpell then setSpell = classtable.FireBreath end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBreath, 'FireBreath')) and (not talents[classtable.FontofMagic] or ( buff[classtable.DragonrageBuff].remains <= 3.25 * SpellHaste and buff[classtable.DragonrageBuff].remains >= 2.5 * SpellHaste ) or talents[classtable.ScorchingEmbers]) and cooldown[classtable.FireBreath].ready then
        if not setSpell then setSpell = classtable.FireBreath end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireBreath, 'FireBreath')) and cooldown[classtable.FireBreath].ready then
        if not setSpell then setSpell = classtable.FireBreath end
    end
end
function Devastation:green()
    if (MaxDps:CheckSpellUsable(classtable.EmeraldBlossom, 'EmeraldBlossom')) and cooldown[classtable.EmeraldBlossom].ready then
        MaxDps:GlowCooldown(classtable.EmeraldBlossom, cooldown[classtable.EmeraldBlossom].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.VerdantEmbrace, 'VerdantEmbrace')) and cooldown[classtable.VerdantEmbrace].ready then
        MaxDps:GlowCooldown(classtable.VerdantEmbrace, cooldown[classtable.VerdantEmbrace].ready)
    end
end
function Devastation:st()
    if (MaxDps:CheckSpellUsable(classtable.Hover, 'Hover')) and (math.huge <6 and not buff[classtable.HoverBuff].up and gcd >= 0.5) and cooldown[classtable.Hover].ready then
        if not setSpell then setSpell = classtable.Hover end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeepBreath, 'DeepBreath')) and (talents[classtable.Maneuverability] and talents[classtable.MeltArmor]) and cooldown[classtable.DeepBreath].ready then
        MaxDps:GlowCooldown(classtable.DeepBreath, cooldown[classtable.DeepBreath].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Dragonrage, 'Dragonrage') and talents[classtable.Dragonrage]) and (( cooldown[classtable.FireBreath].remains <4 or cooldown[classtable.EternitySurge].remains <4 and ( not (MaxDps.tier and MaxDps.tier[32].count >= 4) or not talents[classtable.MassDisintegrate] ) ) and ( cooldown[classtable.FireBreath].remains <8 and ( cooldown[classtable.EternitySurge].remains <8 or (MaxDps.tier and MaxDps.tier[32].count >= 4) and talents[classtable.MassDisintegrate] ) ) and ttd >= 32 or MaxDps:boss() and ttd <32) and cooldown[classtable.Dragonrage].ready then
        MaxDps:GlowCooldown(classtable.Dragonrage, cooldown[classtable.Dragonrage].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.TiptheScales, 'TiptheScales')) and (( not talents[classtable.Dragonrage] or buff[classtable.DragonrageBuff].up ) and ( cooldown[classtable.FireBreath].remains <cooldown[classtable.EternitySurge].remains or ( cooldown[classtable.EternitySurge].remains <cooldown[classtable.FireBreath].remains and talents[classtable.FontofMagic] ) )) and cooldown[classtable.TiptheScales].ready then
        MaxDps:GlowCooldown(classtable.TiptheScales, cooldown[classtable.TiptheScales].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ShatteringStar, 'ShatteringStar') and talents[classtable.ShatteringStar]) and (( buff[classtable.EssenceBurstBuff].count <1 or not talents[classtable.ArcaneVigor] ) and ( not cooldown[classtable.EternitySurge].ready or not buff[classtable.DragonrageBuff].up or talents[classtable.MassDisintegrate] or not talents[classtable.EventHorizon] and ( not talents[classtable.TravelingFlame] or not cooldown[classtable.Engulf].ready ) ) and ( cooldown[classtable.Dragonrage].remains >= 15 or cooldown[classtable.FireBreath].remains >= 8 or buff[classtable.DragonrageBuff].up and ( cooldown[classtable.FireBreath].remains <= gcd and buff[classtable.TiptheScalesBuff].up or cooldown[classtable.TiptheScales].remains >= 15 and not buff[classtable.TiptheScalesBuff].up ) or not talents[classtable.TravelingFlame] ) and ( not cooldown[classtable.FireBreath].ready or buff[classtable.TiptheScalesBuff].up )) and cooldown[classtable.ShatteringStar].ready then
        if not setSpell then setSpell = classtable.ShatteringStar end
    end
    if talents[classtable.Bombardments] then
        bombardment_clause = ( not talents[classtable.Bombardments] or talents[classtable.ExtendedBattle] or debuff[classtable.BombardmentsDeBuff].remains <= 7 and not buff[classtable.MassDisintegrateStacksBuff].up or buff[classtable.DragonrageBuff].up )
    end
    if (( not talents[classtable.Dragonrage] or next_dragonrage >dr_prep_time_st or not talents[classtable.Animosity] ) and ( not cooldown[classtable.EternitySurge].ready or not talents[classtable.EventHorizon] and not talents[classtable.TravelingFlame] or talents[classtable.MassDisintegrate] or not buff[classtable.DragonrageBuff].up ) and ( ttd >= 8 or ttd <30 ) or (MaxDps.Spells[classtable.FireBreath] and cooldown[classtable.FireBreath].ready and targets >=3)) then
        Devastation:fb()
    end
    if (( not talents[classtable.Dragonrage] or next_dragonrage >dr_prep_time_st or not talents[classtable.Animosity] or (MaxDps.tier and MaxDps.tier[32].count >= 4) and talents[classtable.MassDisintegrate] ) and ( ttd >= 8 or ttd <30 ) or (MaxDps.Spells[classtable.EternitySurge] and cooldown[classtable.EternitySurge].ready and targets <3)) then
        Devastation:es()
    end
    if (MaxDps:CheckSpellUsable(classtable.LivingFlame, 'LivingFlame')) and (buff[classtable.DragonrageBuff].up and buff[classtable.DragonrageBuff].remains <( 1 - buff[classtable.EssenceBurstBuff].count ) * gcd and buff[classtable.BurnoutBuff].up) and cooldown[classtable.LivingFlame].ready then
        if not setSpell then setSpell = classtable.LivingFlame end
    end
    if (MaxDps:CheckSpellUsable(classtable.AzureStrike, 'AzureStrike')) and (buff[classtable.DragonrageBuff].up and buff[classtable.DragonrageBuff].remains <( 1 - buff[classtable.EssenceBurstBuff].count ) * gcd) and cooldown[classtable.AzureStrike].ready then
        if not setSpell then setSpell = classtable.AzureStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Engulf, 'Engulf') and talents[classtable.Engulf]) and (debuff[classtable.FireBreathDamageDeBuff].up and ( not talents[classtable.Enkindle] or debuff[classtable.EnkindleDeBuff].up and ( (MaxDps.spellHistory[1] == classtable.Disintegrate) or (MaxDps.spellHistory[1] == classtable.Engulf) or (MaxDps.spellHistory[2] == classtable.Disintegrate) or not talents[classtable.FantheFlames] or targets >1 ) ) and ( not talents[classtable.RubyEmbers] or debuff[classtable.LivingFlameDamageDeBuff].up ) and ( not talents[classtable.ShatteringStar] or debuff[classtable.ShatteringStarDebuffDeBuff].up ) and cooldown[classtable.Dragonrage].remains >= 27) and cooldown[classtable.Engulf].ready then
        if not setSpell then setSpell = classtable.Engulf end
    end
    if (MaxDps:CheckSpellUsable(classtable.LivingFlame, 'LivingFlame')) and (buff[classtable.BurnoutBuff].up and buff[classtable.LeapingFlamesBuff].up and not buff[classtable.EssenceBurstBuff].up and buff[classtable.DragonrageBuff].up) and cooldown[classtable.LivingFlame].ready then
        if not setSpell then setSpell = classtable.LivingFlame end
    end
    if (MaxDps:CheckSpellUsable(classtable.Firestorm, 'Firestorm') and talents[classtable.Firestorm]) and (not buff[classtable.DragonrageBuff].up and not debuff[classtable.ShatteringStarDebuffDeBuff].up and talents[classtable.FeedtheFlames] and ( ( not talents[classtable.Dragonrage] or cooldown[classtable.Dragonrage].remains >= 10 ) and ( Essence >= 3 or buff[classtable.EssenceBurstBuff].up or talents[classtable.ShatteringStar] and cooldown[classtable.ShatteringStar].remains <= 6 ) or talents[classtable.Dragonrage] and cooldown[classtable.Dragonrage].remains <= ( classtable and classtable.Firestorm and GetSpellInfo(classtable.Firestorm).castTime /1000 or 0) and cooldown[classtable.FireBreath].remains <6 and cooldown[classtable.EternitySurge].remains <12 ) and not debuff[classtable.InFirestormDeBuff].up) and cooldown[classtable.Firestorm].ready then
        if not setSpell then setSpell = classtable.Firestorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeepBreath, 'DeepBreath')) and (not buff[classtable.DragonrageBuff].up and ( talents[classtable.ImminentDestruction] and not debuff[classtable.ShatteringStarDebuffDeBuff].up or talents[classtable.MeltArmor] and talents[classtable.Maneuverability] )) and cooldown[classtable.DeepBreath].ready then
        MaxDps:GlowCooldown(classtable.DeepBreath, cooldown[classtable.DeepBreath].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Pyre, 'Pyre')) and (debuff[classtable.InFirestormDeBuff].up and talents[classtable.FeedtheFlames] and buff[classtable.ChargedBlastBuff].count == 20 and targets >= 2) and cooldown[classtable.Pyre].ready then
        if not setSpell then setSpell = classtable.Pyre end
    end
    if (MaxDps:CheckSpellUsable(classtable.Disintegrate, 'Disintegrate')) and (( math.huge >2 or buff[classtable.HoverBuff].up ) and buff[classtable.MassDisintegrateStacksBuff].up and talents[classtable.MassDisintegrate]) and cooldown[classtable.Disintegrate].ready then
        if not setSpell then setSpell = classtable.Disintegrate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Disintegrate, 'Disintegrate')) and (( math.huge >2 or buff[classtable.HoverBuff].up ) and not pool_for_id) and cooldown[classtable.Disintegrate].ready then
        if not setSpell then setSpell = classtable.Disintegrate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Firestorm, 'Firestorm') and talents[classtable.Firestorm]) and (buff[classtable.SnapfireBuff].up or not debuff[classtable.InFirestormDeBuff].up and talents[classtable.FeedtheFlames]) and cooldown[classtable.Firestorm].ready then
        if not setSpell then setSpell = classtable.Firestorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeepBreath, 'DeepBreath')) and (not buff[classtable.DragonrageBuff].up and targets >= 2 and ( ( math.huge >= 120 and not talents[classtable.OnyxLegacy] ) or ( math.huge >= 60 and talents[classtable.OnyxLegacy] ) )) and cooldown[classtable.DeepBreath].ready then
        MaxDps:GlowCooldown(classtable.DeepBreath, cooldown[classtable.DeepBreath].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DeepBreath, 'DeepBreath')) and (not buff[classtable.DragonrageBuff].up and ( talents[classtable.ImminentDestruction] and not debuff[classtable.ShatteringStarDebuffDeBuff].up or talents[classtable.MeltArmor] or talents[classtable.Maneuverability] )) and cooldown[classtable.DeepBreath].ready then
        MaxDps:GlowCooldown(classtable.DeepBreath, cooldown[classtable.DeepBreath].ready)
    end
    if (talents[classtable.AncientFlame] and not buff[classtable.AncientFlameBuff].up and not buff[classtable.ShatteringStarDebuffBuff].up and talents[classtable.ScarletAdaptation] and not buff[classtable.DragonrageBuff].up and not buff[classtable.BurnoutBuff].up) then
        Devastation:green()
    end
    if (MaxDps:CheckSpellUsable(classtable.LivingFlame, 'LivingFlame')) and (not buff[classtable.DragonrageBuff].up or ( buff[classtable.IridescenceRedBuff].remains >timeShift or not talents[classtable.EngulfingBlaze] or buff[classtable.IridescenceBlueBuff].up or buff[classtable.BurnoutBuff].up or buff[classtable.LeapingFlamesBuff].up and cooldown[classtable.FireBreath].remains <= 5 ) and targets == 1) and cooldown[classtable.LivingFlame].ready then
        if not setSpell then setSpell = classtable.LivingFlame end
    end
    if (MaxDps:CheckSpellUsable(classtable.AzureStrike, 'AzureStrike')) and cooldown[classtable.AzureStrike].ready then
        if not setSpell then setSpell = classtable.AzureStrike end
    end
end
function Devastation:trinkets()
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.VerdantEmbrace, false)
    MaxDps:GlowCooldown(classtable.Quell, false)
    MaxDps:GlowCooldown(classtable.DeepBreath, false)
    MaxDps:GlowCooldown(classtable.Dragonrage, false)
    MaxDps:GlowCooldown(classtable.TiptheScales, false)
    MaxDps:GlowCooldown(classtable.EmeraldBlossom, false)
end

function Devastation:callaction()
    next_dragonrage = cooldown[classtable.Dragonrage].remains-- <( ( cooldown[classtable.EternitySurge].remains - 8 ) >( cooldown[classtable.FireBreath].remains - 8 ) and 1 or 0)
    if talents[classtable.ImminentDestruction] and talents[classtable.MeltArmor] and talents[classtable.Maneuverability] then
        pool_for_id = cooldown[classtable.DeepBreath].remains <8 and EssenceDeficit >= 1 and not buff[classtable.EssenceBurstBuff].up
    end
    if (MaxDps:CheckSpellUsable(classtable.Quell, 'Quell')) and cooldown[classtable.Quell].ready then
        MaxDps:GlowCooldown(classtable.Quell, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:CheckSpellUsable(classtable.Unravel, 'Unravel')) and cooldown[classtable.Unravel].ready then
        if not setSpell then setSpell = classtable.Unravel end
    end
    Devastation:trinkets()
    if (targets >= 3) then
        Devastation:aoe()
    end
    Devastation:st()
end
function Evoker:Devastation()
    fd = MaxDps.FrameData
    ttd = (fd.timeToDie and fd.timeToDie) or 500
    timeShift = fd.timeShift
    gcd = fd.gcd
    cooldown = fd.cooldown
    buff = fd.buff
    debuff = fd.debuff
    talents = fd.talents
    targets = MaxDps:SmartAoe()
    Mana = UnitPower('player', ManaPT)
    ManaMax = UnitPowerMax('player', ManaPT)
    ManaDeficit = ManaMax - Mana
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP >0 and targetmaxHP >0 and (targetHP / targetmaxHP) * 100) or 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    Essence = UnitPower('player', EssencePT)
    EssenceMax = UnitPowerMax('player', EssencePT)
    EssenceDeficit = EssenceMax - Essence
    EssenceRegen = GetPowerRegenForPowerType(Enum.PowerType.Essence)
    EssenceTimeToMax = EssenceDeficit / EssenceRegen
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.HoverBuff = 358267
    classtable.MassDisintegrateStacksBuff = 0
    classtable.SnapfireBuff = 370818
    classtable.DragonrageBuff = 375087
    classtable.EssenceBurstBuff = 359618
    classtable.FireBreathDamageDeBuff = 0
    classtable.ShatteringStarDebuffDeBuff = 370452
    classtable.ChargedBlastBuff = 370454
    classtable.BurnoutBuff = 375802
    classtable.ScarletAdaptationBuff = 372470
    classtable.AncientFlameBuff = 375583
    classtable.LeapingFlamesBuff = 370901
    classtable.TiptheScalesBuff = 370553
    classtable.BombardmentsDeBuff = 434300
    classtable.EnkindleDeBuff = 444016
    classtable.LivingFlameDamageDeBuff = 0
    classtable.InFirestormDeBuff = 0
    classtable.ShatteringStarDebuffBuff = 370454
    classtable.IridescenceRedBuff = 386353
    classtable.IridescenceBlueBuff = 386399

    local function debugg()
        talents[classtable.ScarletAdaptation] = 1
        talents[classtable.Firestorm] = 1
        talents[classtable.Engulf] = 1
        talents[classtable.RubyEmbers] = 1
        talents[classtable.ImminentDestruction] = 1
        talents[classtable.MeltArmor] = 1
        talents[classtable.Maneuverability] = 1
        talents[classtable.ArcaneVigor] = 1
        talents[classtable.EternitysSpan] = 1
        talents[classtable.MassDisintegrate] = 1
        talents[classtable.FeedtheFlames] = 1
        talents[classtable.Dragonrage] = 1
        talents[classtable.Iridescence] = 1
        talents[classtable.Animosity] = 1
        talents[classtable.ShatteringStar] = 1
        talents[classtable.ChargedBlast] = 1
        talents[classtable.Volatility] = 1
        talents[classtable.ArcaneIntensity] = 1
        talents[classtable.Burnout] = 1
        talents[classtable.Snapfire] = 1
        talents[classtable.AncientFlame] = 1
        talents[classtable.FontofMagic] = 1
        talents[classtable.ScorchingEmbers] = 1
        talents[classtable.EventHorizon] = 1
        talents[classtable.TravelingFlame] = 1
        talents[classtable.Bombardments] = 1
        talents[classtable.Enkindle] = 1
        talents[classtable.FantheFlames] = 1
        talents[classtable.OnyxLegacy] = 1
        talents[classtable.EngulfingBlaze] = 1
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Devastation:precombat()

    Devastation:callaction()
    if setSpell then return setSpell end
end
