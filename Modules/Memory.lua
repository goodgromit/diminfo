local addon, ns = ...
local C, F, G, L = unpack(ns)

if not C.Memory then return end

local Stat, Text = F.CreateStat("diminfo_Memory", C.MemoryPoint, "Memory")

-- 애드온 메모리 측정 주기(초)
-- UpdateAddOnMemoryUsage는 비싼 호출이다. Blizzard 애드온 목록(AddonList.lua)과 같이 15초에 한 번만 부른다.
local UPDATE_INTERVAL = 15

-- 애드온 메모리 측정. 마지막 측정 후 UPDATE_INTERVAL이 지나지 않았으면 그 값을 그대로 쓴다.
-- force가 true면 시간과 상관없이 측정한다(메모리 정리 직후 등).
local lastMeasured
local function MeasureMemory(force)
	local now = GetTime()
	-- 0.5초 여유: 타이머가 조금 일찍 울려도 그 회차 측정을 건너뛰지 않게 한다
	if force or not lastMeasured or now - lastMeasured >= UPDATE_INTERVAL - 0.5 then
		UpdateAddOnMemoryUsage()
		lastMeasured = now
	end
end

-- KB 값을 "12.3 kb" / "4.5 mb" 형식으로 (단위는 흰색)
local function formatMem(kb)
	if kb > 999 then
		return format("%.1f|cffffffff mb|r", kb / 1024)
	else
		return format("%.1f|cffffffff kb|r", kb)
	end
end

-- 사용량에 따른 글자색 (r, g)
local function memColor(kb)
	if kb <= 102.4 then return 0, 1		-- 100kb 이하
	elseif kb <= 512 then return .75, 1	-- 512kb 이하
	elseif kb <= 1024 then return 1, 1	-- 1mb 이하
	elseif kb <= 2560 then return 1, .75	-- 2.5mb 이하
	elseif kb <= 5120 then return 1, .5	-- 5mb 이하
	else return 1, .1 end
end

-- 로드된 애드온의 메모리 사용량 합계(KB)
local function GetTotalMemory(force)
	MeasureMemory(force)
	local total = 0
	for i = 1, C_AddOns.GetNumAddOns() do
		total = total + GetAddOnMemoryUsage(i)
	end
	return total
end

-- 로드된 애드온별 메모리 목록 (사용량 많은 순). 항목: { 이름, KB }
local memList = {}
local function RefreshList()
	wipe(memList)
	MeasureMemory()
	local total = 0
	for i = 1, C_AddOns.GetNumAddOns() do
		if C_AddOns.IsAddOnLoaded(i) then
			local mem = GetAddOnMemoryUsage(i)
			memList[#memList + 1] = { select(2, C_AddOns.GetAddOnInfo(i)), mem }
			total = total + mem
		end
	end
	table.sort(memList, function(a, b) return a[2] > b[2] end)
	return total
end

local function UpdateText(force)
	local total = GetTotalMemory(force)
	local value, unit = total, "kb"
	if total >= 1024 then
		value, unit = total / 1024, "mb"
	end
	F.SetText(Text, F.Label(ADDONS)..format(" %.1f", value)..F.Label(unit))
end

Stat:SetScript("OnEnter", function(self)
	local total = RefreshList()

	F.OpenTooltip(self, true)
	GameTooltip:AddDoubleLine(ADDONS, formatMem(total), 0, .6, 1, 1, 1, 1)
	GameTooltip:AddLine(" ")

	local maxAddOns = IsShiftKeyDown() and #memList or math.min(F.Setting("MaxAddOns"), #memList)
	for i = 1, maxAddOns do
		local name, mem = memList[i][1], memList[i][2]
		local r, g = memColor(mem)
		GameTooltip:AddDoubleLine(name, formatMem(mem), 1, 1, 1, r, g, 0)
	end

	if maxAddOns < #memList then
		local moreMem = 0
		for i = maxAddOns + 1, #memList do
			moreMem = moreMem + memList[i][2]
		end
		GameTooltip:AddDoubleLine(format("%d %s (%s)", #memList - maxAddOns, L["Hidden"], L["Shift"]), formatMem(moreMem), .6, .8, 1, .6, .8, 1)
	end

	local luaTotal = collectgarbage("count")
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine(L["Default UI Memory Usage:"], formatMem(luaTotal - total), .6, .8, 1, 1, 1, 1)
	GameTooltip:AddDoubleLine(L["Total Memory Usage:"], formatMem(luaTotal), .6, .8, 1, 1, 1, 1)
	GameTooltip:Show()
end)

-- 좌클릭: Lua 메모리 정리 후 확보한 양 출력
Stat:SetScript("OnMouseDown", function(self, btn)
	if btn ~= "LeftButton" then return end

	local before = collectgarbage("count")
	collectgarbage("collect")
	print(format("|cff66C6FF%s|r%s", L["Garbage collected"], formatMem(before - collectgarbage("count"))))

	-- 정리된 결과가 바로 보이도록 즉시 다시 측정한다
	UpdateText(true)
	if self:IsMouseOver() then
		self:GetScript("OnEnter")(self)
	end
end)

UpdateText()

-- 주기적으로 바 글자 갱신. 전투 중에는 건너뛰고 직전 값을 그대로 둔다(전투 후 다음 주기에 갱신).
C_Timer.NewTicker(UPDATE_INTERVAL, function()
	if InCombatLockdown() then return end
	UpdateText()
end)

-- 설정 창에서 값이 바뀌면 바 글자를 다시 그린다 (API.lua F.ApplySettings)
Stat.Refresh = function() UpdateText() end
