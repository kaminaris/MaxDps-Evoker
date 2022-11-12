local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then return end;

local Evoker = addonTable.Evoker;
local MaxDps = MaxDps;

local DV = {
    TipTheScales = 370553,
    Dragonrage = 375087,
    ShatteringStar = 370452,
    EternitySurge = 382411,
    FireBreath = 382266,
    Disintegrate = 356995,
    LivingFlame = 361469,
    AzureStrike = 362969,
    EssenceBurst = 359618,
    Firestorm = 368847,
    Pyre = 357211,
    Burnout = 375802,
    ShatteringStar = 370452,
    EssenceAttunement = 375722,
    Snapfire = 370818
};

setmetatable(DV, Evoker.spellMeta);

function Evoker:Devastation()
    local fd = MaxDps.FrameData;
    fd.essence = UnitPower('player', Enum.PowerType.Essence)
    local talents = fd.talents
    fd.maxEssenceBurst = talents[DV.EssenceAttunement] and 2 or 1
    local cooldown = fd.cooldown

    if talents[DV.Dragonrage] then
        MaxDps:GlowCooldown(DV.Dragonrage, cooldown[DV.Dragonrage].ready)
    end

    if talents[DV.TipTheScales] then
        MaxDps:GlowCooldown(DV.TipTheScales, cooldown[DV.TipTheScales].ready)
    end

    local targets = MaxDps:SmartAoe()

    if targets > 1 then
        return Evoker:DevastationAoe()
    else
        return Evoker:DevastationSingle()
    end
end

function Evoker:DevastationSingle()
    local fd = MaxDps.FrameData;
    local cooldown = fd.cooldown
    local talents = fd.talents
    local buff = fd.buff
    local currentSpell = fd.currentSpell
    local gcd = fd.gcd
    local essence = fd.essence
    local maxEssenceBurst = fd.maxEssenceBurst

    if talents[DV.ShatteringStar] and cooldown[DV.ShatteringStar].ready then
        return DV.ShatteringStar
    end

    if buff[DV.EssenceBurst].up and (maxEssenceBurst == buff[DV.EssenceBurst].count or buff[DV.EssenceBurst].remains <= gcd * 2 or essence >= 4) then
        return DV.Disintegrate
    end

    -- Prevent losing the buff
    if buff[DV.Burnout].up then
        return DV.LivingFlame
    end

    if currentSpell ~= DV.EternitySurge and talents[DV.EternitySurge] and cooldown[DV.EternitySurge].ready then
        return DV.EternitySurge
    end

    if essence >= 5 then
        return DV.Disintegrate
    end

    if buff[DV.EssenceBurst].up and buff[DV.EssenceBurst].remains <= 5 then
        return DV.Disintegrate
    end

    if currentSpell ~= DV.FireBreath and cooldown[DV.FireBreath].ready then
        return DV.FireBreath
    end

    if essence >= 3 or buff[DV.EssenceBurst].up then
        return DV.Disintegrate
    end

    return DV.LivingFlame
end

function Evoker:DevastationAoe()
    local fd = MaxDps.FrameData;
    local cooldown = fd.cooldown
    local talents = fd.talents
    local buff = fd.buff
    local currentSpell = fd.currentSpell
    local gcd = fd.gcd
    local essence = fd.essence
    local maxEssenceBurst = fd.maxEssenceBurst

    if buff[DV.Snapfire].up then
        return DV.Firestorm
    end

    if buff[DV.EssenceBurst].up and (maxEssenceBurst == buff[DV.EssenceBurst].count or buff[DV.EssenceBurst].remains <= gcd * 2 or essence >= 5) then
        return DV.Pyre
    end

    if talents[DV.Firestorm] and currentSpell ~= DV.Firestorm and cooldown[DV.Firestorm].ready then
        return DV.Firestorm
    end

    if talents[DV.EternitySurge] and currentSpell ~= DV.EternitySurge and cooldown[DV.EternitySurge].ready then
        return DV.EternitySurge
    end

    if currentSpell ~= DV.FireBreath and cooldown[DV.FireBreath].ready then
        return DV.FireBreath
    end

    -- Prevent losing the buff
    if buff[DV.Burnout].up then
        return DV.LivingFlame
    end

    if essence >= 5 then
        return DV.Pyre
    end

    if buff[DV.EssenceBurst].up and buff[DV.EssenceBurst].remains <= 5 then
        return DV.Pyre
    end

    if essence >= 2 or buff[DV.EssenceBurst].up then
        return DV.Pyre
    end

    return DV.AzureStrike
end