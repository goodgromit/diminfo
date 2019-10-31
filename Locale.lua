if GetLocale() == "zhTW" then
	infoL = {
		["AutoSell junk"] = "自動賣垃圾：",
		["Trash sold, earned "] = "垃圾售出：",

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
		["AutoCollect"] = "自動整理暫存記憶體：",

		["Home"] = "本地",
		["Latency"] = "延遲：",
		["CPU Usage"] = "顯示CPU占用比例：",
		["Reload UI(on)"] = "|cff777777dim|rinfo[|cff00ff00System|r]：重載介面後顯示插件的CPU佔用。",
		["Reload UI(off)"] = "|cff777777dim|rinfo[|cff00ff00System|r]：重載介面後隱藏插件的CPU佔用。",
	}
elseif GetLocale() == "zhCN" then
	infoL = {
		["AutoSell junk"] = "自动卖垃圾：",
		["Trash sold, earned "] = "垃圾售出：",

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
		["AutoCollect"] = "自动整理暂存：",

		["Home"] = "本地",
		["Latency"] = "延迟：",
		["CPU Usage"] = "显示CPU占用比例：",
		["Reload UI(on)"] = "|cff777777dim|rinfo[|cff00ff00System|r]：重载界面后显示插件的CPU佔用。",
		["Reload UI(off)"] = "|cff777777dim|rinfo[|cff00ff00System|r]：重载界面后隐藏插件的CPU佔用。",
	}
elseif GetLocale() == "koKR" then
	infoL = {
		["AutoSell junk"] = "회색아이템 자동판매：",
		["Trash sold, earned "] = "회색아이템 판매：",

		["AutoRepair"] = "자동수리：",
		["Repair cost"] = "수리비용：",
		["Go farm, newbie"] = "수리비용이 부족합니다.",
		["none"] = "장비 없음",

		["No Guild"] = "길드 없음",
		["Sorting"] = "정렬",
		["Sorting by:"] = "정렬방식：",

		["Shift"] = "Shift확장",
		["Hidden"] = HIDE,

		["Default UI Memory Usage:"] = "기본 UI 메모리 사용：",
		["Total Memory Usage:"] = "전체 메모리 사용：",
		["Garbage collected"] = "여유 메모리 확보：",
		["AutoCollect"] = "자동수집：",

		["Home"] = "지역",
		["Latency"] = "지연：",
		["CPU Usage"] = "CPU 사용률：",
		["Reload UI(on)"] = "|cff777777dim|rinfo[|cff00ff00System|r]：애드온을 다시 로드하면 CPU사용량이 표시됩니다.",
		["Reload UI(off)"] = "|cff777777dim|rinfo[|cff00ff00System|r]：애드온을 다시 로드하면 CPU사용량이 숨겨집니다.",
	}
else

	infoL = {
		["AutoSell junk"] = "Auto Sell junk: ",
		["Trash sold, earned "] = "Trash sold, earned: ",

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
		["AutoCollect"] = "AutoCollect: ",

		["Home"] = "Home",
		["Latency"] = "Latency",
		["CPU Usage"] = "Show CPU Usage",
		["Reload UI(on)"] = "|cff777777dim|rinfo[|cff00ff00System|r]: You could see addon's CPU usage after reloding UI.",
		["Reload UI(off)"] = "|cff777777dim|rinfo[|cff00ff00System|r]: You could hide the addon's CPU usage table after reloding UI.",
	}
end
