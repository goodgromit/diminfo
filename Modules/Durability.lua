local addon, ns = ...
local C, F, G, L = unpack(ns)

if not C.Durability then return end

local Stat, Text = F.CreateStat("diminfo_dura", C.DurabilityPoint)

-- 내구도를 확인할 장비 칸 11개
-- 항목: { 장비 칸 번호, 칸 이름, 현재 값, 최대 값, ItemLocation }
-- 최대 값이 0이면 내구도가 없는 아이템(투척 무기 등)이고, 현재 값에 개수를 넣는다.
local slots = {
	{1, INVTYPE_HEAD},
	{3, INVTYPE_SHOULDER},
	{5, INVTYPE_CHEST},
	{6, INVTYPE_WAIST},
	{9, INVTYPE_WRIST},
	{10, INVTYPE_HAND},
	{7, INVTYPE_LEGS},
	{8, INVTYPE_FEET},
	{16, INVTYPE_WEAPONMAINHAND},
	{17, INVTYPE_WEAPONOFFHAND},
	{18, INVTYPE_RANGED},
}
for _, slot in ipairs(slots) do
	slot[3], slot[4] = 0, 0
	slot[5] = ItemLocation:CreateFromEquipmentSlot(slot[1])
end

-- 장착 아이템 정보: 링크, 아이콘, 아이템 ID (없으면 nil)
local function GetSlotItem(slot)
	local loc = slot[5]
	if not C_Item.DoesItemExist(loc) then return end
	return C_Item.GetItemLink(loc), C_Item.GetItemIcon(loc), C_Item.GetItemID(loc)
end

-- 특성 트리별 투자 포인트 ("31/20/0" 형식)
-- Forever는 C_Traits 특성 시스템을 쓴다. Blizzard 특성 창(Blizzard_ClassTalentsFrame.lua)과 같은 경로로 구한다.
local function GetTalentPoints()
	local configID = C_SpecializationInfo.GetCombatConfigIDForSpecGroup(C_SpecializationInfo.GetActiveSpecGroup())
	local configInfo = configID and C_Traits.GetConfigInfo(configID)
	local treeID = configInfo and configInfo.treeIDs and configInfo.treeIDs[1]
	if not treeID then return end

	local displayInfos = C_Traits.GetGroupDisplayInfoByTreeID(treeID)
	if not displayInfos or #displayInfos == 0 then return end

	local groupIDs = {}
	for i, info in ipairs(displayInfos) do
		groupIDs[i] = info.groupID
	end

	local spentByGroup = {}
	for _, groupInfo in ipairs(C_Traits.GetGroupCurrencyInfo(configID, groupIDs) or {}) do
		local currency = groupInfo.currencyInfos and groupInfo.currencyInfos[1]
		spentByGroup[groupInfo.traitNodeGroupID] = currency and currency.spent or 0
	end

	local points = {}
	for i, info in ipairs(displayInfos) do
		points[i] = spentByGroup[info.groupID] or 0
	end
	return table.concat(points, "/")
end

-- 0~1 비율을 빨강 → 노랑 → 초록 색상 코드로
local function gradientColor(perc)
	perc = perc > 1 and 1 or perc < 0 and 0 or perc
	local seg, relperc = math.modf(perc*2)
	local r1, g1, b1, r2, g2, b2 = select(seg*3+1, 1, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0)
	local r, g, b = r1+(r2-r1)*relperc, g1+(g2-g1)*relperc, b1+(b2-b1)*relperc
	return format("|cff%02x%02x%02x", r*255, g*255, b*255)
end

local function Update()
	local sum, count = 0, 0
	for _, slot in ipairs(slots) do
		local link, _, itemID = GetSlotItem(slot)
		if link then
			local current, max = GetInventoryItemDurability(slot[1])
			if current then
				slot[3], slot[4] = current, max
				sum = sum + current / max * 100
				count = count + 1
			else
				-- 내구도가 없는 아이템(투척 무기 등)은 개수를 표시한다
				slot[3], slot[4] = C_Item.GetItemCount(itemID), 0
			end
		else
			slot[3], slot[4] = 0, 0
		end
	end

	-- 장비 평균 내구도
	if count > 0 then
		local pct = math.floor(sum / count)
		Text:SetText(F.Label(DURABILITY).." "..gradientColor(pct / 100)..pct.."|r%")
	else
		Text:SetText(L["none"])
	end
end

Stat:SetScript("OnEnter", function(self)
	F.OpenTooltip(self, true)

	local talentPoints = GetTalentPoints()
	if talentPoints then
		GameTooltip:AddDoubleLine(TALENT, talentPoints, 0, .6, 1, 0, .6, 1)
		GameTooltip:AddLine(" ")
	end

	for _, slot in ipairs(slots) do
		local link, icon = GetSlotItem(slot)
		local slotIcon = icon and ("|T"..icon..":16:16:0:0:50:50:4:46:4:46|t ") or ""
		if link and slot[4] ~= 0 then
			local ratio = slot[3] / slot[4]
			GameTooltip:AddDoubleLine(slot[2], slotIcon..link.." "..floor(ratio * 100).."%", 1, 1, 1, 2 - ratio * 2, ratio * 2, 0)
		elseif link and slot[3] ~= 0 then
			GameTooltip:AddDoubleLine(slot[2], slotIcon..link.." "..slot[3], 1, 1, 1, 1, 1, 1)
		else
			GameTooltip:AddDoubleLine(slot[2], L["none"], 1, 1, 1, 1, 1, 1)
		end
	end

	F.AddFooter(L["AutoRepair"]..F.OnOff(diminfo.AutoRepair), .4, .78, 1)
	GameTooltip:Show()
end)

-- 좌클릭: 캐릭터 창, 우클릭: 자동 수리 켜기/끄기
Stat:SetScript("OnMouseDown", function(self, btn)
	if btn == "RightButton" then
		diminfo.AutoRepair = not diminfo.AutoRepair
		self:GetScript("OnEnter")(self)
	else
		ToggleCharacter("PaperDollFrame")
	end
end)

Stat:RegisterEvent("PLAYER_ENTERING_WORLD")
Stat:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
Stat:SetScript("OnEvent", Update)

-- 자동 수리
local RepairGear = CreateFrame("Frame")
RepairGear:RegisterEvent("MERCHANT_SHOW")
RepairGear:SetScript("OnEvent", function()
	if not diminfo.AutoRepair or not CanMerchantRepair() then return end

	local cost = GetRepairAllCost()
	if cost <= 0 then return end

	if GetMoney() >= cost then
		RepairAllItems()
		print(format("|cff99CCFF%s|r%s", L["Repair cost"], GetMoneyString(cost)))
	else
		print("|cff99CCFF"..L["Go farm, newbie"].."|r")
	end
end)
