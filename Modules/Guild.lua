local addon, ns = ...
local C, F, G, L = unpack(ns)

if not C.Guild then return end

local Stat, Text = F.CreateStat("diminfo_Guild", C.GuildPoint)

local CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
local MAX_SHOWN = 39	-- 툴팁에 표시할 최대 길드원 수
local tthead, ttsubh, ttoff = {r = 0.4, g = 0.78, b = 1}, {r = .75, g = .9, b = 1}, {r = .3, g = 1, b = .3}
local activezone, inactivezone = {r = 0.3, g = 1.0, b = 0.3}, {r = .65, g = .65, b = .65}
local friendOnline = gsub(ERR_FRIEND_ONLINE_SS, "\124Hplayer:%%s\124h%[%%s%]\124h", "")
local friendOffline = gsub(ERR_FRIEND_OFFLINE_S, "%%s", "")

-- 정렬 기준 (diminfo.Sort에 번호를 저장한다)
local sortOptions = {
	{key = "name", label = NAME},
	{key = "rankOrder", label = RANK},
	{key = "level", label = LEVEL},
	{key = "zone", label = ZONE},
	{key = "classFile", label = CLASS},
}

-- 현재 정렬 기준. 저장값이 잘못돼 있으면 직업순(5)으로 되돌린다.
local function SortOption()
	if not sortOptions[diminfo.Sort] then diminfo.Sort = 5 end
	return sortOptions[diminfo.Sort]
end

-- 게임에 접속 중인 상태 (모바일 앱 접속은 초대, 귓속말 대상이 아니므로 제외)
local inGamePresence = {
	[Enum.ClubMemberPresence.Online] = true,
	[Enum.ClubMemberPresence.Away] = true,
	[Enum.ClubMemberPresence.Busy] = true,
}
local statusIcon = {
	[Enum.ClubMemberPresence.Away] = "|T"..FRIENDS_TEXTURE_AFK..":16:16:-8:-1:32:32|t",
	[Enum.ClubMemberPresence.Busy] = "|T"..FRIENDS_TEXTURE_DND..":16:16:-8:-1:32:32|t",
}

-- 직업 ID → 직업 키("WARRIOR" 등) 캐시
local classFileCache = {}
local function GetClassFile(classID)
	if not classID then return "" end
	local classFile = classFileCache[classID]
	if not classFile then
		local classInfo = C_CreatureInfo.GetClassInfo(classID)
		classFile = classInfo and classInfo.classFile or ""
		classFileCache[classID] = classFile
	end
	return classFile
end

-- 길드 클럽 ID. 클럽 데이터가 준비되기 전이나 채팅 잠금(보스전 등) 중에는 nil.
-- 채팅 잠금 중에는 C_Club 함수들이 secret 값을 돌려주므로 읽지 않는다.
local function GetGuildClubId()
	if C_ChatInfo.InChatMessagingLockdown() then return end
	return C_Club.GetGuildClubId()
end

-- 길드원 정보를 하나씩 넘겨준다. 성공하면 전체 인원을 돌려준다.
local function ForEachMember(callback)
	local clubId = GetGuildClubId()
	if not clubId then return end
	local memberIds = C_Club.GetClubMembers(clubId) or {}
	for _, memberId in ipairs(memberIds) do
		local m = C_Club.GetMemberInfo(clubId, memberId)
		if m and m.name then callback(m) end
	end
	return #memberIds
end

-- 접속 중인 길드원 목록 (툴팁, 메뉴용). 성공하면 접속 인원, 전체 인원을 돌려준다.
local guildTable = {}
local function BuildGuildTable()
	wipe(guildTable)
	local total = ForEachMember(function(m)
		if not inGamePresence[m.presence] then return end
		-- 파티원은 회색 *, 본인은 초록 *
		local flag = ""
		if m.isSelf then
			flag = "|cff00FF00*|r"
		elseif UnitInParty(m.name) or UnitInRaid(m.name) then
			flag = "|cffaaaaaa*|r"
		end
		guildTable[#guildTable + 1] = {
			name = m.name,
			rank = m.guildRank or "",
			rankOrder = m.guildRankOrder or 0,
			level = m.level or 0,
			zone = m.zone or "",
			note = m.memberNote or "",
			officerNote = m.officerNote or "",
			status = statusIcon[m.presence] or " ",
			classFile = GetClassFile(m.classID),
			flag = flag,
			isSelf = m.isSelf,
		}
	end)
	if not total then return end

	-- Shift를 누르고 있으면 등급순, 아니면 선택한 정렬 기준
	local key = IsShiftKeyDown() and "rankOrder" or SortOption().key
	table.sort(guildTable, function(a, b) return a[key] < b[key] end)
	return #guildTable, total
end

-- 바의 접속 인원. 명단 갱신 이벤트가 연달아 와도 1초 뒤 한 번만 센다.
local textPending = false
local function UpdateText()
	textPending = false
	if not IsInGuild() then
		Text:SetText(F.Label(L["No Guild"]))
		return
	end

	local online = 0
	local total = ForEachMember(function(m)
		if inGamePresence[m.presence] then online = online + 1 end
	end)
	if total then
		Text:SetText(F.Label(GUILD).." "..online)
	end
end

local function ScheduleTextUpdate()
	if textPending then return end
	textPending = true
	C_Timer.After(1, UpdateText)
end

local function Update(self, event, ...)
	if event == "CHAT_MSG_SYSTEM" then
		-- 접속/접속 해제 메시지일 때만 명단 갱신을 요청한다. 접속 상태 변화는 명단을 자동으로 갱신하지 않는다.
		-- 채팅 잠금 중에는 메시지가 secret 값일 수 있어 문자열 검색을 하지 않는다.
		local message = ...
		if IsInGuild() and not issecretvalue(message)
			and (string.find(message, friendOnline, 1, true) or string.find(message, friendOffline, 1, true)) then
			C_GuildInfo.GuildRoster()
		end
		return
	end

	if event == "PLAYER_ENTERING_WORLD" and IsInGuild() then
		C_GuildInfo.GuildRoster()
	end
	ScheduleTextUpdate()
