-- C_Map.GetPlayerMapPosition Memory Usage
-- https://www.wowinterface.com/forums/showthread.php?t=56290

local addon, ns = ...
local C, F, G, T = unpack(ns)
local panel = CreateFrame("Frame", nil, UIParent)

if not C.Positions then return end
	-- make addon frame anchor-able
	local Stat = CreateFrame("Frame", "diminfo_pos")
	Stat:EnableMouse(true)
	Stat:SetFrameStrata("BACKGROUND")
	Stat:SetFrameLevel(3)

    -- setup text
	local Text  = panel:CreateFontString(nil, "OVERLAY")
	Text:SetFont(G.Fonts, G.FontSize, G.FontFlag)
	Text:SetPoint(unpack(C.PositionsPoint))
	Stat:SetAllPoints(Text)

	-- zone text color
	local colorT = {
		sanctuary = {SANCTUARY_TERRITORY, {.41, .8, .94}},
		arena = {FREE_FOR_ALL_TERRITORY, {1, .1, .1}},
		friendly = {FACTION_CONTROLLED_TERRITORY, {.1, 1, .1}},
		hostile = {FACTION_CONTROLLED_TERRITORY, {1, .1, .1}},
		contested = {CONTESTED_TERRITORY, {1, .7, 0}},
		combat = {COMBAT_ZONE, {1, .1, .1}},
		neutral = {format(FACTION_CONTROLLED_TERRITORY,FACTION_STANDING_LABEL4), {1, .93, .76}}
	}

	-- position, to get xy
	local mapRects = {}
	local tempVec2D = CreateVector2D(0, 0)
	local function GetPlayerMapPos(mapID)
		tempVec2D.x, tempVec2D.y = UnitPosition("player")
		if not tempVec2D.x then return end

		local mapRect = mapRects[mapID]
		if not mapRect then
			mapRect = {}
			mapRect[1] = select(2, C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(0, 0)))
			mapRect[2] = select(2, C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(1, 1)))
			mapRect[2]:Subtract(mapRect[1])

			mapRects[mapID] = mapRect
		end
		tempVec2D:Subtract(mapRect[1])

		return tempVec2D.y/mapRect[2].y, tempVec2D.x/mapRect[2].x
	end

	local coordX, coordY = 0, 0
	local function formatCoords()
		return format("%.1f, %.1f", coordX*100, coordY*100)
	end

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

	-- zone check
	local subzone, zone, pvp
	local function OnEvent()
		subzone, zone, pvp = GetSubZoneText(), GetZoneText(), {GetZonePVPInfo()}
		if not pvp[1] then pvp[1] = "neutral" end
		local r,g,b = unpack(colorT[pvp[1]][2])
		Text:SetText((subzone ~= "") and subzone or zone)
		Text:SetTextColor(r,g,b)
	end

	-- tooltip
	Stat:RegisterEvent("ZONE_CHANGED")
	Stat:RegisterEvent("ZONE_CHANGED_INDOORS")
	Stat:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	Stat:RegisterEvent("PLAYER_ENTERING_WORLD")
	Stat:RegisterEvent("PLAYER_LOGIN")
	Stat:SetScript("OnEvent", OnEvent)

	-- setup
	Stat:SetScript("OnEnter",function(self)
		self:SetScript("OnUpdate", UpdateCoords)

		self:SetAllPoints(Text)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 0, -10)
		GameTooltip:ClearAllPoints()
		GameTooltip:SetPoint("BOTTOM", self, "BOTTOM", 0, 1)
		GameTooltip:ClearLines()
		if not IsInInstance() then
			GameTooltip:AddLine(format("%s |cffffffff(%s)", zone, formatCoords()), 0, .8, 1, 1, 1, 1)
		else
			GameTooltip:AddLine(zone, 0, .8, 1)
		end

		if pvp[1] and not IsInInstance() then
			local r,g,b = unpack(colorT[pvp[1]][2])
			if subzone and subzone ~= zone then
				GameTooltip:AddLine(subzone, r, g, b)
			end
			GameTooltip:AddLine(format(colorT[pvp[1]][1],pvp[3] or ""), r, g, b)
		end
		GameTooltip:Show()
	end)

	Stat:SetScript("OnLeave",function(self)
		self:SetScript("OnUpdate", nil)
		GameTooltip:Hide()
	end)

	Stat:SetScript("OnMouseUp", function(_,btn)
		if btn == "LeftButton" then
			ToggleFrame(WorldMapFrame)
		else
			if not IsInInstance() then
				ChatFrame_OpenChat(format("%s (%s)", zone, formatCoords()), chatFrame)
			else
				ChatFrame_OpenChat(format("%s", zone), chatFrame)
			end
		end
	end)