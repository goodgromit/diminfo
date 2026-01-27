local addon, ns = ...
local C, F, G = unpack(ns)
local panel = CreateFrame("Frame", nil, UIParent)

if not C.Durability then return end
	-- make addon frame anchor-able
	local Stat = CreateFrame("Frame", "diminfo_dura")
	Stat:EnableMouse(true)
	Stat:SetFrameStrata("BACKGROUND")
	Stat:SetFrameLevel(3)

	-- setup text
	local Text  = panel:CreateFontString(nil, "OVERLAY")
	Text:SetFont(G.Fonts, G.FontSize, G.FontFlag)
	Text:SetPoint(unpack(C.DurabilityPoint))
	Stat:SetAllPoints(Text)

	-- 11 slots
	local localSlots = {
		[1] = {1, INVTYPE_HEAD, 100, 100},
		[2] = {3, INVTYPE_SHOULDER, 100, 100},
		[3] = {5, INVTYPE_CHEST, 100, 100},
		[4] = {6, INVTYPE_WAIST, 100, 100},
		[5] = {9, INVTYPE_WRIST, 100, 100},
		[6] = {10, INVTYPE_HAND, 100, 100},
		[7] = {7, INVTYPE_LEGS, 100, 100},
		[8] = {8, INVTYPE_FEET, 100, 100},
		[9] = {16, INVTYPE_WEAPONMAINHAND, 100, 100},
		[10] = {17, INVTYPE_WEAPONOFFHAND, 100, 100},
		[11] = {18, INVTYPE_RANGED, 100, 100}
	}

	local Total = 0
	local current, max

	local function gradientColor(perc)
		perc = perc > 1 and 1 or perc < 0 and 0 or perc -- Stay between 0-1
		local seg, relperc = math.modf(perc*2)
		local r1, g1, b1, r2, g2, b2 = select(seg*3+1, 1, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0) -- R -> Y -> G
		local r, g, b = r1+(r2-r1)*relperc, g1+(g2-g1)*relperc, b1+(b2-b1)*relperc
		return format("|cff%02x%02x%02x", r*255, g*255, b*255), r, g, b
	end

	-- tooltip
	local function OnEvent(self)
		if diminfo.AutoRepair == nil then diminfo.AutoRepair = true end
		local dura_current = 0
		local dura_max = 0
		for i = 1, 11 do
			if GetInventoryItemLink("player", localSlots[i][1]) ~= nil then
				current, max = GetInventoryItemDurability(localSlots[i][1])
				if current then
					localSlots[i][3] = current
					localSlots[i][4] = max
					dura_current = dura_current + (current/max*100)
					dura_max = dura_max + 100
				else
					localSlots[i][3] = C_Item.GetItemCount(GetInventoryItemID("player", localSlots[i][1]));
					localSlots[i][4] = 0;
				end
			else
				localSlots[i][3] = 0
				localSlots[i][4] = 0
			end
		end

		--table.sort(localSlots, function(a, b) return a[3] < b[3] end)
		if dura_max > 0 then
			local dcolor = gradientColor(math.floor((dura_current/dura_max)*100)/100)
			if C.ClassColor then
				Text:SetText(F.Hex(G.Ccolors)..DURABILITY.." |r"..dcolor..math.floor((dura_current/dura_max)*100).."|r%")
			else
				Text:SetText(DURABILITY..dcolor..math.floor((dura_current/dura_max)*100).."|r%")
			end
		else
			Text:SetText(infoL["none"])
		end

		-- Setup
		self:SetAllPoints(Text)
		self:SetScript("OnEnter", function()
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, -10)
			GameTooltip:ClearAllPoints()
			GameTooltip:SetPoint("BOTTOM", self, "TOP", 0, 1)
			GameTooltip:ClearLines()

			-- C_SpecializationInfo.GetSpecializationInfo, https://warcraft.wiki.gg/wiki/API_C_SpecializationInfo.GetSpecializationInfo
			local p1 = select(3, GetTalentTabInfo(1))
			local p2 = select(3, GetTalentTabInfo(2))
			local p3 = select(3, GetTalentTabInfo(3))
			GameTooltip:AddDoubleLine(TALENT, p1.."/"..p2.."/"..p3, 0, .6, 1, 0, .6, 1)
			GameTooltip:AddLine(" ")
			for i = 1, 11 do
				if localSlots[i][4] ~= 0 then
					green = localSlots[i][3]/localSlots[i][4]*2
					red = 1 - green
					local slotIcon = "|T"..GetInventoryItemTexture("player", localSlots[i][1])..":16:16:0:0:50:50:4:46:4:46|t " or ""
					GameTooltip:AddDoubleLine(localSlots[i][2], slotIcon..GetInventoryItemLink("player", localSlots[i][1]).." "..floor(localSlots[i][3]/localSlots[i][4]*100).."%", 1, 1, 1, red+1, green,0)
				elseif (localSlots[i][4] == 0 and localSlots[i][3] ~= 0) then
					local slotIcon = "|T"..GetInventoryItemTexture("player", localSlots[i][1])..":16:16:0:0:50:50:4:46:4:46|t " or ""
					GameTooltip:AddDoubleLine(localSlots[i][2], slotIcon..GetInventoryItemLink("player", localSlots[i][1]).." "..localSlots[i][3], 1,1,1, 1,1,1)
				else
					GameTooltip:AddDoubleLine(localSlots[i][2], infoL["none"], 1,1,1, 1,1,1)
				end
			end
			GameTooltip:AddDoubleLine(" ","--------------",1,1,1,0.5,0.5,0.5)
			GameTooltip:AddDoubleLine(" ",infoL["AutoRepair"]..(diminfo.AutoRepair and "|cff55ff55"..ENABLE or "|cffff5555"..DISABLE), 1, 1, 1, .4, .78, 1)
			GameTooltip:Show()
		end)
		self:SetScript("OnLeave", function() GameTooltip:Hide() end)
		Total = 0
	end

	Stat:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
	Stat:RegisterEvent("MERCHANT_SHOW")
	Stat:RegisterEvent("PLAYER_ENTERING_WORLD")
	Stat:SetScript("OnMouseDown", function(self, button)
		if button == "RightButton" then
			diminfo.AutoRepair = not diminfo.AutoRepair
			self:GetScript("OnEnter")(self)
		else
			ToggleCharacter("PaperDollFrame")
		end
	end)
	Stat:SetScript("OnEvent", OnEvent)

	-- Auto repair
	local RepairGear = CreateFrame("Frame")
	RepairGear:RegisterEvent("MERCHANT_SHOW")
	RepairGear:SetScript("OnEvent", function()
		if (diminfo.AutoRepair == true and CanMerchantRepair()) then
			local cost = GetRepairAllCost()
			if cost > 0 then
				local money = GetMoney()

				if money > cost then
					RepairAllItems()
					print(format("|cff99CCFF"..infoL["Repair cost"].."|r%s", GetMoneyString(cost)))
				else
					print("|cff99CCFF"..infoL["Go farm, newbie"].."|r")
				end
			end
		end
	end)
