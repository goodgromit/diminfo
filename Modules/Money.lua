local addon, ns = ...
local C, F, G, L = unpack(ns)

if not C.Money then return end

local Stat, Text = F.CreateStat("diminfo_money", C.MoneyPoint)

Stat:RegisterEvent("PLAYER_ENTERING_WORLD")
Stat:RegisterEvent("PLAYER_MONEY")
Stat:SetScript("OnEvent", function()
	F.SetText(Text, C_CurrencyInfo.GetCoinTextureString(GetMoney()))
end)
