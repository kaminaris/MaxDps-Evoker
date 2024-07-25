local _, addonTable = ...
local Evoker = addonTable.Evoker
local MaxDps = _G.MaxDps
if not MaxDps then return end

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
local trinket_1_exclude
local trinket_2_exclude
local trinket_priority
local r1_cast_time
local dr_prep_time_aoe
local dr_prep_time_st
local has_external_pi
local next_dragonrage

local function CheckSpellCosts(spell,spellstring)
    if not IsSpellKnownOrOverridesKnown(spell) then return false end
    if spellstring == 'TouchofDeath' or spellstring == 'KillShot' then
        if targethealthPerc < 15 then
            return true
        else
            return false
        end
    end
    if spellstring == 'HammerofWrath' then
        if ( (classtable.AvengingWrathBuff and buff[classtable.AvengingWrathBuff].up) or (classtable.FinalVerdictBuff and buff[classtable.FinalVerdictBuff].up) ) then
            return true
        end
        if targethealthPerc < 20 then
            return true
        else
            return false
        end
    end
    if spellstring == 'Execute' then
        if (classtable.SuddenDeathBuff and buff[classtable.SuddenDeathBuff].up) then
            return true
        end
        if targethealthPerc < 35 then
            return true
        else
            return false
        end
    end
    local costs = C_Spell.GetSpellPowerCost(spell)
    if type(costs) ~= 'table' and spellstring then return true end
    for i,costtable in pairs(costs) do
        if UnitPower('player', costtable.type) < costtable.cost then
            return false
        end
    end
    return true
end
local function MaxGetSpellCost(spell,power)
    local costs = C_Spell.GetSpellPowerCost(spell)
    if type(costs) ~= 'table' then return 0 end
    for i,costtable in pairs(costs) do
        if costtable.name == power then
            return costtable.cost
        end
    end
    return 0
end



local function CheckEquipped(checkName)
    for i=1,14 do
        local itemID = GetInventoryItemID('player', i)
        local itemName = itemID and C_Item.GetItemInfo(itemID) or ''
        if checkName == itemName then
            return true
        end
    end
    return false
end




local function CheckTrinketNames(checkName)
    --if slot == 1 then
    --    slot = 13
    --end
    --if slot == 2 then
    --    slot = 14
    --end
    for i=13,14 do
        local itemID = GetInventoryItemID('player', i)
        local itemName = C_Item.GetItemInfo(itemID)
        if checkName == itemName then
            return true
        end
    end
    return false
end


local function CheckTrinketCooldown(slot)
    if slot == 1 then
        slot = 13
    end
    if slot == 2 then
        slot = 14
    end
    if slot == 13 or slot == 14 then
        local itemID = GetInventoryItemID('player', slot)
        local _, duration, _ = C_Item.GetItemCooldown(itemID)
        if duration == 0 then return true else return false end
    else
        local tOneitemID = GetInventoryItemID('player', 13)
        local tTwoitemID = GetInventoryItemID('player', 14)
        local tOneitemName = C_Item.GetItemInfo(tOneitemID)
        local tTwoitemName = C_Item.GetItemInfo(tTwoitemID)
        if tOneitemName == slot then
            local _, duration, _ = C_Item.GetItemCooldown(tOneitemID)
            if duration == 0 then return true else return false end
        end
        if tTwoitemName == slot then
            local _, duration, _ = C_Item.GetItemCooldown(tTwoitemID)
            if duration == 0 then return true else return false end
        end
    end
end


