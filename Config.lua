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
	Sort = 5,			-- 길드 정렬 기준 (1:이름 2:등급 3:레벨 4:지역 5:직업)
}

-- 더 이상 쓰지 않는 저장값
local obsolete = {
	"AutoCollect",		-- 자동 메모리 정리 (F1.0에서 삭제)
}

local function ApplyDefaults()
	if type(diminfo) ~= "table" then diminfo = {} end
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

-- 가방
C.Bags = true
C.BagsPoint = {"LEFT", "panel1", "LEFT", 727, 0}

-------------
-- 만든 사람들 --
-------------

-- NDui
-- diminfo
-- Tukz
-- Aftermath
-- kor - gromit
