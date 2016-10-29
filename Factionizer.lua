----------------------------------------------------------
-- Factionizer, a reputation management tool  --
-------------------------------------------------------
---------------------------
-- _00_ Variables Set up --
---------------------------

FIZ_ToExalted = {}
FIZ_ToExalted[0] = 84000;
FIZ_ToExalted[1] = 48000;	-- working on Hated -> Hostile, base offset 21k+12k+6k+3k+3k+3k
FIZ_ToExalted[2] = 45000;	-- working on Hostile -> Unfriendly, base offset 21k+12k+6k+3k+3k
FIZ_ToExalted[3] = 42000;	-- working on Unfriendly -> Neutral, base offset 21k+12k+6k+3k
FIZ_ToExalted[4] = 39000;	-- working on Neutral -> Friendly, base offset 21k+12k+6k
FIZ_ToExalted[5] = 33000;	-- working on Friendly -> Honored, base offset 21k+12k
FIZ_ToExalted[6] = 21000;	-- working on Honored -> Revered, base offset 21k
FIZ_ToExalted[7] = 0;	-- working on Revered -> Exalted, so no base offset
FIZ_ToExalted[8] = 0;	-- already at Exalted -> no offset

FIZ_ToBFF = {}	--> Friendship levels:
FIZ_ToBFF[0] = 42999;	--> 1 - Stranger: 0-8400
FIZ_ToBFF[1] = 42000;	--> 2 - Acquaintance: 8400-16800
FIZ_ToBFF[2] = 33600;	--> 3 - Buddy: 16800-25200
FIZ_ToBFF[3] = 25200;	--> 4 - Friend: 25200-33600
FIZ_ToBFF[4] = 16800;	--> 5 - Good Friend: 33600-42000
FIZ_ToBFF[5] = 8400;	--> 6 - Best Friend: 42000-42999

-- Addon constants
FIZ_NAME = "Factionizer"
FIZ_VNMBR = 70000	-- Number code for this version

-- Colours
FIZ_HELP_COLOUR = "|cFFFFFF7F"
FIZ_NEW_REP_COLOUR = "|cFF7F7FFF"
FIZ_NEW_STANDING_COLOUR = "|cFF6060C0"
FIZ_BAG_COLOUR = "|cFFC0FFC0"
FIZ_BAG_BANK_COLOUR = "|cFFFFFF7F"
FIZ_QUEST_COLOUR = "|cFFC0FFC0"
FIZ_HIGHLIGHT_COLOUR = "|cFF00FF00"
FIZ_QUEST_ACTIVE_COLOUR = "|cFFFF7F7F"
FIZ_LOWLIGHT_COLOUR = "|cFFFF3F3F"
FIZ_SUPPRESS_COLOUR = "|cFF7F7F7F"
--Profestions ggg
FIZ_LIMIT_TYPE_Herb = 1
FIZ_LIMIT_TYPE_Skin = 2
FIZ_LIMIT_TYPE_Mine = 3
FIZ_LIMIT_TYPE_Gather = 4
FIZ_LIMIT_TYPE_Engi = 5
FIZ_LIMIT_TYPE_Alch = 6
FIZ_LIMIT_TYPE_Blac = 7
FIZ_LIMIT_TYPE_Tail = 8
FIZ_LIMIT_TYPE_Leat = 9
FIZ_LIMIT_TYPE_Ench = 10
FIZ_LIMIT_TYPE_Jewe = 11
FIZ_LIMIT_TYPE_Incr = 12
FIZ_LIMIT_TYPE_Aid = 13
FIZ_LIMIT_TYPE_Arch = 14
FIZ_LIMIT_TYPE_Cook = 15
FIZ_LIMIT_TYPE_Fish = 16

FIZ_GUILD_CAP_BASE = 4375
FIZ_FLAG_GUILD_CAP = 1000


--------------------------
-- _01_ Addon Variables --
--------------------------

-- Stored data
FIZ_Data = {}   -- Data saved between sessions
-- Initialization
FIZ_Main = nil   -- Main program window
FIZ_InitComplete = nil
FIZ_VarsLoaded = nil
FIZ_InitStages = 0
FIZ_InitCount = 0
FIZ_difficultyID = 0
FIZ_UpdateRequest = nil
FIZ_UPDATE_INTERVAL = 5
-- Faction information
FIZ_FactionMapping = {}
FIZ_FactionGain = {}

-- Tracking data
FIZ_Entries = {}
-- Skill Tracking ggg
FIZ_Herb = false
FIZ_Skin = false
FIZ_Mine = false
FIZ_Jewel = false
FIZ_Cook = false
FIZ_Arch = false
FIZ_Fish = false
FIZ_Aid = false
FIZ_Black = false
FIZ_Tailor = false
FIZ_Leath = false
FIZ_Enchan = false
FIZ_Engin = false
FIZ_Incrip = false
FIZ_Alche = false
--- Race/Side/Difficulty
FIZ_IsHuman = false
FIZ_IsDeathKnight = false
FIZ_IsAlliance = false
FIZ_IsHorde = false
FIZ_IsHeroic=false
-- Guild Tracking
FIZ_GuildName = nil
-- Guild rep cap
-- FIZ_CapIndex = nil
-- FIZ_Tuesday = nil

------------------------
-- _02_ Addon Startup --
------------------------
------------------------------------------------------------
function FIZ_OnLoad(self)
	-- Events monitored by Event Handler
	FIZ_Main = self
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("VARIABLES_LOADED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_LOGIN")

	-- Slash commands for CLI
	SLASH_FIZ1 = "/factionizer"
	SLASH_FIZ2 = "/fz"
	SlashCmdList.FIZ = FIZ_SlashHandler

	FIZ_Orig_GetFactionInfo = GetFactionInfo;  -- api function
	GetFactionInfo = FIZ_GetFactionInfo;  -- api function

	FIZ_Orig_ReputationFrame_Update = ReputationFrame_Update -- rfl function
	ReputationFrame_Update = FIZ_ReputationFrame_Update -- rfl function

	FIZ_Orig_ReputationBar_OnClick = ReputationBar_OnClick -- rfl function
	ReputationBar_OnClick = FIZ_ReputationBar_OnClick -- rfl function

	FIZ_Orig_ExpandFactionHeader = ExpandFactionHeader
	ExpandFactionHeader = FIZ_ExpandFactionHeader

	FIZ_Orig_CollapseFactionHeader = CollapseFactionHeader
	CollapseFactionHeader = FIZ_CollapseFactionHeader

	--FIZ_Orig_ChatFrame_OnEvent = ChatFrame_OnEvent
	--ChatFrame_OnEvent = FIZ_ChatFrame_OnEvent

	FIZ_Orig_StandingText = ReputationFrameStandingLabel:GetText()
end

------------------------
-- _03_ Event Handler --
------------------------

function FIZ_OnEvent(self, event, ...)
	--- fpt	FIZ_Printtest("Event Handler ",tostring(Event),"")
	local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13 = ...
	if (event == "ADDON_LOADED") and (arg1 == FIZ_NAME) then
		FIZ_Main:UnregisterEvent("ADDON_LOADED")
		FIZ_InitStages = FIZ_InitStages + 1
		FIZ_Init()
	elseif (event == "VARIABLES_LOADED") then
		FIZ_OnShowOptionFrame()
		FIZ_VarsLoaded = true
		FIZ_InitStages = FIZ_InitStages + 2
		FIZ_Init()
	elseif (event == "PLAYER_LOGIN") then
		FIZ_Main:UnregisterEvent("PLAYER_LOGIN")
		--FIZ_DoInitialCollapse()
		FIZ_InitStages = FIZ_InitStages + 4
		FIZ_Init()
	elseif (event == "PLAYER_ENTERING_WORLD") then
		FIZ_InitStages = FIZ_InitStages + 8
		FIZ_Init()
		FIZ_Main:UnregisterEvent("PLAYER_ENTERING_WORLD")
		FIZ_Main:RegisterEvent("UPDATE_FACTION") --rfl
		FIZ_Main:RegisterEvent("LFG_BONUS_FACTION_ID_UPDATED") --rfl
		-- to keep item list up to date
		FIZ_Main:RegisterEvent("BAG_UPDATE")
		FIZ_Main:RegisterEvent("BANKFRAME_OPENED")
		FIZ_Main:RegisterEvent("BANKFRAME_CLOSED")
		-- to keep dungeon difficulty up to date
		FIZ_Main:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
		-- to keep list of known skills up to date
		FIZ_Main:RegisterEvent("CHAT_MSG_SKILL")
		FIZ_Main:RegisterEvent("CHAT_MSG_SPELL_TRADESKILLS")
		FIZ_Main:RegisterEvent("SKILL_LINES_CHANGED")
		FIZ_Main:RegisterEvent("UPDATE_TRADESKILL_RECAST")
		FIZ_Main:RegisterEvent("QUEST_COMPLETE")
		FIZ_Main:RegisterEvent("QUEST_WATCH_UPDATE")

		-- new chat hook system
		ChatFrame_AddMessageEventFilter("CHAT_MSG_COMBAT_FACTION_CHANGE", FIZ_ChatFilter)
		ChatFrame_AddMessageEventFilter("COMBAT_TEXT_UPDATE", FIZ_ChatFilter)

	elseif (event == "UPDATE_FACTION" or
	      	event == "QUEST_COMPLETE" or
	      	event == "QUEST_WATCH_UPDATE") then
-- rfl Event v
		if ( ReputationFrame:IsVisible() ) then
			ReputationFrame_Update(); -- rfl Event
		end
-- rfl event ^
		if ( FIZ_ReputationDetailFrame:IsVisible()) then
			FIZ_BuildUpdateList()
			FIZ_UpdateList_Update()
		end
		FIZ_DumpReputationChangesToChat()

	elseif ( event == "BAG_UPDATE") then
		if (FIZ_ReputationDetailFrame:IsVisible()) then
			-- Update rep frame (implicitely updates detail frame which In turn implicitely reparses bag contents)
			ReputationFrame_Update()
		end 

	elseif ( event == "BANKFRAME_OPENED") then
		FIZ_BankOpen = true

	elseif ( event == "BANKFRAME_CLOSED") then
		-- this is fired twice when closing the bank window, bank contents only available at the first Event
		if (FIZ_BankOpen) then
			-- this is the first call
			FIZ_ParseBankContent()
			FIZ_BankOpen = nil

			if (FIZ_ReputationDetailFrame:IsVisible()) then
				-- Update rep frame (implicitely updates detail frame which In turn implicitely reparses bag contents)
				ReputationFrame_Update()
			end
		end

	elseif ( event == "PLAYER_DIFFICULTY_CHANGED") then -- ccc
			FIZ_Print("PLAYER_DIFFICULTY_CHANGED", nil) 

	elseif ( event == "CHAT_MSG_SKILL") or
		( event == "CHAT_MSG_SPELL_TRADESKILLS") or
		( event == "SKILL_LINES_CHANGED") or
		( event == "UPDATE_TRADESKILL_RECAST") then
		FIZ_ExtractSkills()
		if ( ReputationFrame:IsVisible() ) then
			ReputationFrame_Update(); -- rfl Event
		end
		if ( FIZ_ReputationDetailFrame:IsVisible()) then
			FIZ_BuildUpdateList()
			FIZ_UpdateList_Update()
		end

	end

end

-------------------------------
function FIZ_OnUpdate(self)
	if not FIZ_UpdateRequest then return end
	if FIZ_InitComplete and FIZ_InitCount > 5 then return end
	if (GetTime() < FIZ_UpdateRequest) then return end

	if (FIZ_InitCount <= 5) then
		-- Guild level seems to only return a proper value a little later
		--FIZ_Print("update number "..tostring(FIZ_InitCount))
		FIZ_InitCount = FIZ_InitCount + 1
		FIZ_UpdateRequest = GetTime() + FIZ_UPDATE_INTERVAL
		if (FIZ_InitCount > 5) then
			FIZ_UpdateRequest = nil
			--FIZ_Print("Stopping updates")
		end
	end
end


-------------------------------
-- _04_ Addon Initialization --
-------------------------------
function FIZ_InitVariable(var, value)
	local result = 0
	if var == nil then return result end

	if (not FIZ_Data[var]) and (not FIZ_Data[var.."_inited"]) then
		-- this option is not Set, and has never been Set by default, do so and let the user know
		FIZ_Data[var] = value
		FIZ_Data[var.."_inited"] = true
		result = 1
	elseif (not FIZ_Data[var.."_inited"]) then
		-- the option is enabled, but not marked as inited, do so silently
		FIZ_Data[var.."_inited"] = true
	end

	return result
end

-------------------------------
function FIZ_Init()
	if FIZ_InitComplete then return end
	--FIZ_Print("FIZ_InitStages ["..tostring(FIZ_InitStages).."]")
	if (FIZ_InitStages ~= 15) then return end

	local version = GetAddOnMetadata("Factionizer", "Version");
	if (version == nil) then
		version = "unknown";
	end

	-- create data structures
	if not FIZ_Data then FIZ_Data = {} end
	if not FIZ_Data.OriginalCollapsed then FIZ_Data.OriginalCollapsed = {} end

	if FIZ_Data.ChatFrame == nil then FIZ_Data.ChatFrame = 0 end
	local changed = 0
	changed = changed + FIZ_InitVariable("ShowMobs", true)
	changed = changed + FIZ_InitVariable("ShowQuests", true)
	changed = changed + FIZ_InitVariable("ShowInstances", true)
	changed = changed + FIZ_InitVariable("ShowItems", true)
	changed = changed + FIZ_InitVariable("ShowGeneral", true)

	changed = changed + FIZ_InitVariable("ShowMissing", true)
	changed = changed + FIZ_InitVariable("ExtendDetails", true)
	changed = changed + FIZ_InitVariable("WriteChatMessage", true)
	changed = changed + FIZ_InitVariable("NoGuildGain", true)
	changed = changed + FIZ_InitVariable("SuppressOriginalChat", true)
	changed = changed + FIZ_InitVariable("ShowPreviewRep", true)
	changed = changed + FIZ_InitVariable("SwitchFactionBar", true)
	changed = changed + FIZ_InitVariable("SilentSwitch", true)
	changed = changed + FIZ_InitVariable("NoGuildSwitch", true)
	if (changed > 0) then
		StaticPopupDialogs["FIZ_CONFIG_CHANGED"] = {
			text = FIZ_TXT.configQuestion,
			button1 = FIZ_TXT.showConfig,
			button2 = FIZ_TXT.later,
			OnAccept = function()
					FIZ_ToggleConfigWindow();				--- f_tcw
				end,
			--OnCancel = function()
			--	FIZ_Print(GLDG_Data.colours.help..GLDG_NAME..":|cFFFF0000 "..GLDG_TXT.reload)
			--	end,
			timeout = 0,
			whileDead = 1,
			hideOnEscape = 1,
			sound = "igQuestFailed",
		};
		StaticPopup_Show("FIZ_CONFIG_CHANGED");
	end

	-- keep version In configuration file
	FIZ_Data.Version = FIZ_VNMBR

	-- Set up UI
	FIZ_OptionsButtonText:SetText(FIZ_TXT.options)
	FIZ_OptionsFrameTitle:SetText(FIZ_NAME.." "..FIZ_TXT.options)

	FIZ_EnableMissingBoxText:SetText(FIZ_TXT.showMissing)
	FIZ_ExtendDetailsBoxText:SetText(FIZ_TXT.extendDetails)
	FIZ_GainToChatBoxText:SetText(FIZ_TXT.gainToChat)
	FIZ_NoGuildGainBoxText:SetText(FIZ_TXT.noGuildGain)
	FIZ_SupressOriginalGainBoxText:SetText(FIZ_TXT.suppressOriginalGain)
	FIZ_ShowPreviewRepBoxText:SetText(FIZ_TXT.showPreviewRep)
	FIZ_SwitchFactionBarBoxText:SetText(FIZ_TXT.switchFactionBar)
	FIZ_NoGuildSwitchBoxText:SetText(FIZ_TXT.noGuildSwitch)
	FIZ_SilentSwitchBoxText:SetText(FIZ_TXT.silentSwitch)
	FIZ_OrderByStandingCheckBoxText:SetText(FIZ_TXT.orderByStanding)

	---	FIZ_OnShowOptionFrame()
	FIZ_ExtractSkills()

	local _, race = UnitRace("player")
	local faction, locFaction = UnitFactionGroup("player")
	local class, enClass = UnitClass("player")
	FIZ_Player = UnitName("player")
	FIZ_Realm = GetRealmName()	--	FIZ_Realm = GetCVar("realmName")
	-- gci	FIZ_CapIndex = FIZ_Realm.." - "..FIZ_Player

	if (IsInGuild()) then
		if (FIZ_GuildName == nil or FIZ_GuildName == "") then FIZ_GuildName = GetGuildInfo("player") end
	end

	if (race and faction and locFaction and FIZ_Player and FIZ_Realm) then
		if (race == "Human") then
			FIZ_IsHuman = true
		end

		if enClass and enClass == "DEATHKNIGHT" then
			FIZ_IsDeathKnight = true
		end

		if (faction == FACTION_ALLIANCE) or (locFaction == FACTION_ALLIANCE) then
			FIZ_IsAlliance = true
		end

		if (faction == FACTION_HORDE) or (locFaction == FACTION_HORDE) then
			FIZ_IsHorde = true
		end

		FIZ_InitFactor(FIZ_IsHuman)

		-- Initialize Faction information
		local locale = GetLocale()
		FIZ_InitFactionMap(locale, FIZ_GuildName)
		-- Changed by Bagdad for easy reputation content moderation
		FIZ_FactionGain = {}
		FIZ_InitEnFactionGains(FIZ_GuildName, FIZ_GUILD_CAP_BASE)
		FIZ_DumpReputationChangesToChat(true)

		FIZ_InitComplete = true
		if (FIZ_InitCount <= 5) then
			FIZ_UpdateRequest = GetTime() + FIZ_UPDATE_INTERVAL
			--FIZ_Print("Init complete, setting up updates ("..tostring(FIZ_InitCount).." already done)")
		--else
			--FIZ_Print("Init complete, not starting updates")
		end

	end
end

------------------------
-- _05_ Slash Handler --
------------------------

