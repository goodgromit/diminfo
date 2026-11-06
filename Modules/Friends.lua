local addon, ns = ...
local C, F, G, L = unpack(ns)

if not C.Friends then return end

local Stat, Text = F.CreateStat("diminfo_Friends", C.FriendsPoint)

local CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
local activezone, inactivezone = {r = 0.3, g = 1, b = 0.3}, {r = 0.65, g = 0.65, b = 0.65}
local friendOnline = gsub(ERR_FRIEND_ONLINE_SS, "\124Hplayer:%%s\124h%[%%s%]\124h", "")
local friendOffline = gsub(ERR_FRIEND_OFFLINE_S, "%%s", "")

local function StatusIcon(texture)
	return " |T"..texture..":0:0:-2:-2:50:50:4:46:4:46|t"
end

-- 현지화된 직업 이름 → 직업 키("WARRIOR" 등). 게임 친구 정보에는 직업 이름만 있다.
local classByName = {}
for classFile, name in pairs(LOCALIZED_CLASS_NAMES_MALE) do classByName[name] = classFile end
for classFile, name in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do classByName[name] = classFile end

-- 직업 색. 직업을 모르면 레벨 색을 대신 쓴다.
local function ClassColor(classFile, levelColor)
	return CLASS_COLORS[classFile] or levelColor
end

-- 배틀넷 클라이언트 아이콘
local clientTextures = {
	WoW = "Interface\\FriendsFrame\\Battlenet-WoWicon",
	S2 = "Interface\\FriendsFrame\\Battlenet-Sc2icon",
	D3 = "Interface\\FriendsFrame\\Battlenet-D3icon",
	WTCG = "Interface\\FriendsFrame\\Battlenet-WTCGicon",
	Hero = "Interface\\FriendsFrame\\Battlenet-HotSicon",
	Pro = "Interface\\FriendsFrame\\Battlenet-Overwatchicon",
}
local function ClientIcon(client)
	return "|T"..(clientTextures[client] or "Interface\\FriendsFrame\\Battlenet-Battleneticon")..":16:16:2:0:50:50:4:46:4:46|t "
end

-- 내 캐릭터의 AFK, DND 상태
-- 채팅 잠금(보스전 등) 중에는 UnitIsAFK/UnitIsDND가 secret 값을 돌려주므로 확인하지 않는다(nil 반환).
local function GetPlayerStatus()
	if C_ChatInfo.InChatMessagingLockdown() then return end
	return UnitIsAFK("player"), UnitIsDND("player")
end

local function Whisper(name)
	SetItemRef("player:"..name, ("|Hplayer:%1$s|h[%1$s]|h"):format(name), "LeftButton")
end

local function BNWhisper(accountName, bnetAccountID)
	SetItemRef("BNplayer:"..accountName..":"..bnetAccountID, ("|Hplayer:%1$s|h[%1$s]|h"):format(accountName), "LeftButton")
end

-- 접속 중인 친구 목록. 친구 목록이 바뀌면 dataValid를 내려 다음 툴팁 때 다시 만든다.
local friendTable, BNTable = {}, {}
local dataValid = false

-- 게임 친구
local function BuildFriendTable(total)
	wipe(friendTable)
	for i = 1, total do
		local info = C_FriendList.GetFriendInfoByIndex(i)
		if info and info.connected then
			local status = StatusIcon(FRIENDS_TEXTURE_ONLINE)
			if info.afk then
				status = StatusIcon(FRIENDS_TEXTURE_AFK)
			elseif info.dnd then
				status = StatusIcon(FRIENDS_TEXTURE_DND)
			end

			friendTable[#friendTable + 1] = {
				name = info.name,
				level = info.level or 0,
				classFile = classByName[info.className],
				area = info.area,
				status = status,
			}
		end
	end
	table.sort(friendTable, function(a, b) return a.name < b.name end)
end