function Devastation:precombat()
    --if (MaxDps:FindSpell(classtable.Flask) and CheckSpellCosts(classtable.Flask, 'Flask')) and cooldown[classtable.Flask].ready then
    --    return classtable.Flask
    --end
    --if (MaxDps:FindSpell(classtable.Food) and CheckSpellCosts(classtable.Food, 'Food')) and cooldown[classtable.Food].ready then
    --    return classtable.Food
    --end
    --if (MaxDps:FindSpell(classtable.Augmentation) and CheckSpellCosts(classtable.Augmentation, 'Augmentation')) and cooldown[classtable.Augmentation].ready then
    --    return classtable.Augmentation
    --end
    --if (MaxDps:FindSpell(classtable.SnapshotStats) and CheckSpellCosts(classtable.SnapshotStats, 'SnapshotStats')) and cooldown[classtable.SnapshotStats].ready then
    --    return classtable.SnapshotStats
    --end
    --trinket_1_buffs = trinket.1.has_buff.intellect or trinket.1.has_buff.mastery or trinket.1.has_buff.versatility or trinket.1.has_buff.haste or trinket.1.has_buff.crit or CheckTrinketNames('MirrorofFracturedTomorrows')
    --trinket_2_buffs = trinket.2.has_buff.intellect or trinket.2.has_buff.mastery or trinket.2.has_buff.versatility or trinket.2.has_buff.haste or trinket.2.has_buff.crit or CheckTrinketNames('MirrorofFracturedTomorrows')
    --if trinket_1_buffs and ( trinket.1.cooldown.duration % % cooldown[classtable.Dragonrage].duration == 0 or cooldown[classtable.Dragonrage].duration % % trinket.1.cooldown.duration == 0 ) then
    --    trinket_1_sync = 1
    --else
    --    trinket_1_sync = 0.5
    --end
    --if trinket_2_buffs and ( trinket.2.cooldown.duration % % cooldown[classtable.Dragonrage].duration == 0 or cooldown[classtable.Dragonrage].duration % % trinket.2.cooldown.duration == 0 ) then
    --    trinket_2_sync = 1
    --else
    --    trinket_2_sync = 0.5
    --end
    --trinket_1_manual = CheckTrinketNames('BelorrelostheSuncaller') or CheckTrinketNames('NymuesUnravelingSpindle')
    --trinket_2_manual = CheckTrinketNames('BelorrelostheSuncaller') or CheckTrinketNames('NymuesUnravelingSpindle')
    --trinket_1_exclude = CheckTrinketNames('RubyWhelpShell') or CheckTrinketNames('WhisperingIncarnateIcon')
    --trinket_2_exclude = CheckTrinketNames('RubyWhelpShell') or CheckTrinketNames('WhisperingIncarnateIcon')
    --if not trinket_1_buffs and trinket_2_buffs or trinket_2_buffs and ( ( trinket.2.cooldown.duration % trinket.2.proc.any_dps.duration ) * ( 1.5 + trinket.2.has_buff.intellect ) * ( trinket_2_sync ) ) >( ( trinket.1.cooldown.duration % trinket.1.proc.any_dps.duration ) * ( 1.5 + trinket.1.has_buff.intellect ) * ( trinket_1_sync ) ) then
    --    trinket_priority = 2
    --else
    --    trinket_priority = 1
    --end
    r1_cast_time = 1.0 * SpellHaste
    dr_prep_time_aoe = 4
    dr_prep_time_st = 13
    --has_external_pi = cooldown[classtable.InvokePowerInfusion0].duration >0
    --if (MaxDps:FindSpell(classtable.VerdantEmbrace) and CheckSpellCosts(classtable.VerdantEmbrace, 'VerdantEmbrace')) and (talents[classtable.ScarletAdaptation]) and cooldown[classtable.VerdantEmbrace].ready then
    --    return classtable.VerdantEmbrace
    --end
    --if (MaxDps:FindSpell(classtable.Firestorm) and CheckSpellCosts(classtable.Firestorm, 'Firestorm')) and (talents[classtable.Firestorm]) and cooldown[classtable.Firestorm].ready then
    --    return classtable.Firestorm
    --end
    --if (MaxDps:FindSpell(classtable.LivingFlame) and CheckSpellCosts(classtable.LivingFlame, 'LivingFlame')) and (not talents[classtable.Firestorm]) and cooldown[classtable.LivingFlame].ready then
    --    return classtable.LivingFlame
    --end
