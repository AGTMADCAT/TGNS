local Plugin = Plugin
local kPlayerBadgeIconSize = 20
local prefixes = {}
local captains = {}
captains.isCaptainsCaptain = {}
captains.isOptedInForCaptains = {}
local isApproved = {}
local isQuerying = {}
local isVring = false
local isSquading = false
local isQueryingBadge = {}
local approveReceivedTotal = 0
local approveSentTotal = 0
local APPROVE_TEXTURE_DISABLED = "ui/approve/chevron-disabled.dds"
local QUERY_TEXTURE_DISABLED = "ui/query/contactcard-disabled.dds"
local SQUAD_TEXTURE_DISABLED = "ui/squads/squad-disabled-squad0.dds"
local lastUpdatedPingsWhen = {}
local pings = {}
local showCustomNumbersColumn = true
local showOptionals = false
local notes = {}
local hasJetPacks = {}
local showTeamMessages = true
-- local badgeLabels = {}
local vrConfirmed = {}
local countdownSoundEventName = "sound/tgns.fev/winorlose/countdown"
local tooltipSoundEventName = "sound/NS2.fev/common/hud_on"
local approveSoundEventName = "sound/tgns.fev/scoreboard/approve"
local badSoundEventName = "sound/tgns.fev/laps/bad"
local legSoundEventName = "sound/tgns.fev/laps/leg"
local bestSoundEventName = "sound/tgns.fev/laps/best"
local startSoundEventName = "sound/tgns.fev/laps/start"
local armorDecay1SoundEventName = "sound/tgns.fev/harvesterdecay/armordecay1"
local gameState = {}
gameState.gameIsInProgressLastSetToTrue = 0
gameState.gameIsInProgressLastSetToFalse = 0
gameState.gameIsInProgress = false
gameState.gameIsInCountdown = false
gameState.precisionResources = {}
gameState.nearbyAliveTeammateClientIndexes = {}
gameState.nearbyAliveTeammateClientIndexesLastQueried = {}
gameState.totalTeamResources = {}
local serverSimpleName
local squadNumbers={}
local hudTexts = {}

local squadNumberLastSetTimes = {}
local WELCOME_MESSAGES = { "Welcome to Tactical Gamer Natural Selection (TGNS)!",
						  "If you enjoy mature, respectful play, please ask about our reserved slots.",
						  "To learn more about TGNS, press 'M' and click 'Info'. Enjoy! :)",
						  "( oh, and click the heart at the top of the scoreboard to favorite the server! )" }
local EXTRA_SECONDS_TO_DISPLAY_BANNER_AFTER_TEXT_MESSAGES = 25
local communityDesignationCharacter = '?'
local welcomeBannerImageName
local armorlessMatureHarvesterEntityIds = {}
local startedUntrackableAfkActivityAt = 0
local wasInUntrackableAfkActivity = false
local isUsingSvi = {}
local hasAfkRelevantActivity
local afkRelevantActivityAnnouncedAt = 0
local recentCaptainsClientIndexes = {}
local fails = {}
fails.bka = {}
fails.newComms = {}

local CaptainsCaptainFontColor = Color(0, 1, 0, 1)
local guiItemTooltipText
local hoverBadge
local tunnelDescriptions = {}

local lastTeamNumber = {}
local lastUpdatedTeamNumbers = 0
local lastWinOrLoseWarningWhen = 0
local CHUDOptionsToDisableDuringWinOrLose = {"wps", "minwps"}
local resourceTowersKilled = {}
local serverAddress
local captainsEnabled

local statusColors = {
    ["Shotgun"] = Color(0,1,0,1), -- green
    ["MG"] = Color(1,0,0,1), -- green
    ["FT"] = Color(1,1,0,1), -- yellow
    ["GL"] = Color(1,0,1,1)} -- magenta


local has = {}
has.Celerity = {}
has.Adrenaline = {}
has.Silence = {}

has.Regeneration = {}
has.Carapace = {}
has.Crush = {}

has.Aura = {}
has.Focus = {}
has.Vampirism = {}

has.Welder = {}
has.Mines = {}
has.ClusterGrenade = {}
has.GasGrenade = {}
has.PulseGrenade = {}
has.muteAbility = {}

local kFavoriteIconSize = Vector(26, 26, 0)
local kFavoriteIconPos = Vector(5, 4, 0)
local kFavoriteTexture = PrecacheAsset("ui/menu/favorite.dds")
local kNonFavoriteTexture = PrecacheAsset("ui/menu/nonfavorite.dds")

local kFavoriteMouseOverColor = Color(1,1,0,1)
local kFavoriteColor = Color(1,1,1,0.9)

local streamingWebAddresses = {}

has.ChangedResolutionSinceAddingGameTimeFavorite = false

TGNS.HookNetworkMessage(Shine.Plugins.scoreboard.SCOREBOARD_DATA, function(message)
	prefixes[message.i] = message.p
	captains.isCaptainsCaptain[message.i] = message.c
	isUsingSvi[message.i] = message.s
	fails.bka[message.i] = message.b
	fails.newComms[message.i] = message.n
	has.Welder[message.i] = message.w
	has.Mines[message.i] = message.m
	has.ClusterGrenade[message.i] = message.cg
	has.GasGrenade[message.i] = message.gg
	has.PulseGrenade[message.i] = message.pg
	tunnelDescriptions[message.i] = message.t
	
	has.Celerity[message.i] = message.u1
	has.Adrenaline[message.i] = message.u2
	has.Silence[message.i] = message.u3

	has.Regeneration[message.i] = message.u4
	has.Carapace[message.i] = message.u5
	has.Crush[message.i] = message.u6

	has.Aura[message.i] = message.u7
	has.Focus[message.i] = message.u8
	has.Vampirism[message.i] = message.u9

	streamingWebAddresses[message.i] = message.streaming
	resourceTowersKilled[message.i] = message.rtk
	captains.isOptedInForCaptains[message.i] = message.o
end)

TGNS.HookNetworkMessage(Plugin.PRECISIONRESOURCES, function(message)
	gameState.precisionResources[message.i] = message.r
end)

TGNS.HookNetworkMessage(Plugin.TOTAL_TEAM_RESOURCES, function(message)
	gameState.totalTeamResources[message.t] = message.r
end)

TGNS.HookNetworkMessage(Plugin.TOGGLE_CUSTOM_NUMBERS_COLUMN, function(message)
	showCustomNumbersColumn = message.t
end)

TGNS.HookNetworkMessage(Plugin.APPROVE_RECEIVED_TOTAL, function(message)
	if message.t > approveReceivedTotal then
		Shared.PlaySound(Client.GetLocalPlayer(), approveSoundEventName, 0.015)
	end
	approveReceivedTotal = message.t
end)

TGNS.HookNetworkMessage(Plugin.TOGGLE_OPTIONALS, function(message)
	showOptionals = message.t
end)

TGNS.HookNetworkMessage(Plugin.ENABLE_MUTE, function(message)
	has.muteAbility[Client.GetLocalClientIndex()] = true
end)

TGNS.HookNetworkMessage(Plugin.RECENT_CAPTAINS, function(message)
	recentCaptainsClientIndexes = TGNS.Split(",", message.c)
end)


TGNS.HookNetworkMessage(Plugin.ALERT_ICON, function(message)
	if Client.WindowNeedsAttention then
		Client.WindowNeedsAttention()
	end
end)

TGNS.HookNetworkMessage(Plugin.SQUAD_CONFIRMED, function(message)
	squadNumberLastSetTimes[message.c] = Shared.GetTime()
	squadNumbers[message.c] = message.s
end)

TGNS.HookNetworkMessage(Plugin.VR_CONFIRMED, function(message)
	vrConfirmed[message.c] = true
end)

TGNS.HookNetworkMessage(Plugin.PLAYER_NOTE, function(message)
	local clientIndex = message.c
	local note = message.n
	notes[clientIndex] = note
end)

TGNS.HookNetworkMessage(Plugin.APPROVE_MAY_TRY_AGAIN, function(message)
	isApproved[message.c] = false
end)
TGNS.HookNetworkMessage(Plugin.DESIGNATION, function(message)
	communityDesignationCharacter = message.c
	local welcomeBannerImageNameModifier = communityDesignationCharacter == "S" and "_s" or (communityDesignationCharacter == "P" and "_p" or "")
	welcomeBannerImageName = string.format("ui/welcome/readyroom1%s.dds", welcomeBannerImageNameModifier)
end)
TGNS.HookNetworkMessage(Plugin.APPROVE_ALREADY_APPROVED, function(message)
	isApproved[message.c] = true
end)
TGNS.HookNetworkMessage(Plugin.APPROVE_RESET, function(message)
	isApproved = {}
end)
TGNS.HookNetworkMessage(Plugin.QUERY_ALLOWED, function(message)
	isQuerying[message.c] = false
end)
TGNS.HookNetworkMessage(Plugin.SQUAD_ALLOWED, function(message)
	isSquading = false
end)
TGNS.HookNetworkMessage(Plugin.VR_ALLOWED, function(message)
	isVring = false
end)
TGNS.HookNetworkMessage(Plugin.BADGE_QUERY_ALLOWED, function(message)
	isQueryingBadge[message.c] = false
end)
TGNS.HookNetworkMessage(Plugin.APPROVE_SENT_TOTAL, function(message)
	approveSentTotal = message.t
end)
TGNS.HookNetworkMessage(Plugin.HAS_JETPACK, function(message)
	hasJetPacks[message.c] = message.h
end)
TGNS.HookNetworkMessage(Plugin.HAS_JETPACK_RESET, function(message)
	hasJetPacks = {}
end)
TGNS.HookNetworkMessage(Plugin.SHOW_TEAM_MESSAGES, function(message)
	showTeamMessages = message.s
end)

TGNS.HookNetworkMessage(Plugin.GAME_IN_COUNTDOWN, function(message)
	gameState.gameIsInCountdown = message.b
end)

TGNS.HookNetworkMessage(Plugin.GAME_IN_PROGRESS, function(message)
	gameState.gameIsInProgress = message.b
	if gameState.gameIsInProgress then
		gameState.gameIsInProgressLastSetToTrue = Shared.GetTime()
	else
		gameState.gameIsInProgressLastSetToFalse = Shared.GetTime()
		TGNS.DoFor(CHUDOptionsToDisableDuringWinOrLose, function(key)
			if CHUDOptions and CHUDOptions[key] then
				CHUDOptions[key].disabled = false
			end
		end)
		tunnelDescriptions = {}
	end
end)

TGNS.HookNetworkMessage(Plugin.ARMORDECAY1, function(message)
	Shared.PlaySound(Client.GetLocalPlayer(), armorDecay1SoundEventName, 0.025)
end)

TGNS.HookNetworkMessage(Plugin.WINORLOSE_WARNING, function(message)
	Shared.PlaySound(Client.GetLocalPlayer(), countdownSoundEventName, 0.025)
	lastWinOrLoseWarningWhen = Shared.GetTime()
end)

