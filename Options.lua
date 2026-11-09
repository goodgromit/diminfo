local addon, ns = ...
local C, F, G, L = unpack(ns)

-- 게임 안 설정 창: ESC → 설정 → 애드온 → diminfo (또는 /diminfo)
-- 값은 RegisterProxySetting으로 직접 읽고 쓴다(F.Setting / F.SetSetting, API.lua).
-- 바꾼 값만 diminfo.Settings에 저장되고, 바꾸지 않은 값은 계속 Config.lua 기본값을 따른다.
-- 값을 바꾸면 F.ApplySettings로 바로 반영된다.

local statNames = {
	Memory = "메모리",
	System = "시스템",
	Friends = "친구",
	Guild = "길드",
	Positions = "지역명 (패널 가운데 기준)",
	Money = "소지금",
	Durability = "내구도",
	Bags = "가방",
	Time = "시계",
}

local function Register()
	local category, layout = Settings.RegisterVerticalLayoutCategory("diminfo")
	local settings = {}

	local function AddSetting(key, name, varType)
		local setting = Settings.RegisterProxySetting(category, "DIMINFO_"..key:upper(), varType, name,
			C.SettingDefaults[key],
			function() return F.Setting(key) end,
			function(value)
				F.SetSetting(key, value)
				F.ApplySettings()
			end)
		settings[#settings + 1] = setting
		return setting
	end

	local function AddCheckbox(key, name, tooltip)
		Settings.CreateCheckbox(category, AddSetting(key, name, Settings.VarType.Boolean), tooltip)
	end

	local function AddSlider(key, name, minValue, maxValue, step, tooltip)
		local options = Settings.CreateSliderOptions(minValue, maxValue, step)
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
		Settings.CreateSlider(category, AddSetting(key, name, Settings.VarType.Number), options, tooltip)
	end

	-- 표시
	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("표시"))
	AddCheckbox("ClassColor", "이름표를 직업 색으로 표시", "바 항목의 이름표(친구, 길드 등)를 내 직업 색으로 칠합니다.")
	AddSlider("FontSize", "글자 크기", 8, 24, 1)
	AddSlider("MaxAddOns", "툴팁에 보여 줄 애드온 수", 5, 100, 5, "메모리, 시스템 툴팁에 기본으로 보여 줄 애드온 수입니다. Shift를 누르면 모두 보입니다.")
	AddSlider("DurabilityWarn", "내구도 경고 기준 (%)", 5, 95, 5, "가장 낮은 장비의 내구도가 이 값 미만이면 바에 최저값을 함께 표시합니다.")

	-- 배경 패널
	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("배경 패널"))
	AddSlider("PanelWidth", "너비", 200, 2000, 10)
	AddSlider("PanelHeight", "높이", 8, 40, 1)
	AddSlider("PanelY", "세로 위치", -300, 0, 1, "화면 맨 위에서의 거리입니다. 0이면 화면 맨 위에 붙습니다.")

	-- 항목 위치 (켜져 있는 항목만)
	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("항목 위치", "패널 왼쪽 끝에서의 거리입니다. 지역명만 패널 가운데에서의 거리입니다."))
	for _, key in ipairs(C.StatKeys) do
		if C.SettingDefaults["X_"..key] then
			if key == "Positions" then
				AddSlider("X_"..key, statNames[key], -1000, 1000, 1)
			else
				AddSlider("X_"..key, statNames[key], -100, 2000, 1)
			end
		end
	end

	-- 기본값으로 되돌리기
	layout:AddInitializer(CreateSettingsButtonInitializer("기본값으로 되돌리기", "되돌리기", function()
		for _, setting in ipairs(settings) do
			setting:SetValueToDefault()
		end
	end, "모든 설정을 Config.lua의 기본값으로 되돌립니다.", true))

	Settings.RegisterAddOnCategory(category)

	SLASH_DIMINFO1 = "/diminfo"
	SlashCmdList.DIMINFO = function()
		Settings.OpenToCategory(category:GetID())
	end
end

EventUtil.ContinueOnAddOnLoaded(addon, Register)