function FIZ_SlashHandler(msg)
	if not msg then
		return
	else
		local msgLower = string.lower(msg)
		local words = FIZ_GetWords(msg)
		local wordsLower = FIZ_GetWords(msgLower)
		local size = FIZ_TableSize(wordsLower)
		local FD_SH = FIZ_Data

		if (size>0) then
			if (wordsLower[0]=="enable") then
				if (size>1) then
					if (wordsLower[1]=="mobs") then
						FD_SH.ShowMobs = true
					elseif (wordsLower[1]=="quests") then
						FD_SH.ShowQuests = true
					elseif (wordsLower[1]=="dungeons" or wordsLower[1]=="instances") then
						FD_SH.ShowInstances = true
					elseif (wordsLower[1]=="items") then
						FD_SH.ShowItems = true
					elseif (wordsLower[1]=="general") then
						FD_SH.ShowGeneral = true
					elseif (wordsLower[1]=="missing") then
						FD_SH.ShowMissing = true
					elseif (wordsLower[1]=="details") then
						FD_SH.ExtendDetails = true
					elseif (wordsLower[1]=="chat") then
						FD_SH.WriteChatMessage = true
						FD_SH.NoGuildGain = false
					elseif (wordsLower[1]=="suppress") then
						FD_SH.SuppressOriginalChat = true
					elseif (wordsLower[1]=="preview") then
						FD_SH.ShowPreviewRep = true
					elseif (wordsLower[1]=="bar") then
						FD_SH.SwitchFactionBar = true
						FD_SH.NoGuildSwitch = false
						FD_SH.SilentSwitch = false
					elseif (wordsLower[1]=="all") then
						FD_SH.ShowMobs = true
						FD_SH.ShowQuests = true
						FD_SH.ShowInstances = true
						FD_SH.ShowItems = true
						FD_SH.ShowGeneral = true
						FD_SH.ShowMissing = true
						FD_SH.ExtendDetails = true
						FD_SH.WriteChatMessage = true
						FD_SH.NoGuildGain = false
						FD_SH.SuppressOriginalChat = true
						FD_SH.ShowPreviewRep = true
						FD_SH.SwitchFactionBar = true
						FD_SH.NoGuildSwitch = false
						FD_SH.SilentSwitch = false
					else
						FIZ_PrintSlash(FIZ_TXT.command,msgLower)
					end

					if ( ReputationFrame:IsVisible() ) then
						ReputationFrame_Update(); -- rfl Event
					end
					if ( FIZ_ReputationDetailFrame:IsVisible()) then
						FIZ_BuildUpdateList()
						FIZ_UpdateList_Update()
					end
				else
						FIZ_PrintSlash(FIZ_TXT.command,msgLower)
				end
			elseif (wordsLower[0]=="disable") then
				if (size>1) then
					if (wordsLower[1]=="mobs") then
						FD_SH.ShowMobs = false
					elseif (wordsLower[1]=="quests") then
						FD_SH.ShowQuests = false
					elseif (wordsLower[1]=="dungeons" or wordsLower[1]=="instances") then
						FD_SH.ShowInstances = false
					elseif (wordsLower[1]=="items") then
						FD_SH.ShowItems = false
					elseif (wordsLower[1]=="general") then
						FD_SH.ShowGeneral = false
					elseif (wordsLower[1]=="missing") then
						FD_SH.ShowMissing = false
					elseif (wordsLower[1]=="details") then
						FD_SH.ExtendDetails = false
					elseif (wordsLower[1]=="chat") then
						FD_SH.WriteChatMessage = false
						FD_SH.NoGuildGain = false
					elseif (wordsLower[1]=="suppress") then
						FD_SH.SuppressOriginalChat = false
					elseif (wordsLower[1]=="preview") then
						FD_SH.ShowPreviewRep = false
					elseif (wordsLower[1]=="bar") then
						FD_SH.SwitchFactionBar = false
						FD_SH.NoGuildSwitch = false
						FD_SH.SilentSwitch = false
					elseif (wordsLower[1]=="all") then
						FD_SH.ShowMobs = false
						FD_SH.ShowQuests = false
						FD_SH.ShowInstances = false
						FD_SH.ShowItems = false
						FD_SH.ShowGeneral = false
						FD_SH.ShowMissing = false
						FD_SH.ExtendDetails = false
						FD_SH.WriteChatMessage = false
						FD_SH.NoGuildGain = false
						FD_SH.SuppressOriginalChat = false
						FD_SH.ShowPreviewRep = false
						FD_SH.SwitchFactionBar = false
						FD_SH.NoGuildSwitch = false
						FD_SH.SilentSwitch = false
					else
						FIZ_PrintSlash(FIZ_TXT.command,msgLower)
					end

					if ( ReputationFrame:IsVisible() ) then
						ReputationFrame_Update(); -- rfl Event
					end
					if ( FIZ_ReputationDetailFrame:IsVisible()) then
						FIZ_BuildUpdateList()
						FIZ_UpdateList_Update()
					end
				else
						FIZ_PrintSlash(FIZ_TXT.command,msgLower)
				end
			elseif (wordsLower[0]=="toggle") then
				if (size>1) then
					if (wordsLower[1]=="mobs") then
						FD_SH.ShowMobs = not FD_SH.ShowMobs
					elseif (wordsLower[1]=="quests") then
						FD_SH.ShowQuests = not FD_SH.ShowQuests
					elseif (wordsLower[1]=="dungeons" or wordsLower[1]=="instances") then
						FD_SH.ShowInstances = not FD_SH.ShowInstances
					elseif (wordsLower[1]=="items") then
						FD_SH.ShowItems = not FD_SH.ShowItems
					elseif (wordsLower[1]=="general") then
						FD_SH.ShowGeneral = not FD_SH.ShowGeneral
					elseif (wordsLower[1]=="missing") then
						FD_SH.ShowMissing = not FD_SH.ShowMissing
					elseif (wordsLower[1]=="details") then
						FD_SH.ExtendDetails = not FD_SH.ExtendDetails
					elseif (wordsLower[1]=="chat") then
						FD_SH.WriteChatMessage = not FD_SH.WriteChatMessage
						FD_SH.NoGuildGain = false
					elseif (wordsLower[1]=="suppress") then
						FD_SH.SuppressOriginalChat = not FD_SH.SuppressOriginalChat
					elseif (wordsLower[1]=="preview") then
						FD_SH.ShowPreviewRep = not FD_SH.ShowPreviewRep
					elseif (wordsLower[1]=="preview") then
						FD_SH.SwitchFactionBar = not FD_SH.SwitchFactionBar
						FD_SH.NoGuildSwitch = false
						FD_SH.SilentSwitch = false
					elseif (wordsLower[1]=="all") then
						FD_SH.ShowMobs = not FD_SH.ShowMobs
						FD_SH.ShowQuests = not FD_SH.ShowQuests
						FD_SH.ShowInstances = not FD_SH.ShowInstances
						FD_SH.ShowItems = not FD_SH.ShowItems
						FD_SH.ShowGeneral = not FD_SH.ShowGeneral
						FD_SH.ShowMissing = not FD_SH.ShowMissing
						FD_SH.ExtendDetails = not FD_SH.ExtendDetails
						FD_SH.WriteChatMessage = not FD_SH.WriteChatMessage
						FD_SH.NoGuildGain = false
						FD_SH.SuppressOriginalChat = not FD_SH.SuppressOriginalChat
						FD_SH.ShowPreviewRep = not FD_SH.ShowPreviewRep
						FD_SH.SwitchFactionBar = not FD_SH.SwitchFactionBar
						FD_SH.NoGuildSwitch = false
						FD_SH.SilentSwitch = false
					else
						FIZ_PrintSlash(FIZ_TXT.command,msgLower)
					end

					if ( ReputationFrame:IsVisible() ) then
						ReputationFrame_Update(); -- rfl Event
					end
					if ( FIZ_ReputationDetailFrame:IsVisible()) then
						FIZ_BuildUpdateList()
						FIZ_UpdateList_Update()
					end
				else
						FIZ_PrintSlash(FIZ_TXT.command,msgLower)
				end
			elseif (wordsLower[0]=="list") then
				if (size>1) then
					if (wordsLower[1]=="1" or wordsLower[1]==string.lower(_G["FACTION_STANDING_LABEL1"])) then
						FIZ_ListByStanding(1)
					elseif (wordsLower[1]=="2" or wordsLower[1]==string.lower(_G["FACTION_STANDING_LABEL2"])) then
						FIZ_ListByStanding(2)
					elseif (wordsLower[1]=="3" or wordsLower[1]==string.lower(_G["FACTION_STANDING_LABEL3"])) then
						FIZ_ListByStanding(3)
					elseif (wordsLower[1]=="4" or wordsLower[1]==string.lower(_G["FACTION_STANDING_LABEL4"])) then
						FIZ_ListByStanding(4)
					elseif (wordsLower[1]=="5" or wordsLower[1]==string.lower(_G["FACTION_STANDING_LABEL5"])) then
						FIZ_ListByStanding(5)
					elseif (wordsLower[1]=="6" or wordsLower[1]==string.lower(_G["FACTION_STANDING_LABEL6"])) then
						FIZ_ListByStanding(6)
					elseif (wordsLower[1]=="7" or wordsLower[1]==string.lower(_G["FACTION_STANDING_LABEL7"])) then
						FIZ_ListByStanding(7)
					elseif (wordsLower[1]=="8" or wordsLower[1]==string.lower(_G["FACTION_STANDING_LABEL8"])) then
						FIZ_ListByStanding(8)
					else
						FIZ_PrintSlash(FIZ_TXT.command,msgLower)
					end
				else
					FIZ_ListByStanding()
				end
			elseif (wordsLower[0]=="loc") then
				if (size>1) then
					if (wordsLower[1]=="1" or wordsLower[1]==string.lower(_G["FACTION_STANDING_LABEL1"])) then
						FIZ_ShowGerman(1)
					elseif (wordsLower[1]=="2" or wordsLower[1]==string.lower(_G["FACTION_STANDING_LABEL2"])) then
						FIZ_ShowGerman(2)
					elseif (wordsLower[1]=="3" or wordsLower[1]==string.lower(_G["FACTION_STANDING_LABEL3"])) then
						FIZ_ShowGerman(3)
					elseif (wordsLower[1]=="4" or wordsLower[1]==string.lower(_G["FACTION_STANDING_LABEL4"])) then
						FIZ_ShowGerman(4)
					elseif (wordsLower[1]=="5" or wordsLower[1]==string.lower(_G["FACTION_STANDING_LABEL5"])) then
						FIZ_ShowGerman(5)
					elseif (wordsLower[1]=="6" or wordsLower[1]==string.lower(_G["FACTION_STANDING_LABEL6"])) then
						FIZ_ShowGerman(6)
					elseif (wordsLower[1]=="7" or wordsLower[1]==string.lower(_G["FACTION_STANDING_LABEL7"])) then
						FIZ_ShowGerman(7)
					elseif (wordsLower[1]=="8" or wordsLower[1]==string.lower(_G["FACTION_STANDING_LABEL8"])) then
						FIZ_ShowGerman(8)
					else
						FIZ_PrintSlash(FIZ_TXT.command,msgLower)
					end
				else
					FIZ_ShowGerman()
				end
			elseif (wordsLower[0]=="test") then
				FIZ_Test()
			elseif (wordsLower[0]=="status") then
				FIZ_Status()
			elseif (wordsLower[0]=="help") then
				FIZ_Help()
			elseif (wordsLower[0]=="about") then
				FIZ_About()
			else
				FIZ_PrintSlash(FIZ_TXT.command,msgLower)
			end
		else
			-- do nothing
		end
	end
end

-----------------------------------
-- _06_ General Helper Functions --
-----------------------------------

function FIZ_Print(msg, forceDefault) --zzz
	if not (msg) then return end

	if ((FIZ_Data==nil) or forceDefault) then
		DEFAULT_CHAT_FRAME:AddMessage(msg)
	else
		for i = 1, NUM_CHAT_WINDOWS do
			local chatTab = _G["ChatFrame"..i.."Tab"]
			if chatTab:IsShown() then
				local chatFrame = _G["ChatFrame"..i]
				local messageTypes = chatFrame.messageTypeList
				for j = 1, #messageTypes do
					if messageTypes[j] == "COMBAT_FACTION_CHANGE" then
						_G["ChatFrame"..i]:AddMessage(msg)
					end
				end
			end
		end

	end
end
------------------------------------------------------------
function FIZ_Printtest(msg,msg1,msg2) --fpt
	FIZ_Print(""..tostring(msg).." "..tostring(msg1).."  "..tostring(msg2), nil)
end
------------------------------------------------------------
function FIZ_PrintSlash(msg,msg1) --zzz
	FIZ_Print(FIZ_HELP_COLOUR..FIZ_NAME..":|r "..msg.." ["..FIZ_HELP_COLOUR..msg1.."|r]", true)
	FIZ_Help()
end
------------------------------------------------------------
function FIZ_Debug(msg)
	if not (msg) then return end
	--FIZ_Print(msg)
end
------------------------------------------------------------
function FIZ_TableSize(info)
	local result = 0
	if info then
		for item in pairs(info) do result = result + 1 end
	end
	return result
end

------------------------------------------------------------
function FIZ_GetWords(str)
	local ret = {};
	local pos=0;
	local index=0
	while(true) do
		local word;
		_,pos,word=string.find(str, "^ *([^%s]+) *", pos+1);
		if(not word) then
			return ret;
		end
		ret[index]=word
		index = index+1
	end
end

------------------------------------------------------------
function FIZ_Concat(list, start, stop)
	local ret = "";

	if (start == nil) then start = 0 end
	if (stop == nil) then stop = FIZ_TableSize(list) end

	for i = start,stop do
		if list[i] then
			if (ret ~= "") then ret = ret.." " end
			ret = ret..list[i]
		end
	end
	return ret
end

------------------------------------------------------------
function FIZ_BoolToEnabled(b)
	local result = FIZ_TXT.disabled
	if b then result = FIZ_TXT.enabled end
	return result
end

------------------------------------------------------------
function FIZ_RGBToColour_perc(a, r, g, b)
	return string.format("|c%02X%02X%02X%02X", a*255, r*255, g*255, b*255)
end

------------------------
-- _07_ information
------------------------

function FIZ_Help() --xxx
	FIZ_Print(" ", true)
	FIZ_Print(FIZ_HELP_COLOUR..FIZ_NAME..":|r "..FIZ_TXT.help, true)
	FIZ_Print(FIZ_HELP_COLOUR..FIZ_TXT.usage..":|r /fz help "..FIZ_HELP_COLOUR..FIZ_TXT.helphelp, true)
	FIZ_Print(FIZ_HELP_COLOUR..FIZ_TXT.usage..":|r /fz about "..FIZ_HELP_COLOUR..FIZ_TXT.helpabout, true)
	FIZ_Print(FIZ_HELP_COLOUR..FIZ_TXT.usage..":|r /fz status "..FIZ_HELP_COLOUR..FIZ_TXT.helpstatus, true)
	FIZ_Print(FIZ_HELP_COLOUR..FIZ_TXT.usage..":|r /fz enable { mobs | quests | instances | items | all }", true)
	FIZ_Print(FIZ_HELP_COLOUR..FIZ_TXT.usage..":|r /fz disable { mobs | quests | instances | items | all }", true)
	FIZ_Print(FIZ_HELP_COLOUR..FIZ_TXT.usage..":|r /fz toggle { mobs | quests | instances | items | all }", true)
	FIZ_Print(FIZ_HELP_COLOUR..FIZ_TXT.usage..":|r /fz enable { missing | details | chat | suppress }", true)
	FIZ_Print(FIZ_HELP_COLOUR..FIZ_TXT.usage..":|r /fz disable { missing | details | chat | suppress }", true)
	FIZ_Print(FIZ_HELP_COLOUR..FIZ_TXT.usage..":|r /fz toggle { missing | details | chat | suppress }" , true)
end
------------------------------------------------------------
function FIZ_About()
	local ver = GetAddOnMetadata("Factionizer", "Version");
	local date = GetAddOnMetadata("Factionizer", "X-Date");
	local author = GetAddOnMetadata("Factionizer", "Author");
	local web = GetAddOnMetadata("Factionizer", "X-Website");

	if (author ~= nil) then
		FIZ_Print(FIZ_NAME.." "..FIZ_TXT.by.." "..FIZ_HELP_COLOUR..author.."|r", true);
	end
	if (ver ~= nil) then
		FIZ_Print("  "..FIZ_TXT.version..": "..FIZ_HELP_COLOUR..ver.."|r", true);
	end
	if (date ~= nil) then
		FIZ_Print("  "..FIZ_TXT.date..": "..FIZ_HELP_COLOUR..date.."|r", true);
	end
	if (web ~= nil) then
		FIZ_Print("  "..FIZ_TXT.web..": "..FIZ_HELP_COLOUR..web.."|r", true);
	end

end
------------------------------------------------------------
function FIZ_Status()
	FIZ_Print(" ", true)
	FIZ_Print(FIZ_HELP_COLOUR..FIZ_NAME..":|r "..FIZ_TXT.status, true)
	FIZ_Print("   "..FIZ_TXT.statMobs..": "..FIZ_HELP_COLOUR..FIZ_BoolToEnabled(FIZ_Data.ShowMobs).."|r", true)
	FIZ_Print("   "..FIZ_TXT.statQuests..": "..FIZ_HELP_COLOUR..FIZ_BoolToEnabled(FIZ_Data.ShowQuests).."|r", true)
	FIZ_Print("   "..FIZ_TXT.statInstances..": "..FIZ_HELP_COLOUR..FIZ_BoolToEnabled(FIZ_Data.ShowInstances).."|r", true)
	FIZ_Print("   "..FIZ_TXT.statItems..": "..FIZ_HELP_COLOUR..FIZ_BoolToEnabled(FIZ_Data.ShowItems).."|r", true)
	FIZ_Print("   "..FIZ_TXT.statGeneral..": "..FIZ_HELP_COLOUR..FIZ_BoolToEnabled(FIZ_Data.ShowGeneral).."|r", true)
	FIZ_Print("   "..FIZ_TXT.statMissing..": "..FIZ_HELP_COLOUR..FIZ_BoolToEnabled(FIZ_Data.ShowMissing).."|r", true)
	FIZ_Print("   "..FIZ_TXT.statDetails..": "..FIZ_HELP_COLOUR..FIZ_BoolToEnabled(FIZ_Data.ExtendDetails).."|r", true)
	FIZ_Print("   "..FIZ_TXT.statChat..": "..FIZ_HELP_COLOUR..FIZ_BoolToEnabled(FIZ_Data.WriteChatMessage).."|r", true)

	FIZ_Print("   "..FIZ_TXT.statNoGuildChat..": "..FIZ_HELP_COLOUR..FIZ_BoolToEnabled(FIZ_Data.NoGuildGain).."|r", true)
	FIZ_Print("   "..FIZ_TXT.statSuppress..": "..FIZ_HELP_COLOUR..FIZ_BoolToEnabled(FIZ_Data.SuppressOriginalChat).."|r", true)
	FIZ_Print("   "..FIZ_TXT.statPreview..": "..FIZ_HELP_COLOUR..FIZ_BoolToEnabled(FIZ_Data.ShowPreviewRep).."|r", true)
	FIZ_Print("   "..FIZ_TXT.statSwitch..": "..FIZ_HELP_COLOUR..FIZ_BoolToEnabled(FIZ_Data.SwitchFactionBar).."|r", true)
	FIZ_Print("   "..FIZ_TXT.statNoGuildSwitch..": "..FIZ_HELP_COLOUR..FIZ_BoolToEnabled(FIZ_Data.NoGuildSwitch).."|r", true)
	FIZ_Print("   "..FIZ_TXT.statSilentSwitch..": "..FIZ_HELP_COLOUR..FIZ_BoolToEnabled(FIZ_Data.SilentSwitch).."|r", true)
end

-----------------------------------
-- _08_ Faction map --
-----------------------------------
function FIZ_Initmapname(fimap)
	--- fpt f_imn	FIZ_Printtest(fimap,"","map 1")
	local map
	if fimap == 1 then
		map = FIZ_TXT.srfd
	elseif fimap== 2 then
		map = FIZ_TXT.tbd
	elseif fimap== 3 then
		map = FIZ_TXT.mnd
	elseif fimap== 5 then
		map = FIZ_TXT.nci
	elseif fimap == 6 then
		map = FIZ_TXT.hci
	elseif not fimap then
		map = " "
	else
		local mapName = GetMapNameByID(fimap);
		map = mapName
	end
	--- fpt f_imn	FIZ_Printtest(fimap,"","map 2")
	if not map then
		map = fimap
	end
	mark_map = map
end

function FIZ_Initmobname(fimob)
	--- fpt f_ion	FIZ_Printtest(fimob,"","mob 1")
	local mob
	if fimob == 1 then
		mob = FIZ_TXT.tmob
	elseif fimob== 2 then
		mob = FIZ_TXT.oboss
	elseif fimob== 3 then
		mob = FIZ_TXT.aboss
	elseif fimob == 4 then
		mob = FIZ_TXT.pboss
	elseif fimob == 5 then
		mob = FIZ_TXT.fclear
	elseif fimob == 11 then
		mob = (FIZ_TXT.AU.." "..FIZ_TXT.BB)
	elseif fimob== 12 then
		mob = (FIZ_TXT.AU.." "..FIZ_TXT.SSP)
	elseif fimob== 13 then
		mob = (FIZ_TXT.AU.." "..FIZ_TXT.Wa)
	elseif fimob == 14 then
		mob = FIZ_TXT.VCm
	elseif fimob == 15 then
		mob = (FIZ_TXT.AN.." "..FIZ_TXT.BB)
	elseif fimob== 16 then
		mob = (FIZ_TXT.AN.." "..FIZ_TXT.SSP)
	elseif fimob== 17 then
		mob = (FIZ_TXT.AN.." "..FIZ_TXT.Wa)
	else
	--[[--	local mobName = GetmobNameByID(fimob);
		mob = mobName	--]]--
	end
	--- fpt f_ion	FIZ_Printtest(fimob,mob,"mob 2")
	if not mob then
		mob = fimob
	end
	mark_mob = mob
end

function FIZ_Inititemname(fiitem,amt)
	--- fpt f_iin	FIZ_Printtest(fiitem,amt,"item 1")
	if fiitem==1 then
		item_name = FIZ_TXT.cdq
	elseif fiitem==2 then
		item_name = FIZ_TXT.fdq
	elseif fiitem==3 then
		item_name = FIZ_TXT.ndq
	elseif fiitem == 4 then
		item_name = FIZ_TXT.cbadge
	elseif fiitem == 5 then
		item_name = FIZ_TXT.deleted
	else
		item_name = GetItemInfo(fiitem)
	end
	mark_I={}
	if not item_name then
		item_name=fiitem
	end
	mark_I[item_name]=amt
	--- fpt f_iin	FIZ_Printtest(item_name,mark_I[item_name],"item 2")
end

local quest_names = setmetatable({}, {
	__index = function(t, id_num)
		GameTooltip:SetOwner(UIParent, ANCHOR_NONE)
		GameTooltip:SetHyperlink(format("quest:%d", id_num))

		local quest_name = GameTooltipTextLeft1:GetText()
		GameTooltip:Hide()

		if id_num == 1 then
			quest_name = FIZ_TXT.cdq
		elseif id_num == 2 then
			quest_name = FIZ_TXT.coq
		elseif id_num == 3 then
			quest_name = FIZ_TXT.fdq
		elseif id_num == 4 then
			quest_name = FIZ_TXT.foq
		elseif id_num == 5 then
			quest_name = FIZ_TXT.ndq
		elseif id_num == 6 then
			quest_name = FIZ_TXT.deleted
		elseif id_num == 7 then
			quest_name = FIZ_TXT.Championing
		elseif id_num == 8 then
			quest_name = FIZ_TXT.bpqfg
		elseif id_num== 99 then
			quest_name = FIZ_TXT.tbd
		else
			if not quest_name then
				return id_num
			end
			t[id_num] = quest_name
		end
		return quest_name
	end
})

function FIZ_GetTabardFaction()
	for i = 1, 40 do
		local _, _, _, _, _, _, _, _, _, _, id = UnitBuff("player", i)
		if not id then
			break
		end
		local data = championFactions[id]
		if data then
			local faction, level = data[2], data[1]
			if DEBUG then self:Debug("GetChampionedFaction:", tostring(faction), tostring(level)) end
			return faction, level
		end
	end
	if DEBUG then self:Debug("GetChampionedFaction:", "none") end
end

