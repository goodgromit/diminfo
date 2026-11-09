local addon, ns = ...

-- 로케일 문자열. 다른 애드온과 이름이 겹치지 않도록 전역이 아닌 애드온 내부(ns[4])에 둔다.
local L

if GetLocale() == "zhTW" then
	L = {
		["AutoSell junk"] = "自動賣垃圾：",

		["AutoRepair"] = "自動修理：",
		["Repair cost"] = "修理花費：",
		["Go farm, newbie"] = "你真窮。",
		["none"] = "無裝備",

		["No Guild"] = "沒人要",
		["Sorting"] = "排序",
		["Sorting by:"] = "排序方式：",

		["Shift"] = "Shift展開",
		["Hidden"] = HIDE,

		["Default UI Memory Usage:"] = "内建插件資源占用：",
		["Total Memory Usage:"] = "總資源占用：",
		["Garbage collected"] = "釋放記憶體：",

		["Home"] = "本地",
		["Latency"] = "延遲：",
		["AddOn CPU Usage"] = "插件CPU占用",

		["Session"] = "本次登入",
		["Income"] = "收入",
		["Expense"] = "支出",
		["Net"] = "淨收益",
		["Session time"] = "登入時間",
		["Lowest"] = "最低",
	}
elseif GetLocale() == "zhCN" then
	L = {
		["AutoSell junk"] = "自动卖垃圾：",

		["AutoRepair"] = "自动修理：",
		["Repair cost"] = "修理花费：",
		["Go farm, newbie"] = "你真穷。",
		["none"] = "无装备",

		["No Guild"] = "没人要",
		["Sorting"] = "排序",
		["Sorting by:"] = "排序方式：",

		["Shift"] = "Shift展开",
		["Hidden"] = HIDE,

		["Default UI Memory Usage:"] = "内建插件资源占用：",
		["Total Memory Usage:"] = "总资源占用：",
		["Garbage collected"] = "释放內存：",

		["Home"] = "本地",
		["Latency"] = "延迟：",
		["AddOn CPU Usage"] = "插件CPU占用",

		["Session"] = "本次登录",
		["Income"] = "收入",
		["Expense"] = "支出",
		["Net"] = "净收益",
		["Session time"] = "登录时间",
		["Lowest"] = "最低",
	}
elseif GetLocale() == "koKR" then
	L = {
		["AutoSell junk"] = "회색아이템 자동판매：",

		["AutoRepair"] = "자동수리：",
		["Repair cost"] = "수리비용：",
		["Go farm, newbie"] = "수리비용이 부족합니다.",
		["none"] = "장비 없음",

		["No Guild"] = "길드 없음",
		["Sorting"] = "정렬",
		["Sorting by:"] = "정렬방식：",

		["Shift"] = "(Shift키)모두보기",
		["Hidden"] = "숨겨짐",

		["Default UI Memory Usage:"] = "기본 UI 메모리 사용：",
		["Total Memory Usage:"] = "전체 메모리 사용：",
		["Garbage collected"] = "여유 메모리 확보：",

		["Home"] = "지역",
		["Latency"] = "지연 시간：",
		["AddOn CPU Usage"] = "애드온 CPU 사용량",

		["Session"] = "이번 접속",
		["Income"] = "수입",
		["Expense"] = "지출",
		["Net"] = "순이익",
		["Session time"] = "접속 시간",
		["Lowest"] = "최저",
	}
else
	L = {
		["AutoSell junk"] = "Auto Sell junk: ",

		["AutoRepair"] = "Auto Repair: ",
		["Repair cost"] = "Repair cost: ",
		["Go farm, newbie"] = "Go farm, newbie.",
		["none"] = "None",

		["No Guild"] = "Lonely",
		["Sorting"] = "Sorting",
		["Sorting by:"] = "Sorting by: ",

		["Shift"] = "Shift show all",
		["Hidden"] = "Hidden",

		["Default UI Memory Usage:"] = "Default UI Memory Usage: ",
		["Total Memory Usage:"] = "Total Memory Usage: ",
		["Garbage collected"] = "Garbage collected: ",

		["Home"] = "Home",
		["Latency"] = "Latency",
		["AddOn CPU Usage"] = "AddOn CPU Usage",

		["Session"] = "This session",
		["Income"] = "Income",
		["Expense"] = "Expense",
		["Net"] = "Net",
		["Session time"] = "Session time",
		["Lowest"] = "Lowest",
	}
end

ns[4] = L
