local addon, ns = ...
local C, F, G, L = unpack(ns)

if not C.System then return end

local Stat, Text = F.CreateStat("diminfo_System", C.SystemPoint)

-- 애드온 CPU 측정: 게임에 내장된 상시 측정 기능(C_AddOnProfiler)을 쓴다. 리로드나 CVar 설정이 필요 없다.
-- 최근 60틱 평균 시간을 기준으로 한다(Blizzard 애드온 목록의 "현재 CPU"와 같은 기준).
local CPU_METRIC = Enum.AddOnProfilerMetric.RecentAverageTime
local UPDATE_INTERVAL = 1	-- 바의 FPS, 지연 시간 갱신 주기(초)

-- 지연 시간 색: 100ms 미만 초록, 300ms까지 노랑, 그 이상 빨강
local function colorLatency(latency)
	if latency < 100 then return "|cff0CD809"..latency
	elseif latency <= 300 then return "|cffE8DA0F"..latency
	else return "|cffD80909"..latency end
end

-- FPS 색: 30 미만 빨강, 60 미만 노랑, 그 이상 초록
local function colorFPS(fps)
	if fps < 30 then return "|cffD80909"..fps
	elseif fps < 60 then return "|cffE8DA0F"..fps
	else return "|cff0CD809"..fps end
end

-- 퍼센트 표시 형식 (Blizzard 애드온 목록과 같음)
local function FormatPercent(pct)
	if pct >= 1 then
		return format("%.0f%%", pct)
	elseif pct >= 0.1 then
		return format("%.1f%%", pct)
	elseif pct >= 0.01 then
		return format("%.2f%%", pct)
	else
		return "0%"
	end
end

-- 사용률에 따른 글자색 (r, g)
local function PercentColor(pct)
	if pct > 10 then return 1, 0.1
	elseif pct > 5 then return 1, 0.5
	elseif pct > 1 then return 1, 1
	else return 0, 1 end
end

-- CPU 사용률 계산 (Blizzard 애드온 목록 AddonListMixin:GetAddonMetricPercent와 같은 공식)
--   사용률 = 대상 시간 / (게임 전체 시간 - 모든 애드온 시간 + 대상 시간)
--   = "대상만 켜져 있을 때 프레임 시간 중 차지하는 비율". 다른 애드온의 부하에 영향을 받지 않는다.
-- 대상이 애드온 묶음이면 묶음의 시간 합을 넣는다. 모든 애드온을 넣으면 전체 / 게임 전체 시간과 같다.
-- 애드온마다 분모가 다르므로 애드온별 사용률을 더하면 안 된다.
local appVal, overallVal = 0, 0
local function CPUPercent(targetVal)
	local relativeTotal = appVal - overallVal + targetVal
	return relativeTotal > 0 and (targetVal / relativeTotal * 100) or 0
end

-- 애드온별 CPU 목록 (사용률 높은 순). 항목: { 이름, 사용률, 시간(ms/틱) }
local cpuList = {}
local function RefreshCPU()
	wipe(cpuList)
	appVal = C_AddOnProfiler.GetApplicationMetric(CPU_METRIC)
	overallVal = C_AddOnProfiler.GetOverallMetric(CPU_METRIC)

	for _, result in ipairs(C_AddOnProfiler.GetTopKAddOnsForMetric(CPU_METRIC, C_AddOns.GetNumAddOns())) do
		local title = C_AddOns.GetAddOnTitle(result.addOnName)
		cpuList[#cpuList + 1] = { (title and title ~= "") and title or result.addOnName, CPUPercent(result.metricValue), result.metricValue }
	end
	table.sort(cpuList, function(a, b) return a[3] > b[3] end)

	-- 전체 애드온 사용률
	return CPUPercent(overallVal)
end

local function UpdateText()
	local _, _, latencyHome = GetNetStats()
	local fps = floor(GetFramerate() + 0.5)
	F.SetText(Text, colorFPS(fps).."|rfps "..colorLatency(latencyHome).."|rms")
end

Stat:SetScript("OnEnter", function(self)
	F.OpenTooltip(self, true)
	GameTooltip:AddLine(CHAT_MSG_SYSTEM, 0, .6, 1)
	GameTooltip:AddLine(" ")

	-- CPU 측정은 게임이 항상 켜 두는 기능이다. 혹시 꺼져 있으면 CPU 부분을 표시하지 않는다.
	if C_AddOnProfiler.IsEnabled() then
		local totalPct = RefreshCPU()
		local tr, tg = PercentColor(totalPct)
		GameTooltip:AddDoubleLine(L["AddOn CPU Usage"], FormatPercent(totalPct), 1, 1, 1, tr, tg, 0)

		local maxAddOns = IsShiftKeyDown() and #cpuList or math.min(C.MaxAddOns, #cpuList)
		for i = 1, maxAddOns do
			local name, pct = cpuList[i][1], cpuList[i][2]
			local r, g = PercentColor(pct)
			GameTooltip:AddDoubleLine(name, FormatPercent(pct), 1, 1, 1, r, g, 0)
		end

		if maxAddOns < #cpuList then
			-- 숨겨진 애드온은 시간을 합친 뒤 묶음으로 사용률을 계산한다
			local moreTime = 0
			for i = maxAddOns + 1, #cpuList do
				moreTime = moreTime + cpuList[i][3]
			end
			GameTooltip:AddDoubleLine(format("%d %s (%s)", #cpuList - maxAddOns, L["Hidden"], L["Shift"]), FormatPercent(CPUPercent(moreTime)), .6, .8, 1, .6, .8, 1)
		end
		GameTooltip:AddLine(" ")
	end

	local _, _, latencyHome, latencyWorld = GetNetStats()
	GameTooltip:AddDoubleLine(L["Latency"], format("%s%s(%s)/%s%s(%s)", colorLatency(latencyHome).."|r", "ms", L["Home"], colorLatency(latencyWorld).."|r", "ms", CHANNEL_CATEGORY_WORLD), .6, .8, 1, 1, 1, 1)
	GameTooltip:Show()
end)

-- 좌클릭: Blizzard 애드온 목록 창 열기/닫기 (같은 CPU 수치를 더 자세히 볼 수 있다)
Stat:SetScript("OnMouseDown", function(self, btn)
	if btn ~= "LeftButton" or not AddonList then return end
	GameTooltip:Hide()
	if AddonList:IsShown() then
		HideUIPanel(AddonList)
	else
		ShowUIPanel(AddonList)
	end
end)

UpdateText()
C_Timer.NewTicker(UPDATE_INTERVAL, UpdateText)