end
function Devastation:aoe()
    if (MaxDps:FindSpell(classtable.ShatteringStar) and CheckSpellCosts(classtable.ShatteringStar, 'ShatteringStar')) and (cooldown[classtable.Dragonrage].up) and cooldown[classtable.ShatteringStar].ready then
        return classtable.ShatteringStar
    end
    if (MaxDps:FindSpell(classtable.Firestorm) and CheckSpellCosts(classtable.Firestorm, 'Firestorm')) and (talents[classtable.RagingInferno] and cooldown[classtable.Dragonrage].remains <= gcd and ( ttd >= 32 or ttd <30 )) and cooldown[classtable.Firestorm].ready then
        return classtable.Firestorm
    end
    if (MaxDps:FindSpell(classtable.Dragonrage) and CheckSpellCosts(classtable.Dragonrage, 'Dragonrage')) and (ttd >= 32 or ttd <30) and cooldown[classtable.Dragonrage].ready then
        return classtable.Dragonrage
    end
    if (MaxDps:FindSpell(classtable.TiptheScales) and CheckSpellCosts(classtable.TiptheScales, 'TiptheScales')) and (buff[classtable.DragonrageBuff].up and ( targets <= 3 + 3 * (talents[classtable.EternitysSpan] and 1 or 0) or not cooldown[classtable.FireBreath].up )) and cooldown[classtable.TiptheScales].ready then
        return classtable.TiptheScales
    end
    --next_dragonrage > dr_prep_time_aoe
    if (( not talents[classtable.Dragonrage] or (true) or not talents[classtable.Animosity] ) and ( ( buff[classtable.PowerSwellBuff].remains <r1_cast_time or ( not talents[classtable.Volatility] and targets == 3 ) ) and buff[classtable.BlazingShardsBuff].remains <r1_cast_time or buff[classtable.DragonrageBuff].up ) and ( ttd >= 8 or ttd <30 )) then
        local fbCheck = Devastation:fb()
        if fbCheck then
            return Devastation:fb()
        end
    end
    if (buff[classtable.DragonrageBuff].up or not talents[classtable.Dragonrage] or ( cooldown[classtable.Dragonrage].remains >dr_prep_time_aoe and ( buff[classtable.PowerSwellBuff].remains <r1_cast_time or ( not talents[classtable.Volatility] and targets == 3 ) ) and buff[classtable.BlazingShardsBuff].remains <r1_cast_time ) and ( ttd >= 8 or ttd <30 )) then
        local esCheck = Devastation:es()
        if esCheck then
            return Devastation:es()
        end
    end
    if (MaxDps:FindSpell(classtable.DeepBreath) and CheckSpellCosts(classtable.DeepBreath, 'DeepBreath')) and (not buff[classtable.DragonrageBuff].up and EssenceDeficit >3) and cooldown[classtable.DeepBreath].ready then
        return classtable.DeepBreath
    end
    if (MaxDps:FindSpell(classtable.ShatteringStar) and CheckSpellCosts(classtable.ShatteringStar, 'ShatteringStar')) and (buff[classtable.EssenceBurstBuff].count <EssenceBurstBuffMaxStacks or not talents[classtable.ArcaneVigor]) and cooldown[classtable.ShatteringStar].ready then
        return classtable.ShatteringStar
    end
    if (MaxDps:FindSpell(classtable.Firestorm) and CheckSpellCosts(classtable.Firestorm, 'Firestorm')) and (talents[classtable.RagingInferno] and ( cooldown[classtable.Dragonrage].remains >= 20 or cooldown[classtable.Dragonrage].remains <= 10 ) and ( buff[classtable.EssenceBurstBuff].up or Essence >= 2 or cooldown[classtable.Dragonrage].remains <= 10 ) or buff[classtable.SnapfireBuff].up) and cooldown[classtable.Firestorm].ready then
        return classtable.Firestorm
    end
    if (MaxDps:FindSpell(classtable.Pyre) and CheckSpellCosts(classtable.Pyre, 'Pyre')) and (targets >= 4) and cooldown[classtable.Pyre].ready then
        return classtable.Pyre
    end
    if (MaxDps:FindSpell(classtable.Pyre) and CheckSpellCosts(classtable.Pyre, 'Pyre')) and (targets >= 3 and talents[classtable.Volatility]) and cooldown[classtable.Pyre].ready then
        return classtable.Pyre
    end
    if (MaxDps:FindSpell(classtable.Pyre) and CheckSpellCosts(classtable.Pyre, 'Pyre')) and (buff[classtable.ChargedBlastBuff].count >= 15) and cooldown[classtable.Pyre].ready then
        return classtable.Pyre
    end
    if (MaxDps:FindSpell(classtable.LivingFlame) and CheckSpellCosts(classtable.LivingFlame, 'LivingFlame')) and (( not talents[classtable.Burnout] or buff[classtable.BurnoutBuff].up or targets >= 4 and cooldown[classtable.FireBreath].remains <= gcd * 3 or buff[classtable.ScarletAdaptationBuff].up ) and buff[classtable.LeapingFlamesBuff].up and not buff[classtable.EssenceBurstBuff].up and Essence <EssenceMax - 1) and cooldown[classtable.LivingFlame].ready then
        return classtable.LivingFlame
    end
    if (MaxDps:FindSpell(classtable.Disintegrate) and CheckSpellCosts(classtable.Disintegrate, 'Disintegrate')) and cooldown[classtable.Disintegrate].ready then
        return classtable.Disintegrate
    end
    if (MaxDps:FindSpell(classtable.LivingFlame) and CheckSpellCosts(classtable.LivingFlame, 'LivingFlame')) and (talents[classtable.Snapfire] and buff[classtable.BurnoutBuff].up) and cooldown[classtable.LivingFlame].ready then
        return classtable.LivingFlame
    end
    if (MaxDps:FindSpell(classtable.Firestorm) and CheckSpellCosts(classtable.Firestorm, 'Firestorm')) and cooldown[classtable.Firestorm].ready then
        return classtable.Firestorm
    end
    if (talents[classtable.AncientFlame] and not buff[classtable.AncientFlameBuff].up and not buff[classtable.DragonrageBuff].up) then
        local greenCheck = Devastation:green()
        if greenCheck then
            return Devastation:green()
        end
    end
    if (MaxDps:FindSpell(classtable.AzureStrike) and CheckSpellCosts(classtable.AzureStrike, 'AzureStrike')) and (targetHP) and cooldown[classtable.AzureStrike].ready then
        return classtable.AzureStrike
    end
