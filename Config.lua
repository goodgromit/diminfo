----------------------
-- 수정하지 마세요! --
----------------------

local addon, ns = ...
ns[1] = {} -- C: 설정
ns[2] = {} -- F: 함수, 상수, 변수
ns[3] = {} -- G: 공용 값 (선택)
-- ns[4] = L: 로케일 문자열 (Locale.lua)

local C, F, G = unpack(ns)

-- SavedVariables 기본값
-- 파일 로드 시점에는 SavedVariables가 아직 없으므로 ADDON_LOADED에서 다시 적용한다.
local defaults = {
	AutoSell = true,	-- 회색 아이템 자동 판매
	AutoRepair = true,	-- 자동 수리
	CurrencyMode = "tracked",	-- 소지금 툴팁 화폐 표시 (hidden: 숨김, tracked: 가방에 표시한 화폐, all: 모든 화폐)
	Sort = 5,			-- 길드 정렬 기준 (1:이름 2:등급 3:레벨 4:지역 5:직업)
}

-- 더 이상 쓰지 않는 저장값
local obsolete = {
	"AutoCollect",		-- 자동 메모리 정리 (F1.0에서 삭제)
	"ShowCurrency",		-- 화폐 표시 켜짐/꺼짐 (CurrencyMode로 바뀜)
}

local function ApplyDefaults()
	if type(diminfo) ~= "table" then diminfo = {} end
	-- 예전 저장값 옮기기: 화폐 표시를 끈 적이 있으면 숨김으로
	if diminfo.CurrencyMode == nil and diminfo.ShowCurrency == false then
		diminfo.CurrencyMode = "hidden"
	end
	for k, v in pairs(defaults) do
		if diminfo[k] == nil then diminfo[k] = v end
	end
	for _, k in ipairs(obsolete) do
		diminfo[k] = nil
	end
end
ApplyDefaults()

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, name)
	if name ~= addon then return end
	ApplyDefaults()
	-- 설정 창에서 바꾼 값(diminfo.Settings)을 바와 각 항목에 적용 (API.lua)
	F.ApplySettings()
	self:UnregisterEvent("ADDON_LOADED")
end)

G.Ccolors = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[select(2, UnitClass("player"))] -- 직업 색

local MediaFolder = "Interface\\AddOns\\diminfo\\Media\\"

------------
-- 전체 --
------------

C.Panel = true			-- 배경 패널 사용
C.ClassColor = true		-- 이름표를 직업 색으로 표시

-----------
-- 텍스처, 글꼴 --
-----------

G.Tex = "Interface\\Buttons\\WHITE8x8"
G.Glow = MediaFolder.."glow.tga"
G.Fonts = STANDARD_TEXT_FONT		-- 글꼴
G.FontSize = 12						-- 글자 크기
G.FontFlag = "OUTLINE"				-- 글자 외곽선

-----------
-- 패널 --
-----------

-- 이름, 기준점, 부모 프레임, x 좌표, y 좌표, 너비, 높이, 그림자 크기
C.Panel1 = {"panel1", "TOP", UIParent, 0, -3, 800, 15, 3}

-- 필요하면 추가 (C.Panel5까지)
--C.Panel2 = {"panel2", "TOP", UIParent, 10, -5, 200, 8, 3}

--------------
-- 항목 설정 --
--------------

-- 지역명과 좌표
C.Positions = true
--C.PositionsPoint = {"TOP", Minimap, 0, 10}
--C.PositionsPoint = {"TOP", UIParent, 0, -6}
C.PositionsPoint = {"CENTER", "panel1", "CENTER", 0, 0}

-- 애드온 메모리 사용량
C.Memory = true
C.MaxAddOns = 30
C.MemoryPoint = {"LEFT", "panel1", "LEFT", 17, 0}

-- 시스템: FPS와 지연 시간
C.System = true
C.SystemPoint = {"LEFT", "panel1", "LEFT", 117, 0}

-- 친구
C.Friends = true
C.FriendsPoint = {"LEFT", "panel1", "LEFT", 217, 0}

-- 길드
C.Guild = true
C.GuildPoint = {"LEFT", "panel1", "LEFT", 277, 0}

-- 시계
--C.Time = true
--C.TimePoint = {"LEFT", "panel1", "LEFT", -3, 8}

-- 소지금
C.Money = true
C.MoneyPoint = {"LEFT", "panel1", "LEFT", 487, 0}

-- 내구도
C.Durability = true
C.DurabilityPoint = {"LEFT", "panel1", "LEFT", 637, 0}
C.DurabilityWarn = 30	-- 가장 낮은 장비가 이 % 미만이면 바에 최저값 표시

-- 가방
C.Bags = true
C.BagsPoint = {"LEFT", "panel1", "LEFT", 727, 0}

------------------
-- 설정 창 기본값 --
------------------

-- 게임 안 설정 창(Options.lua)에서 바꿀 수 있는 값의 기본값. 위 설정에서 그대로 가져온다.
-- 설정 창에서 바꾼 값만 diminfo.Settings에 저장되고, 바꾸지 않은 값은 계속 이 파일을 따른다.
C.SettingDefaults = {
	ClassColor = C.ClassColor,
	FontSize = G.FontSize,
	MaxAddOns = C.MaxAddOns,
	DurabilityWarn = C.DurabilityWarn,
	PanelWidth = C.Panel1[6],
	PanelHeight = C.Panel1[7],
	PanelY = C.Panel1[5],
}

-- 항목별 가로 위치 (X_항목 이름). 켜져 있는 항목만 넣는다.
C.StatKeys = {"Memory", "System", "Friends", "Guild", "Positions", "Money", "Durability", "Bags", "Time"}
for _, key in ipairs(C.StatKeys) do
	local point = C[key.."Point"]
	if C[key] and point then
		C.SettingDefaults["X_"..key] = point[4]
	end
end

-------------
-- 만든 사람들 --
-------------

-- NDui
-- diminfo
-- Tukz
-- Aftermath
-- kor - gromit
