local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then return end;

local Evoker = addonTable.Evoker;
local MaxDps = MaxDps;

local HL = {

};

local CN = {
	None      = 0,
	Kyrian    = 1,
	Venthyr   = 2,
	NightFae  = 3,
	Necrolord = 4
};

setmetatable(HL, Evoker.spellMeta);

function Evoker:Preservation()
    local fd = MaxDps.FrameData;

end