local addon, ns = ...
local C, F, G, L = unpack(ns)

if not C.Guild then return end

local Stat, Text = F.CreateStat("diminfo_Guild", C.GuildPoint, "Guild")

local CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
local MAX_SHOWN = 39			-- 툴팁에 표시할 최대 길드원 수
local FULL_SCAN_INTERVAL = 30	-- 명단 갱신 신호로 하는 전체 확인의 최소 간격(초)
local HOVER_COOLDOWN = 1		-- 마우스를 올렸을 때 하는 전체 확인의 쿨타임(초)
local RETRY_DELAY = 5			-- 길드 데이터를 읽을 수 없을 때 다시 시도하기까지(초)

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
-- 채팅 잠금 중에는 C_Club 함수와 이벤트 값이 secret 값일 수 있으므로 읽지 않는다.
local function GetGuildClubId()
	if C_ChatInfo.InChatMessagingLockdown() then return end
	return C_Club.GetGuildClubId()
end

----------------------------------------------------------------
-- 길드원 캐시
-- members[memberId] = 길드원 항목. 이벤트가 오면 해당 길드원만 고치고,
-- 전체 확인(FullScan)은 가끔(명단 갱신 신호, 최소 30초 간격)과 마우스를 올렸을 때(쿨타임 1초)만 한다.
----------------------------------------------------------------
local members = {}
local onlineCount, totalCount = 0, 0
local lastFullScan = 0	-- 마지막 전체 확인 시각(GetTime). 0이면 아직 데이터 없음

local function MakeEntry(m)
	return {
		name = m.name,
		rank = m.guildRank or "",
		rankOrder = m.guildRankOrder or 0,
		level = m.level or 0,
		zone = m.zone or "",
		note = m.memberNote or "",
		officerNote = m.officerNote or "",
		presence = m.presence,
		classFile = GetClassFile(m.classID),
		isSelf = m.isSelf,
	}
end

-- 길드원 한 명의 항목을 바꾸고(nil이면 삭제) 인원 수를 맞춘다
local function SetMember(memberId, entry)
	local old = members[memberId]
	if old then
		totalCount = totalCount - 1
		if inGamePresence[old.presence] then onlineCount = onlineCount - 1 end
	end
	members[memberId] = entry
	if entry then
		totalCount = totalCount + 1
		if inGamePresence[entry.presence] then onlineCount = onlineCount + 1 end
	end
end

-- 길드원 한 명을 C_Club에서 다시 읽는다
local function RefreshMember(clubId, memberId)
	local m = C_Club.GetMemberInfo(clubId, memberId)
	SetMember(memberId, (m and m.name) and MakeEntry(m) or nil)
end

-- 전체 확인: 길드원 전원을 다시 읽는다. 길드 데이터를 읽을 수 없으면 false
local function FullScan()
	local clubId = GetGuildClubId()
	if not clubId then return false end

	wipe(members)
	onlineCount, totalCount = 0, 0
	for _, memberId in ipairs(C_Club.GetClubMembers(clubId) or {}) do
		RefreshMember(clubId, memberId)
	end
	lastFullScan = GetTime()
	return true
end

local function ClearMembers()
	wipe(members)
	onlineCount, totalCount = 0, 0
	lastFullScan = 0
end

----------------------------------------------------------------
-- 바 글자
----------------------------------------------------------------
local function UpdateText()
	if not IsInGuild() then
		F.SetText(Text, F.Label(L["No Guild"]))
	elseif lastFullScan > 0 then
		F.SetText(Text, F.Label(GUILD).." "..onlineCount)
	end
end

----------------------------------------------------------------
-- 전체 확인 예약
-- 명단 갱신 신호가 와도 마지막 전체 확인 후 30초가 지나야 실행한다. 그 전이면 30초가 되는 시점으로 미룬다.
-- 전투 중에는 전투가 끝날 때까지, 길드 데이터를 읽을 수 없으면 5초 뒤로 미룬다.
----------------------------------------------------------------
local scanTimer
local scanAfterCombat = false

local function RequestFullScan(immediate)
	if not IsInGuild() then return end
	if scanTimer and not immediate then return end

	local wait = immediate and 0 or (FULL_SCAN_INTERVAL - (GetTime() - lastFullScan))
	if wait > 0 then
		scanTimer = C_Timer.NewTimer(wait, function()
			scanTimer = nil
			RequestFullScan()
		end)
		return
	end

	if InCombatLockdown() then
		scanAfterCombat = true
		return
	end

	if scanTimer then
		scanTimer:Cancel()
		scanTimer = nil
	end
	if FullScan() then
		UpdateText()
	else
		scanTimer = C_Timer.NewTimer(RETRY_DELAY, function()
			scanTimer = nil
			RequestFullScan(true)
		end)
	end
end

