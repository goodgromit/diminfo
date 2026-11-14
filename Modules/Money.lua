local _, ns = ...
local C, F, _, L = unpack(ns)

if not C.Money then return end

local Stat, Text = F.CreateStat("diminfo_money", C.MoneyPoint, "Money")

-- 이번 접속의 수입과 지출. 소지금이 바뀔 때마다 직전 금액과 비교해서 늘어난 만큼은 수입, 줄어든 만큼은 지출에 더한다.
-- 저장하지 않으므로 접속하거나 /reload 하면 0부터 다시 센다.
local startTime, lastMoney
local income, expense = 0, 0

local function CoinText(amount)
	return C_CurrencyInfo.GetCoinTextureString(amount)
end

local function UpdateText()
	F.SetText(Text, CoinText(GetMoney()))
end

-- 툴팁 화폐 표시 방식. 오른쪽 클릭할 때마다 순서대로 바뀐다.
--   hidden: 숨김, tracked: 캐릭터 창 화폐 탭에서 "가방에 표시"로 고른 화폐, all: 가진 화폐 전부
local CURRENCY_MODES = {"hidden", "tracked", "all"}
local currencyModeText = {
	hidden = "|cffff5555"..HIDE,
	tracked = "|cff55ff55"..SHOW_ON_BACKPACK,
	all = "|cff55ff55"..ALL,
}

-- 현재 화폐 표시 방식. 저장값이 잘못돼 있으면 "가방에 표시한 화폐"로 되돌린다.
local function CurrencyMode()
	if not currencyModeText[diminfo.CurrencyMode] then diminfo.CurrencyMode = "tracked" end
	return diminfo.CurrencyMode
end

local function NextCurrencyMode()
	local current = CurrencyMode()
	for i, mode in ipairs(CURRENCY_MODES) do
		if mode == current then
			return CURRENCY_MODES[i % #CURRENCY_MODES + 1]
		end
	end
end

local function AddCurrencyLine(info)
	GameTooltip:AddDoubleLine("|T"..info.iconFileID..":14:14:0:0:64:64:4:60:4:60|t "..info.name, BreakUpLargeNumbers(info.quantity), 1, 1, 1, 1, 1, 1)
end

-- "가방에 표시"로 고른 화폐 (Forever 화폐 창 Blizzard_TokenUI와 같이 nil이 나올 때까지 순서대로 읽는다)
local function AddTrackedCurrencies()
	for i = 1, 20 do
		local info = C_CurrencyInfo.GetBackpackCurrencyInfo(i)
		if not info then break end
		if i == 1 then GameTooltip:AddLine(" ") end
		AddCurrencyLine(info)
	end
end

-- 가진 화폐 전부 (보유량이 0보다 큰 것만, 화폐 탭의 분류 제목과 함께)
-- 화폐 탭에서 분류를 접어 두면 그 안의 화폐는 목록에 나오지 않는다.
local function AddAllCurrencies()
	local added, header = false, nil
	for i = 1, C_CurrencyInfo.GetCurrencyListSize() do
		local info = C_CurrencyInfo.GetCurrencyListInfo(i)
		if info and info.isHeader then
			header = info.name
		elseif info and (info.quantity or 0) > 0 then
			if not added then
				GameTooltip:AddLine(" ")
				added = true
			end
			if header then
				GameTooltip:AddLine(header, 1, .82, 0)
				header = nil
			end
			AddCurrencyLine(info)
		end
	end
end

local function OnMoneyChanged()
	local money = GetMoney()
	if lastMoney then
		local diff = money - lastMoney
		if diff > 0 then
			income = income + diff
		elseif diff < 0 then
			expense = expense - diff
		end
	else
		startTime = GetTime()
	end
	lastMoney = money
	UpdateText()
end

Stat:SetScript("OnEnter", function(self)
	F.OpenTooltip(self, true)
	GameTooltip:AddDoubleLine(L["Current money"], CoinText(GetMoney()), 0, .6, 1, 1, 1, 1)
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine(L["Income"], CoinText(income), .6, .8, 1, 1, 1, 1)
	GameTooltip:AddDoubleLine(L["Expense"], CoinText(expense), .6, .8, 1, 1, 1, 1)

	-- 이번 접속 순이익(수입 - 지출): 이익은 초록, 손실은 빨강
	local net = income - expense
	if net >= 0 then
		GameTooltip:AddDoubleLine(L["Session"], CoinText(net), .6, .8, 1, .3, 1, .3)
	else
		GameTooltip:AddDoubleLine(L["Session"], "-"..CoinText(-net), .6, .8, 1, 1, .3, .3)
	end

	if startTime then
		GameTooltip:AddDoubleLine(L["Session time"], SecondsToTime(GetTime() - startTime), .6, .8, 1, 1, 1, 1)
	end

	local mode = CurrencyMode()
	if mode == "tracked" then
		AddTrackedCurrencies()
	elseif mode == "all" then
		AddAllCurrencies()
	end
	F.AddFooter(CURRENCY..": "..currencyModeText[mode])
	GameTooltip:Show()
end)

-- 오른쪽 클릭: 툴팁 화폐 표시 방식 바꾸기 (숨김 → 가방에 표시한 화폐 → 모든 화폐 → 숨김)
Stat:SetScript("OnMouseDown", function(self, btn)
	if btn ~= "RightButton" then return end
	diminfo.CurrencyMode = NextCurrencyMode()
	self:GetScript("OnEnter")(self)
end)

Stat:RegisterEvent("PLAYER_ENTERING_WORLD")
Stat:RegisterEvent("PLAYER_MONEY")
Stat:SetScript("OnEvent", OnMoneyChanged)

-- 설정 창에서 값이 바뀌면 바 글자를 다시 그린다 (API.lua F.ApplySettings)
Stat.Refresh = UpdateText
