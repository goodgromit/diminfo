local addon, ns = ... 
local C, F, G, T = unpack(ns)
local panel = CreateFrame("Frame", nil, UIParent)

if not C.System then return end

local lastUpdate = GetTime()
local lastUsage = {} 
local currentCPU = {} 

-- 현재 엔진 활성 상태 (UI 리로드 전까지 변하지 않음)
local isCPUEngineActive = GetCVar("scriptProfile") == "1"

-- 리로드 확인 팝업 설정
StaticPopupDialogs["RELOAD_UI_CONFIRM"] = {
    text = "|cff55ff55diminfo:|r CPU 측정 설정을 변경하려면 UI 리로드가 필요합니다. 지금 하시겠습니까?",
    button1 = ACCEPT,
    button2 = CANCEL,
    OnAccept = function() 
        -- [수정] 사용자가 수락했을 때만 CVar를 토글하고 리로드 실행
        local targetValue = (GetCVar("scriptProfile") == "1") and "0" or "1"
        SetCVar("scriptProfile", targetValue)
        ReloadUI() 
    end,
    -- [수정] Cancel 시에는 아무 작업도 하지 않음 (처리 자체를 취소)
    OnCancel = function() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local Stat = CreateFrame("Frame", "diminfo_System")
Stat:EnableMouse(true)
Stat:SetFrameStrata("BACKGROUND")
Stat:SetFrameLevel(3)

local Text  = panel:CreateFontString(nil, "OVERLAY")
Text:SetFont(G.Fonts, G.FontSize, G.FontFlag)
Text:SetPoint(unpack(C.SystemPoint))
Stat:SetAllPoints(Text)

local function colorLatency(latency)
    if latency < 300 then return "|cff0CD809"..latency
    elseif latency < 500 then return "|cffE8DA0F"..latency
    else return "|cffD80909"..latency end
end

local function colorFPS(fps)
    if fps < 15 then return "|cffD80909"..fps
    elseif fps < 30 then return "|cffE8DA0F"..fps
    else return "|cff0CD809"..fps end
end

local function RefreshCput()
    if not isCPUEngineActive then 
        wipe(currentCPU)
        return 
    end
    
    UpdateAddOnCPUUsage()
    local now = GetTime()
    local elapsed = now - lastUpdate
    if elapsed <= 0 then elapsed = 0.01 end

    wipe(currentCPU) 

    local numAddons = C_AddOns.GetNumAddOns()
    for i = 1, numAddons do
        local name = select(2, C_AddOns.GetAddOnInfo(i))
        local usage = GetAddOnCPUUsage(i)
        local isLoaded = C_AddOns.IsAddOnLoaded(i)

        if isLoaded then
            local diff = usage - (lastUsage[i] or usage)
            local percent = diff / (elapsed * 1000) * 100
            table.insert(currentCPU, { name, percent, isLoaded, i })
            lastUsage[i] = usage
        end
    end
    lastUpdate = now

    table.sort(currentCPU, function(a, b)
        if a and b and a[2] and b[2] then
            return a[2] > b[2]
        end
        return false
    end)
end

local int = 1
local function onUpdate(self, t)
    int = int - t
    if int < 0 then
        local _, _, latencyHome, latencyWorld = GetNetStats()
        local fps = floor(GetFramerate()+0.5)
        Text:SetText(colorFPS(fps).."|rfps "..colorLatency(latencyHome).."|rms")
        int = 0.8
    end
end

Stat:SetScript("OnEnter", function(self)
    RefreshCput()
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, -10)
    GameTooltip:ClearAllPoints()
    GameTooltip:SetPoint("BOTTOM", self, "TOP", 0, 1)
    GameTooltip:ClearLines()
    GameTooltip:AddLine(CHAT_MSG_SYSTEM, 0, .6, 1)
    GameTooltip:AddLine(" ")
    
    if isCPUEngineActive and #currentCPU > 0 then
        GameTooltip:AddLine(infoL["AddOn CPU Usage"], 1, 1, 1)
        local maxAddOns = IsShiftKeyDown() and #currentCPU or math.min(C.MaxAddOns, #currentCPU)
        
        for i = 1, maxAddOns do
            local data = currentCPU[i]
            if data and data[3] then
                local p = data[2]
                local r, g = 0, 1
                if p > 10 then r, g = 1, 0.1
                elseif p > 5 then r, g = 1, 0.5
                elseif p > 1 then r, g = 1, 1
                end
                GameTooltip:AddDoubleLine(data[1], format("%.2f %%", p), 1, 1, 1, r, g, 0)
            end
        end
        
        if not IsShiftKeyDown() and #currentCPU > C.MaxAddOns then
            local more, moreCpu = 0, 0
            for i = C.MaxAddOns + 1, #currentCPU do
                if currentCPU[i][3] then
                    more = more + 1
                    moreCpu = moreCpu + currentCPU[i][2]
                end
            end
            GameTooltip:AddDoubleLine(format("%d %s (%s)", more, infoL["Hidden"], infoL["Shift"]), format("%.2f %%", moreCpu), .6, .8, 1, .6, .8, 1)
        end
        GameTooltip:AddLine(" ")
    end

    local _, _, latencyHome, latencyWorld = GetNetStats()
    GameTooltip:AddDoubleLine(infoL["Latency"], format("%s%s(%s)/%s%s(%s)", colorLatency(latencyHome).."|r", "ms", infoL["Home"], colorLatency(latencyWorld).."|r", "ms", CHANNEL_CATEGORY_WORLD), .6, .8, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine(" ", "--------------", 1, 1, 1, .5, .5, .5)
    GameTooltip:AddDoubleLine(" ", infoL["CPU Usage"]..(isCPUEngineActive and "|cff55ff55"..ENABLE or "|cffff5555"..DISABLE), 1, 1, 1, .6, .8, 1)
    GameTooltip:Show()
end)

Stat:SetScript("OnLeave", function() GameTooltip:Hide() end)

Stat:SetScript("OnMouseDown", function(self, btn)
    if btn == "RightButton" then
        -- [수정] 클릭 시 CVar를 미리 바꾸지 않고 팝업만 호출
        StaticPopup_Show("RELOAD_UI_CONFIRM")
        return
    end
    
    ResetCPUUsage()
    RefreshCput()
    if self:IsMouseOver() then
        self:GetScript("OnEnter")(self)
    end
end)

Stat:SetScript("OnUpdate", onUpdate)