----------------------------------------------------------------
-- 툴팁, 메뉴용 목록: 접속 중인 길드원을 정렬해서 돌려준다
-- 마우스를 올렸을 때는 즉시 전체 확인을 한다(쿨타임 1초).
----------------------------------------------------------------
local onlineList = {}
local function BuildOnlineList()
	if GetTime() - lastFullScan >= HOVER_COOLDOWN then
		if not FullScan() then return end
		UpdateText()
	end

	wipe(onlineList)
	for _, entry in pairs(members) do
		if inGamePresence[entry.presence] then
			onlineList[#onlineList + 1] = entry
		end
	end

	-- Shift를 누르고 있으면 등급순, 아니면 선택한 정렬 기준
	local key = IsShiftKeyDown() and "rankOrder" or SortOption().key
	table.sort(onlineList, function(a, b) return a[key] < b[key] end)
	return #onlineList, totalCount
end

-- 파티원은 회색 *, 본인은 초록 *
local function GroupFlag(entry)
	if entry.isSelf then
		return "|cff00FF00*|r"
	elseif UnitInParty(entry.name) or UnitInRaid(entry.name) then
		return "|cffaaaaaa*|r"
	end
	return ""
end

----------------------------------------------------------------
-- 이벤트
----------------------------------------------------------------
local function OnEvent(self, event, ...)
	if event == "CLUB_MEMBER_PRESENCE_UPDATED" or event == "CLUB_MEMBER_ADDED"
		or event == "CLUB_MEMBER_UPDATED" or event == "CLUB_MEMBER_REMOVED" then
		-- 길드원 한 명의 변화: 그 길드원만 고친다
		local guildClubId = GetGuildClubId()
		if not guildClubId then
			-- 채팅 잠금 중에는 이벤트 값을 믿을 수 없으므로 나중에 전체 확인으로 맞춘다
			if C_ChatInfo.InChatMessagingLockdown() then RequestFullScan() end
			return
		end

		local clubId, memberId, presence = ...
		if clubId ~= guildClubId or lastFullScan == 0 then return end

		if event == "CLUB_MEMBER_REMOVED" then
			SetMember(memberId, nil)
		elseif event == "CLUB_MEMBER_PRESENCE_UPDATED" and members[memberId] then
			local entry = members[memberId]
			SetMember(memberId, nil)
			entry.presence = presence
			SetMember(memberId, entry)
		else
			RefreshMember(clubId, memberId)
		end
		UpdateText()

	elseif event == "CLUB_MEMBERS_UPDATED" then
		-- 여러 명이 한꺼번에 바뀜: 전체 확인 예약
		local clubId = ...
		local guildClubId = GetGuildClubId()
		if not guildClubId or clubId == guildClubId then
			RequestFullScan()
		end

	elseif event == "GUILD_ROSTER_UPDATE" then
		-- 누가 바뀌었는지 알 수 없는 갱신 신호: 전체 확인 예약(최소 30초 간격)
		RequestFullScan()

	elseif event == "PLAYER_GUILD_UPDATE" then
		-- 길드 가입, 탈퇴: 바로 다시 확인한다
		if IsInGuild() then
			RequestFullScan(true)
		else
			ClearMembers()
		end
		UpdateText()

	elseif event == "PLAYER_ENTERING_WORLD" then
		if IsInGuild() then
			C_GuildInfo.GuildRoster()
			if lastFullScan == 0 then RequestFullScan(true) end
		end
		UpdateText()

	elseif event == "PLAYER_REGEN_ENABLED" then
		-- 전투 중에 미룬 전체 확인 실행
		if scanAfterCombat then
			scanAfterCombat = false
			RequestFullScan(true)
		end

	elseif event == "CHAT_MSG_SYSTEM" then
		-- 접속/접속 해제 메시지면 서버에 명단 갱신을 요청한다.
		-- 채팅 잠금 중에는 메시지가 secret 값일 수 있어 문자열 검색을 하지 않는다.
		local message = ...
		if IsInGuild() and not issecretvalue(message)
			and (string.find(message, friendOnline, 1, true) or string.find(message, friendOffline, 1, true)) then
			C_GuildInfo.GuildRoster()
		end
	end
end

----------------------------------------------------------------
-- 마우스 동작
----------------------------------------------------------------

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
	if not BuildOnlineList() then return end

	MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
		rootDescription:CreateTitle(OPTIONS_MENU)

		local inviteMenu = rootDescription:CreateButton(INVITE)
		local whisperMenu = rootDescription:CreateButton(CHAT_MSG_WHISPER_INFORM)
		local sortMenu = rootDescription:CreateButton(L["Sorting"])

		-- 본인을 뺀 접속 중인 길드원
		for _, info in ipairs(onlineList) do
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

	-- 서버에 최신 명단을 요청하고(응답은 GUILD_ROSTER_UPDATE), 지금 가진 데이터로 즉시 전체 확인
	C_GuildInfo.GuildRoster()
	local online, total = BuildOnlineList()
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
	for i, info in ipairs(onlineList) do
		-- 최대 MAX_SHOWN명까지만 표시하고, 나머지는 인원 수만 알려 준다
		if i > MAX_SHOWN then
			GameTooltip:AddLine(format("%s %d", FRIENDS_LIST_ONLINE, #onlineList - MAX_SHOWN), ttsubh.r, ttsubh.g, ttsubh.b)
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
			GameTooltip:AddDoubleLine(F.Hex(levelc)..info.level.."|r "..info.name.." "..GroupFlag(info).." "..(statusIcon[info.presence] or " "), info.zone, classc.r, classc.g, classc.b, zonec.r, zonec.g, zonec.b)
		end
	end

	F.AddFooter(L["Sorting by:"].."|cff55ff55"..SortOption().label)
	GameTooltip:Show()
end)

Stat:RegisterEvent("PLAYER_ENTERING_WORLD")
Stat:RegisterEvent("PLAYER_GUILD_UPDATE")
Stat:RegisterEvent("PLAYER_REGEN_ENABLED")
Stat:RegisterEvent("GUILD_ROSTER_UPDATE")
Stat:RegisterEvent("CLUB_MEMBERS_UPDATED")
Stat:RegisterEvent("CLUB_MEMBER_PRESENCE_UPDATED")
Stat:RegisterEvent("CLUB_MEMBER_ADDED")
Stat:RegisterEvent("CLUB_MEMBER_REMOVED")
Stat:RegisterEvent("CLUB_MEMBER_UPDATED")
Stat:RegisterEvent("CHAT_MSG_SYSTEM")
Stat:SetScript("OnEvent", OnEvent)

-- 설정 창에서 값이 바뀌면 바 글자를 다시 그린다 (API.lua F.ApplySettings)
Stat.Refresh = function() UpdateText() end