TGNS.HookNetworkMessage(Plugin.TOOLTIP_SOUND, function(message)
	Shared.PlaySound(Client.GetLocalPlayer(), tooltipSoundEventName, 20.525)
end)

TGNS.HookNetworkMessage(Plugin.LAPS_BAD, function(message)
	Shared.PlaySound(Client.GetLocalPlayer(), badSoundEventName, 0.025)
end)

TGNS.HookNetworkMessage(Plugin.LAPS_LEG, function(message)
	Shared.PlaySound(Client.GetLocalPlayer(), legSoundEventName, 0.025)
end)

TGNS.HookNetworkMessage(Plugin.LAPS_BEST, function(message)
	Shared.PlaySound(Client.GetLocalPlayer(), bestSoundEventName, 0.025)
end)

TGNS.HookNetworkMessage(Plugin.LAPS_START, function(message)
	Shared.PlaySound(Client.GetLocalPlayer(), startSoundEventName, 0.025)
end)

TGNS.HookNetworkMessage(Plugin.SERVER_SIMPLE_NAME, function(message)
	serverSimpleName = message.n
end)

TGNS.HookNetworkMessage(Plugin.SERVER_ADDRESS, function(message)
	serverAddress = message.a
end)

TGNS.HookNetworkMessage(Plugin.TEAM_SCORES_DATA, function(message)
	Shared.ConsoleCommand(string.format("team1 %s", message.mn))
	Shared.ConsoleCommand(string.format("team2 %s", message.an))
	Shared.ConsoleCommand(string.format("score1 %s", message.ms))
	Shared.ConsoleCommand(string.format("score2 %s", message.as))
end)

TGNS.HookNetworkMessage(Plugin.WYZ, function(message)
	Shared.ConsoleCommand("connect 23.105.33.54")
end)

local function inProgressGameShouldProhibitSquadChanging(teamNumber)
	local result = gameState.gameIsInProgress and (Shared.GetTime() - gameState.gameIsInProgressLastSetToTrue > 30) and teamNumber == kAlienTeamType
	return result
end

local function getTeamApproveTexture(teamNumber)
	local result = string.format("ui/approve/chevron-team%s.dds", teamNumber)
	return result
end

local function getTeamSquadTexture(clientIndex, teamNumber, shouldBeDisabled)
	local teamDescriptor = string.format("%s%s", shouldBeDisabled and "disabled" or "team", teamNumber)
	local result = string.format("ui/squads/squad-%s-squad%s.dds", teamDescriptor, squadNumbers[clientIndex] or 0)
	return result
end

local function getTeamVrTexture(clientIndex, teamNumber)
	local result = vrConfirmed[clientIndex] and string.format("ui/vr/vr-checked-team%s.dds", teamNumber) or string.format("ui/vr/vr-team%s.dds", teamNumber)
	return result
end

local function getDisabledVrTexture(clientIndex)
	local result = vrConfirmed[clientIndex] and "ui/vr/vr-checked-disabled.dds" or VR_TEXTURE_DISABLED
	return result
end

local function getTeamQueryTexture(teamNumber)
	local result = string.format("ui/query/contactcard-team%s.dds", teamNumber)
	return result
end

function Plugin:GetTunnelDescriptions(clientIndex)
	return tunnelDescriptions[clientIndex] or ""
end

function Plugin:OnResolutionChanged( OldX, OldY, NewX, NewY )
	has.ChangedResolutionSinceAddingGameTimeFavorite = true
end

function Plugin:GetFailsBkaPrerequisite(clientIndex)
	return fails.bka[clientIndex]
end

function Plugin:GetFailsNewCommsPrerequisite(clientIndex)
	return fails.newComms[clientIndex]
end

function Plugin:GetPrefixes(clientIndex)
	return prefixes[clientIndex]
end

function updateTeamNumbers(forceUpdate)
	if forceUpdate or lastUpdatedTeamNumbers == nil or Shared.GetTime() - lastUpdatedTeamNumbers > 1 then
		TGNS.DoFor(ScoreboardUI_GetAllScores(), function(playerRecord)
	        local clientIndex = playerRecord.ClientIndex
	        local teamNumber = playerRecord.EntityTeamNumber
			if lastTeamNumber[clientIndex] == nil or lastTeamNumber[clientIndex].teamNumber ~= teamNumber then
				lastTeamNumber[clientIndex] = {teamNumber=teamNumber,when=lastTeamNumber[clientIndex] == nil and -30 or Shared.GetTime()}
			end
		end)
		lastUpdatedTeamNumbers = Shared.GetTime()
	end
end