function FIZ_InitFactor(FIZ_IsHuman,faction)
--- Thanks Gwalkmaur for the heads up
	local factor=1.0
	-- race check
		if FIZ_IsHuman then factor = factor + 0.1 end
	-- bonus repgain check
		local numFactions = GetNumFactions();
		local factionOffset=0;
		local factionIndex;
		local factor_h=0
	---	FIZ_Printtest(numFactions,factionOffset,factionIndex)
	--- f_if	FIZ_Printtest(faction,name)
		for i=1,numFactions do
			local factionIndex = factionOffset + i;
			if (factionIndex <= numFactions) then
				local name, hasBonusRepGain;
				local name, _, _, _, _, _, _, _, _, _, _, _, _, _, hasBonusRepGain, _ = GetFactionInfo(factionIndex);
				if (faction==name) then
				--- f_if	FIZ_Printtest(faction,name,"test")
					if (hasBonusRepGain) then
					--- f_if	FIZ_Printtest(faction,name,"Gain")
						factor=factor+1
					end
				end
			end
		end
	--- f_if	FIZ_Printtest(faction,factor,"fact")
	FIZ_factor = factor

end

function FIZ_InitFaction(guildName,faction)
	if faction=="guildName" or faction==FIZ_GuildName then
	--- f_ifa	FIZ_Printtest(faction,guildName,"1")
		FIZ_faction = faction
	else
	--- f_ifa	FIZ_Printtest(faction,FIZ_faction,"2")
		FIZ_faction = GetFactionInfoByID(faction)
	end
end

function FIZ_InitFactionMap(locale, guildName)
	FIZ_FactionMapping = {}
	FIZ_InitEnFactions()
	if (guildName) then
		FIZ_AddMapping(guildName, guildName)
	end
end

function FIZ_AddMapping(english, localised)
--- f_am	FIZ_Printtest(english, localised,"map")
	if (not FIZ_FactionMapping) then
		FIZ_FactionMapping = {}
	end
	FIZ_InitFaction(FIZ_GuildName,localised)
	if (FIZ_faction) then
		FIZ_FactionMapping[string.lower(FIZ_faction)] = string.lower(english)
	end
end

------------------------------------
-- _09_ Faction Lists --
------------------------------------

function FIZ_AddSpell(faction, from, to, name, rep, zone, limit)

	if not faction then return end
	if not from then return end
	if not to then return end
	if not name then return end
	if not rep then return end
	if (type(rep) ~= "number") then return end
	if ((from<1) or (from>8)) then return end
	if ((to<1) or (to>8)) then return end
	if (from > to) then return end
	faction = string.lower(faction)

--[[--	FIZ_Initspellname(name)
---	FIZ_Initmapname(zone)
	FIZ_InitFaction(FIZ_GuildName,faction)
	FIZ_InitFactor(FIZ_IsHuman,FIZ_faction)
	rep = rep * FIZ_factor
	faction = string.lower(FIZ_faction)
	---	FIZ_Printtest(faction,FIZ_faction,"spell")--fpt

	for standing = from,to do
		local faction_info = FIZ_FactionGain[faction]
		if not faction_info then
			faction_info = {}
			FIZ_FactionGain[faction] = faction_info
		end
		local standing_info = faction_info[standing]
		if not standing_info then
			standing_info = {}
			faction_info[standing] = standing_info
		end
		local add_info = standing_info.spells
		if add_info then
			add_info.count = add_info.count + 1
		else
			add_info = {}
			add_info.data = {}
			add_info.count = 0
			standing_info.spells = add_info
		end
		local count = add_info.count
		add_info.data[count] = {}
		local add_count=add_info.data[count]
		add_count.name = mark_spell --- name
		add_count.rep = rep
		add_count.zone = zone --- mark_map
		add_count.maxStanding = to
		if ((standing == to) and limit) then
			add_count.limit = limit
		end
		FIZ_Debug("Added spell ["..name.."] for faction ["..faction.."] and standing [".._G["FACTION_STANDING_LABEL"..standing].."]")
	end	--]]--
end

function FIZ_AddMob(faction, from, to, name, rep, zone, limit)

	if not faction then return end
	if not from then return end
	if not to then return end
	if not name then return end
	if not rep then return end
	if (type(rep) ~= "number") then return end
	if ((from<1) or (from>8)) then return end
	if ((to<1) or (to>8)) then return end
	if (from > to) then return end

	FIZ_Initmobname(name)
	FIZ_Initmapname(zone)
	FIZ_InitFaction(FIZ_GuildName,faction)
	FIZ_InitFactor(FIZ_IsHuman,FIZ_faction)
	rep = rep * FIZ_factor
	faction = string.lower(FIZ_faction)
	--- f_amo	FIZ_Printtest(faction,FIZ_faction,"mob")

	for standing = from,to do
		local faction_info = FIZ_FactionGain[faction]
		if not faction_info then
			faction_info = {}
			FIZ_FactionGain[faction] = faction_info
		end
		local standing_info = faction_info[standing]
		if not standing_info then
			standing_info = {}
			faction_info[standing] = standing_info
		end
		local add_info = standing_info.mobs
		if add_info then
			add_info.count = add_info.count + 1
		else
			add_info = {}
			add_info.data = {}
			add_info.count = 0
			standing_info.mobs = add_info
		end
		local count = add_info.count
		add_info.data[count] = {}
		local add_count=add_info.data[count]
		add_count.name = mark_mob --- name
		add_count.rep = rep
		add_count.zone = mark_map ---zone 
		add_count.maxStanding = to
		if ((standing == to) and limit) then
			add_count.limit = limit
		end
		FIZ_Debug("Added mob ["..name.."] for faction ["..faction.."] and standing [".._G["FACTION_STANDING_LABEL"..standing].."]")
	end
end

function FIZ_AddQuest(faction, from, to, name, rep, itemList, limitType)

	if not faction then return end
	if not from then return end
	if not to then return end
	if not name then return end
	if not rep then return end
	if (type(rep) ~= "number") then return end
	if ((from<1) or (from>8)) then return end
	if ((to<1) or (to>8)) then return end
	if (from > to) then return end

	FIZ_InitFaction(FIZ_GuildName,faction)
	FIZ_InitFactor(FIZ_IsHuman,FIZ_faction)
	rep = rep * FIZ_factor
	faction = string.lower(FIZ_faction)
	--- f_aq	FIZ_Printtest(faction,FIZ_faction,"quest")

	for standing = from,to do
		local mark_quest = quest_names[name] 
		local faction_info = FIZ_FactionGain[faction]
		if not faction_info then
			faction_info = {}
			FIZ_FactionGain[faction] = faction_info
		end
		local standing_info = faction_info[standing]
		if not standing_info then
			standing_info = {}
			faction_info[standing] = standing_info
		end
		local add_info = standing_info.quests
		if add_info then
			add_info.count = add_info.count + 1
		else
			add_info = {}
			add_info.data = {}
			add_info.count = 0
			standing_info.quests = add_info
		end
		local count=add_info.count
		add_info.data[count] = {}
		local add_count=add_info.data[count]
		add_count.name = mark_quest
		add_count.rep = rep
		add_count.maxStanding = to
		if (itemList) then
			if (itemList == "nil") then
				add_count.profession = limitType
			else
				add_count.items = {}
				for item in pairs(itemList) do
		FIZ_Inititemname(item,itemList[item])
					--- f_aq	FIZ_Printtest(item_name,mark_I[item_name],"item 3")
					add_count.items[item_name] = mark_I[item_name]
					--- f_aq	FIZ_Printtest(add_count.items[item_name],mark_I[item_name],"item 4")
				end
			end
		end
		if ((standing == to) and limit) then
			add_count.limit = limit
		end

		FIZ_Debug("Added quest ["..name.."] for faction ["..faction.."] and standing [".._G["FACTION_STANDING_LABEL"..standing].."]")
	end
end

function FIZ_AddInstance(faction, from, to, name, rep, heroic)
	if not faction then return end
	if not from then return end
	if not to then return end
	if not name then return end
	if not rep then return end
	if (type(rep) ~= "number") then return end
	if ((from<1) or (from>8)) then return end
	if ((to<1) or (to>8)) then return end
	if (from > to) then return end
	faction = string.lower(faction)

	FIZ_Initmapname(name)
	FIZ_InitFaction(FIZ_GuildName,faction)
	FIZ_InitFactor(FIZ_IsHuman,FIZ_faction)
	rep = rep * FIZ_factor
	faction = string.lower(FIZ_faction)
	--- f_ain	FIZ_Printtest(faction,FIZ_faction,"inst")

	for standing = from,to do
		local faction_info = FIZ_FactionGain[faction]
		if not faction_info then
			faction_info = {}
			FIZ_FactionGain[faction] = faction_info
		end
		local standing_info = faction_info[standing]
		if not standing_info then
			standing_info = {}
			faction_info[standing] = standing_info
		end
		local add_info = standing_info.instance
		if add_info then
			add_info.count = add_info.count + 1
		else
			add_info = {}
			add_info.data = {}
			add_info.count = 0
			standing_info.instance = add_info
		end
		local count = add_info.count
		add_info.data[count] = {}
		local add_count=add_info.data[count]
		add_count.name = mark_map
		add_count.rep = rep
		add_count.maxStanding = to
		if (heroic) then --ggg
			add_count.level = FIZ_TXT.heroic
		else
			add_count.level = FIZ_TXT.normal
		end
		if ((standing == to) and limit) then
			add_count.limit = limit
		end

		FIZ_Debug("Added instance ["..name.."] for faction ["..faction.."] and standing [".._G["FACTION_STANDING_LABEL"..standing].."]")
	end
end

function FIZ_AddItems(faction, from, to, rep, itemList)
	if not faction then return end
	if not from then return end
	if not to then return end
	if not rep then return end
	if not itemList then return end
	if (type(rep) ~= "number") then return end
	if ((from<1) or (from>8)) then return end
	if ((to<1) or (to>8)) then return end
	if (from > to) then return end
	faction = string.lower(faction)

	FIZ_InitFaction(FIZ_GuildName,faction)
	FIZ_InitFactor(FIZ_IsHuman,FIZ_faction)
	rep = rep * FIZ_factor
	faction = string.lower(FIZ_faction)
	--- f_ait	FIZ_Printtest(faction,FIZ_faction,"item")

	local itemString = ""
	for standing = from,to do
		local faction_info = FIZ_FactionGain[faction]
		if not faction_info then
			faction_info = {}
			FIZ_FactionGain[faction] = faction_info
		end
		local standing_info = faction_info[standing]
		if not standing_info then
			standing_info = {}
			faction_info[standing] = standing_info
		end
		local add_info = standing_info.items
		if add_info then
			add_info.count = add_info.count + 1
		else
			add_info = {}
			add_info.data = {}
			add_info.count = 0
			standing_info.items = add_info
		end
		local count=add_info.count

		add_info.data[count] = {}
		local add_count=add_info.data[count]
		add_count.rep = rep
		add_count.maxStanding = to
		if (itemList) then
			add_count.items = {}
			for item in pairs(itemList) do
				FIZ_Inititemname(item,itemList[item])
				if itemString ~= "" then itemString = itemString..", " end
				itemString = itemString..mark_I[item_name].."x "..item_name
			--- f_ait	FIZ_Printtest(item_name,mark_I[item_name],"item")
				add_count.items[item_name] = mark_I[item_name]
			end
		end
		if ((standing == to) and limit) then
			add_count.limit = limit
		end

		FIZ_Debug("AddItem: Added items ["..itemString.."] for faction ["..faction.."] and standing [".._G["FACTION_STANDING_LABEL"..standing].."]")
	end
end

function FIZ_AddGeneral(faction, from, to, name, rep, head, tip, tipList, flag)
	if not faction then return end
	if not from then return end
	if not to then return end
	if not rep then return end
	if not name then return end
	if (type(rep) ~= "number") then return end
	if ((from<1) or (from>8)) then return end
	if ((to<1) or (to>8)) then return end
	if (from > to) then return end
	faction = string.lower(faction)

	if name == "1" then
		name = FIZ_TXT.tfr
		head = FIZ_TXT.tfr
		tip = FIZ_TXT.nswts
	else
	end

	FIZ_InitFaction(FIZ_GuildName,faction)
	FIZ_InitFactor(FIZ_IsHuman,FIZ_faction)
	rep = rep * FIZ_factor
	faction = string.lower(FIZ_faction)
	--- f_ag	FIZ_Printtest(faction,FIZ_faction,"gen") 

	local tipString = ""
	for standing = from,to do
		local faction_info = FIZ_FactionGain[faction]
		if not faction_info then
			faction_info = {}
			FIZ_FactionGain[faction] = faction_info
		end
		local standing_info = faction_info[standing]
		if not standing_info then
			standing_info = {}
			faction_info[standing] = standing_info
		end
		local add_info = standing_info.general
		if add_info then
			add_info.count = add_info.count + 1
		else
			add_info = {}
			add_info.data = {}
			add_info.count = 0
			standing_info.general = add_info
		end
		local count = add_info.count
		add_info.data[count] = {}
		local add_count=add_info.data[count]
		add_count.name = name
		add_count.flag = flag
		add_count.head = head
		add_count.tip = tip
		add_count.rep = rep
		add_count.maxStanding = to
		if (tipList) then
			add_count.tipList = {}
			for tip in pairs(tipList) do
				if tipString ~= "" then tipString = tipString..", " end
				tipString = tipString..tipList[tip]..": "..tip
				add_count.tipList[tip] = tipList[tip]
			end
		end
		if ((standing == to) and limit) then
			add_count.limit = limit
		end
		FIZ_Debug("AddGeneral: Added general rep gain ["..name.."] for faction ["..faction.."] and standing [".._G["FACTION_STANDING_LABEL"..standing].."] with tooltip ["..tipString.."]")
	end
end

-----------------------------------
-- _10_ New Hook Functions --
-----------------------------------
function FIZ_GetFactionInfo(factionIndex)

	-- get original information
	local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus = FIZ_Orig_GetFactionInfo(factionIndex)

	-- Normalize Values to within standing
	local normMax = barMax-barMin
	local normCurrent = barValue-barMin

	-- add missing reputation
	if (FIZ_Data.ShowMissing and isHeader and not hasRep and ((normMax-normCurrent)>0)) then
		name = name.." ("..normMax-normCurrent..")"
	end

	-- return Values
	return name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus;
end

--- v rfl 1
function FIZ_ReputationFrame_Update() --rfl
-- v rfl 1.1
	local numFactions
	if FIZ_Data.SortByStanding then
		FIZ_StandingSort()
		numFactions = FIZ_OBS_numFactions
	else
-- ^ rfl 1.1
		numFactions = GetNumFactions();
-- v rfl 1.2
	end
-- ^ rfl 1.2
	-- Update scroll frame
	if ( not FauxScrollFrame_Update(ReputationListScrollFrame, numFactions, NUM_FACTIONS_DISPLAYED, REPUTATIONFRAME_FACTIONHEIGHT ) ) then
		ReputationListScrollFrameScrollBar:SetValue(0);
	end
	local factionOffset = FauxScrollFrame_GetOffset(ReputationListScrollFrame);
-- v rfl 1.3
	if (FIZ_Data.ShowMissing) then
		ReputationFrameStandingLabel:SetText(FIZ_Orig_StandingText.." "..FIZ_TXT.missing)
	else
		ReputationFrameStandingLabel:SetText(FIZ_Orig_StandingText)
	end

	if (FIZ_Data.ShowPreviewRep) then
		FIZ_ParseBagContent()
	end
-- ^ rfl 1.3
	local gender = UnitSex("player");
	local lfgBonusFactionID = GetLFGBonusFactionID();

	local i;
	for i=1, NUM_FACTIONS_DISPLAYED, 1 do
		local factionIndex = factionOffset + i;
		local factionRow = _G["ReputationBar"..i];
		local factionBar = _G["ReputationBar"..i.."ReputationBar"];
		local factionTitle = _G["ReputationBar"..i.."FactionName"];
		local factionButton = _G["ReputationBar"..i.."ExpandOrCollapseButton"];
		local factionStanding = _G["ReputationBar"..i.."ReputationBarFactionStanding"];
		local factionBackground = _G["ReputationBar"..i.."Background"];
-- v rfl 1.4
		local factionBarPreview = _G["FIZ_StatusBar"..i];
-- ^ rfl 1.4
		if ( factionIndex <= numFactions ) then
-- v rfl _9_ Rep Main Window
			if FIZ_Data.SortByStanding then
				FIZ_SortByStanding(i,factionIndex,factionRow,factionBar,factionBarPreview,factionTitle,factionButton,factionStanding,factionBackground)
			else
				FIZ_OriginalRepOrder(i,factionIndex,factionRow,factionBar,factionBarPreview,factionTitle,factionButton,factionStanding,factionBackground)
			end
-- ^ rfl _9_ Rep Main Window
		else
			factionRow:Hide();
		end
	end
	if ( GetSelectedFaction() == 0 ) then
		ReputationDetailFrame:Hide();
-- v rfl 1.5
		FIZ_ReputationDetailFrame:Hide();
-- ^ rfl 1.5
	end
end
-- ^ rfl 1

function FIZ_ExpandFactionHeader(index)
	-- replaces ExpandFactionHeader
	---fpt f_efh	FIZ_Printtest(index,"","f_efh_1")							---fpt f_efh
	if not FIZ_Entries then return end
	if FIZ_Data.SortByStanding then
		if not FIZ_Entries[index] then return end
		FIZ_Collapsed[FIZ_Entries[index].i] = nil
		FIZ_ReputationFrame_Update()
	else
		FIZ_Orig_ExpandFactionHeader(index)
		--[[
		local name = FIZ_Orig_GetFactionInfo(index);
		FIZ_Data.OriginalCollapsed[name] = nil
		--FIZ_Print("Expanding original index "..tostring(index).." which is ["..tostring(name).."]")
		FIZ_ShowCollapsedList()
		]]--
	end
end

function FIZ_ReputationFrame_SetRowType(factionRow, isChild, isHeader, hasRep)
	--rowType is a binary table of type isHeader, isChild
	local factionRowName = factionRow:GetName()
	local factionBar = _G[factionRowName.."ReputationBar"];
	local factionTitle = _G[factionRowName.."FactionName"];
	local factionButton = _G[factionRowName.."ExpandOrCollapseButton"];
	local factionStanding = _G[factionRowName.."ReputationBarFactionStanding"];
	local factionBackground = _G[factionRowName.."Background"];
	local factionLeftTexture = _G[factionRowName.."ReputationBarLeftTexture"];
	local factionRightTexture = _G[factionRowName.."ReputationBarRightTexture"];
	factionLeftTexture:SetWidth(62);
	factionRightTexture:SetWidth(42);
	factionBar:SetPoint("RIGHT", factionRow, "RIGHT", 0, 0);
	if ( isHeader ) then
		factionRow:SetPoint("LEFT", ReputationFrame, "LEFT", 10, 0);
		factionTitle:SetWidth(145);
		factionButton:SetPoint("LEFT", factionRow, "LEFT", 3, 0);
		factionButton:Show();
		factionTitle:SetPoint("LEFT",factionButton,"RIGHT",10,0);
		factionTitle:SetFontObject(GameFontNormalLeft);
		factionBackground:Hide()
		factionLeftTexture:SetHeight(15);
		factionLeftTexture:SetWidth(60);
		factionRightTexture:SetHeight(15);
		factionRightTexture:SetWidth(39);
		factionLeftTexture:SetTexCoord(0.765625, 1.0, 0.046875, 0.28125);
		factionRightTexture:SetTexCoord(0.0, 0.15234375, 0.390625, 0.625);
		factionBar:SetWidth(99);
		factionRow.LFGBonusRepButton:SetPoint("RIGHT", factionButton, "LEFT", 0, 1);
	else
		factionRow:SetPoint("LEFT", ReputationFrame, "LEFT", 29, 0);
		factionTitle:SetWidth(160);
		factionButton:Hide();
		factionTitle:SetPoint("LEFT", factionRow, "LEFT", 10, 0);
		factionTitle:SetFontObject(GameFontHighlightSmall);
		factionBackground:Show();
		factionLeftTexture:SetHeight(21);
		factionRightTexture:SetHeight(21);
		factionLeftTexture:SetTexCoord(0.7578125, 1.0, 0.0, 0.328125);
		factionRightTexture:SetTexCoord(0.0, 0.1640625, 0.34375, 0.671875);
		factionBar:SetWidth(101)
		factionRow.LFGBonusRepButton:SetPoint("RIGHT", factionBackground, "LEFT", -2, 0);
	end
	if ( (hasRep) or (not isHeader) ) then
		factionStanding:Show();
		factionBar:Show();
		factionBar:GetParent().hasRep = true;
	else
		factionStanding:Hide();
		factionBar:Hide();
		factionBar:GetParent().hasRep = false;
	end
end
function FIZ_CollapseFactionHeader(index)
	-- replaces CollapseFactionHeader
	---fpt f_efh	FIZ_Printtest(index,"","f_cfh_1")							---fpt f_efh
	if not FIZ_Entries then return end

	if FIZ_Data.SortByStanding then
		if not FIZ_Entries[index] then return end
		FIZ_Collapsed[FIZ_Entries[index].i] = true
		FIZ_ReputationFrame_Update()
	else
		FIZ_Orig_CollapseFactionHeader(index)
		--[[
		local name = FIZ_Orig_GetFactionInfo(index);
		FIZ_Data.OriginalCollapsed[name] = true
		--FIZ_Print("Collapsing original index "..tostring(index).." which is ["..tostring(name).."]")
		FIZ_ShowCollapsedList()
		]]--
	end
