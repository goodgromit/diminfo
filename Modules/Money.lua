local addon, ns = ...
local C, F, G, L = unpack(ns)

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
	GameTooltip:AddDoubleLine(L["Session"], CoinText(GetMoney()), 0, .6, 1, 1, 1, 1)
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine(L["Income"], CoinText(income), .6, .8, 1, 1, 1, 1)
	GameTooltip:AddDoubleLine(L["Expense"], CoinText(expense), .6, .8, 1, 1, 1, 1)

	-- 순이익: 이익은 초록, 손실은 빨강
	local net = income - expense
	if net >= 0 then
		GameTooltip:AddDoubleLine(L["Net"], CoinText(net), .6, .8, 1, .3, 1, .3)
	else
		GameTooltip:AddDoubleLine(L["Net"], "-"..CoinText(-net), .6, .8, 1, 1, .3, .3)
	end

	if startTime then
		GameTooltip:AddDoubleLine(L["Session time"], SecondsToTime(GetTime() - startTime), .6, .8, 1, 1, 1, 1)
	end
	GameTooltip:Show()
end)

Stat:RegisterEvent("PLAYER_ENTERING_WORLD")
Stat:RegisterEvent("PLAYER_MONEY")
Stat:SetScript("OnEvent", OnMoneyChanged)

-- 설정 창에서 값이 바뀌면 바 글자를 다시 그린다 (API.lua F.ApplySettings)
Stat.Refresh = UpdateText