-- 배틀넷 친구
local function BuildBNTable(total)
	wipe(BNTable)
	for i = 1, total do
		local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
		local game = accountInfo and accountInfo.gameAccountInfo
		if game and game.isOnline then
			local isWoW = game.clientProgram == BNET_CLIENT_WOW

			local status = ""
			if accountInfo.isAFK or game.isGameAFK then
				status = StatusIcon(FRIENDS_TEXTURE_AFK)
			elseif accountInfo.isDND or game.isGameBusy then
				status = StatusIcon(FRIENDS_TEXTURE_DND)
			end

			-- WoW는 지역 이름, 다른 게임은 게임 상태 문구
			local infoText
			if isWoW then
				infoText = (game.areaName and game.areaName ~= "") and game.areaName or UNKNOWN
			else
				infoText = game.richPresence
			end

			BNTable[#BNTable + 1] = {
				accountName = accountInfo.accountName or "",
				bnetAccountID = accountInfo.bnetAccountID,
				battleTag = accountInfo.battleTag,
				characterName = game.characterName,
				gameAccountID = game.gameAccountID,
				client = game.clientProgram,
				isWoW = isWoW,
				status = status,
				realmName = game.realmName,
				classFile = game.classFilename,
				level = game.characterLevel or 0,
				infoText = infoText,
				-- 초대 가능: 같은 게임(Forever), 같은 지역의 서버, 같은 진영인 WoW 캐릭터
				-- (Forever 친구 창 FriendsFrame_BattlenetInviteByIndex와 같은 조건)
				canInvite = isWoW and game.wowProjectID == WOW_PROJECT_ID and game.playerGuid ~= nil
					and (game.realmID or 0) ~= 0 and game.factionName == UnitFactionGroup("player"),
			}
		end
	end
	table.sort(BNTable, function(a, b) return a.accountName < b.accountName end)
end

-- 바의 접속 친구 수. 친구 정보 이벤트(BN_FRIEND_INFO_CHANGED 등)는 자주 오므로 1초 단위로 묶어서 한 번만 센다.
local FRIENDS_LABEL = F.Label(FRIENDS).." "
local textPending = false
local function UpdateText()
	textPending = false
	local _, numBNetOnline = BNGetNumFriends()
	F.SetText(Text, FRIENDS_LABEL..(C_FriendList.GetNumOnlineFriends() + numBNetOnline))
end

local function ScheduleTextUpdate()
	if textPending then return end
	textPending = true
	C_Timer.After(1, UpdateText)
end

local function Update(self, event, ...)
	if event == "CHAT_MSG_SYSTEM" then
		-- 친구 접속/접속 해제 메시지만 처리한다.
		-- 채팅 잠금 중에는 메시지가 secret 값일 수 있어 문자열 검색을 하지 않는다.
		local message = ...
		if issecretvalue(message) then return end
		if not (string.find(message, friendOnline, 1, true) or string.find(message, friendOffline, 1, true)) then return end
	elseif event == "MODIFIER_STATE_CHANGED" then
		-- Shift를 누르거나 뗄 때 툴팁을 다시 그린다 (마우스가 올라가 있을 때만 등록되는 이벤트)
		local key = ...
		if key == "LSHIFT" or key == "RSHIFT" then
			self:GetScript("OnEnter")(self)
		end
		return
	end

	-- 친구 목록이 바뀌었으니 다음 툴팁 때 목록을 다시 만든다
	dataValid = false

	if event == "PLAYER_ENTERING_WORLD" then
		UpdateText()
	else
		ScheduleTextUpdate()
	end
end

-- 좌클릭: 친구 창, 우클릭: 초대/귓속말/상태 메뉴
Stat:SetScript("OnMouseUp", function(self, btn)
	GameTooltip:Hide()
	if btn == "LeftButton" then
		ToggleFriendsFrame()
		return
	end
	if btn ~= "RightButton" then return end

	MenuUtil.CreateContextMenu(UIParent, function(owner, rootDescription)
		rootDescription:CreateTitle(OPTIONS_MENU)

		local inviteMenu = rootDescription:CreateButton(INVITE)
		local whisperMenu = rootDescription:CreateButton(CHAT_MSG_WHISPER_INFORM)

		-- 게임 친구
		for _, info in ipairs(friendTable) do
			local levelc = GetQuestDifficultyColor(info.level)
			local nametext = F.Hex(levelc)..info.level.." "..F.Hex(ClassColor(info.classFile, levelc))..info.name
			inviteMenu:CreateButton(nametext, function() C_PartyInfo.InviteUnit(info.name) end)
			whisperMenu:CreateButton(nametext, function() Whisper(info.name) end)
		end

		-- 배틀넷 친구 (귓속말은 모두, 초대는 초대 가능한 친구만)
		for _, info in ipairs(BNTable) do
			whisperMenu:CreateButton("|cff70C0F5"..info.accountName, function()
				BNWhisper(info.accountName, info.bnetAccountID)
			end)

			if info.canInvite then
				local levelc = GetQuestDifficultyColor(info.level)
				local nametext = F.Hex(levelc)..info.level.." "..F.Hex(ClassColor(info.classFile, levelc))..info.characterName
				inviteMenu:CreateButton(nametext, function() C_BattleNet.InviteFriend(info.gameAccountID) end)
			end
		end

		rootDescription:CreateDivider()
		rootDescription:CreateTitle(PLAYER_STATUS)

		-- 빈 메시지로 "AFK"/"DND"를 보내면 해당 상태가 켜지거나 꺼진다(/afk, /dnd와 같음)
		rootDescription:CreateButton("|cff2BC226"..AVAILABLE.."|r", function()
			local afk, dnd = GetPlayerStatus()
			if afk then
				C_ChatInfo.SendChatMessage("", "AFK")
			elseif dnd then
				C_ChatInfo.SendChatMessage("", "DND")
			end
		end)

		rootDescription:CreateButton("|cffE7E716"..DND.."|r", function()
			local _, dnd = GetPlayerStatus()
			if dnd == false then
				C_ChatInfo.SendChatMessage("", "DND")
			end
		end)

		rootDescription:CreateButton("|cffFF0000"..AFK.."|r", function()
			local afk = GetPlayerStatus()
			if afk == false then
				C_ChatInfo.SendChatMessage("", "AFK")
			end
		end)
	end)
end)