end

function FIZ_ReputationBar_OnClick(self)
	--fpt hed frb_oc	FIZ_Printtest("","","frb_oc 1")
	if ((ReputationDetailFrame:IsVisible() or FIZ_ReputationDetailFrame:IsVisible()) and (GetSelectedFaction() == self.index) ) then
		ReputationDetailFrame:Hide();
		FIZ_ReputationDetailFrame:Hide();
		PlaySound("igMainMenuOptionCheckBoxOff");
	else
		if (self.hasRep) then
			SetSelectedFaction(self.index);
			if (FIZ_Data.ExtendDetails) then
				FIZ_ReputationDetailFrame:Show();
				ReputationDetailFrame:Hide();
				FIZ_OptionsFrame:Hide()

				FIZ_BuildUpdateList()
				FIZ_UpdateList_Update()
			else
				ReputationDetailFrame:Show();
				FIZ_ReputationDetailFrame:Hide();
				FIZ_OptionsFrame:Hide()
			end
			PlaySound("igMainMenuOptionCheckBoxOn");
			ReputationFrame_Update(); -- rfl Event
		end
	end
end

FIZ_UPDATE_LIST_HEIGHT = 13

function FIZ_UpdateList_Update()
	-- usually called in conjuction with FIZ_BuildUpdateList
	--fpt hed ful_u	FIZ_Printtest("","","ful_u 1")
	if (not FIZ_ReputationDetailFrame:IsVisible()) then return end

	FIZ_UpdateListScrollFrame:Show()
	FIZ_ShowQuestButton:SetChecked(FIZ_Data.ShowQuests)
	FIZ_ShowItemsButton:SetChecked(FIZ_Data.ShowItems)
	FIZ_ShowMobsButton:SetChecked(FIZ_Data.ShowMobs)
	FIZ_ShowInstancesButton:SetChecked(FIZ_Data.ShowInstances)
	FIZ_ShowGeneralButton:SetChecked(FIZ_Data.ShowGeneral)

	FIZ_ShowQuestButtonText:SetText(FIZ_TXT.showQuests)
	FIZ_ShowItemsButtonText:SetText(FIZ_TXT.showItems)
	FIZ_ShowMobsButtonText:SetText(FIZ_TXT.showMobs)
	FIZ_ShowInstancesButtonText:SetText(FIZ_TXT.showInstances)
	FIZ_ShowGeneralButtonText:SetText(FIZ_TXT.showGeneral)

	FIZ_ShowAllButton:SetText(FIZ_TXT.showAll)
	FIZ_ShowNoneButton:SetText(FIZ_TXT.showNone)
	FIZ_ExpandButton:SetText(FIZ_TXT.expand)
	FIZ_CollapseButton:SetText(FIZ_TXT.collapse)

	FIZ_SupressNoneFactionButton:SetText(FIZ_TXT.supressNoneFaction)
	FIZ_SupressNoneGlobalButton:SetText(FIZ_TXT.supressNoneGlobal)
	FIZ_ReputationDetailSuppressHint:SetText(FIZ_TXT.suppressHint)
	FIZ_ClearSessionGainButton:SetText(FIZ_TXT.clearSessionGain)

	local numEntries, highestVisible = FIZ_GetUpdateListSize()

	-- Update scroll frame
	if ( not FauxScrollFrame_Update(FIZ_UpdateListScrollFrame, numEntries, FIZ_UPDATE_LIST_HEIGHT, 16 ) ) then
		FIZ_UpdateListScrollFrameScrollBar:SetValue(0);
	end
	local entryOffset = FauxScrollFrame_GetOffset(FIZ_UpdateListScrollFrame);

	local entryIndex
	local entryFrameName, entryFrame, entryTexture
	local entryLabel, entryName, entryRep, entryTimes
	local entryItemTimes, entryItemName, entryItemTotal
	local postfix

	local haveInfo = false;
	entryIndex = 1
	local i = 0
	local max = FIZ_TableSize(FIZ_UpdateList)
	while(i<entryOffset and entryIndex<max) do
		if FIZ_UpdateList[entryIndex].isShown then
			i = i + 1
		end
		entryIndex = entryIndex + 1
	end
	for i=1, FIZ_UPDATE_LIST_HEIGHT, 1 do
		while ((entryIndex <= highestVisible) and not FIZ_UpdateList[entryIndex].isShown) do
			entryIndex = entryIndex + 1
		end
		if (entryIndex <= highestVisible) then
			haveInfo = true

			entryFrameName = "FIZ_UpdateEntry"..i
			entryFrame = _G[entryFrameName]
			entryTexture = _G[entryFrameName.."Texture"]

			entryLabel = _G[entryFrameName.."Label"]
			entryName = _G[entryFrameName.."Name"]
			entryRep = _G[entryFrameName.."Rep"]
			entryTimes = _G[entryFrameName.."Times"]

			entryItemTimes = _G[entryFrameName.."ItemTimes"]
			entryItemName = _G[entryFrameName.."ItemName"]
			entryItemTotal = _G[entryFrameName.."TotalTimes"]
			local F_UL_ei = FIZ_UpdateList[entryIndex]

			if (entryFrame) then
				entryFrame:Show()
				entryFrame.id = F_UL_ei.index
				entryFrame.tooltipHead = F_UL_ei.tooltipHead
				entryFrame.tooltipTip = F_UL_ei.tooltipTip
				entryFrame.tooltipDetails = F_UL_ei.tooltipDetails
			end

			local color = ""
			if (F_UL_ei.highlight) then
				color = FIZ_HIGHLIGHT_COLOUR
			elseif (F_UL_ei.suppress) then
				color = FIZ_SUPPRESS_COLOUR
			elseif (F_UL_ei.lowlight) then
				color = FIZ_LOWLIGHT_COLOUR
			end

			if (F_UL_ei.type ~= "") then
				-- normal entry
				if (F_UL_ei.suppress) then
					postfix = ""
				else
					postfix = "-Green"
				end
				if (F_UL_ei.hasList) then
					if (F_UL_ei.listShown) then
						entryTexture:SetTexture("Interface\\Addons\\Factionizer\\Textures\\UI-MinusButton-Up"..postfix..".tga")
					else
						entryTexture:SetTexture("Interface\\Addons\\Factionizer\\Textures\\UI-PlusButton-Up"..postfix..".tga")
					end
				else
					entryTexture:SetTexture("Interface\\Addons\\Factionizer\\Textures\\UI-EmptyButton-Up"..postfix..".tga")
				end
				if (F_UL_ei.canSuppress) then
					entryTexture:Show()
				else
					entryTexture:Hide()
				end

				entryLabel:Show()
				entryName:Show()
				entryRep:Show()
				entryTimes:Show()

				entryLabel:SetText(color..F_UL_ei.type)
				entryName:SetText(color..F_UL_ei.name)
				entryRep:SetText(color..F_UL_ei.rep)
				entryTimes:SetText(color..F_UL_ei.times)

				entryItemTimes:Hide()
				entryItemName:Hide()
				entryItemTotal:Hide()
			else
				-- item entry
				entryTexture:Hide()
				entryLabel:Hide()
				entryName:Hide()
				entryRep:Hide()
				entryTimes:Hide()

				entryItemTimes:Show()
				entryItemName:Show()

				entryItemTimes:SetText(color..F_UL_ei.times)
				entryItemName:SetText(color..F_UL_ei.name)
			end
			entryIndex = entryIndex + 1
		else
			_G["FIZ_UpdateEntry"..i]:Hide()
		end
		if haveInfo then
			FIZ_NoInformationText:Hide()
		else
			FIZ_NoInformationText:SetText(FIZ_TXT.noInfo)
			FIZ_NoInformationText:Show()
		end
	end
end

function FIZ_MouseButtonUp(self, button)
	-- unkown call
	--fpt hed mbu	FIZ_Printtest("","","1 f_mbu")
	if (button and button == "LeftButton") then
		FIZ_UpdateEntryClick(self)
	elseif (button and button == "RightButton") then
		FIZ_UpdateEntrySuppress(self)
	end
end

function FIZ_UpdateEntryClick(self)
	-- sub function of FIZ_MouseButtonUp
	if (FIZ_UpdateList[self.id] and FIZ_UpdateList[self.id].hasList) then
		if (FIZ_UpdateList[self.id].listShown) then
			FIZ_ShowUpdateEntry(self.id, false)
		else
			FIZ_ShowUpdateEntry(self.id, true)
		end
	end
end

function FIZ_UpdateEntrySuppress(self)
	-- sub function of FIZ_UpdateEntryClick
	--fpt hed f_ues	FIZ_Printtest("","","f_ues 1")
	if (FIZ_UpdateList[self.id]) then
		if (FIZ_UpdateList[self.id].type ~= "") then
			if (FIZ_UpdateList[self.id].faction and FIZ_UpdateList[self.id].originalName) then
				if (not FIZ_Suppressed) then
					FIZ_Suppressed = {}
				end
				if (not FIZ_Suppressed[FIZ_UpdateList[self.id].faction]) then
					FIZ_Suppressed[FIZ_UpdateList[self.id].faction] = {}
				end
				if (FIZ_Suppressed[FIZ_UpdateList[self.id].faction][FIZ_UpdateList[self.id].originalName]) then
					--FIZ_Print("No longer suppressing ["..FIZ_UpdateList[self.id].faction.."]["..FIZ_UpdateList[self.id].originalName.."]");
					FIZ_Suppressed[FIZ_UpdateList[self.id].faction][FIZ_UpdateList[self.id].originalName] = nil
				else
					--FIZ_Print("Suppressing ["..FIZ_UpdateList[self.id].faction.."]["..FIZ_UpdateList[self.id].originalName.."]");
					FIZ_Suppressed[FIZ_UpdateList[self.id].faction][FIZ_UpdateList[self.id].originalName] = true
				end
				FIZ_BuildUpdateList()
			end
		end
	end
end

function FIZ_SupressNone(allFactions)
	-- unkown call
	--fpt hed sn	FIZ_Printtest("","","1 sn")
	if (allFactions == true) then
		FIZ_Suppressed = {}
		FIZ_BuildUpdateList()
	else
		local factionIndex = GetSelectedFaction()
		local faction = GetFactionInfo(factionIndex)

		if (faction) then
			faction = string.lower(faction)
	--- fpt sn	FIZ_Printtest(faction,FIZ_faction,"1 sn")
			if (FIZ_FactionMapping[faction]) then
	--- fpt sn	FIZ_Printtest(faction,FIZ_faction,"2 sn")
				faction = FIZ_FactionMapping[faction]
			end

			if (not FIZ_Suppressed) then
				FIZ_Suppressed = {}
			end
			FIZ_Suppressed[faction] = {}
		end
		FIZ_BuildUpdateList()
	end
end

-----------------------------------
-- _11_ Prepare update entries	 --
-----------------------------------
function FIZ_ParseBagContent()
	--fpt hed f_pbc	FIZ_Printtest("","","f_pbc 1")
	FIZ_ItemsCarried = {}

	for i = 0, NUM_BAG_SLOTS do
		local num = GetContainerNumSlots(i)
		for j = 1, num do
			local link = GetContainerItemLink(i, j)
			-- |cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0|h[Broken Fang]|h|r
			if link then
				local count = GetItemCount(link)
				local _, _, itemString, itemName = string.find(link, "^|c%x+|H(.+)|h%[(.+)%]")
				if count and itemName then
					if (not FIZ_ItemsCarried[itemName]) then
						FIZ_ItemsCarried[itemName] = count
					end
				end
			end
		end
	end
end

function FIZ_ParseBankContent()
	--fpt hed f_pBc	FIZ_Printtest("","","f_pBc 1")
	if (not FIZ_Data.Bank) then FIZ_Data.Bank = {} end
	FIZ_Data.Bank[FIZ_Realm.." - "..FIZ_Player] = {}

	local i = BANK_CONTAINER
	local num = GetContainerNumSlots(i)
	for j = 1, num do
		local link = GetContainerItemLink(i, j)
		-- |cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0|h[Broken Fang]|h|r
		if link then
			local count = GetItemCount(link)
			local _, count = GetContainerItemInfo(i, j);
			local _, _, itemString, itemName = string.find(link, "^|c%x+|H(.+)|h%[(.+)%]")
			if count and itemName then
				if (FIZ_Data.Bank[FIZ_Realm.." - "..FIZ_Player][itemName]) then
					FIZ_Data.Bank[FIZ_Realm.." - "..FIZ_Player][itemName] = FIZ_Data.Bank[FIZ_Realm.." - "..FIZ_Player][itemName] + count
				else
					FIZ_Data.Bank[FIZ_Realm.." - "..FIZ_Player][itemName] = count
				end
			end
		end
	end

	for i = NUM_BAG_SLOTS+NUM_BAG_SLOTS + NUM_BANKBAGSLOTS, NUM_BAG_SLOTS do
		local num = GetContainerNumSlots(i)
		for j = 1, num do
			local link = GetContainerItemLink(i, j)
			-- |cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0|h[Broken Fang]|h|r
			if link then
				local count = GetItemCount(link)
				local _, count = GetContainerItemInfo(i, j);
				local _, _, itemString, itemName = string.find(link, "^|c%x+|H(.+)|h%[(.+)%]")
				if count and itemName then
					if (FIZ_Data.Bank[FIZ_Realm.." - "..FIZ_Player][itemName]) then
						FIZ_Data.Bank[FIZ_Realm.." - "..FIZ_Player][itemName] = FIZ_Data.Bank[FIZ_Realm.." - "..FIZ_Player][itemName] + count
					else
						FIZ_Data.Bank[FIZ_Realm.." - "..FIZ_Player][itemName] = count
					end
				end
			end
		end
	end
end

function FIZ_Update_Tooltip(FIZ_Set,FIZ_Detail_1,FIZ_Detail_2)
	--- fpt hed f_u_t	FIZ_Printtest("","","f_u_t 1")
	--- fpt ddd	fiz_printtest(FIZ_Set,FIZ_Detail_1,FIZ_Detail_2)
	FIZ_UpdateList[index].tooltipDetails[FIZ_Set] = {}
	FIZ_UpdateList[index].tooltipDetails[FIZ_Set].l = FIZ_Detail_1
	FIZ_UpdateList[index].tooltipDetails[FIZ_Set].r = FIZ_Detail_2
end

function FIZ_BuildUpdateList() --xxx
	--- fpt hed f_bul	FIZ_Printtest("","","f_bul 1")
	FIZ_UpdateList = {}
	FIZ_CurrentRepInBag = 0
	FIZ_CurrentRepInBagBank = 0
	FIZ_CurrentRepInQuest = 0
	local index = 1

	if (not FIZ_ReputationDetailFrame:IsVisible()) then
		return
	end

--- fpt pbc	FIZ_ParseBagContent()

	local factionIndex = GetSelectedFaction()
	local faction, description, standingId, barMin, barMax, barValue = GetFactionInfo(factionIndex)

	if (faction) then
		origFaction = faction
		oFaction = string.lower(faction)
		faction = string.lower(faction)
		if (FIZ_FactionMapping[faction]) then
			faction = FIZ_FactionMapping[faction]
		end
		-- Normalize Values
		local normMax = barMax - barMin
		local normCurrent = barValue - barMin
		local repToNext = barMax - barValue
		if (FIZ_FactionGain[oFaction]) then
			local fg_sid=FIZ_FactionGain[oFaction][standingId]
			if (fg_sid) then
				-- instances
				if (fg_sid.instance and FIZ_Data.ShowInstances) then
					local fg_sid_x=fg_sid.instance
					for i = 0, fg_sid.instance.count do
						local fg_sid_x_d=fg_sid_x.data[i]
						if (not fg_sid_x_d.limit or (normCurrent < fg_sid_x_d.limit)) then
							local toDo = string.format("%.2f", repToNext / fg_sid_x_d.rep)
							if (fg_sid_x_d.limit) then
								toDo = string.format("%.2f", (fg_sid_x_d.limit - normCurrent) / fg_sid_x_d.rep)
							end --zzz
							FIZ_UpdateList[index] = {}
							local FUL_I = FIZ_UpdateList[index]
							FUL_I.type = FIZ_TXT.instanceShort
							FUL_I.times = toDo.."x"
							FUL_I.rep = string.format("%d", fg_sid_x_d.rep)
							FUL_I.hasList = false
							FUL_I.listShown = nil
							FUL_I.index = index
							FUL_I.belongsTo = nil
							FUL_I.isShown = true
							FUL_I.name = fg_sid_x_d.name.." ("..fg_sid_x_d.level..")"

							FUL_I.tooltipHead = FIZ_TXT.instanceHead
							FUL_I.tooltipTip = FIZ_TXT.instanceTip

							FUL_I.tooltipDetails = {}
							local FUL_I_TD = FUL_I.tooltipDetails
							local x = 0
--- ddd							FIZ_Update_Tooltip(x, FIZ_TXT.instance2, fg_sid_x_d.name)
							FUL_I_TD[x] = {}
							FUL_I_TD[x].l = FIZ_TXT.instance2
							FUL_I_TD[x].r = fg_sid_x_d.name

							x = x+1
