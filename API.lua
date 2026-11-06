local addon, ns = ...
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

-- 바 항목 이름표. 직업 색 설정이 켜져 있으면 직업 색으로 칠한다.
-- 직업 색은 바뀌지 않으므로 색 코드는 한 번만 만든다.
local classHex = C.ClassColor and G.Ccolors and F.Hex(G.Ccolors)
F.Label = function(text)
	return classHex and (classHex..text.."|r") or text
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
local textHolder = CreateFrame("Frame", nil, UIParent)
F.CreateStat = function(name, point)
	local Stat = CreateFrame("Frame", name, UIParent)
	Stat:EnableMouse(true)
	Stat:SetFrameStrata("BACKGROUND")
	Stat:SetFrameLevel(3)

	local Text = textHolder:CreateFontString(nil, "OVERLAY")
	Text:SetFont(G.Fonts, G.FontSize, G.FontFlag)
	Text:SetPoint(unpack(point))
	Stat:SetAllPoints(Text)

	Stat:SetScript("OnLeave", GameTooltip_Hide)
	return Stat, Text
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
	if panel then F.CreatePanel(unpack(panel)) end
end