end
function Devastation:es()
    if (MaxDps:FindSpell(classtable.EternitySurge) and CheckSpellCosts(classtable.EternitySurge, 'EternitySurge')) and (targets <= 1 + (talents[classtable.EternitysSpan] and 1 or 0) or buff[classtable.DragonrageBuff].remains <1.75 * SpellHaste and buff[classtable.DragonrageBuff].remains >= 1 * SpellHaste or buff[classtable.DragonrageBuff].up and ( targets == 5 and not talents[classtable.FontofMagic] or targets >( 3 + (talents[classtable.FontofMagic] and 1 or 0) ) * ( 1 + (talents[classtable.EternitysSpan] and 1 or 0)) ) or targets >= 6 and not talents[classtable.EternitysSpan]) and cooldown[classtable.EternitySurge].ready then
        return classtable.EternitySurge
    end
    if (MaxDps:FindSpell(classtable.EternitySurge) and CheckSpellCosts(classtable.EternitySurge, 'EternitySurge')) and (targets <= 2 + 2 * (talents[classtable.EternitysSpan] and 1 or 0) or buff[classtable.DragonrageBuff].remains <2.5 * SpellHaste and buff[classtable.DragonrageBuff].remains >= 1.75 * SpellHaste) and cooldown[classtable.EternitySurge].ready then
        return classtable.EternitySurge
    end
    if (MaxDps:FindSpell(classtable.EternitySurge) and CheckSpellCosts(classtable.EternitySurge, 'EternitySurge')) and (targets <= 3 + 3 * (talents[classtable.EternitysSpan] and 1 or 0) or not talents[classtable.FontofMagic] or buff[classtable.DragonrageBuff].remains <= 3.25 * SpellHaste and buff[classtable.DragonrageBuff].remains >= 2.5 * SpellHaste) and cooldown[classtable.EternitySurge].ready then
        return classtable.EternitySurge
    end
    if (MaxDps:FindSpell(classtable.EternitySurge) and CheckSpellCosts(classtable.EternitySurge, 'EternitySurge')) and (targetHP) and cooldown[classtable.EternitySurge].ready then
        return classtable.EternitySurge
    end
