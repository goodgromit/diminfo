-- C_Map.GetPlayerMapPosition의 메모리 사용 문제 (대신 UnitPosition으로 좌표 계산)
-- https://www.wowinterface.com/forums/showthread.php?t=56290

local addon, ns = ...
local C, F, G, L = unpack(ns)

if not C.Positions then return end

local Stat, Text = F.CreateStat("diminfo_pos", C.PositionsPoint, "Positions")

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

-- 현재 좌표를 구한다. 구할 수 없으면 (0, 0)으로 두고 false
local function RefreshCoords()
	local x, y = GetPlayerMapPos(C_Map.GetBestMapForUnit("player"))
	if x then
		coordX, coordY = x, y
		return true
	end
	coordX, coordY = 0, 0
	return false
end

-- 지역 이름과 PvP 상태 (pvp: pvpType, isSubZonePvP, factionName)
local subzone, zone, pvp

-- 툴팁 첫 줄: "지역 (x, y)"
local function CoordLine()
	return format("%s |cffffffff(%s)", zone, formatCoords())
end

-- 툴팁이 떠 있는 동안 0.1초마다 좌표를 확인하고, 바뀌었을 때만 첫 줄(좌표 줄)의 글자를 고친다
local shownCoordLine
local function UpdateCoords(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if self.elapsed < .1 then return end
	self.elapsed = 0

	if not GameTooltip:IsOwned(self) then
		self:SetScript("OnUpdate", nil)
		return
	end
	if not RefreshCoords() then
		self:SetScript("OnUpdate", nil)
	end

	local line = CoordLine()
	if line ~= shownCoordLine then
		shownCoordLine = line
		local fontString = GameTooltip:GetLeftLine(1)
		if fontString then
			fontString:SetText(line)
			GameTooltip:Show()	-- 글자 길이가 바뀌었을 수 있으므로 툴팁 크기를 다시 맞춘다
		end
	end
end

Stat:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 0, -10)
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint("BOTTOM", self, "BOTTOM", 0, 1)
	GameTooltip:ClearLines()

	if IsInInstance() then
		-- 인스턴스 안에서는 좌표를 표시하지 않으므로 갱신도 하지 않는다
		self:SetScript("OnUpdate", nil)
		GameTooltip:AddLine(zone, 0, .8, 1)
	else
		RefreshCoords()
		shownCoordLine = CoordLine()
		GameTooltip:AddLine(shownCoordLine, 0, .8, 1)

		local r, g, b = unpack(colorT[pvp[1]][2])
		if subzone and subzone ~= zone then
			GameTooltip:AddLine(subzone, r, g, b)
		end
		GameTooltip:AddLine(format(colorT[pvp[1]][1], pvp[3] or ""), r, g, b)

		self.elapsed = 0
		self:SetScript("OnUpdate", UpdateCoords)
	end
	GameTooltip:Show()
end)

local function Update()
	subzone, zone, pvp = GetSubZoneText(), GetZoneText(), {C_PvP.GetZonePVPInfo()}
	if not colorT[pvp[1]] then pvp[1] = "neutral" end
	F.SetText(Text, subzone ~= "" and subzone or zone)
	Text:SetTextColor(unpack(colorT[pvp[1]][2]))

	-- 툴팁이 떠 있는 동안 지역이 바뀌면 툴팁을 다시 그린다
	if GameTooltip:IsOwned(Stat) then
		Stat:GetScript("OnEnter")(Stat)
	end
end

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
		RefreshCoords()	-- 마지막으로 마우스를 올렸을 때가 아닌 지금 좌표
		ChatFrameUtil.OpenChat(format("%s (%s)", zone, formatCoords()))
	end
end)

Stat:RegisterEvent("PLAYER_ENTERING_WORLD")
Stat:RegisterEvent("ZONE_CHANGED")
Stat:RegisterEvent("ZONE_CHANGED_INDOORS")
Stat:RegisterEvent("ZONE_CHANGED_NEW_AREA")
Stat:SetScript("OnEvent", Update)

-- 설정 창에서 값이 바뀌면 바 글자를 다시 그린다 (API.lua F.ApplySettings)
Stat.Refresh = function() Update() end
