local _, ns = ...
local C, F = unpack(ns)

if not C.Time then return end

local Stat, Text = F.CreateStat("diminfo_Time", C.TimePoint, "Time")

-- 바의 시계. 게임의 시계 설정(지역/서버 시간, 24시간제)을 그대로 따른다.
local function UpdateText()
	F.SetText(Text, GameTime_GetTime(true))
end

-- "오전/오후" 표시를 소문자 am/pm으로
local function lowerAMPM(text)
	return (text:gsub("%s*AM", " am"):gsub("%s*PM", " pm"))
end

local function ShowTooltip(self)
	F.OpenTooltip(self)
	GameTooltip:AddDoubleLine(TIMEMANAGER_TOOLTIP_LOCALTIME, lowerAMPM(GameTime_GetLocalTime(true)), .6, .8, 1, 1, 1, 1)
	GameTooltip:AddDoubleLine(TIMEMANAGER_TOOLTIP_REALMTIME, lowerAMPM(GameTime_GetGameTime(true)), .6, .8, 1, 1, 1, 1)

	-- 귀속된 공격대 (연장된 귀속은 초록색)
	local titleAdded = false
	for i = 1, GetNumSavedInstances() do
		local name, _, reset, _, locked, extended, _, isRaid, _, difficultyName = GetSavedInstanceInfo(i)
		if isRaid and (locked or extended) then
			if not titleAdded then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(GUILD_CHALLENGE_TYPE2, .6, .8, 1)
				titleAdded = true
			end
			local r, g, b = 1, 1, 1
			if extended then
				r, g, b = .3, 1, .3
			end
			GameTooltip:AddDoubleLine(difficultyName.." - "..name, SecondsToTime(reset, true, nil, 3), 1, .82, 0, r, g, b)
		end
	end

	GameTooltip:Show()
end

-- 귀속 정보를 요청하고 툴팁을 띄운다. 응답(UPDATE_INSTANCE_INFO)이 오면 요청 없이 툴팁만 다시 그린다.
Stat:SetScript("OnEnter", function(self)
	RequestRaidInfo()
	ShowTooltip(self)
end)

-- 좌클릭: 채널 창, 우클릭: 시계 창
Stat:SetScript("OnMouseDown", function(self, btn)
	if btn == "RightButton" then
		ToggleTimeManager()
	else
		ToggleChannelFrame()
	end
end)

Stat:RegisterEvent("UPDATE_INSTANCE_INFO")
Stat:SetScript("OnEvent", function(self)
	if GameTooltip:IsOwned(self) then
		ShowTooltip(self)
	end
end)

UpdateText()
C_Timer.NewTicker(1, UpdateText)

-- 설정 창에서 값이 바뀌면 바 글자를 다시 그린다 (API.lua F.ApplySettings)
Stat.Refresh = function() UpdateText() end