function Plugin:Initialise()
	self.Enabled = true

	Client.PrecacheLocalSound(countdownSoundEventName)
	Client.PrecacheLocalSound(tooltipSoundEventName)
	Client.PrecacheLocalSound(approveSoundEventName)
	Client.PrecacheLocalSound(badSoundEventName)
	Client.PrecacheLocalSound(legSoundEventName)
	Client.PrecacheLocalSound(bestSoundEventName)
	Client.PrecacheLocalSound(startSoundEventName)
	Client.PrecacheLocalSound(armorDecay1SoundEventName)

	local scoreboardIsVisible = false
	local mouseIsHoveringOverPlayerRowOrFavoriteIcon = false

	local originalGUIScoreboardUpdate = GUIScoreboard.Update
	GUIScoreboard.Update = function(self, deltaTime)
		originalGUIScoreboardUpdate(self, deltaTime)

		scoreboardIsVisible = self.visible
		mouseIsHoveringOverPlayerRowOrFavoriteIcon = false

    	guiItemTooltipText = nil
    	hoverBadge = nil

        if self.visible == true then

        	updateTeamNumbers(true)

			for index, team in ipairs(self.teams) do
	            self:UpdateTeam(team)
		    end

            if guiItemTooltipText and self.badgeNameTooltip and not self.hoverMenu.background:GetIsVisible() and not MainMenu_GetIsOpened() and mouseIsHoveringOverPlayerRowOrFavoriteIcon then
				self.badgeNameTooltip:SetText(guiItemTooltipText)
				self.badgeNameTooltip.protectedText = guiItemTooltipText
                self.badgeNameTooltip:Show(0)
            else
                if not hoverBadge then
	                self.badgeNameTooltip:Hide(0, true)
                end
            end

            if self.gameTimeFavorite and not has.ChangedResolutionSinceAddingGameTimeFavorite then
				self.gameTimeFavorite:SetColor(kFavoriteColor)
	            if MouseTracker_GetIsVisible() then
					local mouseX, mouseY = Client.GetCursorPosScreen()
					if GUIItemContainsPoint(self.gameTimeFavorite, mouseX, mouseY) then
						self.gameTimeFavorite:SetColor(kFavoriteMouseOverColor)
					end
	            end
            end


        else
	    	if self.badgeNameTooltip then
	    		self.badgeNameTooltip:Hide(0, true)
			end
        end

        if Shine.VoteMenu.Visible then
        	self.badgeNameTooltip:Hide(0, true)
        end

     --    Shared.Message("Shared.GetTime(): " .. tostring(Shared.GetTime()))
	    -- Shared.Message("guiItemTooltipText: " .. tostring(guiItemTooltipText))
	    -- Shared.Message("hoverBadge: " .. tostring(hoverBadge))
	    -- Shared.Message("self.badgeNameTooltip: " .. tostring(self.badgeNameTooltip))
	    -- Shared.Message("self.hoverMenu.background:GetIsVisible(): " .. tostring(self.hoverMenu.background:GetIsVisible()))
	    -- Shared.Message("MainMenu_GetIsOpened(): " .. tostring(MainMenu_GetIsOpened()))
	    -- Shared.Message("Shine.VoteMenu.Visible: " .. tostring(Shine.VoteMenu.Visible))

	end

	local totalResourceNodesCount
	local originalGUIScoreboardUpdateTeam = GUIScoreboard.UpdateTeam
	GUIScoreboard.UpdateTeam = function(self, updateTeam)
		originalGUIScoreboardUpdateTeam(self, updateTeam)

		local numberOfMarinesPlaying = 0
		local numberOfAliensPlaying = 0

		local teamNumber = updateTeam["TeamNumber"]
		gameState.nearbyAliveTeammateClientIndexes[Client.GetLocalClientTeamNumber()] = gameState.nearbyAliveTeammateClientIndexes[Client.GetLocalClientTeamNumber()] or {}

		if self.visible then
	        local gameTime = PlayerUI_GetGameLengthTime()
	        local minutes = math.floor( gameTime / 60 )
	        local seconds = math.floor( gameTime - minutes * 60 )
	        local serverName = Client.GetServerIsHidden() and "Hidden" or Client.GetConnectedServerName()

	        local ingamePlayersCount = 0
		    for teamsIndex, team in ipairs(self.teams) do
		    	local playerList = team["PlayerList"]
		    	local teamScores = team["GetScores"]()

				for playerListIndex, player in ipairs(playerList) do
					local playerRecord = teamScores[playerListIndex]
					if playerRecord then
						if playerRecord.SteamId > 0 then
							ingamePlayersCount = ingamePlayersCount + 1
						end

						local prefix = prefixes[playerRecord.ClientIndex]
						if TGNS.HasNonEmptyValue(prefix) and (TGNS.Contains(prefix, "P") or TGNS.Contains(prefix, "A")) then
							if playerRecord.EntityTeamNumber == kMarineTeamType then
								numberOfMarinesPlaying = numberOfMarinesPlaying + 1
							elseif playerRecord.EntityTeamNumber == kAlienTeamType then
								numberOfAliensPlaying = numberOfAliensPlaying + 1
							end
						end
					end
				end
		    end
	        local numPlayersConnecting = PlayerUI_GetNumConnectingPlayers()
	        local mapName = Shared.GetMapName()
	        if IMGUIAirStatus then
	        	mapName = TGNS.Replace(mapName, "ns2_", "infest_")
	        end
	        local gameTimeText = string.format("%s | %s - (%d %s%s) - %d:%02d", serverName, mapName, ingamePlayersCount, ingamePlayersCount == 1 and Locale.ResolveString("SB_PLAYER") or Locale.ResolveString("SB_PLAYERS"), numPlayersConnecting > 0 and string.format(", %d %s", numPlayersConnecting, Locale.ResolveString("SB_CONNECTING")) or "", minutes, seconds)
	        self.gameTime:SetText(gameTimeText)

		end

        gameState.nearbyAliveTeammateClientIndexesLastQueried[Client.GetLocalClientTeamNumber()] = gameState.nearbyAliveTeammateClientIndexesLastQueried[Client.GetLocalClientTeamNumber()] or 0
        if Shared.GetTime() - gameState.nearbyAliveTeammateClientIndexesLastQueried[Client.GetLocalClientTeamNumber()] > 0.5 and TGNS.Has({kMarineTeamType, kAlienTeamType}, Client.GetLocalClientTeamNumber()) then
        	local player = Client.GetLocalPlayer()
        	gameState.nearbyAliveTeammateClientIndexes[Client.GetLocalClientTeamNumber()] = TGNS.Select(Shared.GetEntitiesWithTagInRange("class:Player", player:GetOrigin(), kMaxRelevancyDistance / 1.5, function(e) return e:GetTeamNumber() == Client.GetLocalClientTeamNumber() and not e:isa("Commander") end), function(p) return p:GetClientIndex() end)
        	gameState.nearbyAliveTeammateClientIndexesLastQueried[Client.GetLocalClientTeamNumber()] = Shared.GetTime()
		end




		if (has.ChangedResolutionSinceAddingGameTimeFavorite or not self.gameTimeFavorite) and serverAddress then
		    self.gameTimeFavorite = GUIManager:CreateGraphicItem()
		    self.gameTimeFavorite:SetSize(kFavoriteIconSize)
		    self.gameTimeFavorite:SetPosition(kFavoriteIconPos)
		    self.gameTimeFavorite:SetTexture(GetServerIsFavorite(serverAddress) and kFavoriteTexture or kNonFavoriteTexture)
		    self.gameTimeFavorite:SetColor(kFavoriteColor)
		    self.gameTimeBackground:AddChild(self.gameTimeFavorite)
		    has.ChangedResolutionSinceAddingGameTimeFavorite = false
		end

		local playerList = updateTeam["PlayerList"]
		local teamScores = updateTeam["GetScores"]()

		local currentPlayerIndex = 1
		local totalAfkCount = 0
		for index, player in pairs(playerList) do
	        local playerRecord = teamScores[currentPlayerIndex]
	        if playerRecord then

		        local clientIndex = playerRecord.ClientIndex

	        	player["Kills"]:SetText(string.format("%s [%s]", player["Kills"]:GetText(), resourceTowersKilled[clientIndex] or 0))

		        if showCustomNumbersColumn then
		        	player["Number"]:SetIsVisible(true)
			        local prefix = prefixes[clientIndex]
			        player["Number"]:SetText(TGNS.HasNonEmptyValue(prefix) and prefix or "")
			        local numberColor = Color(0.5, 0.5, 0.5, 1)
			        if numberOfMarinesPlaying >= 7 and numberOfAliensPlaying >= 7 then
			        	numberColor = Color(255/255, 255/255, 138/255, 1)
			        end
			        if captains.isCaptainsCaptain[clientIndex] == true then
			        	numberColor = CaptainsCaptainFontColor
			        	captainsEnabled = true
		        	elseif captains.isOptedInForCaptains[clientIndex] == true and clientIndex == Client.GetLocalClientIndex() and not captainsEnabled then
			        	numberColor = CaptainsCaptainFontColor
			        end
			        player["Number"]:SetColor(numberColor)
		        end

				local playerIsBot = playerRecord.Ping == 0 and TGNS.StartsWith(playerRecord.Name, "[BOT] ")

		        local tunnelIconTexture = nil
		        local tunnelDescription = tunnelDescriptions[clientIndex] or ""
		        if TGNS.HasNonEmptyValue(tunnelDescription) then
		        	tunnelIconTexture = "ui/badges/aliens/ClosedTunnel.dds"
		        	if TGNS.Contains(tunnelDescription, " / ") then
			        	tunnelIconTexture = "ui/badges/aliens/OpenTunnel.dds"
		        	end
		        end

		        local playerIconShouldDisplay = {}
		        playerIconShouldDisplay.Squad = (teamNumber == kMarineTeamType or teamNumber == kAlienTeamType) and ((teamNumber == Client.GetLocalClientTeamNumber()) or (PlayerUI_GetIsSpecating() and Client.GetLocalClientTeamNumber() ~= kMarineTeamType and Client.GetLocalClientTeamNumber() ~= kAlienTeamType)) and not playerIsBot
		        playerIconShouldDisplay.Approve = ((clientIndex ~= Client.GetLocalClientIndex()) and (not playerIsBot) and showOptionals)
		        playerIconShouldDisplay.Query = ((clientIndex ~= Client.GetLocalClientIndex()) and (not playerIsBot) and showOptionals)
		        playerIconShouldDisplay.Vr = (((Client.GetLocalClientTeamNumber() == kSpectatorIndex) or (teamNumber == Client.GetLocalClientTeamNumber())) and (clientIndex ~= Client.GetLocalClientIndex()) and (not playerIsBot) and showOptionals)
	        	playerIconShouldDisplay.Note = (teamNumber == kMarineTeamType or teamNumber == kAlienTeamType) and ((teamNumber == Client.GetLocalClientTeamNumber()) or (PlayerUI_GetIsSpecating() and Client.GetLocalClientTeamNumber() ~= kMarineTeamType and Client.GetLocalClientTeamNumber() ~= kAlienTeamType))
	        	-- playerIconShouldDisplay.ApproveStatus = (clientIndex == Client.GetLocalClientIndex() and showOptionals)
	        	playerIconShouldDisplay.Welder = (((Client.GetLocalClientTeamNumber() == kSpectatorIndex) or (teamNumber == Client.GetLocalClientTeamNumber() and teamNumber == kMarineTeamType)) and has.Welder[clientIndex] == true)
	        	playerIconShouldDisplay.Mines = (((Client.GetLocalClientTeamNumber() == kSpectatorIndex) or (teamNumber == Client.GetLocalClientTeamNumber() and teamNumber == kMarineTeamType)) and has.Mines[clientIndex] == true)
	        	playerIconShouldDisplay.ClusterGrenade = (((Client.GetLocalClientTeamNumber() == kSpectatorIndex) or (teamNumber == Client.GetLocalClientTeamNumber() and teamNumber == kMarineTeamType)) and has.ClusterGrenade[clientIndex] == true)
	        	playerIconShouldDisplay.GasGrenade = (((Client.GetLocalClientTeamNumber() == kSpectatorIndex) or (teamNumber == Client.GetLocalClientTeamNumber() and teamNumber == kMarineTeamType)) and has.GasGrenade[clientIndex] == true)
	        	playerIconShouldDisplay.PulseGrenade = (((Client.GetLocalClientTeamNumber() == kSpectatorIndex) or (teamNumber == Client.GetLocalClientTeamNumber() and teamNumber == kMarineTeamType)) and has.PulseGrenade[clientIndex] == true)
	        	playerIconShouldDisplay.Tunnel = (((Client.GetLocalClientTeamNumber() == kSpectatorIndex) or (teamNumber == Client.GetLocalClientTeamNumber() and teamNumber == kAlienTeamType)) and TGNS.HasNonEmptyValue(tunnelDescription))

				playerIconShouldDisplay.Celerity = (((Client.GetLocalClientTeamNumber() == kSpectatorIndex) or (teamNumber == Client.GetLocalClientTeamNumber() and teamNumber == kAlienTeamType)) and has.Celerity[clientIndex] == true)
				playerIconShouldDisplay.Adrenaline = (((Client.GetLocalClientTeamNumber() == kSpectatorIndex) or (teamNumber == Client.GetLocalClientTeamNumber() and teamNumber == kAlienTeamType)) and has.Adrenaline[clientIndex] == true)
				playerIconShouldDisplay.Silence = (((Client.GetLocalClientTeamNumber() == kSpectatorIndex) or (teamNumber == Client.GetLocalClientTeamNumber() and teamNumber == kAlienTeamType)) and has.Silence[clientIndex] == true)

				playerIconShouldDisplay.Regeneration = (((Client.GetLocalClientTeamNumber() == kSpectatorIndex) or (teamNumber == Client.GetLocalClientTeamNumber() and teamNumber == kAlienTeamType)) and has.Regeneration[clientIndex] == true)
				playerIconShouldDisplay.Carapace = (((Client.GetLocalClientTeamNumber() == kSpectatorIndex) or (teamNumber == Client.GetLocalClientTeamNumber() and teamNumber == kAlienTeamType)) and has.Carapace[clientIndex] == true)
				playerIconShouldDisplay.Crush = (((Client.GetLocalClientTeamNumber() == kSpectatorIndex) or (teamNumber == Client.GetLocalClientTeamNumber() and teamNumber == kAlienTeamType)) and has.Crush[clientIndex] == true)

				playerIconShouldDisplay.Aura = (((Client.GetLocalClientTeamNumber() == kSpectatorIndex) or (teamNumber == Client.GetLocalClientTeamNumber() and teamNumber == kAlienTeamType)) and has.Aura[clientIndex] == true)
				playerIconShouldDisplay.Focus = (((Client.GetLocalClientTeamNumber() == kSpectatorIndex) or (teamNumber == Client.GetLocalClientTeamNumber() and teamNumber == kAlienTeamType)) and has.Focus[clientIndex] == true)
				playerIconShouldDisplay.Vampirism = (((Client.GetLocalClientTeamNumber() == kSpectatorIndex) or (teamNumber == Client.GetLocalClientTeamNumber() and teamNumber == kAlienTeamType)) and has.Vampirism[clientIndex] == true)

		        playerIconShouldDisplay.Streaming = (teamNumber == 0 or Client.GetScreenWidth() >= 1280 or TGNS.Has({kGameState.Countdown,kGameState.Started,kGameState.Team1Won,kGameState.Team2Won,kGameState.Draw}, TGNS.GetGameState())) and TGNS.HasNonEmptyValue(streamingWebAddresses[clientIndex])





	        	local playerNote = notes[clientIndex]

	        	local targetPrefix = prefixes[clientIndex] or ""
		        if playerIconShouldDisplay.Vr then
	        		local targetPrefixFiltered = TGNS.Replace(targetPrefix, "!", "")
	        		targetPrefixFiltered = TGNS.Replace(targetPrefixFiltered, "*", "")
	        		playerIconShouldDisplay.Vr = not TGNS.HasNonEmptyValue(targetPrefixFiltered)
		        end

	        	if Shared.GetDevMode() then
			        playerIconShouldDisplay.Squad = true
			        playerIconShouldDisplay.Approve = true
			        playerIconShouldDisplay.Query = true
			        playerIconShouldDisplay.Vr = true
			        if teamNumber == kMarineTeamType or teamNumber == kAlienTeamType then
			        	playerIconShouldDisplay.Note = true
			        	if teamNumber == kMarineTeamType then
				        	playerIconShouldDisplay.Welder = true
				        	playerIconShouldDisplay.Mines = true
				        	playerIconShouldDisplay.ClusterGrenade = true
				        	playerIconShouldDisplay.GasGrenade = true
				        	playerIconShouldDisplay.PulseGrenade = true
				        elseif teamNumber == kAlienTeamType then
				        	playerIconShouldDisplay.Tunnel = true
				        	tunnelDescription = "Here / There"
				        	tunnelIconTexture = "ui/badges/aliens/OpenTunnel.dds"
				        	playerIconShouldDisplay.Celerity = true
				        	playerIconShouldDisplay.Adrenaline = true
				        	playerIconShouldDisplay.Silence = true

				        	playerIconShouldDisplay.Regeneration = true
				        	playerIconShouldDisplay.Carapace = true
				        	playerIconShouldDisplay.Crush = true

				        	playerIconShouldDisplay.Aura = true
				        	playerIconShouldDisplay.Focus = true
				        	playerIconShouldDisplay.Vampirism = true
			        	end
			        end
		        	-- playerIconShouldDisplay.ApproveNote = true
		        	playerNote = playerNote or "test"
		        	playerIconShouldDisplay.Streaming = true
	        	end

	   	        local icons = {
		        	{n="PlayerSquadIcon",t=SQUAD_TEXTURE_DISABLED,x=-25,l=function(clientIndex, teamNumber)
				        local circleName = "Player Circle"
				        local circleCycleName = "squads and lifeforms"
				        if teamNumber == kMarineTeamType then
				        	circleName = "Squad Circle"
				        	circleCycleName = "squad assignments"
				        elseif teamNumber == kAlienTeamType then
				        	circleName = "Lifeform Circle"
				        	circleCycleName = "planned lifeforms"
				        end
		        		return circleName .. "\n\nClick to cycle through\n" .. circleCycleName .. "."
		        	end}
		        	,{n="PlayerApproveIcon",t=APPROVE_TEXTURE_DISABLED,l="Approve Chevron\n\nClick to approve this player for any reason!\n\nAlso: if a player has an unchecked Voicecomm Vouch Bubble,\nclick this when you're SURE they can hear team voicecomm.\nThis lets the whole team see that the player has been vouched!"}
		        	,{n="PlayerQueryIcon",t=QUERY_TEXTURE_DISABLED,l="Contact Card\n\nClick to see player\nidentity information."}
		        	,{n="PlayerVrIcon",t=VR_TEXTURE_DISABLED,l="Voicecomm Vouch Bubble\n\nClick to warn anyone not\nresponding to team voicecomm.\n\nAlso: a checkmark in the bubble means someone already\nvouched that this player can hear team voicecomm."}
		        	,{n="PlayerWelderIcon",t="ui/badges/marines/Welder.dds",x=-139,l="Welder\n\nThis player has a Welder."}
		        	,{n="PlayerMinesIcon",t="ui/badges/marines/Mines.dds",x=-160,l="Mines\n\nThis player has Mines."}
		        	,{n="PlayerPulseGrenadeIcon",t="ui/badges/marines/Pulse.dds",x=-180,l="Pulse Grenades\n\nThis player has Pulse Grenades."}
		        	,{n="PlayerGasGrenadeIcon",t="ui/badges/marines/Gas.dds",x=-180,l="Gas Grenades\n\nThis player has Gas Grenades."}
		        	,{n="PlayerClusterGrenadeIcon",t="ui/badges/marines/Cluster.dds",x=-180,l="Cluster Grenades\n\nThis player has Cluster Grenades."}
		        	,{n="PlayerTunnelIcon",t=tunnelIconTexture,x=-140,l=function(clientIndex, teamNumber)
		        		local tunnelDescription = tunnelDescriptions[clientIndex] or ""
		        		return string.format("Gorge Tunnel\n\nThis player has a Gorge Tunnel.\n\nIt's %s in:\n\n%s%s", TGNS.Contains(tunnelDescription, " / ") and "OPEN" or "CLOSED", tunnelDescription, TGNS.Contains(tunnelDescription, " / ") and "\n\nNote: The first entrance listed above is older and\nwill be destroyed if this player drops another." or "")
		        	end}

		        	,{n="PlayerCelerityIcon",t="ui/badges/aliens/celerity.dds",x=-200,l="Celerity\n\nThis player has the Celerity upgrade."}
		        	,{n="PlayerAdrenalineIcon",t="ui/badges/aliens/adren.dds",x=-200,l="Adrenaline\n\nThis player has the Adrenaline upgrade."}
		        	,{n="PlayerSilenceIcon",t="ui/badges/aliens/silence.dds",x=-200,l="Silence\n\nThis player has the Silence upgrade."}

		        	,{n="PlayerAuraIcon",t="ui/badges/aliens/aura.dds",x=-180,l="Aura\n\nThis player has the Aura upgrade."}
		        	,{n="PlayerFocusIcon",t="ui/badges/aliens/focus.dds",x=-180,l="Focus\n\nThis player has the Focus upgrade."}
		        	,{n="PlayerVampirismIcon",t="ui/badges/aliens/vampirism.dds",x=-180,l="Vampirism\n\nThis player has the Vampirism upgrade."}

		        	,{n="PlayerRegenerationIcon",t="ui/badges/aliens/regen.dds",x=-160,l="Regeneration\n\nThis player has the Regeneration upgrade."}
		        	,{n="PlayerCarapaceIcon",t="ui/badges/aliens/cara.dds",x=-160,l="Carapace\n\nThis player has the Carapace upgrade."}
		        	,{n="PlayerCrushIcon",t="ui/badges/aliens/crush.dds",x=-160,l="Crush\n\nThis player has the Crush upgrade."}

		        	,{n="PlayerStreamingIcon",t="ui/badges/streaming/camera.dds",x=-220,l=function(clientIndex, teamNumber) return string.format("Streaming/Recording\n\n%s is streaming/recording!\n\nWatch: %s\n\nAre you streaming/recording? Chat '!streaming' to share.", Scoreboard_GetPlayerData(clientIndex, "Name"), streamingWebAddresses[clientIndex]) end}
		    	}

		    	if teamNumber == kMarineTeamType then
		    		if ((Client.GetLocalClientTeamNumber() == kMarineTeamType) or (Client.GetLocalClientTeamNumber() == kSpectatorIndex)) then
			    		local statusText = player.Status:GetText()
			    		if statusText and statusText ~= "Dead" then
				    		player.Status:SetColor(Color(1,1,1))
				    		TGNS.DoForPairs(statusColors, function(weapon, color)
				    			if TGNS.Contains(statusText, weapon) then
				    				player.Status:SetColor(color)
				    			end
				    		end)
			    		end
		    		end
		    	elseif teamNumber == kAlienTeamType then
		    		if ((Client.GetLocalClientTeamNumber() == kAlienTeamType) or (Client.GetLocalClientTeamNumber() == kSpectatorIndex)) then
		    			-- Shared.Message(string.format("%s %s %s %s", player.Status:GetText(), gameState.gameIsInProgress, playerRecord.Resources, playerRecord.ClientIndex))
		    			if playerRecord.Resources < 3 and gameState.gameIsInProgress and TGNS.Contains(player.Status:GetText(), "Gorge") then
		    				local precisionResources = gameState.precisionResources[playerRecord.ClientIndex]
		    				if precisionResources and precisionResources < 3 then
		    					player["Resources"]:SetText(ToString(math.floor(precisionResources * 10) / 10))
		    				end
		    			end
		    		end
		    	end

				TGNS.DoFor(icons, function(i)
					if player[i.n] then
						local icon = player[i.n]
						if icon:GetIsVisible() then
							if i.x then
								local iconPosition = icon:GetPosition()
								local statusPosition = player.Status:GetPosition()
								iconPosition.x = statusPosition.x + i.x
								icon:SetPosition(iconPosition)
							end
							if i.t ~= icon.lastTexture then
							    icon:SetTexture(i.t)
							    icon.lastTexture = i.t
							end
						end
					else
					    local icon = GUIManager:CreateGraphicItem()
					    --local position = player.Status:GetPosition()
					    --position.x = position.x + i.x
					    --position.y = position.y + (i.y or -10)
					    icon:SetSize(Vector(20, 20, 0))
					    icon:SetAnchor(GUIItem.Left, GUIItem.Center)
					    -- icon:SetPosition(position)
					    icon:SetTexture(i.t)
					    icon.lastTexture = i.t
					    icon.tooltipText = i.l
					    player[i.n] = icon
					    player.Background:AddChild(icon)
					    if player.IconTable then
					    	table.insert(player["IconTable"], icon)
					    end
					end
				end)

				if teamNumber == 0 and player.Status:GetText():find("Spec") then
					local shouldShowSvi = isUsingSvi[clientIndex] and Client.GetLocalClientTeamNumber() == kSpectatorIndex -- and isUsingSvi[Client.GetLocalClientIndex()]
					player.Status:SetText(shouldShowSvi and "Spec(SVI)" or "Spectator")
				end

				if teamNumber == 0 then
					if fails.bka[clientIndex] then
						player.Name:SetColor(TGNS.Colors.BkaFail)
					elseif fails.newComms[clientIndex] then
						player.Name:SetColor(TGNS.Colors.NewCommsFail)
					end
				end

				if not player.PlayerNoteItem then
					local playerNoteItem = GUIManager:CreateTextItem()
					playerNoteItem:SetFontName(GUIScoreboard.kTeamInfoFontName)
					playerNoteItem:SetAnchor(GUIItem.Left, GUIItem.Top)
					playerNoteItem:SetTextAlignmentX(GUIItem.Align_Max)
					playerNoteItem:SetTextAlignmentY(GUIItem.Align_Min)
					player.PlayerNoteItem = playerNoteItem
					player.Background:AddChild(playerNoteItem)
				end

				if clientIndex == Client.GetLocalClientIndex() and teamNumber == kAlienTeamType and player.Status and (squadNumbers[clientIndex] or 0) == 0 and TGNS.Has({kGameState.NotStarted,kGameState.PreGame,kGameState.WarmUp,kGameState.Countdown}, TGNS.GetGameState()) and Shared.GetTime() - (gameState.gameIsInProgressLastSetToFalse or 0) > TGNS.ENDGAME_TIME_TO_READYROOM + 1 then
					local moment = math.floor(Shared.GetTime())
					player.Status:SetText(moment % 2 == 0 and (moment % 4 == 0 and "<-- Role" or "<-- Plan") or "<- Click")
				end


	        	if player.SteamFriend then
				    player.SteamFriend:SetAnchor(GUIItem.Right, GUIItem.Center)
				    player.SteamFriend:SetPosition(Vector(-kPlayerBadgeIconSize/2, -kPlayerBadgeIconSize/2, 0) * GUIScoreboard.kScalingFactor)
				    player.SteamFriend:SetIsVisible(playerRecord.IsSteamFriend or Shared.GetDevMode() or Client.GetLocalClientIndex() == clientIndex)
				    if player.IconTable then
				    	table.removevalue(player.IconTable, player.SteamFriend)
				    end
	        	end


		        if TGNS.Contains(targetPrefix, "!") then
		        	totalAfkCount = totalAfkCount + 1
		        end

				local playerNoteItemPosition = player.Status:GetPosition()
				local xOffset = 0
				local addOffsetIf = function(boolean) if boolean then xOffset = xOffset + 20 end end
				addOffsetIf(playerIconShouldDisplay.Squad)
				addOffsetIf(playerIconShouldDisplay.Approve)
				addOffsetIf(playerIconShouldDisplay.Query)
				addOffsetIf(playerIconShouldDisplay.Vr)

				-- addOffsetIf(playerIconShouldDisplay.Welder)
				-- addOffsetIf(playerIconShouldDisplay.Mines)
				-- addOffsetIf(playerIconShouldDisplay.ClusterGrenade)
				-- addOffsetIf(playerIconShouldDisplay.GasGrenade)
				-- addOffsetIf(playerIconShouldDisplay.PulseGrenade)

				playerNoteItemPosition.x = playerNoteItemPosition.x - xOffset - 5
			    playerNoteItemPosition.y = playerNoteItemPosition.y + 7
				player.PlayerNoteItem:SetPosition(playerNoteItemPosition)

				local guiItems = {}
		        if player["PlayerApproveIcon"] then
		        	table.insert(guiItems, player["PlayerApproveIcon"])
		        	player["PlayerApproveIcon"]:SetIsVisible(playerIconShouldDisplay.Approve)
			        player["PlayerApproveIcon"]:SetTexture(isApproved[clientIndex] and APPROVE_TEXTURE_DISABLED or getTeamApproveTexture(teamNumber))
		        end
		        if player["PlayerVrIcon"] then
		        	table.insert(guiItems, player["PlayerVrIcon"])
		        	player["PlayerVrIcon"]:SetIsVisible(playerIconShouldDisplay.Vr)
		        	local playerVrIconShouldBeDisabled = isVring or (TGNS.Contains(targetPrefix, "!") and not vrConfirmed[clientIndex])
			        player["PlayerVrIcon"]:SetTexture(playerVrIconShouldBeDisabled and getDisabledVrTexture(clientIndex) or getTeamVrTexture(clientIndex, teamNumber))
		        end
		        if player["PlayerQueryIcon"] then
		        	table.insert(guiItems, player["PlayerQueryIcon"])
		        	player["PlayerQueryIcon"]:SetIsVisible(playerIconShouldDisplay.Query)
			        player["PlayerQueryIcon"]:SetTexture(isQuerying[clientIndex] and QUERY_TEXTURE_DISABLED or getTeamQueryTexture(teamNumber))
		        end
		        if player["PlayerWelderIcon"] then
		        	table.insert(guiItems, player["PlayerWelderIcon"])
		        	player["PlayerWelderIcon"]:SetIsVisible(playerIconShouldDisplay.Welder)
		        end
		        if player["PlayerMinesIcon"] then
		        	table.insert(guiItems, player["PlayerMinesIcon"])
		        	player["PlayerMinesIcon"]:SetIsVisible(playerIconShouldDisplay.Mines)
		        end
		        if player["PlayerClusterGrenadeIcon"] then
		        	table.insert(guiItems, player["PlayerClusterGrenadeIcon"])
		        	player["PlayerClusterGrenadeIcon"]:SetIsVisible(playerIconShouldDisplay.ClusterGrenade)
		        end
		        if player["PlayerGasGrenadeIcon"] then
		        	table.insert(guiItems, player["PlayerGasGrenadeIcon"])
		        	player["PlayerGasGrenadeIcon"]:SetIsVisible(playerIconShouldDisplay.GasGrenade)
		        end
		        if player["PlayerPulseGrenadeIcon"] then
		        	table.insert(guiItems, player["PlayerPulseGrenadeIcon"])
		        	player["PlayerPulseGrenadeIcon"]:SetIsVisible(playerIconShouldDisplay.PulseGrenade)
		        end
		        if player["PlayerTunnelIcon"] then
		        	table.insert(guiItems, player["PlayerTunnelIcon"])
		        	player["PlayerTunnelIcon"]:SetIsVisible(playerIconShouldDisplay.Tunnel)
		        end


		        if player["PlayerCelerityIcon"] then
		        	table.insert(guiItems, player["PlayerCelerityIcon"])
		        	player["PlayerCelerityIcon"]:SetIsVisible(playerIconShouldDisplay.Celerity)
		        end
		        if player["PlayerAdrenalineIcon"] then
		        	table.insert(guiItems, player["PlayerAdrenalineIcon"])
		        	player["PlayerAdrenalineIcon"]:SetIsVisible(playerIconShouldDisplay.Adrenaline)
		        end
		        if player["PlayerSilenceIcon"] then
		        	table.insert(guiItems, player["PlayerSilenceIcon"])
		        	player["PlayerSilenceIcon"]:SetIsVisible(playerIconShouldDisplay.Silence)
		        end

		        if player["PlayerRegenerationIcon"] then
		        	table.insert(guiItems, player["PlayerRegenerationIcon"])
		        	player["PlayerRegenerationIcon"]:SetIsVisible(playerIconShouldDisplay.Regeneration)
		        end
		        if player["PlayerCarapaceIcon"] then
		        	table.insert(guiItems, player["PlayerCarapaceIcon"])
		        	player["PlayerCarapaceIcon"]:SetIsVisible(playerIconShouldDisplay.Carapace)
		        end
		        if player["PlayerCrushIcon"] then
		        	table.insert(guiItems, player["PlayerCrushIcon"])
		        	player["PlayerCrushIcon"]:SetIsVisible(playerIconShouldDisplay.Crush)
		        end

		        if player["PlayerAuraIcon"] then
		        	table.insert(guiItems, player["PlayerAuraIcon"])
		        	player["PlayerAuraIcon"]:SetIsVisible(playerIconShouldDisplay.Aura)
		        end
		        if player["PlayerFocusIcon"] then
		        	table.insert(guiItems, player["PlayerFocusIcon"])
		        	player["PlayerFocusIcon"]:SetIsVisible(playerIconShouldDisplay.Focus)
		        end
		        if player["PlayerVampirismIcon"] then
		        	table.insert(guiItems, player["PlayerVampirismIcon"])
		        	player["PlayerVampirismIcon"]:SetIsVisible(playerIconShouldDisplay.Vampirism)
		        end








		        if player["PlayerStreamingIcon"] then
		        	table.insert(guiItems, player["PlayerStreamingIcon"])
		        	player["PlayerStreamingIcon"]:SetIsVisible(playerIconShouldDisplay.Streaming)
		        end
		        if player["SteamFriend"] and player["SteamFriend"]:GetIsVisible() then
		        	player["SteamFriend"].tooltipText = function(clientIndex, teamNumber) return string.format("Steam Friend\n\n%s", clientIndex == Client.GetLocalClientIndex() and "You're your own best friend!\n\n(Rows without this icon represent\nopportunities to add more players\nto your Steam Friends roster.)" or string.format("%s is in your Steam Friends list.", Scoreboard_GetPlayerData(clientIndex, "Name"))) end
		        	table.insert(guiItems, player["SteamFriend"])
		        end













			    local color = GUIScoreboard.kSpectatorColor
			    if teamNumber == kTeam1Index then
			        color = GUIScoreboard.kBlueColor
			    elseif teamNumber == kTeam2Index then
			        color = GUIScoreboard.kRedColor
			    end
		        -- local playerApproveStatusItem = player["PlayerApproveStatusItem"]
		        -- if playerApproveStatusItem then
		        -- 	table.insert(guiItems, playerApproveStatusItem)
		        -- 	playerApproveStatusItem:SetIsVisible(playerIconShouldDisplay.ApproveStatus)
		        -- 	playerApproveStatusItem:SetText(tostring(approveSentTotal) .. ":" .. tostring(approveReceivedTotal))
		        -- 	playerApproveStatusItem:SetColor(color)
		        -- end

		        if player["PlayerNoteItem"] then
		        	player["PlayerNoteItem"]:SetIsVisible(playerIconShouldDisplay.Note)
		        	player["PlayerNoteItem"]:SetText(string.format("%s", playerNote and playerNote or ""))
		        	player["PlayerNoteItem"]:SetColor(color)
		        end
		        if player["PlayerSquadIcon"] then
		        	table.insert(guiItems, player["PlayerSquadIcon"])
		        	player["PlayerSquadIcon"]:SetIsVisible(playerIconShouldDisplay.Squad)
		        	if playerIconShouldDisplay.Squad then
			        	local playerSquadIconShouldBeDisabled = isSquading or (Client.GetLocalClientTeamNumber() == kSpectatorIndex) or inProgressGameShouldProhibitSquadChanging(teamNumber)
				        player["PlayerSquadIcon"]:SetTexture(getTeamSquadTexture(clientIndex, teamNumber, playerSquadIconShouldBeDisabled))
		        	end
		        end

				if MouseTracker_GetIsVisible() and not guiItemTooltipText and not hoverBadge then
					local mouseX, mouseY = Client.GetCursorPosScreen()
					if GUIItemContainsPoint(player["Background"], mouseX, mouseY) then
						mouseIsHoveringOverPlayerRowOrFavoriteIcon = mouseIsHoveringOverPlayerRowOrFavoriteIcon or true
						for i = 1, #guiItems do
							local guiItem = guiItems[i]
							if GUIItemContainsPoint(guiItem, mouseX, mouseY) and guiItem:GetIsVisible() then
								guiItemTooltipText = type(guiItem.tooltipText) == "function" and guiItem.tooltipText(clientIndex, teamNumber) or guiItem.tooltipText
								break
							end
						end
		                for i = 1, #player.BadgeItems do
		                    local badgeItem = player.BadgeItems[i]
		                    if GUIItemContainsPoint(badgeItem, mouseX, mouseY) and badgeItem:GetIsVisible() then
		                        hoverBadge = true
		                        break
		                    end
		                end
		            elseif self.gameTimeFavorite and GUIItemContainsPoint(self.gameTimeFavorite, mouseX, mouseY) then
		            	mouseIsHoveringOverPlayerRowOrFavoriteIcon = mouseIsHoveringOverPlayerRowOrFavoriteIcon or true
		            	guiItemTooltipText = (GetServerIsFavorite(serverAddress) and "TGNS is in your favorites! Yay!\n\nClick the heart to remove it.\n(not that you'd ever want to...)" or "TGNS isn't in your favorites -- YET.\n\nClick the heart to add it (yayyy!!!).") 
					end
				end

				if TGNS.Has(recentCaptainsClientIndexes, tostring(clientIndex)) and teamNumber == 0 and not player.Status:GetText():find("Spec") then
					color = Color(17/255,115/255,17/255)
					player["Background"]:SetColor(color)
				elseif #gameState.nearbyAliveTeammateClientIndexes[Client.GetLocalClientTeamNumber()] > 1 and TGNS.Has(gameState.nearbyAliveTeammateClientIndexes[Client.GetLocalClientTeamNumber()], clientIndex) and not playerRecord.IsCommander then
					-- if math.floor(Shared.GetTime()) % 2 == 0 then
						-- color = Color((color.r*.5*255)/255,(color.g*.5*255)/255,(color.b*.5*255)/255) -- darker
						color = Color(1-(0.5*(1-color.r)),1-(0.5*(1-color.g)),1-(0.5*(1-color.b))) -- lighter
						player["Background"]:SetColor(color)
					-- end
				end

				if lastTeamNumber[clientIndex] ~= nil then
					local duration = 30
					local secondsSinceTeamNumberChange = Shared.GetTime() - lastTeamNumber[clientIndex].when
					if secondsSinceTeamNumberChange < duration and not playerRecord.IsCommander then
						local transparencyPercentage = secondsSinceTeamNumberChange / duration
						color = Color(color.r, color.g, color.b, transparencyPercentage)
						player["Background"]:SetColor(color)
					end
				end

				if self.hoverMenu then
					self.hoverMenu:RemoveButtonByText("Mute text")
					self.hoverMenu:RemoveButtonByText("Hive profile")
					if gameState.gameIsInProgress and (Client.GetLocalClientTeamNumber() == kMarineTeamType or Client.GetLocalClientTeamNumber() == kAlienTeamType) then
						self.hoverMenu:RemoveButtonByText("NS2Stats profile")
					end
					if not has.muteAbility[Client.GetLocalClientIndex()] then
						self.hoverMenu:RemoveButtonByText(Locale.ResolveString("SB_MENU_MUTE_VOICE"))
					end
				end
			end


	        currentPlayerIndex = currentPlayerIndex + 1
		end

		-- if gameState.gameIsInProgress and (Client.GetLocalClientTeamNumber() == kMarineTeamType or Client.GetLocalClientTeamNumber() == kAlienTeamType) and teamNumber == Client.GetLocalClientTeamNumber() then
		if ((Client.GetLocalClientTeamNumber() == kMarineTeamType or Client.GetLocalClientTeamNumber() == kAlienTeamType) and teamNumber == Client.GetLocalClientTeamNumber()) or Client.GetLocalClientTeamNumber() == kSpectatorIndex then

			local teamInfo = GetEntitiesForTeam("TeamInfo", teamNumber)
		    if teamInfo and #teamInfo > 0 then
			    local ownedResourceNodesCount = teamInfo[1]:GetNumResourceTowers()
			    totalResourceNodesCount = totalResourceNodesCount or Shared.GetEntitiesWithClassname("ResourcePoint"):GetSize()
			    local percentResourceNodesOwned = math.floor(ownedResourceNodesCount / totalResourceNodesCount * 100)
				local resourceNodesName = teamNumber == kMarineTeamType and "Extractors" or "Harvesters"

				local totalMarineResources = gameState.totalTeamResources[kMarineTeamType] or 0
				local totalAlienResources = gameState.totalTeamResources[kAlienTeamType] or 0
				local totalResources = totalMarineResources + totalAlienResources

				local teamResourcePercentages = {}
			    teamResourcePercentages[kMarineTeamType] = totalResources > 0 and math.floor(totalMarineResources / totalResources * 100) or 0
			    teamResourcePercentages[kAlienTeamType] = totalResources > 0 and 100 - teamResourcePercentages[kMarineTeamType] or 0

				local resourcesPercentage = teamResourcePercentages[teamNumber]

				local resourcesPercentageDisplay = string.format("; Resources Gathered: %s%%", resourcesPercentage)
		    	local teamInfoGUIItem = updateTeam["GUIs"]["TeamInfo"]
		    	if teamInfoGUIItem then
			    	local originalTeamInfoGuiItemText = teamInfoGUIItem:GetText()
				    teamInfoGUIItem:SetText(string.format("%s (%s: %s/%s - %s%%%s)", originalTeamInfoGuiItemText, resourceNodesName, ownedResourceNodesCount, totalResourceNodesCount, percentResourceNodesOwned, resourcesPercentageDisplay))
		    	end
		    end

		    local teamNameGUIItem = updateTeam["GUIs"]["TeamName"]
		    local teamNameGUIItemText = teamNameGUIItem:GetText()
			local truncatedTeamNameGUIItemText = string.sub(teamNameGUIItemText, 1, string.len(teamNameGUIItemText) - 1)
			local afkDisplay = totalAfkCount > 0 and string.format(", with %d AFK", totalAfkCount) or ""
			local supplyDisplay = (TGNS.IsGameplayTeamNumber(teamNumber) and gameState.gameIsInProgress) and string.format("            %s/%s Supply", GetSupplyUsedByTeam(teamNumber), GetMaxSupplyForTeam(teamNumber)) or ""
		    local teamHeaderText = string.format("%s%s)%s", truncatedTeamNameGUIItemText, afkDisplay, supplyDisplay)
		    teamNameGUIItem:SetText(teamHeaderText)

		end
	end

	local originalGUIScoreboardSendKeyEvent = GUIScoreboard.SendKeyEvent
	GUIScoreboard.SendKeyEvent = function(self, key, down)
		if self.hoverMenu then
			if self.hoverPlayerClientIndex ~= 0 then
				local isCommander = Scoreboard_GetPlayerData(self.hoverPlayerClientIndex, "IsCommander")
				local teamNumber = Scoreboard_GetPlayerData(self.hoverPlayerClientIndex, "EntityTeamNumber")
				local textColor = Color(1, 1, 1, 1)
				local teamColorBg
				local teamColorHighlight
				local groupLabelColor = Color(0, 0, 0, 0)
				
				if isCommander then
					teamColorBg = GUIScoreboard.kCommanderFontColor
				elseif teamNumber == 1 then
					teamColorBg = GUIScoreboard.kBlueColor
				elseif teamNumber == 2 then
					teamColorBg = GUIScoreboard.kRedColor
				else
					teamColorBg = GUIScoreboard.kSpectatorColor
				end
				
				teamColorHighlight = teamColorBg * 0.60
				teamColorBg = teamColorBg * 0.4					

				local targetPrefix = prefixes[self.hoverPlayerClientIndex] or ""
				local targetIsSelf = GetSteamIdForClientIndex(self.hoverPlayerClientIndex) == Client.GetSteamId()
				local targetIsEligibleForAfkRr = teamNumber == Client.GetLocalClientTeamNumber() and (not gameState.gameIsInProgress or PlayerUI_GetGameLengthTime() < 60) and TGNS.Contains(targetPrefix, "!") and (Client.GetLocalClientTeamNumber() == kMarineTeamType or Client.GetLocalClientTeamNumber() == kAlienTeamType)
				local playerName = Scoreboard_GetPlayerData(self.hoverPlayerClientIndex, "Name")
				local buttons = {
					{text="TGNS"}
				  , {text="  Portal: My Badges", callback=function(data) Client.ShowWebpage("http://rr.tacticalgamer.com/Badges/Manage") end, condition=targetIsSelf}
				  , {text="  Portal: My Karma", callback=function(data) Client.ShowWebpage("http://rr.tacticalgamer.com/Karma") end, condition=targetIsSelf}
				  , {text="  Portal: My Laps", callback=function(data) Client.ShowWebpage("http://rr.tacticalgamer.com/Laps/Manage") end, condition=targetIsSelf}
				  , {text="  Portal: My Tagline", callback=function(data) Client.ShowWebpage("http://rr.tacticalgamer.com/Tagline/Manage") end, condition=targetIsSelf}
				  , {text="  Portal: My Settings / NS2ID", callback=function(data) Client.ShowWebpage("http://rr.tacticalgamer.com/My/Settings") end, condition=targetIsSelf}
				  , {text="  Send to RR (pre/early-game AFK)", callback=function(data) TGNS.SendNetworkMessage(Plugin.REQUEST_AFKRR, {c=self.hoverPlayerClientIndex}) end, condition=targetIsEligibleForAfkRr}
				  , {text="Admin Feedback", callback=function(data) Client.ShowWebpage(string.format("http://rr.tacticalgamer.com/Feedback/Index?i=%s&n=%s&s=%s", data.ns2id, url_encode(data.playerName), url_encode(data.serverSimpleName))) end, condition=not targetIsSelf}
				  , {text=string.format("  Praise %s", playerName), callback=function(data) Client.ShowWebpage(string.format("http://rr.tacticalgamer.com/Feedback/Index?i=%s&n=%s&s=%s", data.ns2id, url_encode(data.playerName), url_encode(data.serverSimpleName))) end, condition=not targetIsSelf}
				  , {text=string.format("  Report %s", playerName), callback=function(data) Client.ShowWebpage(string.format("http://rr.tacticalgamer.com/Feedback/Index?i=%s&n=%s&s=%s", data.ns2id, url_encode(data.playerName), url_encode(data.serverSimpleName))) end, condition=not targetIsSelf}
				}
				local ns2id = GetSteamIdForClientIndex(self.hoverPlayerClientIndex)
				for i = 1, #buttons do
					local button = buttons[i]
					self.hoverMenu:RemoveButtonByText(button.text)
					if button.condition == nil or button.condition then
						local bgColor = button.callback and teamColorBg or groupLabelColor
						local highlightColor = button.callback and teamColorHighlight or groupLabelColor
						button.callback = button.callback or function() end
						self.hoverMenu:AddButton(button.text, bgColor, highlightColor, textColor, function() button.callback({ns2id=ns2id,playerName=playerName,serverSimpleName=serverSimpleName}) end)
					end
				end
			end
		end

			if (GetIsBinding(key, "MovementModifier")) then
				self.MovementModifierIsPressed = down
			end


		local result = originalGUIScoreboardSendKeyEvent(self, key, down)
		if result then
			local mouseX, mouseY = Client.GetCursorPosScreen()
		    for t = 1, #self.teams do

		        local playerList = self.teams[t]["PlayerList"]
		        for p = 1, #playerList do

		            local playerItem = playerList[p]
	                local clientIndex = playerItem["ClientIndex"]
		            local playerApproveIcon = playerItem["PlayerApproveIcon"]
		            if playerApproveIcon and playerApproveIcon:GetIsVisible() and GUIItemContainsPoint(playerApproveIcon, mouseX, mouseY) then
		            	if self.hoverMenu then
		            		self.hoverMenu:Hide()
		            	end
		            	if not isApproved[clientIndex] then
			                isApproved[clientIndex] = true
			                TGNS.SendNetworkMessage(Plugin.APPROVE_REQUESTED, {c=clientIndex})
		            	end
		            end
		            if playerItem["PlayerQueryIcon"] and playerItem["PlayerQueryIcon"]:GetIsVisible() and GUIItemContainsPoint(playerItem["PlayerQueryIcon"], mouseX, mouseY) then
		            	if self.hoverMenu then
		            		self.hoverMenu:Hide()
		            	end
		            	if not isQuerying[clientIndex] then
			                isQuerying[clientIndex] = true
			                TGNS.SendNetworkMessage(Plugin.QUERY_REQUESTED, {c=clientIndex})
		            	end
		            end
		            if playerItem["PlayerVrIcon"] and playerItem["PlayerVrIcon"]:GetIsVisible() and GUIItemContainsPoint(playerItem["PlayerVrIcon"], mouseX, mouseY) then
		            	if self.hoverMenu then
		            		self.hoverMenu:Hide()
		            	end
		            	if not isVring then
			                isVring = true
			                TGNS.SendNetworkMessage(Plugin.VR_REQUESTED, {c=clientIndex})
		            	end
		            end
		            local playerSquadIconShouldBeDisabled = isSquading or (Client.GetLocalClientTeamNumber() == kSpectatorIndex) or inProgressGameShouldProhibitSquadChanging(Client.GetLocalClientTeamNumber())
		            if playerItem["PlayerSquadIcon"] and playerItem["PlayerSquadIcon"]:GetIsVisible() and GUIItemContainsPoint(playerItem["PlayerSquadIcon"], mouseX, mouseY) then
		            	local squadNumberDelta = self.MovementModifierIsPressed and -1 or 1
		            	if self.hoverMenu then
		            		self.hoverMenu:Hide()
		            	end
		            	if (not playerSquadIconShouldBeDisabled) then
			                isSquading = true
			                TGNS.SendNetworkMessage(Shine.Plugins.squadnumbers.SQUAD_REQUESTED, {c=clientIndex,d=squadNumberDelta})
		            	end
		            end
		        end

		    end
	        if self.gameTimeFavorite and GUIItemContainsPoint(self.gameTimeFavorite, mouseX, mouseY) then
	        	local serverIsFavorite = GetServerIsFavorite(serverAddress)
	        	self.gameTimeFavorite:SetTexture(serverIsFavorite and kNonFavoriteTexture or kFavoriteTexture)
	            SetServerIsFavorite({address=serverAddress}, not serverIsFavorite)
	        end
		end
		return result
	end

	if GUIMarineTeamMessage == nil or GUIAlienTeamMessage == nil then
		Script.Load("lua/GUIMarineTeamMessage.lua")
	end

	if GUIMarineTeamMessage and GUIMarineTeamMessage.SetTeamMessage then
		local originalGUIMarineTeamMessageSetTeamMessage = GUIMarineTeamMessage.SetTeamMessage
		GUIMarineTeamMessage.SetTeamMessage = function(self, message)
			if showTeamMessages then
				originalGUIMarineTeamMessageSetTeamMessage(self, message)
			end
		end
	end

	if GUIAlienTeamMessage and GUIAlienTeamMessage.SetTeamMessage then
		local originalGUIAlienTeamMessageSetTeamMessage = GUIAlienTeamMessage.SetTeamMessage
		GUIAlienTeamMessage.SetTeamMessage = function(self, message)
			if showTeamMessages then
				originalGUIAlienTeamMessageSetTeamMessage(self, message)
			end
		end
	end

	local originalSharedGetString = Shared.GetString
	Shared.GetString = function(stringIndex)
		local result = stringIndex == TGNS.READYROOM_LOCATION_ID and "Ready Room" or originalSharedGetString(stringIndex)
		return result
	end

	local originalGUIHoverTooltipHide = GUIHoverTooltip.Hide
	GUIHoverTooltip.Hide = function(self, hideTime, hideProtectedText)
		if scoreboardIsVisible then
			-- Shared.Message(string.format("GUIHoverTooltip.Hide: hideTime=%s; hideProtectedText=%s; self.protectedText=%s; MouseTracker_GetIsVisible()=%s; scoreboardIsVisible=%s; mouseIsHoveringOverPlayerRowOrFavoriteIcon=%s", hideTime,hideProtectedText, self.protectedText, MouseTracker_GetIsVisible(), scoreboardIsVisible, mouseIsHoveringOverPlayerRowOrFavoriteIcon))
			-- Shared.Message("GUIHoverTooltip.Hide: 10")
			if self.protectedText and MouseTracker_GetIsVisible() then
				-- Shared.Message("GUIHoverTooltip.Hide: 20")
				if self.tooltip and self.tooltip.GetText and hideProtectedText and TGNS.Truncate(self.tooltip:GetText(), 50) == TGNS.Truncate(self.protectedText, 50) then
					-- Shared.ConsoleCommand("output GUIHoverTooltip.Hide: 30")
					-- Shared.Message("GUIHoverTooltip.Hide: 30")
					originalGUIHoverTooltipHide(self, hideTime)
					self.protectedText = nil
				end
			else
				-- Shared.Message("GUIHoverTooltip.Hide: 40")
				originalGUIHoverTooltipHide(self, hideTime)
				-- self.protectedText = nil
			end
		else
			-- Shared.Message("GUIHoverTooltip.Hide: 50")
			originalGUIHoverTooltipHide(self, hideTime)
			-- self.protectedText = nil
		end
	end

	local originalGUIInsight_PlayerHealthbarsUpdatePlayers
	originalGUIInsight_PlayerHealthbarsUpdatePlayers = Class_ReplaceMethod("GUIInsight_PlayerHealthbars", "UpdatePlayers", function(playerHealthbarsSelf, deltaTime)
		originalGUIInsight_PlayerHealthbarsUpdatePlayers(playerHealthbarsSelf, deltaTime)
		local players = Shared.GetEntitiesWithClassname("Player")
		for index, player in ientitylist(players) do
			if player:GetTeamNumber() == kMarineTeamType then
				local squadNumber = squadNumbers[player:GetClientIndex()] or 0
				if squadNumber ~= 0 then
					local playerIndex = player:GetId()
					local playerIsVisibleAliveGroundling = player:GetIsVisible() and player:GetIsAlive() and not player:isa("Commander")
					if playerIsVisibleAliveGroundling then
						local playerList = GetUpValue( GUIInsight_PlayerHealthbars.UpdatePlayers, "playerList", { LocateRecurse = true } )
						local playerGUI = playerList[playerIndex]
						if playerGUI and not Client.GetLocalPlayer():GetIsMinimapVisible() then
							local text = string.format("%s (Squad %s)", playerGUI.Name:GetText(), squadNumber)
							playerGUI.Name:SetText(text)
						end
					end
				end
			end
		end
	end)



	-- local originalGUIMinimapUpdate
	-- originalGUIMinimapUpdate = Class_ReplaceMethod("GUIMinimap", "Update", function(minimapSelf, deltaTime)
	-- 	local originalScoreboardGetPlayerRecord = Scoreboard_GetPlayerRecord
	-- 	Scoreboard_GetPlayerRecord = function(clientIndex)
	-- 		local playerRecord = originalScoreboardGetPlayerRecord(clientIndex)
	-- 		if playerRecord and playerRecord.EntityTeamNumber and playerRecord.EntityTeamNumber == kMarineTeamType then
	-- 			local squadNumber = squadNumbers[playerRecord.ClientIndex] or 0
	-- 			if squadNumber ~= 0 then
	-- 				playerRecord.Name = string.format("%s (Squad %s)", playerRecord.Name, squadNumber)
	-- 			end
	-- 		end
	-- 		return playerRecord
	-- 	end
	-- 	originalGUIMinimapUpdate(minimapSelf, deltaTime)
	-- 	Scoreboard_GetPlayerRecord = originalScoreboardGetPlayerRecord
	-- end)

	local parent, OldUpdateUnitStatusBlip = LocateUpValue( GUIUnitStatus.Update, "UpdateUnitStatusBlip", { LocateRecurse = true } )
	function SquadUpdateUnitStatusBlip( self, blipData, updateBlip, localPlayerIsCommander, baseResearchRot, showHints, playerTeamType )
		OldUpdateUnitStatusBlip( self, blipData, updateBlip, localPlayerIsCommander, baseResearchRot, showHints, playerTeamType )
		if blipData.IsPlayer and blipData.TeamType == Client.GetLocalClientTeamNumber() and blipData.TeamType == kMarineTeamType then
			local kUnitStatusCommanderDisplayRange = 50
			local kUnitStatusDisplayRange = 13

			local player = Client.GetLocalPlayer()
			local eyePos = player:GetEyePos()
	        local range = player:isa("Commander") and kUnitStatusCommanderDisplayRange or kUnitStatusDisplayRange
			local unit
			TGNS.DoFor(GetEntitiesWithMixinWithinRange("UnitStatus", eyePos, range), function(u)
				if u:GetUnitName(player) == blipData.Name then
					unit = u
				end
			end)
			if unit and unit.GetClientIndex then
				local clientIndex = unit:GetClientIndex()
				local squadNumber = squadNumbers[clientIndex]
				if squadNumber and squadNumber ~= 0 and not Client.GetLocalPlayer():GetIsMinimapVisible() then
					local textObject = updateBlip.NameText
					local originalText = textObject:GetText()
					local newText = string.format("%s (%s)", originalText, string.format("Squad %d", squadNumber))
					textObject:SetText(newText)
				end
			end
		end
	end
	ReplaceUpValue( parent, "UpdateUnitStatusBlip", SquadUpdateUnitStatusBlip, { LocateRecurse = true } )

	local originalGUIVoiceChatUpdate
	originalGUIVoiceChatUpdate = Class_ReplaceMethod("GUIVoiceChat", "Update", function(guivoicechatself, deltaTime)
		originalGUIVoiceChatUpdate(guivoicechatself, deltaTime)
		if Client.GetLocalClientTeamNumber() == kSpectatorIndex then
			if Client.GetScreenHeight() >= 1080 then
				local numAliens = 0
				local allPlayers = ScoreboardUI_GetAllScores()
--			    // How many items per player.
			    for i = 1, #allPlayers do
			        if allPlayers[i].EntityTeamNumber == kAlienTeamType then
			        	numAliens = numAliens + 1
			        end
			    end
			    if numAliens >= 7 then
			    	yOffset = 35
			    	if numAliens >= 8 then
			    		yOffset = yOffset + 45
			    	end
				    for i, bar in ipairs(guivoicechatself.chatBars) do
				        if bar.Background:GetIsVisible() then
					    	local position = bar.Background:GetPosition()
					    	position.y = position.y + yOffset
					    	bar.Background:SetPosition(position)
				        end
				    end
			    end
			end
			local marineCommanderName
			local alienCommanderName
			TGNS.DoFor(ScoreboardUI_GetAllScores(), function(s)
				if s.IsCommander then
					if s.EntityTeamNumber == kMarineTeamType then
						marineCommanderName = s.Name
					else
						alienCommanderName = s.Name
					end
				end
			end)
			TGNS.DoForPairs(guivoicechatself.chatBars, function(index, bar)
		        if bar.Background:GetIsVisible() then
			    	local chatBarPlayerName = bar.Name:GetText()
			    	local commanderNamePrefix
			    	if chatBarPlayerName == marineCommanderName then
			    		commanderNamePrefix = "MC"
			    	elseif chatBarPlayerName == alienCommanderName then
			    		commanderNamePrefix = "AC"
			    	end
			    	if commanderNamePrefix then
			    		bar.Name:SetText(string.format("[%s] %s", commanderNamePrefix, bar.Name:GetText()))
			    	end
		        end
			end)
		end
	end)

	local originalGUIReadyRoomOrdersUninitialize
	originalGUIReadyRoomOrdersUninitialize = Class_ReplaceMethod("GUIReadyRoomOrders", "Uninitialize", function(guiReadyRoomOrdersUninitializeSelf)
		originalGUIReadyRoomOrdersUninitialize(guiReadyRoomOrdersUninitializeSelf)
		if guiReadyRoomOrdersUninitializeSelf.logo then
			GUI.DestroyItem(guiReadyRoomOrdersUninitializeSelf.logo)
		end
		guiReadyRoomOrdersUninitializeSelf.logo = nil
    end)

	local message
	local welcomeIsFinished

	local originalGUIReadyRoomOrdersInitialize
	originalGUIReadyRoomOrdersInitialize = Class_ReplaceMethod("GUIReadyRoomOrders", "Initialize", function(guiReadyRoomOrdersInitializeSelf)
		originalGUIReadyRoomOrdersInitialize(guiReadyRoomOrdersInitializeSelf)
		guiReadyRoomOrdersInitializeSelf.welcomeTextCount = nil
		welcomeIsFinished = nil
		message = nil
    end)

	local originalGUIReadyRoomOrdersUpdate
	originalGUIReadyRoomOrdersUpdate = Class_ReplaceMethod("GUIReadyRoomOrders", "Update", function(guiReadyRoomOrdersUpdateSelf, deltaTime)
		originalGUIReadyRoomOrdersUpdate(guiReadyRoomOrdersUpdateSelf, deltaTime)

		local displayBannerImageName
		if fails.bka[Client.GetLocalClientIndex()] then
			displayBannerImageName = "ui/welcome/bka_advisory.dds"
		elseif welcomeBannerImageName and not welcomeIsFinished then
			displayBannerImageName = welcomeBannerImageName
		end

		local kFadeInColor = Color(1, 1, 1, 1)
		local kFadeOutColor = Color(1, 1, 1, 0)
		if displayBannerImageName then
			local displayBannerImageNameIsWelcomeBannerImageName = displayBannerImageName == welcomeBannerImageName
			local kWelcomeFadeInTime = 4
			local kWelcomeFadeOutTime = 1
			local kWelcomeStartFadeOutTime = 6
			local kWelcomeTextReset = 8
			local kLogoSize = GUIScale(Vector(1024, 180, 0))

			if not guiReadyRoomOrdersUpdateSelf.logo then
				guiReadyRoomOrdersUpdateSelf.logo = GetGUIManager():CreateGraphicItem()
				guiReadyRoomOrdersUpdateSelf.logo:SetSize(kLogoSize)
				guiReadyRoomOrdersUpdateSelf.logo:SetPosition(Vector(-kLogoSize.x * 0.5, kLogoSize.y * 0.3, 0))
				guiReadyRoomOrdersUpdateSelf.logo:SetAnchor(GUIItem.Middle, GUIItem.Top)
				guiReadyRoomOrdersUpdateSelf.logo:SetColor(kFadeOutColor)
			end

			guiReadyRoomOrdersUpdateSelf.logo:SetTexture(displayBannerImageName)

			if displayBannerImageNameIsWelcomeBannerImageName then
				if guiReadyRoomOrdersUpdateSelf.welcomeTextCount == nil then
					guiReadyRoomOrdersUpdateSelf.welcomeText:SetColor(kFadeOutColor)
					guiReadyRoomOrdersUpdateSelf.welcomeTextCount = 0
				else
					local timeSinceStart = Shared.GetTime() - guiReadyRoomOrdersUpdateSelf.welcomeTextStartTime
					for i = 1, #WELCOME_MESSAGES do
						if timeSinceStart > kWelcomeTextReset and i > guiReadyRoomOrdersUpdateSelf.welcomeTextCount then
							message = WELCOME_MESSAGES[i]
						    guiReadyRoomOrdersUpdateSelf.welcomeText:SetText(message)
						    guiReadyRoomOrdersUpdateSelf.welcomeText:SetColor(kFadeOutColor)
						    guiReadyRoomOrdersUpdateSelf.welcomeTextStartTime = Shared.GetTime()
						    guiReadyRoomOrdersUpdateSelf.welcomeTextCount = i
						    break
						end
					end

					if timeSinceStart <= kWelcomeFadeInTime then
						local color = LerpColor(kFadeOutColor, kFadeInColor, Clamp(timeSinceStart / kWelcomeFadeInTime, 0, 1))
					    guiReadyRoomOrdersUpdateSelf.welcomeText:SetColor(color)
						if message == WELCOME_MESSAGES[1] then
							guiReadyRoomOrdersUpdateSelf.logo:SetColor(color)
						end
					elseif timeSinceStart >= kWelcomeStartFadeOutTime then
						guiReadyRoomOrdersUpdateSelf.welcomeText:SetColor(LerpColor(kFadeInColor, kFadeOutColor, Clamp((timeSinceStart - kWelcomeStartFadeOutTime) / kWelcomeFadeOutTime, 0, 1)))
						if message == WELCOME_MESSAGES[#WELCOME_MESSAGES] and timeSinceStart >= kWelcomeFadeOutTime + kWelcomeTextReset + EXTRA_SECONDS_TO_DISPLAY_BANNER_AFTER_TEXT_MESSAGES then
							local percentage = Clamp((timeSinceStart  - (kWelcomeFadeOutTime + kWelcomeTextReset + EXTRA_SECONDS_TO_DISPLAY_BANNER_AFTER_TEXT_MESSAGES)) / kWelcomeFadeOutTime, 0, 1)
							guiReadyRoomOrdersUpdateSelf.logo:SetColor(LerpColor(kFadeInColor, kFadeOutColor, percentage))
							if percentage == 1 then
								welcomeIsFinished = true -- thanks to / inspired by: https://steamcommunity.com/sharedfiles/filedetails/?id=132302678
							end
						end
					end
				end
			else
				guiReadyRoomOrdersUpdateSelf.logo:SetColor(kFadeInColor)
			end
		else
			if guiReadyRoomOrdersUpdateSelf.logo then
				guiReadyRoomOrdersUpdateSelf.logo:SetColor(kFadeOutColor)
			end
		end
	end)

	local purple = Color(.625, .125, 0.9375)
	local darkKhaki = Color(0.73828125, 0.71484375, 0.41796875)
	local khaki = Color(240/255,230/255,140/255)

	TGNS.HookNetworkMessage(Plugin.ARMORLESS_HARVESTERS, function(message)
		armorlessMatureHarvesterEntityIds = StringSplit(message.l, ",")
	end)

	local originalMapBlipGetMapBlipColor = MapBlip.GetMapBlipColor
	MapBlip.GetMapBlipColor = function(self, minimap, item)
		local result = originalMapBlipGetMapBlipColor(self, minimap, item)
		if EnumToString(kMinimapBlipType, self.mapBlipType) == "Harvester" and Client.GetLocalClientTeamNumber() ~= kMarineTeamType and not self:GetIsInCombat() then
			for i = 1, #armorlessMatureHarvesterEntityIds do
				local armorlessMatureHarvesterEntityId = armorlessMatureHarvesterEntityIds[i]
				if tonumber(armorlessMatureHarvesterEntityId) == tonumber(self.ownerEntityId) then
					result = khaki
					break
				end
			end
		end
		return result
	end

	originalMouseTracker_SendKeyEvent = MouseTracker_SendKeyEvent
	MouseTracker_SendKeyEvent = function(key, down, amount, inputBlocked)
		local result = originalMouseTracker_SendKeyEvent(key, down, amount, inputBlocked)
		hasAfkRelevantActivity = true
		return result
	end

	local function ReplacementGetMostRelevantPheromone(toOrigin)
	    local pheromones = GetEntitiesWithinRange("Pheromone", toOrigin, (Shared.GetTime() - lastWinOrLoseWarningWhen) < 10 and 300 or 100)
	    local bestPheromone
	    local bestDistSq = math.huge
	    for p = 1, #pheromones do
	    
	        local currentPheromone = pheromones[p]
	        local currentDistSq = currentPheromone:GetDistanceSquared(toOrigin)

	        if currentDistSq < bestDistSq then
	        
	            bestDistSq = currentDistSq
	            bestPheromone = currentPheromone
	            
	        end
	        
	    end
	    
	    return bestPheromone
	end

	ReplaceLocals( PlayerUI_GetOrderPath, { GetMostRelevantPheromone = ReplacementGetMostRelevantPheromone } )



	-- GUIGameFeedback.kMinPlayTime = 0
	local originalGUIFeedbackState_EndSendReport = GUIFeedbackState_End.SendReport
	GUIFeedbackState_End.SendReport = function(GUIFeedbackState_EndSelf)
		originalGUIFeedbackState_EndSendReport(GUIFeedbackState_EndSelf)
		local rating = GUIFeedbackState_EndSelf.parent.rating
		local reasons = {}
		TGNS.DoFor(GUIFeedbackState_EndSelf.parent.reasons, function(r)
			local matchingReasons = TGNS.Where(GUIFeedbackState_Reason.Reasons, function(reason) return reason[1] == r end)
			if #matchingReasons > 0 then
				local resolvedReasonString = Locale.ResolveString(matchingReasons[1][2])
				table.insert(reasons, resolvedReasonString)
			end
		end)
		TGNS.SendNetworkMessage(Plugin.GAME_FEEDBACK, {rating=rating, reasons=GUIFeedbackState_EndSelf.parent.reasons and json.encode(reasons) or ""})
	end

	local originalGUIFeedbackState_EndInitialize = GUIFeedbackState_End.Initialize
	GUIFeedbackState_End.Initialize = function(GUIFeedbackState_Endself, guiElement)
		originalGUIFeedbackState_EndInitialize(GUIFeedbackState_Endself, guiElement)
		GUIFeedbackState_Endself.closeTime = GUIFeedbackState_Endself.closeTime - 1
	end

	-- IsSeasonForThrowing = function()
	-- 	return true
	-- end





	-- local fogIsLifted = false
	-- local originalGUIMinimapUpdate = GUIMinimap.Update
	-- GUIMinimap.Update = function(guiMinimapSelf, deltaTime)
	-- 	-- if fogIsLifted or not gameState.gameIsInProgress then
	-- 	-- 	guiMinimapSelf:ResetAll()
	-- 	-- end
	-- 	originalGUIMinimapUpdate(guiMinimapSelf, deltaTime)
	-- end

	-- TGNS.HookNetworkMessage(Plugin.FOG_NEEDS_LIFT, function(message)
	-- 	fogIsLifted = message.b
	-- end)

	return true
end

function Plugin:Think(deltaTime)
	local isInUntrackableAfkActivity = not (Client.GetIsWindowFocused() or (Client.GetIsSteamOverlayActive and Client.GetIsSteamOverlayActive()))
	if isInUntrackableAfkActivity then
		if not wasInUntrackableAfkActivity then
			startedUntrackableAfkActivityAt = Shared.GetTime()
		end
		local secondsSinceStartedUntrackableAfkActivity = math.floor(Shared.GetTime() - startedUntrackableAfkActivityAt)
		if secondsSinceStartedUntrackableAfkActivity <= 15 then
			hasAfkRelevantActivity = true
		end
	end
	wasInUntrackableAfkActivity = isInUntrackableAfkActivity

	if hasAfkRelevantActivity then
		local secondsSinceAfkRelevantActivityAnnounced = math.floor(Shared.GetTime() - afkRelevantActivityAnnouncedAt)
		if secondsSinceAfkRelevantActivityAnnounced >= 3 then
			TGNS.SendNetworkMessage(Plugin.CHATTING_OR_MENUING_STARTED_RECENTLY, {}) -- todo rename this message to AFK_RELEVANT_ACTIVITY
			afkRelevantActivityAnnouncedAt = Shared.GetTime()
			hasAfkRelevantActivity = false
		end
	end

	if (Shared.GetTime() - lastWinOrLoseWarningWhen) < 10 then
		TGNS.DoFor(CHUDOptionsToDisableDuringWinOrLose, function(key) CHUDOptions[key].disabled = true end)
		-- show center winorlose attack image
	end

	updateTeamNumbers()
end

function Plugin:Cleanup()
    --Cleanup your extra stuff like timers, data etc.
    self.BaseClass.Cleanup( self )
end