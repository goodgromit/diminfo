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
		if diminfo.AutoSell == nil then
			diminfo.AutoSell = true
		end

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
	local SellGray = CreateFrame("Frame")
	SellGray:RegisterEvent("MERCHANT_SHOW")

	SellGray:SetScript("OnEvent", function()
		-- 자동 판매 옵션이 켜져 있는지 확인
		if not diminfo.AutoSell then return end

		local totalEarnings = 0
		-- 가방 번호는 보통 0~4(기본+가방4개)이며, 최신 버전은 재료 가방(5)까지 포함 가능
		for bag = 0, 5 do
			for slot = 1, C_Container.GetContainerNumSlots(bag) do
				-- 최신 API는 정보를 테이블 형태로 반환함
				local containerInfo = C_Container.GetContainerItemInfo(bag, slot)
				
				if containerInfo then
					local itemLink = containerInfo.hyperlink
					local stackCount = containerInfo.stackCount
					
					-- 아이템 링크가 있고 정보가 유효한지 확인
					if itemLink then
						local itemName, _, itemQuality, _, _, _, _, _, _, _, itemSellPrice = C_Item.GetItemInfo(itemLink)
						
						-- 품질이 0(잡동사니/회색)이고 판매 가격이 있는 경우
						if itemQuality == 0 and itemSellPrice and itemSellPrice > 0 then
							local currentPrice = itemSellPrice * stackCount
							
							-- 아이템 판매 실행 (최신 API 권장)
							C_Container.UseContainerItem(bag, slot)
							totalEarnings = totalEarnings + currentPrice
						end
					end
				end
			end
		end

		-- 판매 금액이 있다면 출력
		if totalEarnings > 0 then
			local goldString = GetMoneyString(totalEarnings)
			print(format("|cff99CCFF%s|r %s", infoL["Trash sold, earned "] or "잡동사니 판매 완료: ", goldString))
		end
	end)