-- 툴팁: 접속 중인 친구 목록
Stat:SetScript("OnEnter", function(self)
	local numberOfFriends = C_FriendList.GetNumFriends()
	local onlineFriends = C_FriendList.GetNumOnlineFriends()
	local totalBNet, numBNetOnline = BNGetNumFriends()
	local totalOnline = onlineFriends + numBNetOnline

	if totalOnline == 0 then return end
	if not dataValid then
		BuildFriendTable(numberOfFriends)
		BuildBNTable(totalBNet)
		dataValid = true
	end

	F.OpenTooltip(self)
	GameTooltip:AddDoubleLine(FRIEND, format("%s/%s", totalOnline, numberOfFriends + totalBNet), 0, .6, 1, 0, .6, 1)

	-- 게임 친구
	if onlineFriends > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("WOW")

		local myZone = GetRealZoneText()
		for _, info in ipairs(friendTable) do
			local zonec = (myZone == info.area) and activezone or inactivezone
			local levelc = GetQuestDifficultyColor(info.level)
			local classc = ClassColor(info.classFile, levelc)
			GameTooltip:AddDoubleLine(F.Hex(levelc)..info.level.."|r "..F.Hex(classc)..info.name.."|r"..info.status, info.area, classc.r, classc.g, classc.b, zonec.r, zonec.g, zonec.b)
		end
	end

	-- 배틀넷 친구
	if numBNetOnline > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Battle.NET")

		local myRealm = GetRealmName()
		for _, info in ipairs(BNTable) do
			local icon = ClientIcon(info.client)
			if info.isWoW then
				local levelc = GetQuestDifficultyColor(info.level)
				local classc = ClassColor(info.classFile, levelc)
				local name = info.characterName or ""
				local infoText = info.infoText and ("- "..info.infoText) or ""
				GameTooltip:AddDoubleLine(icon..F.Hex(levelc)..info.level.."|r "..name.."|cffffffff "..infoText, info.accountName, classc.r, classc.g, classc.b, 1, 1, 1)

				-- Shift: 서버 이름 (내 서버면 초록색)
				if IsShiftKeyDown() then
					local realmc = (myRealm == info.realmName) and activezone or inactivezone
					GameTooltip:AddDoubleLine(F.Hex(levelc)..info.level.."|r "..name, info.realmName, classc.r, classc.g, classc.b, realmc.r, realmc.g, realmc.b)
				end
			elseif info.characterName then
				GameTooltip:AddDoubleLine(icon..info.characterName..info.status.." - "..(info.infoText or ""), info.battleTag, 1, 1, 1, 1, 1, 1)
			else
				GameTooltip:AddDoubleLine(icon..info.status, info.accountName, 1, 1, 1, 1, 1, 1)
			end
		end
	end

	GameTooltip:Show()
	self:RegisterEvent("MODIFIER_STATE_CHANGED")
end)

Stat:SetScript("OnLeave", function(self)
	GameTooltip:Hide()
	self:UnregisterEvent("MODIFIER_STATE_CHANGED")
end)

Stat:RegisterEvent("PLAYER_ENTERING_WORLD")
Stat:RegisterEvent("FRIENDLIST_UPDATE")
Stat:RegisterEvent("BN_FRIEND_ACCOUNT_ONLINE")
Stat:RegisterEvent("BN_FRIEND_ACCOUNT_OFFLINE")
Stat:RegisterEvent("BN_FRIEND_INFO_CHANGED")
Stat:RegisterEvent("CHAT_MSG_SYSTEM")
Stat:SetScript("OnEvent", Update)