--- ddd							FIZ_Update_Tooltip(x, FIZ_TXT.mode, fg_sid_x_d.level)
							FUL_I_TD[x] = {}
							FUL_I_TD[x].l = FIZ_TXT.mode
							FUL_I_TD[x].r = fg_sid_x_d.level
							x = x+1
							FUL_I_TD[x] = {}
							FUL_I_TD[x].l = FIZ_TXT.reputation
							FUL_I_TD[x].r = FUL_I.rep
							x = x+1
							FUL_I_TD[x] = {}
							FUL_I_TD[x].l = FIZ_TXT.timesToRun
							FUL_I_TD[x].r = FUL_I.times
							x = x+1
							FUL_I_TD[x] = {}
							FUL_I_TD[x].l = " "
							FUL_I_TD[x].r = " "
							x = x+1
							FUL_I_TD[x] = {}
							FUL_I_TD[x].l = FIZ_TXT.maxStanding
							FUL_I_TD[x].r = _G["FACTION_STANDING_LABEL"..fg_sid_x_d.maxStanding]
							FUL_I_TD.count = x
							FUL_I.tooltipDetails = FUL_I_TD
							FIZ_UpdateList[index] = FUL_I
							index = index + 1
						end
					end
				end

				-- mobs
				if (fg_sid.mobs and FIZ_Data.ShowMobs) then
					local fg_sid_x=fg_sid.mobs
					for i = 0, fg_sid_x.count do
					local fg_sid_x_d=fg_sid_x.data[i]
						if (not fg_sid_x_d.limit or (normCurrent < fg_sid_x_d.limit)) then
							local toDo = ceil(repToNext / fg_sid_x_d.rep)
							if (fg_sid_x_d.limit) then
								toDo = ceil((fg_sid_x_d.limit - normCurrent) / fg_sid_x_d.rep)
							end
							FIZ_UpdateList[index] = {}
							local FUL_I = FIZ_UpdateList[index]
							FUL_I.type = FIZ_TXT.mobShort
							FUL_I.times = toDo.."x"
							FUL_I.rep = string.format("%d", fg_sid_x_d.rep)
							FUL_I.hasList = false
							FUL_I.listShown = nil
							FUL_I.index = index
							FUL_I.belongsTo = nil
							FUL_I.isShown = true
							FUL_I.tooltipHead = FIZ_TXT.mobHead
							FUL_I.tooltipTip = FIZ_TXT.mobTip
							if (fg_sid_x_d.zone) then
								FUL_I.name = fg_sid_x_d.name.." ("..fg_sid_x_d.zone..")"
								FUL_I.tooltipDetails = {}
								local FUL_I_TD = FUL_I.tooltipDetails
								local x = 0
								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = FIZ_TXT.mob2
								FUL_I_TD[x].r = fg_sid_x_d.name
								x = x+1
								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = FIZ_TXT.location
								FUL_I_TD[x].r = fg_sid_x_d.zone
								x = x+1
								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = FIZ_TXT.reputation
								FUL_I_TD[x].r = FUL_I.rep
								x = x+1
								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = FIZ_TXT.toDo
								FUL_I_TD[x].r = FUL_I.times
								x = x+1
								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = " "
								FUL_I_TD[x].r = " "
								x = x+1
								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = FIZ_TXT.maxStanding
								FUL_I_TD[x].r = _G["FACTION_STANDING_LABEL"..fg_sid_x_d.maxStanding]
								FUL_I_TD.count = x
							else
								FUL_I.name = fg_sid_x_d.name
								FUL_I_TD = {}
								local x = 0
								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = FIZ_TXT.mob2
								FUL_I_TD[x].r = fg_sid_x_d.name
								x = x+1
								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = FIZ_TXT.reputation
								FUL_I_TD[x].r = FUL_I.rep
								x = x+1
								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = FIZ_TXT.toDo
								FUL_I_TD[x].r = FUL_I.times
								x = x+1
								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = " "
								FUL_I_TD[x].r = " "
								x = x+1
								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = FIZ_TXT.maxStanding
								FUL_I_TD[x].r = _G["FACTION_STANDING_LABEL"..fg_sid_x_d.maxStanding]
								FUL_I_TD.count = x
								FUL_I.tooltipDetails = FUL_I_TD
							end
							FIZ_UpdateList[index] = FUL_I
							index = index + 1
						end
					end
				end

				-- quests (may have items)
				local sum = 0
				local count = 0
				if (fg_sid.quests and FIZ_Data.ShowQuests) then
					local fg_sid_x=fg_sid.quests
					for i = 0, fg_sid_x.count do
					local fg_sid_x_d=fg_sid_x.data[i]
					local showQuest = true
					if (fg_sid_x_d.profession) then
						local fg_sid_x_d_p=fg_sid_x_d.profession
						if ((fg_sid_x_d_p == FIZ_LIMIT_TYPE_Herb) and not FIZ_Herb) then
							-- if list of known professions does not contain Herbology
							showQuest = false
							--FIZ_Print("Not showing quest ["..FIZ_FactionGain[faction][standingId].quests.data[i].name.."] because you do not know Herbalism")
						elseif ((fg_sid_x_d_p == FIZ_LIMIT_TYPE_Skin) and not FIZ_Skin) then
							-- if list of known professions does not contain Herbology
							showQuest = false
							--FIZ_Print("Not showing quest ["..FIZ_FactionGain[faction][standingId].quests.data[i].name.."] because you do not know Skinning")
						elseif ((fg_sid_x_d_p == FIZ_LIMIT_TYPE_Mine) and not FIZ_Mine) then
							-- if list of known professions does not contain Herbology
							showQuest = false
							--FIZ_Print("Not showing quest ["..FIZ_FactionGain[faction][standingId].quests.data[i].name.."] because you do not know mining")
						elseif ((fg_sid_x_d_p == FIZ_LIMIT_TYPE_Gather) and not (FIZ_Herb or FIZ_Skin or FIZ_Mine)) then
							-- no gathering profession
							showQuest = false
						elseif ((fg_sid_x_d_p == FIZ_LIMIT_TYPE_Jewe) and not FIZ_Jewel) then
							-- if list of known professions does not contain jewelcrafting
							showQuest = false
						elseif ((fg_sid_x_d_p == FIZ_LIMIT_TYPE_Cook) and not FIZ_Cook) then
							-- if list of known professions does not contain jewelcrafting
							showQuest = false
						elseif ((fg_sid_x_d_p == FIZ_LIMIT_TYPE_Arch) and not FIZ_Arch) then
							-- if list of known professions does not contain jewelcrafting
							showQuest = false
						elseif ((fg_sid_x_d_p == FIZ_LIMIT_TYPE_Fish) and not FIZ_Fish) then
							-- if list of known professions does not contain jewelcrafting
							showQuest = false
						elseif ((fg_sid_x_d_p == FIZ_LIMIT_TYPE_Aid) and not FIZ_Aid) then
							-- if list of known professions does not contain jewelcrafting
							showQuest = false
						elseif ((fg_sid_x_d_p == FIZ_LIMIT_TYPE_Blac) and not FIZ_Black) then
							-- if list of known professions does not contain BLACKsmith
							showQuest = false
						elseif ((fg_sid_x_d_p == FIZ_LIMIT_TYPE_Tail) and not FIZ_Tailor) then
							-- if list of known professions does not contain tailor
							showQuest = false
						elseif ((fg_sid_x_d_p == FIZ_LIMIT_TYPE_Leat) and not FIZ_Leath) then
							-- if list of known professions does not contain leather
							showQuest = false
						elseif ((fg_sid_x_d_p == FIZ_LIMIT_TYPE_Ench) and not FIZ_Enchan) then
							-- if list of known professions does not contain enchanter
							showQuest = false
						elseif ((fg_sid_x_d_p == FIZ_LIMIT_TYPE_Engi) and not FIZ_Engin) then
							-- if list of known professions does not contain BLACKsmith
							showQuest = false
						elseif ((fg_sid_x_d_p == FIZ_LIMIT_TYPE_Incr) and not FIZ_Incrip) then
							-- if list of known professions does not contain leather
							showQuest = false
						elseif ((fg_sid_x_d_p == FIZ_LIMIT_TYPE_Alch) and not FIZ_Alche) then
							-- if list of known professions does not contain enchanter
							showQuest = false
						else
							-- unexpected limit -> ignore this and still show quest ggg
						end
					end

					if (showQuest) then
						if (not fg_sid_x_d.limit or (normCurrent < fg_sid_x_d.limit)) then
							local toDo = ceil(repToNext / fg_sid_x_d.rep)
							if (fg_sid_x_d.limit) then
								toDo = ceil((fg_sid_x_d.limit - normCurrent) / fg_sid_x_d.rep)
							end
							FIZ_UpdateList[index] = {}
							local FUL_I = FIZ_UpdateList[index]
							FUL_I.type = FIZ_TXT.questShort
							FUL_I.times = toDo.."x"
							FUL_I.rep = string.format("%d", fg_sid_x_d.rep)
							FUL_I.index = index
							FUL_I.belongsTo = nil
							FUL_I.isShown = true
							FUL_I.name = fg_sid_x_d.name
							FUL_I.originalName = FUL_I.name
							FUL_I.faction = faction
							FUL_I.canSuppress = true
							FUL_I.suppress = nil
							if (FIZ_Suppressed and FIZ_Suppressed[oFaction] and FIZ_Suppressed[oFaction][FUL_I.originalName]) then
								FUL_I.suppress = true
							end
							FUL_I.tooltipHead = FIZ_TXT.questHead
							FUL_I.tooltipTip = FIZ_TXT.questTip

							FUL_I.tooltipDetails = {}
							local FUL_I_TD = FUL_I.tooltipDetails
							local x = 0
							FUL_I_TD[x] = {}
							FUL_I_TD[x].l = FIZ_TXT.quest2
							FUL_I_TD[x].r = FUL_I.name
							x = x+1
							FUL_I_TD[x] = {}
							FUL_I_TD[x].l = FIZ_TXT.reputation
							FUL_I_TD[x].r = FUL_I.rep
							x = x+1
							FUL_I_TD[x] = {}
							FUL_I_TD[x].l = FIZ_TXT.timesToDo
							FUL_I_TD[x].r = FUL_I.times
							x = x+1

							if (not FUL_I.suppress) then
								sum = sum + fg_sid_x_d.rep
								count = count + 1
							end

							if (fg_sid_x_d.items) then
								FUL_I.hasList = true
								FUL_I.listShown = false

								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = " "
								FUL_I_TD[x].r = " "
								x = x+1
								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = FIZ_TXT.itemsRequired
								FUL_I_TD[x].r = " "
								x = x+1

								-- quest In log?
								FUL_I.lowlight = nil

								-- check if this quest is known
								local entries, quests = GetNumQuestLogEntries()
								for z=1,entries do
									local title,level,tag,group,header,collapsed,complete,daily = GetQuestLogTitle(z)
									if (title and not header) then
										if string.find(string.lower(fg_sid_x_d.name), string.lower(title)) then
											-- this quest matches
											FUL_I.lowlight = true
											FUL_I.name = FUL_I.name..FIZ_QUEST_ACTIVE_COLOUR.." ("..FIZ_TXT.active..")|r"
										end
									end
								end

								-- add items
								local itemIndex = index+1

								local currentQuestTimesBag = -1
								local currentQuestTimesBagBank = -1
								for item in pairs(fg_sid_x_d.items) do
									FIZ_UpdateList[itemIndex] = {}
									local FUL_II = FIZ_UpdateList[itemIndex]
									FUL_II.type = ""
									FUL_II.times = (fg_sid_x_d.items[item] * toDo).."x"
									FUL_II.rep = nil
									FUL_II.index = itemIndex
									FUL_II.belongsTo = index
									FUL_II.hasList = nil
									FUL_II.listShown = nil
									FUL_II.isShown = FUL_I.listShown
									FUL_II.name = item.." ("..fg_sid_x_d.items[item].."x)"

									FUL_I_TD[x] = {}
									FUL_I_TD[x].l = fg_sid_x_d.items[item].."x"
									FUL_I_TD[x].r = item
									x = x+1

									if (FIZ_ItemsCarried and FIZ_ItemsCarried[item]) then
										if ((FIZ_ItemsCarried[item] >= fg_sid_x_d.items[item]) and (fg_sid_x_d.items[item] > 0)) then
											FUL_II.name = FUL_II.name..FIZ_BAG_COLOUR.." ["..FIZ_ItemsCarried[item].."x]|r"
											FUL_II.currentTimesBag = floor(FIZ_ItemsCarried[item] / fg_sid_x_d.items[item])
											if (currentQuestTimesBag == -1) then
												-- first items for this quest --> take value
												currentQuestTimesBag = FUL_II.currentTimesBag
											else
												-- some items already Set
												if (FUL_II.currentTimesBag < currentQuestTimesBag) then
													-- fewer of this item than of others, reduce quest count
													currentQuestTimesBag = FUL_II.currentTimesBag
												end
											end
										else
											-- not enough of this item for quest -> set to 0
											currentQuestTimesBag = 0
											FUL_II.name = FUL_II.name.." ["..FIZ_ItemsCarried[item].."x]"
										end
										if (FIZ_Data.Bank and
											FIZ_Data.Bank[FIZ_Realm.." - "..FIZ_Player] and
											FIZ_Data.Bank[FIZ_Realm.." - "..FIZ_Player][item]) then
											local total = FIZ_Data.Bank[FIZ_Realm.." - "..FIZ_Player][item] + FIZ_ItemsCarried[item]
											if ((total >= fg_sid_x_d.items[item]) and (fg_sid_x_d.items[item] > 0)) then
												FUL_II.name = FUL_II.name..FIZ_BAG_BANK_COLOUR.." ["..total.."x]|r"
												FUL_II.currentTimesBagBank = floor(total / fg_sid_x_d.items[item])
												if (currentQuestTimesBagBank == -1) then
													-- first items for this quest --> take value
													currentQuestTimesBagBank = FUL_II.currentTimesBagBank
												else
													-- some items already Set
													if (FUL_II.currentTimesBagBank < currentQuestTimesBagBank) then
														-- fewer of this item than of others, reduce quest count
														currentQuestTimesBagBank = FUL_II.currentTimesBagBank
													end
												end
											else
												-- not enough of this item for quest -> set to 0
												currentQuestTimesBagBank = 0
												FUL_II.name = FUL_II.name.." ["..total.."x]"
											end
										else
											-- none of this carried In bank
										end
									else
										-- not enough of this item for quest -> set to 0
										currentQuestTimesBag = 0
									end
									FIZ_UpdateList[itemIndex] = FUL_II
									itemIndex = itemIndex + 1
								end
								if (currentQuestTimesBag > 0) then
									FUL_I.name = FUL_I.name..FIZ_BAG_COLOUR.." ["..currentQuestTimesBag.."x]|r"
									FUL_I.currentTimesBag = currentQuestTimesBag
									FUL_I.currentRepBag = currentQuestTimesBag * FUL_I.rep
									FUL_I.highlight = true
									FUL_I.name = FUL_I.originalName
									FUL_I.lowlight = nil
									FIZ_CurrentRepInBag = FIZ_CurrentRepInBag + FUL_I.currentRepBag

									FUL_I_TD[x] = {}
									FUL_I_TD[x].l = " "
									FUL_I_TD[x].r = " "
									x = x+1
									FUL_I_TD[x] = {}
									FUL_I_TD[x].l = FIZ_TXT.inBag
									FUL_I_TD[x].r = " "
									x = x+1
									FUL_I_TD[x] = {}
									FUL_I_TD[x].l = FIZ_TXT.turnIns
									FUL_I_TD[x].r = string.format("%d", FUL_I.currentTimesBag)
									x = x+1
									FUL_I_TD[x] = {}
									FUL_I_TD[x].l = FIZ_TXT.reputation
									FUL_I_TD[x].r = string.format("%d", FUL_I.currentRepBag)
									x = x+1
								else
									FUL_I.currentTimesBag = nil
									FUL_I.currentRepBag = nil
								end
								if (currentQuestTimesBagBank > 0) then
									FUL_I.name = FUL_I.name..FIZ_BAG_BANK_COLOUR.." ["..currentQuestTimesBagBank.."x]|r"
									FUL_I.currentTimesBagBank = currentQuestTimesBagBank
									FUL_I.currentRepBagBank = currentQuestTimesBagBank * FUL_I.rep
									FUL_I.highlight = true
									FUL_I.name = FUL_I.originalName
									FUL_I.lowlight = nil
									FIZ_CurrentRepInBagBank = FIZ_CurrentRepInBagBank + FUL_I.currentRepBagBank

									FUL_I_TD[x] = {}
									FUL_I_TD[x].l = " "
									FUL_I_TD[x].r = " "
									x = x+1
									FUL_I_TD[x] = {}
									FUL_I_TD[x].l = FIZ_TXT.inBagBank
									FUL_I_TD[x].r = " "
									x = x+1
									FUL_I_TD[x] = {}
									FUL_I_TD[x].l = FIZ_TXT.turnIns
									FUL_I_TD[x].r = string.format("%d", FUL_I.currentTimesBagBank)
									x = x+1
									FUL_I_TD[x] = {}
									FUL_I_TD[x].l = FIZ_TXT.reputation
									FUL_I_TD[x].r = string.format("%d", FUL_I.currentRepBagBank)
									x = x+1
								else
									FUL_I.currentTimesBagBank = nil
									FUL_I.currentRepBagBank = nil
								end
								if ((currentQuestTimesBag == 0) and (currentQuestTimesBagBank)) then
									FUL_I.highlight = nil
								end

								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = " "
								FUL_I_TD[x].r = " "
								x = x+1
								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = FIZ_TXT.maxStanding
								FUL_I_TD[x].r = _G["FACTION_STANDING_LABEL"..fg_sid_x_d.maxStanding]
								x = x+1

								FUL_I_TD.count = x-1
								index = itemIndex
							else
								-- no items to add
								FUL_I.hasList = false
								FUL_I.listShown = nil
								FUL_I.highlight = nil	-- will be Changed below if needed
								FUL_I.lowlight = nil

								-- check if this quest is known and/or completed
								local entries, quests = GetNumQuestLogEntries()
								for z=1,entries do
									local title,level,tag,group,header,collapsed,complete,daily = GetQuestLogTitle(z)
									if (title and not header) then
										if string.find(string.lower(fg_sid_x_d.name), string.lower(title)) then
											-- this quest matches
											if (complete) then
												FUL_I.highlight = true
												FUL_I.name = FUL_I.name..FIZ_QUEST_COLOUR.." ("..FIZ_TXT.complete..")|r"
												FUL_I.currentTimesQuest = 1
												FUL_I.currentRepQuest = FUL_I.rep

												FIZ_CurrentRepInQuest = FIZ_CurrentRepInQuest + fg_sid_x_d.rep

												FUL_I_TD[x] = {}
												FUL_I_TD[x].l = " "
												FUL_I_TD[x].r = " "
												x = x+1
												FUL_I_TD[x] = {}
												FUL_I_TD[x].l = FIZ_TXT.questCompleted
												FUL_I_TD[x].r = " "
												x = x+1
												FUL_I_TD[x] = {}
												FUL_I_TD[x].l = FIZ_TXT.reputation
												FUL_I_TD[x].r = string.format("%d", FUL_I.currentRepQuest)
												x = x+1
											else
												FUL_I.lowlight = true
												FUL_I.name = FUL_I.name..FIZ_QUEST_ACTIVE_COLOUR.." ("..FIZ_TXT.active..")|r"
											end
										end
									end
								end

								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = " "
								FUL_I_TD[x].r = " "
								x = x+1
								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = FIZ_TXT.maxStanding
								FUL_I_TD[x].r = _G["FACTION_STANDING_LABEL"..fg_sid_x_d.maxStanding]
								x = x+1

								FUL_I_TD.count = x-1
								FIZ_UpdateList[index] = FUL_I
								index = index + 1
							end
						end
					end
				end
				if ((sum > 0) and (count > 1)) then
					-- add virtual quest to show summary of all quests:
					local toDo = ceil(repToNext / sum)
					FIZ_UpdateList[index] = {}
					local FUL_I = FIZ_UpdateList[index]
					FUL_I.type = FIZ_TXT.questShort
					FUL_I.times = toDo.."x"
					FUL_I.rep = string.format("%d", sum)
					FUL_I.index = index
					FUL_I.belongsTo = nil
					FUL_I.isShown = true
					FUL_I.name = string.format(FIZ_TXT.allOfTheAbove, count)
					FUL_I.tooltipHead = string.format(FIZ_TXT.questSummaryHead, count)
					FUL_I.tooltipTip = FIZ_TXT.questSummaryTip

					FUL_I_TD = {}
					local x = 0
					FUL_I_TD[x] = {}
					FUL_I_TD[x].l = FIZ_TXT.reputation
					FUL_I_TD[x].r = FUL_I.rep
					x = x+1
					FUL_I_TD[x] = {}
					FUL_I_TD[x].l = FIZ_TXT.timesToDo
					FUL_I_TD[x].r = FUL_I.times
					FUL_I_TD.count = x
					FUL_I.tooltipDetails = FUL_I_TD
					FIZ_UpdateList[index] = FUL_I
					index = index + 1
				end
			end

			-- items
			if (fg_sid.items and FIZ_Data.ShowItems) then
				local fg_sid_x=fg_sid.items
				for i = 0, fg_sid_x.count do
				local fg_sid_x_d=fg_sid_x.data[i]
					if (not fg_sid_x_d.limit or (normCurrent < fg_sid_x_d.limit)) then
						local toDo = ceil(repToNext / fg_sid_x_d.rep)
						if (fg_sid_x_d.limit) then
							toDo = ceil((fg_sid_x_d.limit - normCurrent) / fg_sid_x_d.rep)
						end
						if (fg_sid_x_d.items) then
							FIZ_UpdateList[index] = {}
							local FUL_I = FIZ_UpdateList[index]
							FUL_I.type = FIZ_TXT.itemsShort
							FUL_I.times = toDo.."x"
							FUL_I.rep = string.format("%d", fg_sid_x_d.rep)
							FUL_I.index = index
							FUL_I.belongsTo = nil
							FUL_I.isShown = true
							FUL_I.name = FIZ_TXT.itemsName
							FUL_I.hasList = true
							FUL_I.listShown = false
							FUL_I.tooltipHead = FIZ_TXT.itemsHead
							FUL_I.tooltipTip = FIZ_TXT.itemsTip

							FUL_I.tooltipDetails = {}
							local FUL_I_TD = FUL_I.tooltipDetails
							local x = 0
							FUL_I_TD[x] = {}
							FUL_I_TD[x].l = FUL_I.name
							FUL_I_TD[x].r = " "
							x = x+1
							FUL_I_TD[x] = {}
							FUL_I_TD[x].l = " "
							FUL_I_TD[x].r = " "
							x = x+1
							FUL_I_TD[x] = {}
							FUL_I_TD[x].l = FIZ_TXT.itemsRequired
							FUL_I_TD[x].r = " "
							x = x+1

							-- add items
							local itemIndex = index+1

							local currentQuestTimesBag = -1
							local currentQuestTimesBagBank = -1
							for item in pairs(fg_sid_x_d.items) do
								FIZ_UpdateList[itemIndex] = {}
								local FUL_II = FIZ_UpdateList[itemIndex]
								FUL_II.type = ""
								FUL_II.times = (fg_sid_x_d.items[item] * toDo).."x"
								FUL_II.rep = nil
								FUL_II.index = itemIndex
								FUL_II.belongsTo = index
								FUL_II.hasList = nil
								FUL_II.listShown = nil
								FUL_II.isShown = FUL_I.listShown
								FUL_II.name = item.." ("..fg_sid_x_d.items[item].."x)"

								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = fg_sid_x_d.items[item].."x"
								FUL_I_TD[x].r = item
								x = x+1

								if (FIZ_ItemsCarried and FIZ_ItemsCarried[item]) then
									if ((FIZ_ItemsCarried[item] >= fg_sid_x_d.items[item]) and (fg_sid_x_d.items[item] > 0)) then
										FUL_II.currentTimesBag = floor(FIZ_ItemsCarried[item] / fg_sid_x_d.items[item])
										FUL_II.name = FUL_II.name..FIZ_BAG_COLOUR.." ["..FIZ_ItemsCarried[item].."x]|r"
										if (currentQuestTimesBag == -1) then
											-- first items for this quest --> take value
											currentQuestTimesBag = FUL_II.currentTimesBag
										else
											-- some items already Set
											if (FUL_II.currentTimesBag < currentQuestTimesBag) then
												-- fewer of this item than of others, reduce quest count
												currentQuestTimesBag = FUL_II.currentTimesBag
											end
										end
									else
										-- not enough of this item for quest -> set to 0
										currentQuestTimesBag = 0
										FUL_II.name = FUL_II.name.." ["..FIZ_ItemsCarried[item].."x]"
									end
									if (FIZ_Data.Bank and
										FIZ_Data.Bank[FIZ_Realm.." - "..FIZ_Player] and
										FIZ_Data.Bank[FIZ_Realm.." - "..FIZ_Player][item]) then
										local total = FIZ_Data.Bank[FIZ_Realm.." - "..FIZ_Player][item] + FIZ_ItemsCarried[item]
										if ((total >= fg_sid_x_d.items[item]) and (fg_sid_x_d.items[item] > 0)) then
											FUL_II.name = FUL_II.name..FIZ_BAG_BANK_COLOUR.." ["..total.."x]|r"
											FUL_II.currentTimesBagBank = floor(total / fg_sid_x_d.items[item])
											if (currentQuestTimesBagBank == -1) then
												-- first items for this quest --> take value
												currentQuestTimesBagBank = FUL_II.currentTimesBagBank
											else
												-- some items already Set
												if (FUL_II.currentTimesBagBank < currentQuestTimesBagBank) then
													-- fewer of this item than of others, reduce quest count
													currentQuestTimesBagBank = FUL_II.currentTimesBagBank
												end
											end
										else
											-- not enough of this item for quest -> set to 0
											currentQuestTimesBagBank = 0
											FUL_II.name = FUL_II.name.." ["..total.."x]"
										end
									else
										-- none of this carried In bank
									end
								else
									-- not enough of this item for quest -> set to 0
									currentQuestTimesBag = 0
								end
								FIZ_UpdateList[itemIndex] = FUL_II
								itemIndex = itemIndex + 1
							end
							if (currentQuestTimesBag > 0) then
								FUL_I.highlight = true
								FUL_I.lowlight = nil
								FUL_I.name = FUL_I.name..FIZ_BAG_COLOUR.." ["..currentQuestTimesBag.."x]|r"
								FUL_I.currentTimesBag = currentQuestTimesBag
								FUL_I.currentRepBag = currentQuestTimesBag * FUL_I.rep
								FIZ_CurrentRepInBag = FIZ_CurrentRepInBag + FUL_I.currentRepBag

								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = " "
								FUL_I_TD[x].r = " "
								x = x+1
								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = FIZ_TXT.inBag
								FUL_I_TD[x].r = " "
								x = x+1
								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = FIZ_TXT.turnIns

								FUL_I_TD[x].r = string.format("%d", FUL_I.currentTimesBag)
								x = x+1
								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = FIZ_TXT.reputation
								FUL_I_TD[x].r = string.format("%d", FUL_I.currentRepBag)
								x = x+1
							else
								FUL_I.currentTimesBag = nil
								FUL_I.currentRepBag = nil
								FUL_I.highlight = nil
							end
							if (currentQuestTimesBagBank > 0) then
								FUL_I.highlight = true
								FUL_I.lowlight = nil
								FUL_I.name = FUL_I.name..FIZ_BAG_BANK_COLOUR.." ["..currentQuestTimesBagBank.."]|r"
								FUL_I.currentTimesBagBank = currentQuestTimesBagBank

								FUL_I.currentRepBagBank = currentQuestTimesBagBank * FUL_I.rep
								FIZ_CurrentRepInBagBank = FIZ_CurrentRepInBagBank + FUL_I.currentRepBagBank

								FUL_I_TD[x] = {}
								if (not FIZ_UpdateList[index].hasList) then return end	-- not a list Header entry
									FUL_I_TD[x].l = " "
									FUL_I_TD[x].r = " "
									x = x+1
									FUL_I_TD[x] = {}
									FUL_I_TD[x].l = FIZ_TXT.inBagBank
									FUL_I_TD[x].r = " "
									x = x+1
									FUL_I_TD[x] = {}
									FUL_I_TD[x].l = FIZ_TXT.turnIns
									FUL_I_TD[x].r = string.format("%d", FUL_I.currentTimesBagBank)
									x = x+1
									FUL_I_TD[x] = {}
									FUL_I_TD[x].l = FIZ_TXT.reputation
									FUL_I_TD[x].r = string.format("%d", FUL_I.currentRepBagBank)
									x = x+1
								else
									FUL_I.currentTimesBagBank = nil
									FUL_I.currentRepBagBank = nil
									FUL_I.highlight = nil
								end
								if ((currentQuestTimesBag == 0) and (currentQuestTimesBagBank)) then
									FUL_I.highlight = nil
								end

								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = " "
								FUL_I_TD[x].r = " "
								x = x+1
								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = FIZ_TXT.maxStanding
								FUL_I_TD[x].r = _G["FACTION_STANDING_LABEL"..fg_sid_x_d.maxStanding]
								x = x+1

								FUL_I_TD.count = x-1
								FUL_I.tooltipDetails = FUL_I_TD
								FIZ_UpdateList[index] = FUL_I
								index = itemIndex
							end
						end
					end
				end

				-- General
				if (fg_sid.general and FIZ_Data.ShowGeneral) then
					local fg_sid_x=fg_sid.general
					for i = 0, fg_sid_x.count do
						local fg_sid_x_d=fg_sid_x.data[i]
						if (not fg_sid_x_d.limit or (normCurrent < fg_sid_x_d.limit)) then
							local toDo = string.format("%.2f", repToNext / fg_sid_x_d.rep)
							if (fg_sid_x_d.limit) then
								toDo = string.format("%.2f", (fg_sid_x_d.limit - normCurrent) / fg_sid_x_d.rep)
							end
							-- calculate Number of times to do differently for Guild cap
						--[[--	if (fg_sid_x_d.flag == FIZ_FLAG_GUILD_CAP) then
								toDo = string.format("%.2f", (barMax - FIZ_Data.cap[FIZ_CapIndex].base) / fg_sid_x_d.rep)
							end	--]]--
							FIZ_UpdateList[index] = {}
							local FUL_I = FIZ_UpdateList[index]
							FUL_I.type = FIZ_TXT.generalShort
							FUL_I.times = toDo.."x"
							FUL_I.rep = string.format("%d", fg_sid_x_d.rep)
							FUL_I.hasList = false
							FUL_I.listShown = nil
							FUL_I.index = index
							FUL_I.belongsTo = nil
							FUL_I.isShown = true
							FUL_I.name = fg_sid_x_d.name

							if (fg_sid_x_d.head and fg_sid_x_d.head ~= "") then
								FUL_I.tooltipHead = fg_sid_x_d.head
							else
								FUL_I.tooltipHead = FIZ_TXT.generalHead
							end
							if (fg_sid_x_d.tip and fg_sid_x_d.tip ~= "") then
								FUL_I.tooltipTip = fg_sid_x_d.tip
							else
								FUL_I.tooltipTip = FIZ_TXT.generalTip
							end

							FUL_I.tooltipDetails = {}
							local FUL_I_TD = FUL_I.tooltipDetails
							local x = 0
						--[[--	if (fg_sid_x_d.flag == FIZ_FLAG_GUILD_CAP) then
								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = FIZ_TXT.reputationCap
								FUL_I_TD[x].r = FUL_I.rep
								x = x+1
								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = FIZ_TXT.reputationCapCurrent
								FUL_I_TD[x].r = FIZ_Data.cap[FIZ_CapIndex].rep
							else	--]]--
								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = FIZ_TXT.general2
								FUL_I_TD[x].r = fg_sid_x_d.name
								x = x+1
								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = FIZ_TXT.reputation
								FUL_I_TD[x].r = FUL_I.rep
						--	end
							x = x+1
							FUL_I_TD[x] = {}
							FUL_I_TD[x].l = FIZ_TXT.timesToRun
							FUL_I_TD[x].r = FUL_I.times
							x = x+1
							FUL_I_TD[x] = {}
							FUL_I_TD[x].l = " "
							FUL_I_TD[x].r = " "

							if (fg_sid_x_d.tipList) then
								for tip in pairs(fg_sid_x_d.tipList) do
									x = x+1
									FUL_I_TD[x] = {}
									FUL_I_TD[x].l = tip
									FUL_I_TD[x].r = fg_sid_x_d.tipList[tip]
								end
								x = x+1
								FUL_I_TD[x] = {}
								FUL_I_TD[x].l = " "
								FUL_I_TD[x].r = " "
							end

							x = x+1
							FUL_I_TD[x] = {}
							FUL_I_TD[x].l = FIZ_TXT.maxStanding
							FUL_I_TD[x].r = _G["FACTION_STANDING_LABEL"..fg_sid_x_d.maxStanding]
							FUL_I_TD.count = x
							local FUL_I_TD = FUL_I.tooltipDetails
							FIZ_UpdateList[index] = FUL_I
							index = index + 1
						end
					end
				end
			end
		end
	end

	--FIZ_Print("Added "..(index-1).." entries for ["..faction.."] at standing "..standingId)

	FIZ_UpdateList_Update()
