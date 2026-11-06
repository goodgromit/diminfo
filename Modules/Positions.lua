-- C_Map.GetPlayerMapPosition Memory Usage
-- https://www.wowinterface.com/forums/showthread.php?t=56290

local addon, ns = ...
local C, F, G, L = unpack(ns)

if not C.Positions then return end

local Stat, Text = F.CreateStat("diminfo_pos", C.PositionsPoint)

-- PvP 지역 유형별 설명 문구와 색
local colorT = {
	sanctuary = {SANCTUARY_TERRITORY, {.41, .8, .94}},
	arena = {FREE_FOR_ALL_TERRITORY, {1, .1, .1}},
	friendly = {FACTION_CONTROLLED_TERRITORY, {.1, 1, .1}},
	hostile = {FACTION_CONTROLLED_TERRITORY, {1, .1, .1}},
	contested = {CONTESTED_TERRITORY, {1, .7, 0}},
	combat = {COMBAT_ZONE, {1, .1, .1}},
	neutral = {format(FACTION_CONTROLLED_TERRITORY, FACTION_STANDING_LABEL4), {1, .93, .76}},
}

-- 플레이어 좌표 (0~1). C_Map.GetPlayerMapPosition보다 메모리를 덜 쓰는 방식(위 링크 참고)
local mapRects = {}
local tempVec2D = CreateVector2D(0, 0)
local function GetPlayerMapPos(mapID)
	if not mapID then return end
	tempVec2D.x, tempVec2D.y = UnitPosition("player")
	if not tempVec2D.x then return end

	local mapRect = mapRects[mapID]
	if not mapRect then
		local _, topLeft = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(0, 0))
		local _, bottomRight = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(1, 1))
		if not topLeft or not bottomRight then return end
		bottomRight:Subtract(topLeft)
		mapRect = {topLeft, bottomRight}
		mapRects[mapID] = mapRect
	end
	tempVec2D:Subtract(mapRect[1])

	return tempVec2D.y / mapRect[2].y, tempVec2D.x / mapRect[2].x
end

local coordX, coordY = 0, 0
local function formatCoords()
	return format("%.1f, %.1f", coordX * 100, coordY * 100)
end

-- 툴팁이 떠 있는 동안 0.1초마다 좌표를 갱신한다
local function UpdateCoords(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if self.elapsed > .1 then
		local x, y = GetPlayerMapPos(C_Map.GetBestMapForUnit("player"))
		if x then
			coordX, coordY = x, y
		else
			coordX, coordY = 0, 0
			self:SetScript("OnUpdate", nil)
		end
		self:GetScript("OnEnter")(self)
		self.elapsed = 0
	end
end

-- 지역 이름과 PvP 상태 (pvp: pvpType, isSubZonePvP, factionName)
local subzone, zone, pvp
local function Update()
	subzone, zone, pvp = GetSubZoneText(), GetZoneText(), {C_PvP.GetZonePVPInfo()}
	if not colorT[pvp[1]] then pvp[1] = "neutral" end
	Text:SetText(subzone ~= "" and subzone or zone)
	Text:SetTextColor(unpack(colorT[pvp[1]][2]))
end

Stat:SetScript("OnEnter", function(self)
	self:SetScript("OnUpdate", UpdateCoords)

	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 0, -10)
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint("BOTTOM", self, "BOTTOM", 0, 1)
	GameTooltip:ClearLines()

	if IsInInstance() then
		GameTooltip:AddLine(zone, 0, .8, 1)
	else
		GameTooltip:AddLine(format("%s |cffffffff(%s)", zone, formatCoords()), 0, .8, 1)

		local r, g, b = unpack(colorT[pvp[1]][2])
		if subzone and subzone ~= zone then
			GameTooltip:AddLine(subzone, r, g, b)
		end
		GameTooltip:AddLine(format(colorT[pvp[1]][1], pvp[3] or ""), r, g, b)
	end
	GameTooltip:Show()
end)

Stat:SetScript("OnLeave", function(self)
	self:SetScript("OnUpdate", nil)
	GameTooltip:Hide()
end)

-- 좌클릭: 세계 지도, 우클릭: 채팅창에 "지역 (좌표)" 입력
Stat:SetScript("OnMouseUp", function(_, btn)
	if btn == "LeftButton" then
		ToggleFrame(WorldMapFrame)
	elseif IsInInstance() then
		ChatFrameUtil.OpenChat(zone)
	else
		ChatFrameUtil.OpenChat(format("%s (%s)", zone, formatCoords()))
	end
end)

Stat:RegisterEvent("PLAYER_ENTERING_WORLD")
Stat:RegisterEvent("ZONE_CHANGED")
Stat:RegisterEvent("ZONE_CHANGED_INDOORS")
Stat:RegisterEvent("ZONE_CHANGED_NEW_AREA")
Stat:SetScript("OnEvent", Update)
