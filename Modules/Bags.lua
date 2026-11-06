local addon, ns = ...
local C, F, G = unpack(ns)
local panel = CreateFrame("Frame", nil, UIParent)

if not C.Bags then return end

	-- make addon frame anchor-able
	local Stat = CreateFrame("Frame", "diminfo_Bag")
	Stat:EnableMouse(true)
	Stat:SetFrameStrata("BACKGROUND")
	Stat:SetFrameLevel(3)

	-- setup text
	local Text  = panel:CreateFontString(nil, "OVERLAY")
	Text:SetFont(G.Fonts, G.FontSize, G.FontFlag)
	Text:SetPoint(unpack(C.BagsPoint))
	Stat:SetAllPoints(Text)

	local function OnEvent(self, event, ...)
		-- text
		local free, total, used = 0, 0, 0
		for i = 0, NUM_BAG_SLOTS do
			free, total = free + C_Container.GetContainerNumFreeSlots(i), total + C_Container.GetContainerNumSlots(i)
		end
		used = total - free
		Text:SetText(C.ClassColor and F.Hex(G.Ccolors)..BAGSLOT.." |r"..free.."/"..total or BACKPACK_TOOLTIP.." "..free.."/"..total)
		self:SetAllPoints(Text)

		-- tooltip
		Stat:SetScript("OnEnter", function()
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, -10)
			GameTooltip:ClearAllPoints()
			GameTooltip:SetPoint("BOTTOM", self, "TOP", 0, 1)
			GameTooltip:ClearLines()
			GameTooltip:AddDoubleLine(BAGSLOT, free, 0, .6, 1, 0, .6, 1)
			GameTooltip:AddLine(" ")
			GameTooltip:AddDoubleLine(TOTAL, total, .6, .8, 1, 1, 1, 1)
			GameTooltip:AddDoubleLine(USE, used, .6, .8, 1, 1, 1, 1)
			GameTooltip:AddDoubleLine(" ","--------------", 1, 1, 1, 0.5, 0.5, 0.5)
			GameTooltip:AddDoubleLine(" ",infoL["AutoSell junk"]..(diminfo.AutoSell and "|cff55ff55"..ENABLE or "|cffff5555"..DISABLE), 1, 1, 1, .6, .8, 1)
			GameTooltip:Show()
		end)
		Stat:SetScript("OnLeave", function() GameTooltip:Hide() end)
	end

	Stat:RegisterEvent("PLAYER_LOGIN")
	Stat:RegisterEvent("BAG_UPDATE")
	Stat:SetScript("OnEvent", OnEvent)
	Stat:SetScript("OnMouseDown", function(self,button)
		if button == "RightButton" then
			diminfo.AutoSell = not diminfo.AutoSell
			self:GetScript("OnEnter")(self)
		else
			ToggleAllBags()
		end
	end)

	-- Auto sell gray
	-- Blizzard 상인 창의 "잡동사니 모두 팔기" 버튼과 같은 C_MerchantFrame.SellAllJunkItems를 쓴다.
	-- 판매 금액은 게임이 시스템 메시지로 알려 주므로 따로 출력하지 않는다.
	local SellGray = CreateFrame("Frame")
	SellGray:RegisterEvent("MERCHANT_SHOW")
	SellGray:SetScript("OnEvent", function()
		if not diminfo.AutoSell or not C_MerchantFrame.IsSellAllJunkEnabled() then return end
		if C_MerchantFrame.GetNumJunkItems() == 0 then return end
		C_MerchantFrame.SellAllJunkItems()
	end)