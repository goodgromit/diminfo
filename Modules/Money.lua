local addon, ns = ...
local C, F, G = unpack(ns)
local panel = CreateFrame("Frame", nil, UIParent)

if not C.Money then return end
	-- make addon frame anchor-able
	local Stat = CreateFrame("Frame", "diminfo_money")
	Stat:EnableMouse(true)
	Stat:SetFrameStrata("BACKGROUND")
	Stat:SetFrameLevel(3)

	-- setup text
	local Text  = panel:CreateFontString(nil, "OVERLAY")
	Text:SetFont(G.Fonts, G.FontSize, G.FontFlag)
	Text:SetPoint(unpack(C.MoneyPoint))
	Stat:SetAllPoints(Text)

	local function OnEvent(self, event, ...)
		Text:SetText(GetCoinTextureString(GetMoney()));
    self:SetAllPoints(Text)
  end

	Stat:RegisterEvent("VARIABLES_LOADED")
	Stat:RegisterEvent("PLAYER_MONEY")
	Stat:RegisterEvent("PLAYER_ENTERING_WORLD")
	Stat:SetScript("OnEvent", OnEvent)