end

function FIZ_GetUpdateListSize()
	-- sub function of	FIZ_UpdateList_Update()
	--fpt hed f_guls	FIZ_Printtest("","","f_guls 1")
	local count = 0
	local highest = 0
	for i in pairs(FIZ_UpdateList) do
		if (FIZ_UpdateList[i].isShown) then
			count = count + 1
			if (i > highest) then
				highest = i
			end
		end
	end

	return count, highest
end

function FIZ_ShowUpdateEntry(index, show)
	--fpt hed f_sue	FIZ_Printtest("","","f_sue 1")
	if (not FIZ_UpdateList[index]) then return end		-- invalid index
	if (not FIZ_UpdateList[index].hasList) then return end	-- not a list Header entry
	if (type(show)~="boolean") then return end		-- wrong data type

	FIZ_UpdateList[index].listShown = show
	for i in pairs(FIZ_UpdateList) do
		if (FIZ_UpdateList[i].belongsTo == index) then
			FIZ_UpdateList[i].isShown = show
		end
	end

	FIZ_UpdateList_Update()
end

function FIZ_ShowUpdateEntries(show)
	if (type(show)~="boolean") then return end		-- wrong data type

	for i in pairs(FIZ_UpdateList) do
		if (FIZ_UpdateList[i].belongsTo == nil) then
			-- always show parent entries, show or Hide their children
			FIZ_UpdateList[i].isShown = true
			FIZ_UpdateList[i].listShown = show
		else
			-- show or Hide child entries
			FIZ_UpdateList[i].isShown = show
		end
	end

	FIZ_UpdateList_Update()
end

function FIZ_ShowLineToolTip(self)
	if not self then return end

	if (self.tooltipHead) then
		GameTooltip_SetDefaultAnchor(GameTooltip, self)
		GameTooltip:SetText(self.tooltipHead, 1, 1, 0.5, 1)
		if (self.tooltipTip) then
			GameTooltip:AddLine(self.tooltipTip, 1, 1, 1, 1)
		end
		if (self.tooltipDetails and type(self.tooltipDetails) == "table") then
			GameTooltip:AddLine(" ", 1, 1, 1, 1)
			for i = 0, self.tooltipDetails.count do
				if (self.tooltipDetails[i].l and self.tooltipDetails[i].r) then
					if (self.tooltipDetails[i].r == " " or self.tooltipDetails[i].r=="") then
						GameTooltip:AddDoubleLine(self.tooltipDetails[i].l, self.tooltipDetails[i].r, 1, 1, 0, 1, 1, 1)
					else
						GameTooltip:AddDoubleLine(self.tooltipDetails[i].l, self.tooltipDetails[i].r, 1, 1, 0.5, 1, 1, 1)
					end
				end
			end
		end
		GameTooltip:Show()
	end
end