end
function Devastation:fb()
    if (MaxDps:FindSpell(classtable.FireBreath) and CheckSpellCosts(classtable.FireBreath, 'FireBreath')) and (( buff[classtable.DragonrageBuff].up and targets <= 2 ) or ( targets == 1 and not talents[classtable.EverburningFlame] ) or ( buff[classtable.DragonrageBuff].remains <1.75 * SpellHaste and buff[classtable.DragonrageBuff].remains >= 1 * SpellHaste )) and cooldown[classtable.FireBreath].ready then
        return classtable.FireBreath
    end
    if (MaxDps:FindSpell(classtable.FireBreath) and CheckSpellCosts(classtable.FireBreath, 'FireBreath')) and (( not debuff[classtable.InFirestormDeBuff].up and talents[classtable.EverburningFlame] and targets <= 3 ) or ( targets == 2 and not talents[classtable.EverburningFlame] ) or ( buff[classtable.DragonrageBuff].remains <2.5 * SpellHaste and buff[classtable.DragonrageBuff].remains >= 1.75 * SpellHaste )) and cooldown[classtable.FireBreath].ready then
        return classtable.FireBreath
    end
    if (MaxDps:FindSpell(classtable.FireBreath) and CheckSpellCosts(classtable.FireBreath, 'FireBreath')) and (( talents[classtable.EverburningFlame] and buff[classtable.DragonrageBuff].up and targets >= 5 ) or not talents[classtable.FontofMagic] or ( debuff[classtable.InFirestormDeBuff].up and talents[classtable.EverburningFlame] and targets <= 3 ) or ( buff[classtable.DragonrageBuff].remains <= 3.25 * SpellHaste and buff[classtable.DragonrageBuff].remains >= 2.5 * SpellHaste )) and cooldown[classtable.FireBreath].ready then
        return classtable.FireBreath
    end
    if (MaxDps:FindSpell(classtable.FireBreath) and CheckSpellCosts(classtable.FireBreath, 'FireBreath')) and (targetHP) and cooldown[classtable.FireBreath].ready then
        return classtable.FireBreath
    end
end
function Devastation:green()
    --if (MaxDps:FindSpell(classtable.EmeraldBlossom) and CheckSpellCosts(classtable.EmeraldBlossom, 'EmeraldBlossom')) and cooldown[classtable.EmeraldBlossom].ready then
    --    return classtable.EmeraldBlossom
    --end
    --if (MaxDps:FindSpell(classtable.VerdantEmbrace) and CheckSpellCosts(classtable.VerdantEmbrace, 'VerdantEmbrace')) and cooldown[classtable.VerdantEmbrace].ready then
    --    return classtable.VerdantEmbrace
    --end
