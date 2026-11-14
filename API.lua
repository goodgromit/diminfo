local _, ns = ...
local C, F, G = unpack(ns)

-- 색상 코드 문자열. 인자가 없으면 흰색.
-- F.Hex(r, g, b), F.Hex({r=, g=, b=}), F.Hex({r, g, b}) 모두 가능하다.
F.Hex = function(r, g, b)
	if not r then return "|cffFFFFFF" end

	if type(r) == "table" then
		if r.r then
			r, g, b = r.r, r.g, r.b
		else
			r, g, b = unpack(r)
		end
	end

	return ("|cff%02x%02x%02x"):format(r * 255, g * 255, b * 255)
end

-- 설정값. 설정 창에서 바꾼 값(diminfo.Settings)이 있으면 그 값, 없으면 Config.lua의 기본값
F.Setting = function(key)
	local saved = type(diminfo) == "table" and diminfo.Settings
	if type(saved) == "table" and saved[key] ~= nil then
		return saved[key]
	end
	return C.SettingDefaults[key]
end

-- 설정값 저장. 기본값과 같으면 저장하지 않는다(Config.lua 기본값을 바꾸면 그대로 따라가도록).
F.SetSetting = function(key, value)
	if type(diminfo.Settings) ~= "table" then diminfo.Settings = {} end
	if value == C.SettingDefaults[key] then
		diminfo.Settings[key] = nil
	else
		diminfo.Settings[key] = value
	end
end

-- 바 항목 이름표. 직업 색 설정이 켜져 있으면 직업 색으로 칠한다.
-- 직업 색은 바뀌지 않으므로 색 코드는 한 번만 만든다.
local classHex = G.Ccolors and F.Hex(G.Ccolors)
F.Label = function(text)
	if classHex and F.Setting("ClassColor") then
		return classHex..text.."|r"
	end
	return text
end

-- 바 글자 설정. 내용이 같으면 다시 쓰지 않는다(글자 크기 재계산과 위치 재배치를 줄인다).
F.SetText = function(fontString, text)
	if fontString._diminfoText ~= text then
		fontString:SetText(text)
		fontString._diminfoText = text
	end
end

-- 켜짐/꺼짐 표시 문자열
F.OnOff = function(enabled)
	return enabled and "|cff55ff55"..ENABLE or "|cffff5555"..DISABLE
end

-- 툴팁 열기. above가 true면 항목 위쪽에 붙인다(바가 화면 위에 있으면 화면 안쪽으로 밀려 내려온다).
F.OpenTooltip = function(owner, above)
	GameTooltip:SetOwner(owner, "ANCHOR_BOTTOM", 0, -10)
	if above then
		GameTooltip:ClearAllPoints()
		GameTooltip:SetPoint("BOTTOM", owner, "TOP", 0, 1)
	end
	GameTooltip:ClearLines()
end

-- 툴팁 맨 아래 구분선과 설정 상태 줄
F.AddFooter = function(text, r, g, b)
	GameTooltip:AddDoubleLine(" ", "--------------", 1, 1, 1, .5, .5, .5)
	GameTooltip:AddDoubleLine(" ", text, 1, 1, 1, r or .6, g or .8, b or 1)
end

-- 바 항목 하나를 만든다.
-- Text: 바에 표시되는 글자, Stat: 글자 영역을 덮는 마우스 영역(이벤트도 이 프레임으로 받는다)
-- key: 설정 창의 가로 위치 설정 이름(X_key). 각 모듈은 Stat.Refresh에 바 글자를 다시 그리는 함수를 넣는다.
local textHolder = CreateFrame("Frame", nil, UIParent)
local stats = {}
F.CreateStat = function(name, point, key)
	local Stat = CreateFrame("Frame", name, UIParent)
	Stat:EnableMouse(true)
	Stat:SetFrameStrata("BACKGROUND")
	Stat:SetFrameLevel(3)

	local Text = textHolder:CreateFontString(nil, "OVERLAY")
	Text:SetFont(G.Fonts, G.FontSize, G.FontFlag)
	Text:SetPoint(unpack(point))
	Stat:SetAllPoints(Text)

	Stat:SetScript("OnLeave", GameTooltip_Hide)
	stats[#stats + 1] = { Stat = Stat, Text = Text, point = point, key = key }
	return Stat, Text
end

-- 설정 적용: 글자 크기, 항목 위치, 배경 패널 크기와 위치, 바 글자(직업 색 등)
-- 저장 변수가 로드된 직후(Config.lua)와 설정 창에서 값을 바꿀 때 부른다.
local mainPanel
F.ApplySettings = function()
	local fontSize = F.Setting("FontSize")
	for _, s in ipairs(stats) do
		s.Text:SetFont(G.Fonts, fontSize, G.FontFlag)
		local p = s.point
		local x = s.key and F.Setting("X_"..s.key) or p[4]
		s.Text:ClearAllPoints()
		s.Text:SetPoint(p[1], p[2], p[3], x, p[5])
		if s.Stat.Refresh then s.Stat.Refresh() end
	end

	if mainPanel then
		local p = C.Panel1
		mainPanel:SetSize(F.Setting("PanelWidth"), F.Setting("PanelHeight"))
		mainPanel:ClearAllPoints()
		mainPanel:SetPoint(p[2], p[3], p[4], F.Setting("PanelY"))
	end
end

-- 배경 패널
F.CreatePanel = function(name, anchor, parent, x, y, w, h, size)
	local panel = CreateFrame("Frame", name, parent, "BackdropTemplate")
	local framelvl = parent:GetFrameLevel()

	panel:SetWidth(w)
	panel:SetHeight(h)
	panel:ClearAllPoints()
	panel:SetPoint(anchor, parent, x, y)
	panel:SetFrameStrata("BACKGROUND")
	panel:SetFrameLevel(framelvl == 0 and 0 or framelvl-1)
	panel:SetBackdrop({
		bgFile = G.Tex,
		edgeFile = G.Tex, edgeSize = 1,
	})
	panel:SetBackdropColor(.1, .1, .1, .6)
	panel:SetBackdropBorderColor(.1, .1, .1, .6)

	-- 그림자 프레임은 이름 없이 만든다. 같은 이름을 쓰면 전역 panel1이 그림자 프레임으로 덮어써진다.
	local sd = CreateFrame("Frame", nil, panel, "BackdropTemplate")
	sd:SetPoint("TOPLEFT", -size, size)
	sd:SetPoint("BOTTOMRIGHT", size, -size)
	sd:SetFrameStrata(panel:GetFrameStrata())
	sd:SetFrameLevel(framelvl == 0 and 0 or framelvl-1)
	sd:SetBackdrop({
		edgeFile = G.Glow,
		edgeSize = size,
	})
	sd:SetBackdropBorderColor(0, 0, 0)

	return panel
end

if not C.Panel then return end

for i = 1, 5 do
	local panel = C["Panel"..i]
	if panel then
		local frame = F.CreatePanel(unpack(panel))
		-- 첫 번째 패널은 설정 창의 크기, 위치 설정을 따른다
		if i == 1 then mainPanel = frame end
	end
end
