local addon, ns = ...
local C, F, G, L = unpack(ns)

if not C.Bags then return end

local Stat, Text = F.CreateStat("diminfo_Bag", C.BagsPoint, "Bags")

-- 가방 칸 수 (가방 0 ~ NUM_BAG_SLOTS, 재료 가방 제외)
local free, total = 0, 0

local function Update()
	free, total = 0, 0
	for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
		free = free + C_Container.GetContainerNumFreeSlots(bag)
		total = total + C_Container.GetContainerNumSlots(bag)
	end
	F.SetText(Text, F.Label(BAGSLOT).." "..free.."/"..total)
end

Stat:SetScript("OnEnter", function(self)
	F.OpenTooltip(self, true)
	GameTooltip:AddDoubleLine(BAGSLOT, free, 0, .6, 1, 0, .6, 1)
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine(TOTAL, total, .6, .8, 1, 1, 1, 1)
	GameTooltip:AddDoubleLine(USE, total - free, .6, .8, 1, 1, 1, 1)
	F.AddFooter(L["AutoSell junk"]..F.OnOff(diminfo.AutoSell))
	GameTooltip:Show()
end)

-- 좌클릭: 가방 열기, 우클릭: 자동 판매 켜기/끄기
Stat:SetScript("OnMouseDown", function(self, btn)
	if btn == "RightButton" then
		diminfo.AutoSell = not diminfo.AutoSell
		self:GetScript("OnEnter")(self)
	else
		ToggleAllBags()
	end
end)

-- BAG_UPDATE_DELAYED: 가방 변경이 한 번에 여러 개 일어나도 묶어서 한 번만 온다
Stat:RegisterEvent("PLAYER_ENTERING_WORLD")
Stat:RegisterEvent("BAG_UPDATE_DELAYED")
Stat:SetScript("OnEvent", Update)

-- 회색 아이템 자동 판매
-- Blizzard 상인 창의 "잡동사니 모두 팔기" 버튼과 같은 C_MerchantFrame.SellAllJunkItems를 쓴다.
-- 판매 금액은 게임이 시스템 메시지로 알려 주므로 따로 출력하지 않는다.
local SellGray = CreateFrame("Frame")
SellGray:RegisterEvent("MERCHANT_SHOW")
SellGray:SetScript("OnEvent", function()
	if not diminfo.AutoSell or not C_MerchantFrame.IsSellAllJunkEnabled() then return end
	if C_MerchantFrame.GetNumJunkItems() == 0 then return end
	C_MerchantFrame.SellAllJunkItems()
end)

-- 설정 창에서 값이 바뀌면 바 글자를 다시 그린다 (API.lua F.ApplySettings)
Stat.Refresh = function() Update() end