end
function Devastation:st()
    --if (MaxDps:FindSpell(classtable.Hover) and CheckSpellCosts(classtable.Hover, 'Hover')) and (raid_event.movement.in <2 and not buff[classtable.HoverBuff].up) and cooldown[classtable.Hover].ready then
    --    return classtable.Hover
    --end
    if (MaxDps:FindSpell(classtable.Firestorm) and CheckSpellCosts(classtable.Firestorm, 'Firestorm')) and (buff[classtable.SnapfireBuff].up) and cooldown[classtable.Firestorm].ready then
        return classtable.Firestorm
    end
    if (MaxDps:FindSpell(classtable.Dragonrage) and CheckSpellCosts(classtable.Dragonrage, 'Dragonrage')) and (cooldown[classtable.FireBreath].remains <4 and cooldown[classtable.EternitySurge].remains <10 and ttd >= 32 or ttd <32) and cooldown[classtable.Dragonrage].ready then
        return classtable.Dragonrage
    end
    if (MaxDps:FindSpell(classtable.TiptheScales) and CheckSpellCosts(classtable.TiptheScales, 'TiptheScales')) and (buff[classtable.DragonrageBuff].up and ( ( ( not talents[classtable.FontofMagic] or talents[classtable.EverburningFlame] ) and cooldown[classtable.FireBreath].remains <cooldown[classtable.EternitySurge].remains and buff[classtable.DragonrageBuff].remains <14 ) or ( cooldown[classtable.EternitySurge].remains <cooldown[classtable.FireBreath].remains and not talents[classtable.EverburningFlame] and talents[classtable.FontofMagic] ) )) and cooldown[classtable.TiptheScales].ready then
        return classtable.TiptheScales
    end
    --next_dragonrage > dr_prep_time_st
    if (( not talents[classtable.Dragonrage] or (true) or not talents[classtable.Animosity] ) and ( buff[classtable.BlazingShardsBuff].remains <r1_cast_time or buff[classtable.DragonrageBuff].up ) and ( not cooldown[classtable.EternitySurge].up or not talents[classtable.EventHorizon] or not buff[classtable.DragonrageBuff].up ) and ( ttd >= 8 or ttd <30 )) then
        local fbCheck = Devastation:fb()
        if fbCheck then
            return Devastation:fb()
        end
    end
    if (MaxDps:FindSpell(classtable.ShatteringStar) and CheckSpellCosts(classtable.ShatteringStar, 'ShatteringStar')) and (( buff[classtable.EssenceBurstBuff].count <EssenceBurstBuffMaxStacks or not talents[classtable.ArcaneVigor] ) and ( not cooldown[classtable.EternitySurge].up or not buff[classtable.DragonrageBuff].up or not talents[classtable.EventHorizon] )) and cooldown[classtable.ShatteringStar].ready then
        return classtable.ShatteringStar
    end
    --next_dragonrage > dr_prep_time_st
    if (( not talents[classtable.Dragonrage] or (true) or not talents[classtable.Animosity] ) and ( buff[classtable.BlazingShardsBuff].remains <r1_cast_time or buff[classtable.DragonrageBuff].up ) and ( ttd >= 8 or ttd <30 )) then
        local esCheck = Devastation:es()
        if esCheck then
            return Devastation:es()
        end
    end
    --if (MaxDps:FindSpell(classtable.Wait) and CheckSpellCosts(classtable.Wait, 'Wait')) and (talents[classtable.Animosity] and buff[classtable.DragonrageBuff].up and buff[classtable.DragonrageBuff].remains <gcd + r1_cast_time * not buff[classtable.TiptheScalesBuff].up and buff[classtable.DragonrageBuff].remains - cooldown[classtable.FireBreath].remains >= r1_cast_time * not buff[classtable.TiptheScalesBuff].up) and cooldown[classtable.Wait].ready then
    --    return classtable.Wait
    --end
    --if (MaxDps:FindSpell(classtable.Wait) and CheckSpellCosts(classtable.Wait, 'Wait')) and (talents[classtable.Animosity] and buff[classtable.DragonrageBuff].up and buff[classtable.DragonrageBuff].remains <gcd + r1_cast_time and buff[classtable.DragonrageBuff].remains - cooldown[classtable.EternitySurge].remains >r1_cast_time * not buff[classtable.TiptheScalesBuff].up) and cooldown[classtable.Wait].ready then
    --    return classtable.Wait
    --end
    if (MaxDps:FindSpell(classtable.LivingFlame) and CheckSpellCosts(classtable.LivingFlame, 'LivingFlame')) and (buff[classtable.DragonrageBuff].up and buff[classtable.DragonrageBuff].remains <( EssenceBurstBuffMaxStacks - buff[classtable.EssenceBurstBuff].count ) * gcd and buff[classtable.BurnoutBuff].up) and cooldown[classtable.LivingFlame].ready then
        return classtable.LivingFlame
    end
    if (MaxDps:FindSpell(classtable.AzureStrike) and CheckSpellCosts(classtable.AzureStrike, 'AzureStrike')) and (buff[classtable.DragonrageBuff].up and buff[classtable.DragonrageBuff].remains <( EssenceBurstBuffMaxStacks - buff[classtable.EssenceBurstBuff].count ) * gcd) and cooldown[classtable.AzureStrike].ready then
        return classtable.AzureStrike
    end
    if (MaxDps:FindSpell(classtable.LivingFlame) and CheckSpellCosts(classtable.LivingFlame, 'LivingFlame')) and (buff[classtable.BurnoutBuff].up and ( buff[classtable.LeapingFlamesBuff].up and not buff[classtable.EssenceBurstBuff].up or not buff[classtable.LeapingFlamesBuff].up and buff[classtable.EssenceBurstBuff].count <EssenceBurstBuffMaxStacks ) and EssenceDeficit >= 2) and cooldown[classtable.LivingFlame].ready then
        return classtable.LivingFlame
    end
    if (MaxDps:FindSpell(classtable.Pyre) and CheckSpellCosts(classtable.Pyre, 'Pyre')) and (debuff[classtable.InFirestormDeBuff].up and talents[classtable.RagingInferno] and buff[classtable.ChargedBlastBuff].count == 20 and targets >= 2) and cooldown[classtable.Pyre].ready then
        return classtable.Pyre
    end
    if (MaxDps:FindSpell(classtable.Disintegrate) and CheckSpellCosts(classtable.Disintegrate, 'Disintegrate')) and cooldown[classtable.Disintegrate].ready then
        return classtable.Disintegrate
    end
    if (MaxDps:FindSpell(classtable.Firestorm) and CheckSpellCosts(classtable.Firestorm, 'Firestorm')) and (not buff[classtable.DragonrageBuff].up and not debuff[classtable.ShatteringStarDebuffDeBuff].up) and cooldown[classtable.Firestorm].ready then
        return classtable.Firestorm
    end
    if (MaxDps:FindSpell(classtable.DeepBreath) and CheckSpellCosts(classtable.DeepBreath, 'DeepBreath')) and (not buff[classtable.DragonrageBuff].up and targets >= 2) and cooldown[classtable.DeepBreath].ready then
        return classtable.DeepBreath
    end
    if (MaxDps:FindSpell(classtable.DeepBreath) and CheckSpellCosts(classtable.DeepBreath, 'DeepBreath')) and (not buff[classtable.DragonrageBuff].up and talents[classtable.ImminentDestruction] and not debuff[classtable.ShatteringStarDebuffDeBuff].up) and cooldown[classtable.DeepBreath].ready then
        return classtable.DeepBreath
    end
    if (talents[classtable.AncientFlame] and not buff[classtable.AncientFlameBuff].up and not buff[classtable.ShatteringStarDebuffBuff].up and talents[classtable.ScarletAdaptation] and not buff[classtable.DragonrageBuff].up) then
        local greenCheck = Devastation:green()
        if greenCheck then
            return Devastation:green()
        end
    end
    if (MaxDps:FindSpell(classtable.LivingFlame) and CheckSpellCosts(classtable.LivingFlame, 'LivingFlame')) and (not buff[classtable.DragonrageBuff].up or ( buff[classtable.IridescenceRedBuff].remains >timeShift or buff[classtable.IridescenceBlueBuff].up ) and targets == 1) and cooldown[classtable.LivingFlame].ready then
        return classtable.LivingFlame
    end
    if (MaxDps:FindSpell(classtable.AzureStrike) and CheckSpellCosts(classtable.AzureStrike, 'AzureStrike')) and cooldown[classtable.AzureStrike].ready then
        return classtable.AzureStrike
    end
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
    targets = 1--MaxDps:SmartAoe()
    Mana = UnitPower('player', ManaPT)
    ManaMax = UnitPowerMax('player', ManaPT)
    ManaDeficit = ManaMax - Mana
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP / targetmaxHP) * 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    SpellHaste = UnitSpellHaste('target')
    SpellCrit = GetCritChance()
    Essence = UnitPower('player', EssencePT)
    EssenceMax = UnitPowerMax('player', EssencePT)
    EssenceDeficit = EssenceMax - Essence
    classtable.DragonrageBuff = 375087
    classtable.PowerSwellBuff = 376850
    classtable.BlazingShardsBuff = 405519
    classtable.EssenceBurstBuff = 359618
    classtable.SnapfireBuff = 370818
    classtable.ChargedBlastBuff = 370454
    classtable.BurnoutBuff = 375802
    classtable.ScarletAdaptationBuff = 372470
    classtable.LeapingFlamesBuff = 370901
    classtable.HoverBuff = 358267
    classtable.AncientFlameBuff = 375583
    classtable.InFirestormDeBuff = 0
    classtable.TiptheScalesBuff = 370553
    classtable.ShatteringStarDebuffDeBuff = 370452
    classtable.ShatteringStarDebuffBuff = 370454
    classtable.IridescenceRedBuff = 386353
    classtable.IridescenceBlueBuff = 386399
    --EternitySurge Needs Seperate Entry as it is a talent and modified by another talent
    if talents[classtable.FontofMagic] then
        classtable.FireBreath = 382266
        classtable.EternitySurgeSpell = 382411
    elseif not talents[classtable.FontofMagic] then
        classtable.FireBreath = 357208
        classtable.EternitySurgeSpell = 359073
    end

    if talents[classtable.EssenceAttunement] then
        EssenceBurstBuffMaxStacks = 2
    else
        EssenceBurstBuffMaxStacks = 1
    end

    Devastation:precombat()

    --if (MaxDps:FindSpell(classtable.Potion) and CheckSpellCosts(classtable.Potion, 'Potion')) and (buff[classtable.DragonrageBuff].up and ( not cooldown[classtable.ShatteringStar].up or targets >= 2 ) or ttd <35) and cooldown[classtable.Potion].ready then
    --    return classtable.Potion
    --end
    next_dragonrage = cooldown[classtable.Dragonrage].remains and (cooldown[classtable.EternitySurge].remains > 0 and cooldown[classtable.EternitySurge].remains - 2 * gcd) or (cooldown[classtable.FireBreath].remains > 0 and cooldown[classtable.FireBreath].remains - gcd) or 0
    --if (MaxDps:FindSpell(classtable.Quell) and CheckSpellCosts(classtable.Quell, 'Quell')) and (target.debuff.casting.up) and cooldown[classtable.Quell].ready then
    --    return classtable.Quell
    --end
    if (targets >= 3) then
        local aoeCheck = Devastation:aoe()
        if aoeCheck then
            return Devastation:aoe()
        end
    end
    local stCheck = Devastation:st()
    if stCheck then
        return stCheck
    end
    if (talents[classtable.Dragonrage] and talents[classtable.Iridescence] and ( ttd >= 32 or ttd <30 ) and cooldown[classtable.Dragonrage].remains <= gcd) then
        local fbCheck = Devastation:fb()
        if fbCheck then
            return Devastation:fb()
        end
    end
    --(true)
    if (( not talents[classtable.Dragonrage] or (true) or not talents[classtable.Animosity] ) and ( ( buff[classtable.PowerSwellBuff].remains <r1_cast_time or ( not talents[classtable.Volatility] and targets == 3 ) ) and buff[classtable.BlazingShardsBuff].remains <r1_cast_time or buff[classtable.DragonrageBuff].up ) and ( ttd >= 8 or ttd <30 )) then
        local fbCheck = Devastation:fb()
        if fbCheck then
            return Devastation:fb()
        end
    end
    if (buff[classtable.DragonrageBuff].up or not talents[classtable.Dragonrage] or ( cooldown[classtable.Dragonrage].remains >dr_prep_time_aoe and ( buff[classtable.PowerSwellBuff].remains <r1_cast_time or ( not talents[classtable.Volatility] and targets == 3 ) ) and buff[classtable.BlazingShardsBuff].remains <r1_cast_time ) and ( ttd >= 8 or ttd <30 )) then
        local esCheck = Devastation:es()
        if esCheck then
            return Devastation:es()
        end
    end
    if (talents[classtable.AncientFlame] and not buff[classtable.AncientFlameBuff].up and not buff[classtable.DragonrageBuff].up) then
        local greenCheck = Devastation:green()
        if greenCheck then
            return Devastation:green()
        end
    end
    --next_dragonrage > dr_prep_time_st
    if (( not talents[classtable.Dragonrage] or (true) or not talents[classtable.Animosity] ) and ( buff[classtable.BlazingShardsBuff].remains <r1_cast_time or buff[classtable.DragonrageBuff].up ) and ( not cooldown[classtable.EternitySurge].up or not talents[classtable.EventHorizon] or not buff[classtable.DragonrageBuff].up ) and ( ttd >= 8 or ttd <30 )) then
        local fbCheck = Devastation:fb()
        if fbCheck then
            return Devastation:fb()
        end
    end
    --next_dragonrage > dr_prep_time_st
    if (( not talents[classtable.Dragonrage] or (true) or not talents[classtable.Animosity] ) and ( buff[classtable.BlazingShardsBuff].remains <r1_cast_time or buff[classtable.DragonrageBuff].up ) and ( ttd >= 8 or ttd <30 )) then
        local esCheck = Devastation:es()
        if esCheck then
            return Devastation:es()
        end
    end
    if (talents[classtable.AncientFlame] and not buff[classtable.AncientFlameBuff].up and not buff[classtable.ShatteringStarDebuffBuff].up and talents[classtable.ScarletAdaptation] and not buff[classtable.DragonrageBuff].up) then
        local greenCheck = Devastation:green()
        if greenCheck then
            return Devastation:green()
        end
    end

end