end

-- 좌클릭: 길드 및 커뮤니티 창 (J 키와 같음)
Stat:SetScript("OnMouseDown", function(self, btn)
	if btn == "LeftButton" and IsInGuild() then
		ToggleGuildFrame()
	end
end)

-- 우클릭: 초대/귓속말/정렬 메뉴
Stat:SetScript("OnMouseUp", function(self, btn)
	GameTooltip:Hide()
	if btn ~= "RightButton" or not IsInGuild() or InCombatLockdown() then return end
	BuildGuildTable()

	MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
		rootDescription:CreateTitle(OPTIONS_MENU)

		local inviteMenu = rootDescription:CreateButton(INVITE)
		local whisperMenu = rootDescription:CreateButton(CHAT_MSG_WHISPER_INFORM)
		local sortMenu = rootDescription:CreateButton(L["Sorting"])

		-- 본인을 뺀 접속 중인 길드원
		for _, info in ipairs(guildTable) do
			if not info.isSelf then
				local levelc = GetQuestDifficultyColor(info.level)
				local classc = CLASS_COLORS[info.classFile] or HIGHLIGHT_FONT_COLOR
				local nameText = F.Hex(levelc)..info.level.."|r "..F.Hex(classc)..info.name.."|r"
				local grouped = UnitInParty(info.name) or UnitInRaid(info.name)

				whisperMenu:CreateButton(nameText..(grouped and "|cffaaaaaa*|r" or ""), function()
					SetItemRef("player:"..info.name, ("|Hplayer:%1$s|h[%1$s]|h"):format(info.name), "LeftButton")
				end)

				-- 이미 파티, 공격대에 있으면 초대 목록에서 뺀다
				if not grouped then
					inviteMenu:CreateButton(nameText, function()
						C_PartyInfo.InviteUnit(info.name)
					end)
				end
			end
		end

		for i, option in ipairs(sortOptions) do
			sortMenu:CreateButton(option.label, function()
				diminfo.Sort = i
			end)
		end

		rootDescription:CreateButton(GUILD_AND_COMMUNITIES, ToggleGuildFrame)
	end)
end)

-- 툴팁: 접속 중인 길드원 목록
Stat:SetScript("OnEnter", function(self)
	if not IsInGuild() then return end

	C_GuildInfo.GuildRoster()
	local online, total = BuildGuildTable()
	if not online then return end

	local clubId = GetGuildClubId()
	local clubInfo = clubId and C_Club.GetClubInfo(clubId)
	local selfInfo = clubId and C_Club.GetMemberInfoForSelf(clubId)

	F.OpenTooltip(self)
	GameTooltip:AddDoubleLine(clubInfo and clubInfo.name or GUILD, format("%d/%d", online, total), 0, .6, 1, 0, .6, 1)
	GameTooltip:AddDoubleLine(RANK, selfInfo and selfInfo.guildRank or "")

	-- 길드 공지
	local motd = C_GuildInfo.GetMOTD()
	if motd ~= "" then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(GUILD_MOTD, tthead.r, tthead.g, tthead.b)
		GameTooltip:AddLine(motd, ttsubh.r, ttsubh.g, ttsubh.b, true)
	end
	GameTooltip:AddLine(" ")

	local myZone = GetRealZoneText()
	local shift = IsShiftKeyDown()
	for i, info in ipairs(guildTable) do
		-- 최대 MAX_SHOWN명까지만 표시하고, 나머지는 인원 수만 알려 준다
		if i > MAX_SHOWN then
			GameTooltip:AddLine(format("%s %d", FRIENDS_LIST_ONLINE, #guildTable - MAX_SHOWN), ttsubh.r, ttsubh.g, ttsubh.b)
			break
		end

		local zonec = (myZone == info.zone) and activezone or inactivezone
		local classc = CLASS_COLORS[info.classFile] or HIGHLIGHT_FONT_COLOR
		local levelc = GetQuestDifficultyColor(info.level)

		if shift then
			-- Shift: 이름 - 등급, 메모, 관리자 메모
			GameTooltip:AddDoubleLine(info.name.." |cff999999-|cffffffff "..info.rank, info.zone, classc.r, classc.g, classc.b, zonec.r, zonec.g, zonec.b)
			if info.note ~= "" then
				GameTooltip:AddLine(format("|cff999999%s:|r %s", LABEL_NOTE, info.note), ttsubh.r, ttsubh.g, ttsubh.b, true)
			end
			if info.officerNote ~= "" then
				GameTooltip:AddLine(format("|cff999999%s:|r %s", GUILD_RANK1_DESC, info.officerNote), ttoff.r, ttoff.g, ttoff.b, true)
			end
		else
			GameTooltip:AddDoubleLine(F.Hex(levelc)..info.level.."|r "..info.name.." "..info.flag.." "..info.status, info.zone, classc.r, classc.g, classc.b, zonec.r, zonec.g, zonec.b)
		end
	end

	F.AddFooter(L["Sorting by:"].."|cff55ff55"..SortOption().label)
	GameTooltip:Show()
end)

Stat:RegisterEvent("PLAYER_ENTERING_WORLD")
Stat:RegisterEvent("GUILD_ROSTER_UPDATE")
Stat:RegisterEvent("PLAYER_GUILD_UPDATE")
Stat:RegisterEvent("CHAT_MSG_SYSTEM")
Stat:SetScript("OnEvent", Update)
