local addon, ns = ...
local C, F, G = unpack(ns)
local panel = CreateFrame("Frame", nil, UIParent)

if not C.Guild then return end
	-- localized references for global functions (about 50% faster)
	local format		= string.format
	local gsub			= string.gsub
	local sort			= table.sort
	local ceil			= math.ceil

	local tthead, ttsubh, ttoff = {r = 0.4, g = 0.78, b = 1}, {r = .75, g = .9, b = 1}, {r = .3, g = 1, b = .3}
	local activezone, inactivezone = {r = 0.3, g = 1.0, b = 0.3}, {r = .65, g = .65, b = .65}
	--local guildInfoString = "%s [%d]"
	local guildMotDString = "%s |cffaaaaaa- |cffffffff%s"
	local levelNameString = "|cff%02x%02x%02x%d|r |cff%02x%02x%02x%s|r %s"
	local levelNameStatusString = "|cff%02x%02x%02x%d|r %s %s %s"
	local nameRankString = "%s |cff999999-|cffffffff %s"
	local friendOnline, friendOffline = gsub(ERR_FRIEND_ONLINE_SS, "\124Hplayer:%%s\124h%[%%s%]\124h",""), gsub(ERR_FRIEND_OFFLINE_S, "%%s", "")
	local guildTable, guildMotD = {}, ""
	local MAX_SHOWN = 39	-- 툴팁에 표시할 최대 길드원 수 (기존 동작과 같은 39명)

	-- make addon frame anchor-able
	local Stat = CreateFrame("Frame", "diminfo_Guild")
	Stat:EnableMouse(true)
	Stat:SetFrameStrata("BACKGROUND")
	Stat:SetFrameLevel(3)

	-- setup text
	local Text  = panel:CreateFontString(nil, "OVERLAY")
	Text:SetFont(G.Fonts, G.FontSize, G.FontFlag)
	Text:SetPoint(unpack(C.GuildPoint))
	Stat:SetAllPoints(Text)

	local sort_array = {
		[1] = {1, NAME},
		[2] = {10, RANK},
		[3] = {3, LEVEL},
		[4] = {4, ZONE},
		[5] = {9, CLASS}
	}

	local function RequestGuildRoster()
		C_GuildInfo.GuildRoster()
	end

	-- 직업 ID → 직업 파일명("WARRIOR" 등) 캐시. RAID_CLASS_COLORS 키로 쓴다.
	local classFileCache = {}
	local function GetClassFile(classID)
		if not classID then return end
		local classFile = classFileCache[classID]
		if not classFile then
			local classInfo = C_CreatureInfo.GetClassInfo(classID)
			classFile = classInfo and classInfo.classFile
			classFileCache[classID] = classFile
		end
		return classFile
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

	-- 길드 클럽 ID. 클럽 데이터가 준비되기 전이나 채팅 잠금(보스전 등) 중에는 nil.
	-- 채팅 잠금 중에는 C_Club 함수들이 secret 값을 돌려주므로 읽지 않는다.
	local function GetGuildClubId()
		if C_ChatInfo.InChatMessagingLockdown() then return end
		return C_Club.GetGuildClubId()
	end

	-- sort by/排序
	local function SortGuildTable(shift)
		sort(guildTable, function(a, b)
			if a and b then
				if shift then
					return a[10] < b[10]
				else
					return a[C.Sortingby] < b[C.Sortingby]
				end
			end
		end)
	end

	-- 접속 중인 길드원 목록(guildTable)을 만든다. 성공하면 접속 인원, 전체 인원을 돌려준다.
	-- guildTable 항목: { 이름, 등급, 레벨, 지역, 메모, 관리자 메모, 접속, 상태 아이콘, 직업 파일명, 등급 순서, 파티 표시, 본인 여부 }
	local function BuildGuildTable()
		local clubId = GetGuildClubId()
		if not clubId then return end

		wipe(guildTable)
		local memberIds = C_Club.GetClubMembers(clubId) or {}
		local count = 0
		for _, memberId in ipairs(memberIds) do
			local m = C_Club.GetMemberInfo(clubId, memberId)
			if m and m.name and inGamePresence[m.presence] then
				local name = m.name
				-- 파티원은 회색 *, 본인은 초록 *
				local flag = ""
				if m.isSelf then
					flag = "|cff00FF00*|r"
				elseif UnitInParty(name) or UnitInRaid(name) then
					flag = "|cffaaaaaa*|r"
				end

				count = count + 1
				guildTable[count] = { name, m.guildRank or "", m.level or 0, m.zone or "", m.memberNote or "", m.officerNote or "",
					true, statusIcon[m.presence] or " ", GetClassFile(m.classID) or "", m.guildRankOrder or 0, flag, m.isSelf }
			end
		end
		SortGuildTable(IsShiftKeyDown())
		return count, #memberIds
	end

	-- guild daily massage/公會每日訊息
	local function UpdateGuildMessage()
		guildMotD = C_GuildInfo.GetMOTD()
	end


	local function Update(self, event, ...)
		if not sort_array[diminfo.Sort] then diminfo.Sort = 5 end
		C.Sortingby = sort_array[diminfo.Sort][1]

		if IsInGuild() then
			-- special handler to request guild roster updates when guild members come online or go
			-- offline, since this does not automatically trigger the GuildRoster update from the server
			-- 접속/접속 해제 메시지일 때만 명단 갱신을 요청한다. 다른 시스템 메시지는 무시한다.
			if event == "CHAT_MSG_SYSTEM" then
				local message = ...
				-- 채팅 잠금 중에는 메시지가 secret 값일 수 있어 문자열 검색을 하지 않는다
				if not issecretvalue(message) and (string.find(message, friendOnline, 1, true) or string.find(message, friendOffline, 1, true)) then
					RequestGuildRoster()
				end
				return
			end

			if event == "GUILD_MOTD" then
				UpdateGuildMessage()
				return
			end

			-- 캐릭터가 세계에 접속했을 때
			if event == "PLAYER_ENTERING_WORLD" then
				if IsInGuild() then
					-- 1. 최신 API를 사용하여 커뮤니티(길드) UI 로드 여부 확인 및 로드
					if not C_AddOns.IsAddOnLoaded("Blizzard_Communities") then
						C_AddOns.LoadAddOn("Blizzard_Communities")
					end
					
					-- 2. 길드 메시지 업데이트 함수 호출
					-- (UpdateGuildMessage가 사용자 정의 함수라면 그대로 유지)
					if type(UpdateGuildMessage) == "function" then
						UpdateGuildMessage()
					end
				end
			end

			-- an event occured that could change the guild roster, so request update,
			-- and wait for guild roster update to occur
			if event ~= "GUILD_ROSTER_UPDATE" and event~="PLAYER_GUILD_UPDATE" then
				RequestGuildRoster()
				return
			end

			local online = BuildGuildTable()
			if online then
				Text:SetText(format(C.ClassColor and F.Hex(G.Ccolors)..GUILD.." |r".."%d" or GUILD.." %d", online))
			end
			else
			Text:SetText(C.ClassColor and F.Hex(G.Ccolors)..infoL["No Guild"] or infoL["No Guild"])
		end
	end

	local function whisperClick(self,arg1,arg2,checked)
		SetItemRef( "player:"..arg1, ("|Hplayer:%1$s|h[%1$s]|h"):format(arg1), "LeftButton" )
	end

	local function sortingClick(self,arg1,arg2,checked)
		C.Sortingby = arg1
		diminfo.Sort = arg2
	end

	local function ToggleGuildFrame()
		if IsInGuild() then
			-- 1. 최신 API를 사용하여 길드/커뮤니티 애드온 로드
			if not C_AddOns.IsAddOnLoaded("Blizzard_Communities") then
				C_AddOns.LoadAddOn("Blizzard_Communities")
			end
			
			-- 2. 길드 창 토글 (과거 ToggleFriendsFrame, 3 방식의 최신 대응)
			-- 보통 J키를 눌렀을 때 나오는 '길드 및 커뮤니티' 창을 엽니다.
			if CommunitiesFrame then
				ToggleCommunitiesFrame()
			else
				-- 클래식이나 구형 UI 구조를 유지하는 경우를 위한 백업
				securecall(ToggleFriendsFrame, 3)
			end
		end
	end

	-- click function
	Stat:SetScript("OnMouseUp", function(self, btn)
		GameTooltip:Hide()
		if btn ~= "RightButton" or not IsInGuild() then return end
		if InCombatLockdown() then return end

		-- 메뉴 생성 시작
		MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
			-- 1. 타이틀
			rootDescription:CreateTitle(OPTIONS_MENU)

			-- 서브메뉴 헤더 생성
			local inviteMenu = rootDescription:CreateButton(INVITE)
			local whisperMenu = rootDescription:CreateButton(CHAT_MSG_WHISPER_INFORM)
			local sortMenu = rootDescription:CreateButton(infoL["Sorting"])

			-- 길드원 데이터 처리 루프
			for i = 1, #guildTable do
				local info = guildTable[i]
				-- 온라인 상태(info[7]) 및 본인(info[12]) 제외
				if info[7] and not info[12] then
					local classc = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[info[9]] or HIGHLIGHT_FONT_COLOR
					local levelc = GetQuestDifficultyColor(tonumber(info[3]))
					
					-- 이름 텍스트 생성
					local nameText = format(levelNameString, levelc.r*255, levelc.g*255, levelc.b*255, info[3], classc.r*255, classc.g*255, classc.b*255, info[1], "")

					-- [귓속말 메뉴]
					local grouped = (UnitInParty(info[1]) or UnitInRaid(info[1])) and "|cffaaaaaa*|r" or ""
					whisperMenu:CreateButton(nameText .. grouped, function()
						whisperClick(nil, info[1])
					end)

					-- [초대 메뉴] (파티 중이 아닐 때만)
					if not (UnitInParty(info[1]) or UnitInRaid(info[1])) then
						inviteMenu:CreateButton(nameText, function()
							C_PartyInfo.InviteUnit(info[1])
						end)
					end
				end
			end

			-- [정렬 메뉴]
			for i = 1, 5 do
				sortMenu:CreateButton(sort_array[i][2], function()
					sortingClick(nil, sort_array[i][1], i)
				end)
			end

			rootDescription:CreateButton(GUILD_AND_COMMUNITIES, function()
				ToggleGuildFrame()
			end)
		end)
	end)

	Stat:SetScript("OnMouseDown", function(self, btn)
		if btn ~= "LeftButton" then return end
		ToggleGuildFrame()
	end)

	-- tooltip setup: guild member list
	Stat:SetScript("OnEnter", function(self)
		if not IsInGuild() then return end

		RequestGuildRoster()
		local online, total = BuildGuildTable()
		if not online then return end

		local clubId = GetGuildClubId()
		local clubInfo = clubId and C_Club.GetClubInfo(clubId)
		local selfInfo = clubId and C_Club.GetMemberInfoForSelf(clubId)
		local guildName = clubInfo and clubInfo.name or GUILD
		local guildRank = selfInfo and selfInfo.guildRank or ""

		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, -10)
		GameTooltip:ClearLines()
		GameTooltip:AddDoubleLine(guildName, format("%d/%d", online, total),0,.6,1,0,.6,1)
		GameTooltip:AddDoubleLine(RANK, guildRank)
		--GameTooltip:AddLine(guildRank, unpack(tthead))

		--  guild daily massage/公會每日訊息
		local guildMotD = C_GuildInfo.GetMOTD()
		if guildMotD ~= "" then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(GUILD_MOTD, unpack(tthead))
			GameTooltip:AddLine(guildMotD, ttsubh.r, ttsubh.g, ttsubh.b, 2)
		end
		GameTooltip:AddLine(" ")

		local zonec, classc, levelc, info
		local shown = 0

		for i = 1, #guildTable do
			-- 최대 MAX_SHOWN명까지만 표시하고, 나머지는 인원 수만 알려 준다
			if shown >= MAX_SHOWN then
				GameTooltip:AddLine(format("%s %d", FRIENDS_LIST_ONLINE, #guildTable - shown), ttsubh.r, ttsubh.g, ttsubh.b)
				break
			end

			info = guildTable[i]
			if GetRealZoneText() == info[4] then
				zonec = activezone
				else
				zonec = inactivezone
			end
			classc, levelc = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[info[9]] or HIGHLIGHT_FONT_COLOR, GetQuestDifficultyColor(info[3])

			if IsShiftKeyDown() then
				GameTooltip:AddDoubleLine(format(nameRankString, info[1], info[2]), info[4], classc.r, classc.g, classc.b, zonec.r, zonec.g, zonec.b)
				if info[5] ~= "" then
					GameTooltip:AddLine(format(format("|cff999999%s:|r %s", LABEL_NOTE, info[5])), ttsubh.r, ttsubh.g, ttsubh.b, 1)
				end
				if info[6] ~= "" then
					GameTooltip:AddLine(format(format("|cff999999%s:|r %s", GUILD_RANK1_DESC, info[6])), ttoff.r, ttoff.g, ttoff.b, 1)
				end
			else
				GameTooltip:AddDoubleLine(format(levelNameStatusString, levelc.r*255, levelc.g*255, levelc.b*255, info[3], info[1], info[11], info[8]), info[4], classc.r,classc.g,classc.b, zonec.r,zonec.g,zonec.b)
			end
			shown = shown + 1
		end
		GameTooltip:AddDoubleLine(" ","--------------", 1, 1, 1, .5, .5, .5)
		GameTooltip:AddDoubleLine(" ",infoL["Sorting by:"].."|cff55ff55"..sort_array[diminfo.Sort][2], 1, 1, 1, .6, .8, 1)
		GameTooltip:Show()
	end)

	Stat:SetScript("OnLeave", function() GameTooltip:Hide() end)

	--Stat:RegisterEvent("GUILD_MEMBER_SHOW")
	Stat:RegisterEvent("PLAYER_ENTERING_WORLD")
	Stat:RegisterEvent("GUILD_ROSTER_UPDATE")
	Stat:RegisterEvent("PLAYER_GUILD_UPDATE")
	Stat:RegisterEvent("GUILD_MOTD")
	Stat:RegisterEvent("CHAT_MSG_SYSTEM")
	Stat:SetScript("OnEvent", Update)