function FIZ_ShowHelpToolTip(self, element)
	if not element then return end

	local name = ""

	-- cut off leading frame name
	--if (string.find(element, GLDG_GUI)) then
	--	name = string.sub(element, string.len(GLDG_GUI)+1)
	--elseif (string.find(element, GLDG_COLOUR)) then
	--	name = string.sub(element, string.len(GLDG_COLOUR)+1)
	--elseif (string.find(element, GLDG_LIST)) then
		name = element
	--end

	-- cut off trailing Number In case of line and collect
	--local s,e = string.find(name, "Line");
	--if (s and e) then
	--	name = string.sub(name, 0, e)
	--end
	--s,e = string.find(name, "Collect");
	--if (s and e) then
	--	name = string.sub(name, 0, e)
	--end

	-- cut off colour button/texture
	--if (string.find(name, "Colour") == 1) then
	--	-- ["ColourGuildNewButton"] = true,
	--	s,e = string.find(name, "Button");
	--	if (s and e) then
	--		name = string.sub(name, 0, s-1)
	--	end
	--	-- ["ColourGuildNewColour"] = true,
	--	s,e = string.find(name, "Colour", 2);	-- start at 2 to skip the initial Colour
	--	if (s and e) then
	--		name = string.sub(name, 0, s-1)
	--	end
	--end

	local tip = ""
	local head = ""
	if (FIZ_TXT.elements and
		FIZ_TXT.elements.name and
		FIZ_TXT.elements.tip and
		FIZ_TXT.elements.name[name] and
		FIZ_TXT.elements.tip[name]) then
		tip = FIZ_TXT.elements.tip[name]
		head = FIZ_TXT.elements.name[name]

		if (FIZ_Data.needsTip and FIZ_Data.needsTip[name]) then
			FIZ_Data.needsTip[name] = nil
		end
	else
		if (not FIZ_Data.needsTip) then
			FIZ_Data.needsTip = {}
		end
		FIZ_Data.needsTip[name] = true
	end

	--GameTooltip_SetDefaultAnchor(GameTooltip, self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	if (head ~= "") then
		GameTooltip:SetText(head, 1, 1, 0.5, 1.0, 1)
--		GameTooltip:AddLine(name, 1, 0, 0, 1.0, 1)
		GameTooltip:AddLine(tip, 1, 1, 1, 1.0, 1)
--	else
--		GameTooltip:SetText(element, 1, 1, 0.5, 1.0, 1)
--		GameTooltip:AddLine(name, 1, 1, 1, 1.0, 1)
	end

	GameTooltip:Show()
end

-----------------------------------
-- _12_ reputation Changes to chat
-----------------------------------
function FIZ_DumpReputationChangesToChat(initOnly)
	if not FIZ_StoredRep then FIZ_StoredRep = {} end

	local numFactions = GetNumFactions();
	local factionIndex, watchIndex, watchedIndex, watchName
	local name, standingID, barMin, barMax, barValue, isHeader, hasRep
	local RepRemains

	watchIndex = 0
	watchedIndex = 0
	watchName = nil
	for factionIndex=1, numFactions, 1 do
		name, _, standingID, barMin, barMax, barValue, _, _, isHeader, _, hasRep, isWatched = GetFactionInfo(factionIndex)

		--if (not isHeader) then
		if (not isHeader or hasRep) then
			if (isWatched) then
				watchedIndex = factionIndex
			end
			if FIZ_StoredRep[name] and not initOnly then
				if (FIZ_Data.WriteChatMessage) then
					if (not FIZ_Data.NoGuildGain or name ~= FIZ_GuildName) then
						local sign=""
						if ((barValue-FIZ_StoredRep[name].origRep)>0) then
							sign = "+"
						end
						if (barValue > FIZ_StoredRep[name].rep) then
							-- increased rep
							FIZ_Print(FIZ_NEW_REP_COLOUR..string.format(FACTION_STANDING_INCREASED..FIZ_TXT.stats, name, barValue-FIZ_StoredRep[name].rep, sign, barValue-FIZ_StoredRep[name].origRep, barMax-barValue))
						elseif (barValue < FIZ_StoredRep[name].rep) then
							FIZ_Print(FIZ_NEW_REP_COLOUR..string.format(FACTION_STANDING_DECREASED..FIZ_TXT.stats, name, FIZ_StoredRep[name].rep-barValue, sign, barValue-FIZ_StoredRep[name].origRep, barMax-barValue))
							-- decreased rep
						end
						if (FIZ_StoredRep[name].standingID ~= standingID) then
							FIZ_Print(FIZ_NEW_STANDING_COLOUR..string.format(FACTION_STANDING_CHANGED, _G["FACTION_STANDING_LABEL"..standingID], name))
						end
					end
				end
				if (FIZ_Data.SwitchFactionBar) then
					if (not FIZ_Data.NoGuildSwitch or name ~= FIZ_GuildName) then
						if (barValue > FIZ_StoredRep[name].rep) then
							--FIZ_Print("Marking faction ["..tostring(name).."] index ["..tostring(factionIndex).."] for rep watch bar")
							watchIndex = factionIndex
							watchName = name
						--elseif (barValue ~= FIZ_StoredRep[name].rep) then
							--FIZ_Print("Faction ["..tostring(name).."] lost rep")
						end
					end
				end
			else
				FIZ_StoredRep[name] = {}
				FIZ_StoredRep[name].origRep = barValue
			end
			FIZ_StoredRep[name].standingID = standingID
			FIZ_StoredRep[name].rep = barValue
		end
	end
	if (watchIndex > 0) then
		if (watchIndex ~= watchedIndex) then
			if (not FIZ_Data.SilentSwitch) then
				FIZ_Print(FIZ_HELP_COLOUR..FIZ_NAME..":|r "..FIZ_TXT.switchBar.." ["..tostring(watchName).."|r]")
			end
		end
		-- choose Faction to show
		SetWatchedFactionIndex(watchIndex)
		ReputationWatchBar_Update(); -- rfl functions
	end
end

function FIZ_ClearSessionGain()
	local factionIndex = GetSelectedFaction()
	local name, _, standingID, barMin, barMax, barValue, _, _, isHeader, _, hasRep, isWatched = GetFactionInfo(factionIndex)

	if (name) then
		FIZ_StoredRep[name] = {}
		FIZ_StoredRep[name].origRep = barValue
		FIZ_StoredRep[name].standingID = standingID
		FIZ_StoredRep[name].rep = barValue
	end
	FIZ_ReputationFrame_Update()
end

-----------------------------------
-- _13_ chat filtering
-----------------------------------

--function FIZ_ChatFrame_OnEvent(self, event, ...)
function FIZ_ChatFilter(chatFrame, event, ...) -- chatFrame = self
	--[[
	CHAT_MSG_COMBAT_FACTION_CHANGE
		Fires when player's faction changes. ie: "Your reputation with Timbermaw Hold has very slightly increased." -- NEW 1.9
		arg1
			The message to display

	COMBAT_TEXT_UPDATE
		arg1
			Combat message type.
			Known values include "HONOR_GAINED", and "FACTION".
		arg2
			for faction gain, this is the faction name.
		arg3
			for faction gain, the amount of reputation gained.
	]]--

	local msg, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13 = ...;
	local skip = false
	if (FIZ_Data.SuppressOriginalChat and event) then

		if (event == "CHAT_MSG_COMBAT_FACTION_CHANGE") then
			skip = true
		end
		if ((event == "COMBAT_TEXT_UPDATE") and (msg=="FACTION")) then
			skip = true
		end

	end
	return skip, msg, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13
end

-----------------------------------
-- _13_ show option window
-----------------------------------
function FIZ_ToggleConfigWindow()
	--- fpt f_tcw	FIZ_Printtest("f_tcw","","")
	if ReputationFrame:IsVisible() then
		if FIZ_OptionsFrame:IsVisible() then
			-- both windows shown -> hide them both
			FIZ_OptionsFrame:Hide()
			HideUIPanel(CharacterFrame)
		else
			-- options window not shown -> show, hide any detail window
			FIZ_OptionsFrame:Show()
			FIZ_ReputationDetailFrame:Hide();
			ReputationDetailFrame:Hide();
		end
	else
		-- window not shown -> show both
		ToggleCharacter("ReputationFrame")
		FIZ_ReputationDetailFrame:Hide();
		ReputationDetailFrame:Hide();
		FIZ_OptionsFrame:Show()
	end
end

function FIZ_ToggleDetailWindow()
	--- fpt f_tdw	FIZ_Printtest("f_tdw","","")
	if ReputationFrame:IsVisible() then
		if (FIZ_Data.ExtendDetails) then
			if FIZ_ReputationDetailFrame:IsVisible() then
				-- both windows shown -> hide them both
				FIZ_ReputationDetailFrame:Hide()
				HideUIPanel(CharacterFrame)
			else
				-- detail window not shown -> show it, hide any others
				FIZ_ReputationDetailFrame:Show()
				ReputationDetailFrame:Hide();
				FIZ_OptionsFrame:Hide();
				ReputationFrame_Update(); -- rfl Event
			end
		else
			if ReputationDetailFrame:IsVisible() then
				-- both windows shown -> hide them both
				ReputationDetailFrame:Hide()
				HideUIPanel(CharacterFrame)
			else
				-- detail window not shown -> show it, hide any others
				FIZ_ReputationDetailFrame:Hide()
				ReputationDetailFrame:Show();
				FIZ_OptionsFrame:Hide();
				ReputationFrame_Update(); -- rfl Event
			end
		end
	else
		-- window not shown -> show both
		ToggleCharacter("ReputationFrame")
		if (FIZ_Data.ExtendDetails) then
			FIZ_ReputationDetailFrame:Show();
		else
			ReputationDetailFrame:Show();
		end
		FIZ_OptionsFrame:Hide()
		ReputationFrame_Update(); -- rfl Event
	end
end



-----------------------------------
-- _14_ Testing
-----------------------------------


function FIZ_Test()

	if (FIZ_GuildFactionBar:GetParent()) then
		FIZ_Print("FIZ_GuildFactionBar parent: "..tostring(FIZ_GuildFactionBar:GetParent():GetName()))
	else
		FIZ_Print("FIZ_GuildFactionBar has no parent")
	end

	if (FIZ_GuildFactionBarCapHeader:GetParent()) then
		FIZ_Print("FIZ_GuildFactionBarCapHeader parent: "..tostring(FIZ_GuildFactionBarCapHeader:GetParent():GetName()))
	else
		FIZ_Print("FIZ_GuildFactionBarCapHeader has no parent")
	end
	if (FIZ_GuildFactionBarCapText:GetParent()) then
		FIZ_Print("FIZ_GuildFactionBarCapText parent: "..tostring(FIZ_GuildFactionBarCapText:GetParent():GetName()))
	else
		FIZ_Print("FIZ_GuildFactionBarCapText has no parent")
	end
	if (FIZ_GuildFactionBarCapMarker:GetParent()) then
		FIZ_Print("FIZ_GuildFactionBarCapMarker parent: "..tostring(FIZ_GuildFactionBarCapMarker:GetParent():GetName()))
	else
		FIZ_Print("FIZ_GuildFactionBarCapMarker has no parent")
	end
	if (FIZ_GuildFactionBarBaseMarker:GetParent()) then
		FIZ_Print("FIZ_GuildFactionBarBaseMarker parent: "..tostring(FIZ_GuildFactionBarBaseMarker:GetParent():GetName()))
	else
		FIZ_Print("FIZ_GuildFactionBarBaseMarker has no parent")
	end
end

-------------------------------------------
-- _15_ Getting reputation ready to hand In
-------------------------------------------
function FIZ_GetReadyReputation(factionIndex)

	local result = 0
	if not factionIndex then return result end

	if (not ReputationFrame:IsVisible()) then return result end

	local maxFactionIndex = GetNumFactions()
	if (factionIndex > maxFactionIndex) then return result end

	local faction, description, standingId, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild = FIZ_Orig_GetFactionInfo(factionIndex)
	if (isHeader) then return result end

	if (faction) then
		origFaction = faction
		faction = string.lower(faction)
	--- fpt grr	FIZ_Printtest(faction, FIZ_FactionMapping[faction],"1 grr")
		if (FIZ_FactionMapping[faction]) then
	--- fpt grr	FIZ_Printtest(faction, FIZ_FactionMapping[faction],"2 grr")
			faction = FIZ_FactionMapping[faction]
		end

		-- Normalize Values
		local normMax = barMax - barMin
		local normCurrent = barValue - barMin
		local repToNext = barMax - barValue

		local FIZ_FG_f=FIZ_FactionGain[faction]
		if (FIZ_FG_f) then
		local FIZ_FG_fs=FIZ_FG_f[standingId]
			if (FIZ_FG_fs) then

				-- quests (may have items)
				local FIZ_FG_fs_h=FIZ_FG_fs.quests
				if (FIZ_FG_fs_h) then
					for i = 0, FIZ_FG_fs_h.count do
					local FIZ_FG_fs_h_d=FIZ_FG_fs_h.data[i]
						if (not FIZ_FG_fs_h_d.limit or (normCurrent < FIZ_FG_fs_h_d.limit)) then
							local toDo = ceil(repToNext / FIZ_FG_fs_h_d.rep)
							if (FIZ_FG_fs_h_d.limit) then
								toDo = ceil((FIZ_FG_fs_h_d.limit - normCurrent) / FIZ_FG_fs_h_d.rep)
							end

							if (FIZ_FG_fs_h_d.items) then
								local currentQuestTimesBag = -1
								local currentQuestTimesBagBank = -1
								for item in pairs(FIZ_FG_fs_h_d.items) do
									if (FIZ_ItemsCarried and FIZ_ItemsCarried[item]) then
										if ((FIZ_ItemsCarried[item] >= FIZ_FG_fs_h_d.items[item]) and (FIZ_FG_fs_h_d.items[item] > 0)) then
											local localCurrentTimesBag = floor(FIZ_ItemsCarried[item] / FIZ_FG_fs_h_d.items[item])
											if (currentQuestTimesBag == -1) then
												-- first items for this quest --> take value
												currentQuestTimesBag = localCurrentTimesBag
											else
												-- some items already Set
												if (localCurrentTimesBag < currentQuestTimesBag) then
													-- fewer of this item than of others, reduce quest count
													currentQuestTimesBag = localCurrentTimesBag
												end
											end
										else
											-- not enough of this item for quest -> set to 0
											currentQuestTimesBag = 0
										end
										if (FIZ_Data.Bank and
										    FIZ_Data.Bank[FIZ_Realm.." - "..FIZ_Player] and
										    FIZ_Data.Bank[FIZ_Realm.." - "..FIZ_Player][item]) then
											local total = FIZ_Data.Bank[FIZ_Realm.." - "..FIZ_Player][item] + FIZ_ItemsCarried[item]
											if ((total >= FIZ_FG_fs_h_d.items[item]) and (FIZ_FG_fs_h_d.items[item] > 0)) then
												local localCurrentTimesBagBank = floor(total / FIZ_FG_fs_h_d.items[item])
												if (currentQuestTimesBagBank == -1) then
													-- first items for this quest --> take value
													currentQuestTimesBagBank = localCurrentTimesBagBank
												else
													-- some items already Set
													if (localCurrentTimesBagBank < currentQuestTimesBagBank) then
														-- fewer of this item than of others, reduce quest count
														currentQuestTimesBagBank = localCurrentTimesBagBank
													end
												end
											else
												-- not enough of this item for quest -> set to 0
												currentQuestTimesBagBank = 0
											end
										else
											-- none of this carried In bank
										end
									else
										-- not enough of this item for quest -> set to 0
										currentQuestTimesBag = 0
									end
								end
								if (currentQuestTimesBag > toDo) then
									currentQuestTimesBag = toDo
								end
								if (currentQuestTimesBagBank > toDo) then
									currentQuestTimesBagBank = toDo
								end
								if (currentQuestTimesBagBank > 0) then
									result = result + currentQuestTimesBagBank * FIZ_FG_fs_h_d.rep
								elseif (currentQuestTimesBag > 0) then
									result = result + currentQuestTimesBag * FIZ_FG_fs_h_d.rep
								else
									-- nothing to add
								end
							else
								-- no items, check if this quest is completed
								local entries, quests = GetNumQuestLogEntries()
								for z=1,entries do
									local title,level,tag,group,header,collapsed,complete,daily = GetQuestLogTitle(z)
									if (title and not header and complete) then
										if string.find(string.lower(FIZ_FG_fs_h_d.name), string.lower(title)) then
											-- this quest matches
											result = result + FIZ_FG_fs_h_d.rep
										end
									end
								end
							end
						end
					end
				end

				-- items
				local FIZ_FG_fs_h=FIZ_FG_fs.items
				if (FIZ_FG_fs_h and FIZ_Data.ShowItems) then
					for i = 0, FIZ_FG_fs_h.count do
					local FIZ_FG_fs_h_d=FIZ_FG_fs_h.data[i]
						if (not FIZ_FG_fs_h_d.limit or (normCurrent < FIZ_FG_fs_h_d.limit)) then
							local toDo = ceil(repToNext / FIZ_FG_fs_h_d.rep)
							if (FIZ_FG_fs_h_d.limit) then
								toDo = ceil((FIZ_FG_fs_h_d.limit - normCurrent) / FIZ_FG_fs_h_d.rep)
							end
							if (FIZ_FG_fs_h_d.items) then
								local currentQuestTimesBag = -1
								local currentQuestTimesBagBank = -1
								for item in pairs(FIZ_FG_fs_h_d.items) do
									if (FIZ_ItemsCarried and FIZ_ItemsCarried[item]) then
										if ((FIZ_ItemsCarried[item] >= FIZ_FG_fs_h_d.items[item]) and (FIZ_FG_fs_h_d.items[item] > 0)) then
											local localCurrentTimesBag = floor(FIZ_ItemsCarried[item] / FIZ_FG_fs_h_d.items[item])
											if (currentQuestTimesBag == -1) then
												-- first items for this quest --> take value
												currentQuestTimesBag = localCurrentTimesBag
											else
												-- some items already Set
												if (localCurrentTimesBag < currentQuestTimesBag) then
													-- fewer of this item than of others, reduce quest count
													currentQuestTimesBag = localCurrentTimesBag
												end
											end
										else
											-- not enough of this item for quest -> set to 0
											currentQuestTimesBag = 0
										end
										if (FIZ_Data.Bank and
										    FIZ_Data.Bank[FIZ_Realm.." - "..FIZ_Player] and
										    FIZ_Data.Bank[FIZ_Realm.." - "..FIZ_Player][item]) then
											local total = FIZ_Data.Bank[FIZ_Realm.." - "..FIZ_Player][item] + FIZ_ItemsCarried[item]
											if ((total >= FIZ_FG_fs_h_d.items[item]) and (FIZ_FG_fs_h_d.items[item] > 0)) then
												local localCurrentTimesBagBank = floor(total / FIZ_FG_fs_h_d.items[item])
												if (currentQuestTimesBagBank == -1) then
													-- first items for this quest --> take value
													currentQuestTimesBagBank = localCurrentTimesBagBank
												else
													-- some items already Set
													if (localCurrentTimesBagBank < currentQuestTimesBagBank) then
														-- fewer of this item than of others, reduce quest count
														currentQuestTimesBagBank = localCurrentTimesBagBank
													end
												end
											else
												-- not enough of this item for quest -> set to 0
												currentQuestTimesBagBank = 0
												FIZ_UpdateList[itemIndex].name = FIZ_UpdateList[itemIndex].name.." ["..total.."x]"
											end
										else
											-- none of this carried In bank
										end
									else
										-- not enough of this item for quest -> set to 0
										currentQuestTimesBag = 0
									end
								end
								if (currentQuestTimesBag > toDo) then
									currentQuestTimesBag = toDo
								end
								if (currentQuestTimesBagBank > toDo) then
									currentQuestTimesBagBank = toDo
								end
								if (currentQuestTimesBagBank > 0) then
									result = result + currentQuestTimesBagBank * FIZ_FG_fs_h_d.rep
								elseif (currentQuestTimesBag > 0) then
									result = result + currentQuestTimesBag * FIZ_FG_fs_h_d.rep
								end
							end
						end
					end
				end
			end
		end
	end

	return result;
end

----------------------------------
-- _16_ FSS // RDF_IS // RDF
-----------------------------------
-- ^ rfl 2.7 v ptr
function FIZ_StandingSort()
-- del	local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus;
	local standings = {}
	local numFactions = GetNumFactions();

	for i=1,numFactions do
		local name, description, standingID, _, barMax, barValue, _, _, isHeader, _, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus= GetFactionInfo(i);

		--if (not isHeader) then only list factions, not faction groups headers
		if (not isHeader or hasRep) then
			if not standings[standingID] then
				standings[standingID] = {}
			end
			local size = FIZ_TableSize(standings[standingID])
			local entry = {}
			local inserted = false
			entry.missing = barMax-barValue
			entry.i = i
			if (size) then
				for j=1,size do
					if (not inserted) then
						if (standings[standingID][j].missing > entry.missing) then
							table.insert(standings[standingID], j, entry);
							inserted = true
						end
					end
				end
				if (not inserted) then
					table.insert(standings[standingID], entry)
				end
			else
				table.insert(standings[standingID], entry)
			end
		end
	end

	-- find Number of elements to display
	local numFactions = 0
	FIZ_Entries = {}
	if (not FIZ_Collapsed) then
		FIZ_Collapsed = {}
	end
	for i=8,1, -1 do
	--for i In pairs(standings) do
		if FIZ_TableSize(standings[i]) then
			if (standings[i]) then
				numFactions = numFactions + 1 -- count standing as header
				FIZ_Entries[numFactions] = {}
				FIZ_Entries[numFactions].header = true
				FIZ_Entries[numFactions].i = i	-- this is the standingID
				FIZ_Entries[numFactions].size = FIZ_TableSize(standings[i]) -- this is the number of factions with this standing
				if (not FIZ_Collapsed[i]) then
					for j in pairs(standings[i]) do
						numFactions = numFactions + 1 -- count each faction in the current standing
						FIZ_Entries[numFactions] = {}
						FIZ_Entries[numFactions].header = false
						FIZ_Entries[numFactions].i = standings[i][j].i -- this is the index into the faction table
						FIZ_Entries[numFactions].size = 0
					end
				end
			end
		end
	end
	FIZ_OBS_numFactions = numFactions
end
-- ^ 2 rfl ptr v R_D_F_IS
function FIZ_ReputationDetailFrame_IsShown(faction,flag,flag2,i)
	local name, description = GetFactionInfo(faction);
-- v rfl _16_
	ReputationDetailFactionName:SetText(name);
	ReputationDetailFactionDescription:SetText(description);
	if ( atWarWith ) then
		ReputationDetailAtWarCheckBox:SetChecked(1);
	else
		ReputationDetailAtWarCheckBox:SetChecked(nil);
	end
-- v rfl _16_ 1
	if flag then
-- ^ rfl _16_ 1
		ReputationDetailAtWarCheckBox:Enable();
		ReputationDetailAtWarCheckBoxText:SetTextColor(RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
	else
		ReputationDetailAtWarCheckBox:Disable();
		ReputationDetailAtWarCheckBoxText:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
	end

	if flag2==2 then

		if ( not isHeader ) then
			ReputationDetailInactiveCheckBox:Enable();
			ReputationDetailInactiveCheckBoxText:SetTextColor(ReputationDetailInactiveCheckBoxText:GetFontObject():GetTextColor());
		else
			ReputationDetailInactiveCheckBox:Disable();
			ReputationDetailInactiveCheckBoxText:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
		end
-- v rfl _16_ 3
		_G["ReputationBar"..i.."ReputationBarHighlight1"]:Show();
		_G["ReputationBar"..i.."ReputationBarHighlight2"]:Show();
	end
-- ^ rfl _16_ 3
-- v rfl _16_ 2
	if ( IsFactionInactive(faction) ) then
		ReputationDetailInactiveCheckBox:SetChecked(1);
	else
		ReputationDetailInactiveCheckBox:SetChecked(nil);
	end
	if ( isWatched ) then
		ReputationDetailMainScreenCheckBox:SetChecked(1);
	else
		ReputationDetailMainScreenCheckBox:SetChecked(nil);
	end
-- ^ rfl _16_ 2
end
-- ^ R_D_F_IS v R_D_F
function FIZ_Rep_Detail_Frame(faction,colorID,barValue,barMax,origBarValue,standingID,toExalted,factionStandingtext)
	local name, description, _, _, _, _, atWarWith, canToggleAtWar, _, _, _, _, _, _, _, _ = GetFactionInfo(faction);
	local gender = UnitSex("player");
	FIZ_BuildUpdateList()

	FIZ_ReputationDetailFactionName:SetText(name);
	FIZ_ReputationDetailFactionDescription:SetText(description);

	FIZ_ReputationDetailStandingName:SetText(factionStandingtext)
	local color = FACTION_BAR_COLORS[colorID]
	FIZ_ReputationDetailStandingName:SetTextColor(color.r, color.g, color.b)

	FIZ_ReputationDetailStandingCurrent:SetText(FIZ_TXT.currentRep)
	FIZ_ReputationDetailStandingNeeded:SetText(FIZ_TXT.neededRep)
	FIZ_ReputationDetailStandingMissing:SetText(FIZ_TXT.missingRep)
	FIZ_ReputationDetailStandingBag:SetText(FIZ_TXT.repInBag)
	FIZ_ReputationDetailStandingBagBank:SetText(FIZ_TXT.repInBagBank)
	FIZ_ReputationDetailStandingQuests:SetText(FIZ_TXT.repInQuest)
	FIZ_ReputationDetailStandingGained:SetText(FIZ_TXT.factionGained)

	FIZ_ReputationDetailStandingCurrentValue:SetText(barValue)
	FIZ_ReputationDetailStandingNeededValue:SetText(barMax)
	FIZ_ReputationDetailStandingMissingValue:SetText(barMax-barValue)
	FIZ_ReputationDetailStandingBagValue:SetText(FIZ_CurrentRepInBag)
	FIZ_ReputationDetailStandingBagBankValue:SetText(FIZ_CurrentRepInBagBank)
	FIZ_ReputationDetailStandingQuestsValue:SetText(FIZ_CurrentRepInQuest)
	if (FIZ_StoredRep and FIZ_StoredRep[name] and FIZ_StoredRep[name].origRep) then
		FIZ_ReputationDetailStandingGainedValue:SetText(string.format("%d", origBarValue-FIZ_StoredRep[name].origRep))
	else
		FIZ_ReputationDetailStandingGainedValue:SetText("")
	end

	if (standingID <8) then
		color = FACTION_BAR_COLORS[standingID+1]
		--FIZ_ReputationDetailStandingNext:SetText(FIZ_TXT.nextLevel)
		FIZ_ReputationDetailStandingNextValue:SetText("(--> "..GetText("FACTION_STANDING_LABEL"..standingID+1, gender)..")")
		FIZ_ReputationDetailStandingNextValue:SetTextColor(color.r, color.g, color.b)
	else
		--FIZ_ReputationDetailStandingNext:SetText("")
		FIZ_ReputationDetailStandingNextValue:SetText("")
	end
	if (standingID <7) then
		FIZ_ReputationDetailStandingToExaltedHeader:SetText(FIZ_TXT.toExalted)
		FIZ_ReputationDetailStandingToExaltedValue:SetText(toExalted)
	else
		FIZ_ReputationDetailStandingToExaltedHeader:SetText("")
		FIZ_ReputationDetailStandingToExaltedValue:SetText("")
	end

	if ( atWarWith ) then
		FIZ_ReputationDetailAtWarCheckBox:SetChecked(1);
	else
		FIZ_ReputationDetailAtWarCheckBox:SetChecked(nil);
	end
	if ( canToggleAtWar ) then
		FIZ_ReputationDetailAtWarCheckBox:Enable();
		FIZ_ReputationDetailAtWarCheckBoxText:SetTextColor(RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
	else
		FIZ_ReputationDetailAtWarCheckBox:Disable();
		FIZ_ReputationDetailAtWarCheckBoxText:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
	end

	if ( IsFactionInactive(faction) ) then
		FIZ_ReputationDetailInactiveCheckBox:SetChecked(1);
	else
		FIZ_ReputationDetailInactiveCheckBox:SetChecked(nil);
	end
	if ( isWatched ) then
		FIZ_ReputationDetailMainScreenCheckBox:SetChecked(1);
	else
		FIZ_ReputationDetailMainScreenCheckBox:SetChecked(nil);
	end
end
-- ^ rfl R_D_F

function FIZ_Friend_Detail(factionID, standingID,factionRow)
	local colorIndex, factionStandingtext, isCappedFriendship;
	local friendID, friendRep, friendMaxRep, friendName, friendText, friendTexture, friendTextLevel, friendThreshold, nextFriendThreshold = GetFriendshipReputation(factionID);
	if (friendID ~= nil) then
		if ( nextFriendThreshold ) then
			barMin, barMax, barValue = friendThreshold, nextFriendThreshold, friendRep;
		else	-- max rank, make it look like a full bar
			barMin, barMax, barValue = 0, 1, 1;
			isCappedFriendship = true;
		end
		colorIndex = 5;	-- always color friendships green
		factionStandingtext = friendTextLevel;
		factionRow.friendshipID = friendID;
	else
		factionStandingtext = GetText("FACTION_STANDING_LABEL"..standingID, gender);
		factionRow.friendshipID = nil;
		colorIndex = standingID;
	end
	return colorIndex, isCappedFriendship, factionStandingtext
end

-----------------------------------
-- _16_ Listing by standing
-----------------------------------
function FIZ_ListByStanding(standing)
	local numFactions = GetNumFactions();
	local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, hasRep, isCollapsed, isWatched;
	local list = {}

	-- get factions by standing
	for i=1, numFactions do
		name, description, standingID, barMin, barMax, barValue, _, _, isHeader, _, hasRep = GetFactionInfo(i)
		--if (not isHeader) then
		if (not isHeader or hasRep) then
			if ((standing == nil) or (standing==standingID)) then
				if (not list[standingID]) then
					list[standingID] = {}
				end
				list[standingID][name]={}
				list[standingID][name].max = barMax-barMin
				list[standingID][name].value = barValue-barMin
			end
		end
	end

	-- output
	for i=1, 8 do
		if (list[i]) then
			FIZ_Print(FIZ_HELP_COLOUR..FIZ_NAME..":|r "..FIZ_RGBToColour_perc(1, FACTION_BAR_COLORS[i].r, FACTION_BAR_COLORS[i].g, FACTION_BAR_COLORS[i].b).."--- "..FIZ_TXT_STAND_LV[i].." ("..i..") ---|r")
			for p in pairs(list[i]) do
				--FIZ_Print("    "..p..": "..list[i][p].value.."/"..list[i][p].max.." ("..FIZ_TXT.missing2..": "..list[i][p].max-list[i][p].value..")")
				FIZ_Print("    "..p..": "..FIZ_TXT.missing2..": "..list[i][p].max-list[i][p].value)
			end
			if (not standing) then
				FIZ_Print(" ")
			end
		end
	end
end

-----------------------------------
-- _17_ list German names
-----------------------------------

function FIZ_ShowGerman(standing)

	local en,de,color,min,max
	min=1
	max=8
	if ((standing ~= nil) and (standing<=8)) then
		min=standing
		max=standing
	end
	FIZ_Print(FIZ_HELP_COLOUR..FIZ_NAME..":|r German standing names:")
	for i=min,max do
		en = _G["FACTION_STANDING_LABEL"..i]
		de = FIZ_TXT_STAND_LV[i]
		color = FACTION_BAR_COLORS[i]
		FIZ_Print("  "..FIZ_RGBToColour_perc(1,color.r,color.g,color.b)..i..": "..en.." = "..de)
	end
end

------------------------
-- _18_ extracting Skill information now 6
------------------------
function FIZ_ExtractSkills() --- ggg
	FIZ_Herb = false
	FIZ_Skin = false
	FIZ_Mine = false
	FIZ_Alche = false
	FIZ_Black = false
	FIZ_Enchan = false
	FIZ_Engin = false
	FIZ_Jewel = false
	FIZ_Incrip = false
	FIZ_Leath = false
	FIZ_Tailor = false
	FIZ_Aid = false
	FIZ_Arch = false
	FIZ_Cook = false
	FIZ_Fish = false

	local professions = {}
	local name, skillLine
	local prof1, prof2, archaeology, fishing, cooking, firstaid = GetProfessions();
	if (prof1) then
		name, _, _, _, _, _, skillLine = GetProfessionInfo(prof1);
		if name then professions[1] = name end
	end
	if (prof2) then
		name, _, _, _, _, _, skillLine = GetProfessionInfo(prof2);
		if name then professions[2] = name end
	end
	if (archaeology) then
		name, _, _, _, _, _, skillLine = GetProfessionInfo(archaeology);
		if name then professions[3] = name end
	end
	if (fishing) then
		name, _, _, _, _, _, skillLine = GetProfessionInfo(fishing);
		if name then professions[4] = name end
	end
	if (cooking) then
		name, _, _, _, _, _, skillLine = GetProfessionInfo(cooking);
		if name then professions[5] = name end
	end
	if (firstaid) then
		name, _, _, _, _, _, skillLine = GetProfessionInfo(firstaid);
		if name then professions[6] = name end
	end
	for skillIndex in pairs(professions) do
		skillName = professions[skillIndex] --- ggg zzz
		if (skillName == FIZ_TXT.skillHerb) then
			FIZ_Herb = true
		elseif (skillName == FIZ_TXT.skillSkin) then
			FIZ_Skin = true
		elseif (skillName == FIZ_TXT.skillMine) then
			FIZ_Mine = true
		elseif (skillName == FIZ_TXT.skillAlch) then
			FIZ_Alche = true
		elseif (skillName == FIZ_TXT.skillBlack) then
			FIZ_Black = true
		elseif (skillName == FIZ_TXT.skillEnch) then
			FIZ_Enchan = true
		elseif (skillName == FIZ_TXT.skillEngi) then
			FIZ_Engin = true
		elseif (skillName == FIZ_TXT.skillIncrip) then
			FIZ_Incrip = true
		elseif (skillName == FIZ_TXT.skillJewel) then
			FIZ_Jewel = true
		elseif (skillName == FIZ_TXT.skillLeath) then
			FIZ_Leath = true
		elseif (skillName == FIZ_TXT.skillTail) then
			FIZ_Tailor = true
		elseif (skillName == FIZ_TXT.skillAid) then
			FIZ_Aid = true
		elseif (skillName == FIZ_TXT.skillArch) then
			FIZ_Arch = true
		elseif (skillName == FIZ_TXT.skillCook) then
			FIZ_Cook = true
		elseif (skillName == FIZ_TXT.skillFish) then
			FIZ_Fish = true
		end
	end
--[[----------------------------------------------------------
	FIZ_Printtest(prof1, prof2, archaeology)--fpt --zzz
	FIZ_Printtest(fishing, cooking, firstaid)--fpt --zzz
	FIZ_Printtest("skillHerb",FIZ_TXT.skillHerb,FIZ_Herb)
	FIZ_Printtest("skillHerb",FIZ_TXT.skillMine,FIZ_Mine)
	FIZ_Printtest("skillHerb",FIZ_TXT.skillSkin,FIZ_Skin)
	FIZ_Printtest("skillHerb",FIZ_TXT.skillAlch,FIZ_Alche)
	FIZ_Printtest("skillHerb",FIZ_TXT.skillBlack,FIZ_Black)
	FIZ_Printtest("skillHerb",FIZ_TXT.skillEnch,FIZ_Enchan)
	FIZ_Printtest("skillHerb",FIZ_TXT.skillEngi,FIZ_Engin)
	FIZ_Printtest("skillHerb",FIZ_TXT.skillIncrip,FIZ_Incrip)
	FIZ_Printtest("skillHerb",FIZ_TXT.skillJewel,FIZ_Jewel)
	FIZ_Printtest("skillHerb",FIZ_TXT.skillLeath,FIZ_Leath)
	FIZ_Printtest("skillHerb",FIZ_TXT.skillAid,FIZ_Aid)
	FIZ_Printtest("skillHerb",FIZ_TXT.skillArch,FIZ_Arch)
	FIZ_Printtest("skillHerb",FIZ_TXT.skillCook,FIZ_Cook)
	FIZ_Printtest("skillHerb",FIZ_TXT.skillFish,FIZ_Fish)--]]--
end

--------------------------
-- _20_ classic options
--------------------------
function FIZ_OnShowOptionFrame()
	FIZ_EnableMissingBox:SetChecked(FIZ_Data.ShowMissing)
	FIZ_ExtendDetailsBox:SetChecked(FIZ_Data.ExtendDetails)
	FIZ_GainToChatBox:SetChecked(FIZ_Data.WriteChatMessage)
	FIZ_NoGuildGainBox:SetChecked(FIZ_Data.NoGuildGain)
	FIZ_SupressOriginalGainBox:SetChecked(FIZ_Data.SuppressOriginalChat)
	FIZ_ShowPreviewRepBox:SetChecked(FIZ_Data.ShowPreviewRep)
	FIZ_SwitchFactionBarBox:SetChecked(FIZ_Data.SwitchFactionBar)
	FIZ_NoGuildSwitchBox:SetChecked(FIZ_Data.NoGuildSwitch)
	FIZ_SilentSwitchBox:SetChecked(FIZ_Data.SilentSwitch)
	FIZ_OrderByStandingCheckBox:SetChecked(FIZ_Data.SortByStanding)

end

--------------------------
-- _21_ interface options
--------------------------
function FIZ_OnLoadOptions(panel)
	panel.name = FIZ_NAME
	panel.okay = FIZ_OptionsOk
	panel.cancel = FIZ_OptionsCancel
	panel.default = FIZ_OptionsDefault

	InterfaceOptions_AddCategory(panel);

	FIZ_OptionEnableMissingCBText:SetText(FIZ_TXT.showMissing)
	FIZ_OptionExtendDetailsCBText:SetText(FIZ_TXT.extendDetails)
	FIZ_OptionGainToChatCBText:SetText(FIZ_TXT.gainToChat)
	FIZ_OptionNoGuildGainCBText:SetText(FIZ_TXT.noGuildGain)
	FIZ_OptionSupressOriginalGainCBText:SetText(FIZ_TXT.suppressOriginalGain)
	FIZ_OptionShowPreviewRepCBText:SetText(FIZ_TXT.showPreviewRep)
	FIZ_OptionSwitchFactionBarCBText:SetText(FIZ_TXT.switchFactionBar)
	FIZ_OptionNoGuildSwitchCBText:SetText(FIZ_TXT.noGuildSwitch)
	FIZ_OptionSilentSwitchCBText:SetText(FIZ_TXT.silentSwitch)

end

------------------------------------------------------------
function FIZ_OnShowOptions(self)
	if (FIZ_Data and FIZ_VarsLoaded) then
		FIZ_OptionsShown = true
		FIZ_OptionEnableMissingCB:SetChecked(FIZ_Data.ShowMissing)
		FIZ_OptionExtendDetailsCB:SetChecked(FIZ_Data.ExtendDetails)
		FIZ_OptionGainToChatCB:SetChecked(FIZ_Data.WriteChatMessage)
		FIZ_OptionNoGuildGainCB:SetChecked(FIZ_Data.NoGuildGain)
		FIZ_OptionSupressOriginalGainCB:SetChecked(FIZ_Data.SuppressOriginalChat)
		FIZ_OptionShowPreviewRepCB:SetChecked(FIZ_Data.ShowPreviewRep)
		FIZ_OptionSwitchFactionBarCB:SetChecked(FIZ_Data.SwitchFactionBar)
		FIZ_OptionNoGuildSwitchCB:SetChecked(FIZ_Data.NoGuildSwitch)
		FIZ_OptionSilentSwitchCB:SetChecked(FIZ_Data.SilentSwitch)

	end
end

------------------------------------------------------------
function FIZ_OptionsOk()
	if (FIZ_OptionsShown) then
		FIZ_Data.ShowMissing = FIZ_OptionEnableMissingCB:GetChecked()
		FIZ_Data.ExtendDetails = FIZ_OptionExtendDetailsCB:GetChecked()
		FIZ_Data.WriteChatMessage = FIZ_OptionGainToChatCB:GetChecked()
		FIZ_Data.NoGuildGain = FIZ_OptionNoGuildGainCB:GetChecked()
		FIZ_Data.SuppressOriginalChat = FIZ_OptionSupressOriginalGainCB:GetChecked()
		FIZ_Data.ShowPreviewRep = FIZ_OptionShowPreviewRepCB:GetChecked()
		FIZ_Data.SwitchFactionBar = FIZ_OptionSwitchFactionBarCB:GetChecked()
		FIZ_Data.NoGuildSwitch = FIZ_OptionNoGuildSwitchCB:GetChecked()
		FIZ_Data.SilentSwitch = FIZ_OptionSilentSwitchCB:GetChecked()

		ReputationFrame_Update()
	end
	FIZ_OptionsShown = nil
end

------------------------------------------------------------
function FIZ_OptionsCancel()
	-- nothing to do
	FIZ_OptionsShown = nil
end

------------------------------------------------------------
function FIZ_OptionsDefault()
	-- nothing to do
end

--------------------------
-- _22_ Rep Main Window
--------------------------

function FIZ_SortByStanding(i,factionIndex,factionRow,factionBar,factionBarPreview,factionTitle,factionButton,factionStanding,factionBackground)
-- v rfl SBS

	local OBS_fi = FIZ_Entries[factionIndex]
	local OBS_fi_i = OBS_fi.i

	if (OBS_fi.header) then
		FIZ_ReputationFrame_SetRowType(factionRow, isChild, OBS_fi.header, hasRep);
		factionRow.LFGBonusRepButton:SetShown(false);
		-- display the standingID as Header
		if (OBS_fi_i == 8) then
			factionTitle:SetText(GetText("FACTION_STANDING_LABEL"..OBS_fi_i, gender).." ("..tostring(OBS_fi.size)..")");
		else
			factionTitle:SetText(GetText("FACTION_STANDING_LABEL"..OBS_fi_i, gender).." -> "..GetText("FACTION_STANDING_LABEL"..OBS_fi_i+1, gender).." ("..tostring(OBS_fi.size)..")");
		end
-- v rfl SBS 2
-- v rfl SBS 2.1
		if ( FIZ_Collapsed[OBS_fi_i] ) then
-- ^ rfl SBS 2.1
			factionButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
		else
			factionButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up");
		end
		factionRow.index = factionIndex
-- v rfl 2.2.2
		factionRow.isCollapsed = FIZ_Collapsed[OBS_fi_i];
-- ^ rfl SBS 2.2
-- ^ rfl SBS 2
	else
-- v rfl SBS 1
		-- get the info for this Faction
		local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus = GetFactionInfo(OBS_fi_i);
		factionTitle:SetText(name);
-- ^ rfl SBS 1
-- v rfl _16_
	local colorIndex, isCappedFriendship, factionStandingtext  = FIZ_Friend_Detail(factionID, standingID, factionRow);
-- ^ rfl  _16_
-- v rfl SBS 4
		-- Normalize Values

		local origBarValue = barValue

		barMax = barMax - barMin;
		barValue = barValue - barMin;
		barMin = 0;
-- ^ rfl SBS 4
-- v rfl SBS 3
-- v rfl SBS 3.1
		local toExalted = 0
		if (standingID <8) then
			toExalted = FIZ_ToExalted[standingID] + barMax - barValue;
		end

		factionRow.index = OBS_fi_i;

		if (FIZ_Data.ShowMissing) then
			factionRow.standingText = factionStandingtext.." ("..barMax - barValue..")";
		else
-- ^ rfl SBS 3.1
			factionRow.standingText = factionStandingtext;
-- v rfl SBS 3.2
		end
-- ^ rfl SBS 3.2
-- ^ rfl SBS 3
-- v rfl SBS 5
-- v rfl SBS 5.1
		factionStanding:SetText(factionRow.standingText);
-- ^ rfl SBS 5.1
		if ( isCappedFriendship ) then
			factionRow.tooltip = nil;
		else
			factionRow.tooltip = HIGHLIGHT_FONT_COLOR_CODE.." "..barValue.." / "..barMax..FONT_COLOR_CODE_CLOSE;
		end
		factionBar:SetMinMaxValues(0, barMax);
		factionBar:SetValue(barValue);
		local color = FACTION_BAR_COLORS[standingID];
		factionBar:SetStatusBarColor(color.r, color.g, color.b);
		factionBar.BonusIcon:SetShown(hasBonusRepGain);
		factionRow.LFGBonusRepButton.factionID = factionID;
		factionRow.LFGBonusRepButton:SetShown(canBeLFGBonus);
		factionRow.LFGBonusRepButton:SetChecked(lfgBonusFactionID == factionID);
		factionRow.LFGBonusRepButton:SetEnabled(lfgBonusFactionID ~= factionID);
-- ^ rfl SBS 5
		local previewValue = 0
		if (FIZ_Data.ShowPreviewRep) then
			previewValue = FIZ_GetReadyReputation(OBS_fi_i)
		end
		if ((previewValue > 0) and not ((standingID==8) and (barMax-barValue == 1) ) ) then
			factionBarPreview:Show()
			factionBarPreview:SetMinMaxValues(0, barMax)
			previewValue = previewValue + barValue
			if (previewValue > barMax) then previewValue = barMax end
			factionBarPreview:SetValue(previewValue)
			factionBarPreview:SetID(factionIndex)
			factionBarPreview:SetStatusBarColor(0.8, 0.8, 0.8, 0.5)
		else
			factionBarPreview:Hide()
		end
-- v rfl SBS 6
-- v rfl SBS 6.1
		FIZ_ReputationFrame_SetRowType(factionRow, isChild, OBS_fi.header, hasRep);
-- ^ rfl SBS 6.1
		factionRow:Show();
		-- Update details if this is the selected Faction
		if ( atWarWith ) then
			_G["ReputationBar"..i.."ReputationBarAtWarHighlight1"]:Show();
			_G["ReputationBar"..i.."ReputationBarAtWarHighlight2"]:Show();
		else
			_G["ReputationBar"..i.."ReputationBarAtWarHighlight1"]:Hide();
			_G["ReputationBar"..i.."ReputationBarAtWarHighlight2"]:Hide();
		end
		-- Update details if this is the selected faction
-- v rfl SBS 6
-- v rfl SBS 6.1
		if ( OBS_fi_i == GetSelectedFaction() ) then
-- ^ rfl SBS 6.1
			if ( ReputationDetailFrame:IsShown() ) then
-- ^ rfl SBS 6
				if ( canToggleAtWar ) then local flag = 1 end
-- v rfl _16_
				FIZ_ReputationDetailFrame_IsShown(OBS_fi_I,flag,1,i)
-- ^ rfl _16_
			end

			if ( FIZ_ReputationDetailFrame:IsVisible() ) then FIZ_Rep_Detail_Frame(OBS_fi_i,standingID,barValue,barMax,origBarValue,standingID,toExalted,factionStandingtext) end
			_G["ReputationBar"..i.."ReputationBarHighlight1"]:Show();
			_G["ReputationBar"..i.."ReputationBarHighlight2"]:Show();


-- v rfl SBS 7
		else
			_G["ReputationBar"..i.."ReputationBarHighlight1"]:Hide();
			_G["ReputationBar"..i.."ReputationBarHighlight2"]:Hide();
		end
-- ^ rfl SBS 7
	end

end
function FIZ_OriginalRepOrder(i,factionIndex,factionRow,factionBar,factionBarPreview,factionTitle,factionButton,factionStanding,factionBackground)
-- v rfl ORO


-- v rfl ORO 1
	local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus = GetFactionInfo(factionIndex);
	factionTitle:SetText(name);
-- ^ rfl ORO 1
-- v rfl ORO 2



	if ( isCollapsed ) then

		factionButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
	else
		factionButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up");
	end
	factionRow.index = factionIndex;

	factionRow.isCollapsed = isCollapsed;

-- ^ rfl ORO 2

-- v rfl _16_
	local colorIndex, isCappedFriendship, factionStandingtext  = FIZ_Friend_Detail(factionID, standingID, factionRow);
-- ^ rfl  _16_
	-- Normalize Values

	local origBarValue = barValue

	barMax = barMax - barMin;
	barValue = barValue - barMin;
	barMin = 0;
-- ^ rfl ORO 4
-- v rfl ORO 3
-- v rfl ORO 3.1
	local toExalted = 0
	if (standingID <8) then
		toExalted = FIZ_ToExalted[standingID] + barMax - barValue;
	end



	if (FIZ_Data.ShowMissing) then
		factionRow.standingText = factionStandingtext.." ("..barMax - barValue..")";
	else
-- ^ rfl ORO 3.1
		factionRow.standingText = factionStandingtext;
-- v rfl ORO 3.2
	end
-- ^ rfl ORO 3.2
-- ^ rfl ORO 3
-- v rfl ORO 5
-- v rfl ORO 5.1
	factionStanding:SetText(factionRow.standingText);
-- ^ rfl ORO 5.1
	if ( isCappedFriendship ) then
		factionRow.tooltip = nil;
	else
		factionRow.tooltip = HIGHLIGHT_FONT_COLOR_CODE.." "..barValue.." / "..barMax..FONT_COLOR_CODE_CLOSE;
	end
	factionBar:SetMinMaxValues(0, barMax);
	factionBar:SetValue(barValue);
	local color = FACTION_BAR_COLORS[colorIndex];
	factionBar:SetStatusBarColor(color.r, color.g, color.b);
	factionBar.BonusIcon:SetShown(hasBonusRepGain);
	factionRow.LFGBonusRepButton.factionID = factionID;
	factionRow.LFGBonusRepButton:SetShown(canBeLFGBonus);
	factionRow.LFGBonusRepButton:SetChecked(lfgBonusFactionID == factionID);
	factionRow.LFGBonusRepButton:SetEnabled(lfgBonusFactionID ~= factionID);
-- ^ rfl ORO 5
	local previewValue = 0
	if (FIZ_Data.ShowPreviewRep) then
		previewValue = FIZ_GetReadyReputation(factionIndex)
	end
	if ((previewValue > 0) and not ((standingID==8) and (barMax-barValue == 1) ) ) then
		factionBarPreview:Show()
		factionBarPreview:SetMinMaxValues(0, barMax)
		previewValue = previewValue + barValue
		if (previewValue > barMax) then previewValue = barMax end
		factionBarPreview:SetValue(previewValue)
		factionBarPreview:SetID(factionIndex)
		factionBarPreview:SetStatusBarColor(0.8, 0.8, 0.8, 0.5)
	else
	---	factionBarPreview:Hide()
	end
-- v rfl ORO 6

	ReputationFrame_SetRowType(factionRow, isChild, isHeader, hasRep);

	factionRow:Show();
	-- Update details if this is the selected Faction
	if ( atWarWith ) then
		_G["ReputationBar"..i.."ReputationBarAtWarHighlight1"]:Show();
		_G["ReputationBar"..i.."ReputationBarAtWarHighlight2"]:Show();
	else
		_G["ReputationBar"..i.."ReputationBarAtWarHighlight1"]:Hide();
		_G["ReputationBar"..i.."ReputationBarAtWarHighlight2"]:Hide();
	end

	if ( factionIndex == GetSelectedFaction() ) then

		if ( ReputationDetailFrame:IsShown() ) then
-- ^ rfl ORO 6
			if ( canToggleAtWar and (not isHeader)) then local flag = 1 end
-- v rfl _16_
			FIZ_ReputationDetailFrame_IsShown(factionIndex,flag,2,i)
-- ^ rfl _16_
		end
-- ^ rfl 1.5
		if ( FIZ_ReputationDetailFrame:IsVisible() ) then 
			FIZ_Rep_Detail_Frame(factionIndex,colorIndex,barValue,barMax,origBarValue,standingID,toExalted,factionStandingtext) 
			_G["ReputationBar"..i.."ReputationBarHighlight1"]:Show();
			_G["ReputationBar"..i.."ReputationBarHighlight2"]:Show();
		end
	else
		_G["ReputationBar"..i.."ReputationBarHighlight1"]:Hide();
		_G["ReputationBar"..i.."ReputationBarHighlight2"]:Hide();
	end
-- v rfl 1.6.1
end

--------------------------
-- _23_ Guild rep cap handling
--------------------------
------------------------------------------------------------
--function FIZ_GuildFrame_OnLoad(...)
	-- to Guild frame is now loaded, we can now attach our elements
	--FIZ_Print("----- OnLoad called ---------------")
--	if (GuildFactionBar) then
--		FIZ_GuildFactionBar:SetParent("GuildFactionBar")
--		FIZ_GuildFactionBarCapHeader:SetPoint("BOTTOMLEFT", "GuildFactionBar", "TOPLEFT", 0, 10)
--		FIZ_GuildFactionBarCapText:SetPoint("LEFT", "FIZ_GuildFactionBarCapHeader", "RIGHT", 2, 0)
--	end
--end

------------------------------------------------------------
--function FIZ_OnLoadGuildFactionBar(self)
--	hooksecurefunc("GuildFrame_LoadUI", FIZ_GuildFrame_OnLoad)

--	FIZ_GuildFactionBarCapHeader:SetText(FIZ_TXT.weeklyCap)
--	FIZ_GuildFactionBarCapText:SetText("")
--end	

