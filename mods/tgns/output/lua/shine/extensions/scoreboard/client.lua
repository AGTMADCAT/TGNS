local Plugin = Plugin

local prefixes = {}
local isCaptainsCaptain = {}
local isApproved = {}
local isQuerying = {}
local isVring = false
local isQueryingBadge = {}
local approveReceivedTotal = 0
local approveSentTotal = 0
local APPROVE_TEXTURE_DISABLED = "ui/approve/chevron-disabled.dds"
local QUERY_TEXTURE_DISABLED = "ui/query/contactcard-disabled.dds"
local VR_TEXTURE_DISABLED = "ui/vr/vr-disabled.dds"
local lastUpdatedPingsWhen = {}
local pings = {}
local showCustomNumbersColumn = true
local showOptionals = false
local notes = {}
local hasJetPacks = {}
local showTeamMessages = true
local badgeLabels = {}
local vrConfirmed = {}
local countdownSoundEventName = "sound/tgns.fev/winorlose/countdown"
local approveSoundEventName = "sound/tgns.fev/scoreboard/approve"

local CaptainsCaptainFontColor = Color(0, 1, 0, 1)

TGNS.HookNetworkMessage(Shine.Plugins.scoreboard.SCOREBOARD_DATA, function(message)
	prefixes[message.i] = message.p
	isCaptainsCaptain[message.i] = message.c
end)

local function getTeamApproveTexture(teamNumber)
	local result = string.format("ui/approve/chevron-team%s.dds", teamNumber)
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

function Plugin:Initialise()
	self.Enabled = true

	Client.PrecacheLocalSound(countdownSoundEventName)
	Client.PrecacheLocalSound(approveSoundEventName)

	-- lua\GUIScoreboard.lua
	local originalGUIScoreboardUpdateTeam = GUIScoreboard.UpdateTeam
	GUIScoreboard.UpdateTeam = function(self, updateTeam)
		originalGUIScoreboardUpdateTeam(self, updateTeam)
		local playerList = updateTeam["PlayerList"]
		local teamScores = updateTeam["GetScores"]()
		local teamNumber = updateTeam["TeamNumber"]
		local currentPlayerIndex = 1
		for index, player in pairs(playerList) do
	        local playerRecord = teamScores[currentPlayerIndex]
	        local clientIndex = playerRecord.ClientIndex
	        if showCustomNumbersColumn then
		        local prefix = prefixes[clientIndex]
		        player["Number"]:SetText(TGNS.HasNonEmptyValue(prefix) and prefix or "")
		        local numberColor = Color(0.5, 0.5, 0.5, 1)
		        if isCaptainsCaptain[clientIndex] == true then
		        	numberColor = CaptainsCaptainFontColor
		        end
		        player["Number"]:SetColor(numberColor)
	        end



			if not player.PlayerApproveIcon then
			    local playerApproveIcon = GUIManager:CreateGraphicItem()
			    local playerApproveIconPosition = player.Status:GetPosition()
			    playerApproveIconPosition.x = playerApproveIconPosition.x - 25
			    playerApproveIconPosition.y = playerApproveIconPosition.y - 10
			    playerApproveIcon:SetSize(Vector(20, 20, 0))
			    playerApproveIcon:SetAnchor(GUIItem.Left, GUIItem.Center)
			    playerApproveIcon:SetPosition(playerApproveIconPosition)
			    playerApproveIcon:SetTexture(APPROVE_TEXTURE_DISABLED)
			    player.PlayerApproveIcon = playerApproveIcon
			    player.Background:AddChild(playerApproveIcon)
			end
			if not player.PlayerVrIcon then
			    local playerVrIcon = GUIManager:CreateGraphicItem()
			    local playerVrIconPosition = player.Status:GetPosition()
			    playerVrIconPosition.x = playerVrIconPosition.x - 65
			    playerVrIconPosition.y = playerVrIconPosition.y - 10
			    playerVrIcon:SetSize(Vector(20, 20, 0))
			    playerVrIcon:SetAnchor(GUIItem.Left, GUIItem.Center)
			    playerVrIcon:SetPosition(playerVrIconPosition)
			    playerVrIcon:SetTexture(VR_TEXTURE_DISABLED)
			    player.PlayerVrIcon = playerVrIcon
			    player.Background:AddChild(playerVrIcon)
			end
			if not player.PlayerQueryIcon then
			    local playerQueryIcon = GUIManager:CreateGraphicItem()
			    local playerQueryIconPosition = player.Status:GetPosition()
			    playerQueryIconPosition.x = playerQueryIconPosition.x - 45
			    playerQueryIconPosition.y = playerQueryIconPosition.y - 10
			    playerQueryIcon:SetSize(Vector(20, 20, 0))
			    playerQueryIcon:SetAnchor(GUIItem.Left, GUIItem.Center)
			    playerQueryIcon:SetPosition(playerQueryIconPosition)
			    playerQueryIcon:SetTexture(QUERY_TEXTURE_DISABLED)
			    player.PlayerQueryIcon = playerQueryIcon
			    player.Background:AddChild(playerQueryIcon)
			end
			-- if not player.PlayerApproveStatusItem then
			-- 	local playerApproveStatusItem = GUIManager:CreateTextItem()
			-- 	playerApproveStatusItem:SetFontName(GUIScoreboard.kTeamInfoFontName)
			-- 	playerApproveStatusItem:SetAnchor(GUIItem.Left, GUIItem.Top)
			-- 	playerApproveStatusItem:SetTextAlignmentX(GUIItem.Align_Min)
			-- 	playerApproveStatusItem:SetTextAlignmentY(GUIItem.Align_Min)
			-- 	local playerApproveStatusItemPosition = player.Status:GetPosition()
			--     playerApproveStatusItemPosition.x = playerApproveStatusItemPosition.x - 25
			--     playerApproveStatusItemPosition.y = playerApproveStatusItemPosition.y + 8
			-- 	playerApproveStatusItem:SetPosition(playerApproveStatusItemPosition)
			-- 	player.PlayerApproveStatusItem = playerApproveStatusItem
			-- 	player.Background:AddChild(playerApproveStatusItem)
			-- end
			if not player.PlayerNoteItem then
				local playerNoteItem = GUIManager:CreateTextItem()
				playerNoteItem:SetFontName(GUIScoreboard.kTeamInfoFontName)
				playerNoteItem:SetAnchor(GUIItem.Left, GUIItem.Top)
				playerNoteItem:SetTextAlignmentX(GUIItem.Align_Max)
				playerNoteItem:SetTextAlignmentY(GUIItem.Align_Min)
				player.PlayerNoteItem = playerNoteItem
				player.Background:AddChild(playerNoteItem)
			end


			local guiItemsWhichShouldPreventNs2PlusHighlight = {}

			local playerIsBot = playerRecord.Ping == 0
	        local playerApproveIcon = player["PlayerApproveIcon"]
	        local playerApproveIconShouldDisplay = ((clientIndex ~= Client.GetLocalClientIndex()) and (not playerIsBot) and showOptionals) or Shared.GetDevMode()
	        local playerVrIconShouldDisplay = (((Client.GetLocalClientTeamNumber() == kSpectatorIndex) or (teamNumber == Client.GetLocalClientTeamNumber())) and (clientIndex ~= Client.GetLocalClientIndex()) and (not playerIsBot) and showOptionals) or Shared.GetDevMode()
        	local targetPrefix = prefixes[clientIndex] or ""
	        if playerVrIconShouldDisplay then
        		local targetPrefixFiltered = TGNS.Replace(targetPrefix, "!", "")
        		targetPrefixFiltered = TGNS.Replace(targetPrefixFiltered, "*", "")
        		playerVrIconShouldDisplay = not TGNS.HasNonEmptyValue(targetPrefixFiltered)
	        end

			local playerNoteItemPosition = player.Status:GetPosition()
			playerNoteItemPosition.x = playerNoteItemPosition.x - ((playerVrIconShouldDisplay and 60 or 40) + 5)
		    playerNoteItemPosition.y = playerNoteItemPosition.y + 8
			player.PlayerNoteItem:SetPosition(playerNoteItemPosition)

	        local playerQueryIconShouldDisplay = ((clientIndex ~= Client.GetLocalClientIndex()) and (not playerIsBot) and showOptionals) or Shared.GetDevMode()
	        if playerApproveIcon then
	        	table.insert(guiItemsWhichShouldPreventNs2PlusHighlight, playerApproveIcon)
	        	playerApproveIcon:SetIsVisible(playerApproveIconShouldDisplay)
		        playerApproveIcon:SetTexture(isApproved[clientIndex] and APPROVE_TEXTURE_DISABLED or getTeamApproveTexture(teamNumber))
	        end
	        local playerVrIcon = player["PlayerVrIcon"]
	        if playerVrIcon then
	        	table.insert(guiItemsWhichShouldPreventNs2PlusHighlight, playerVrIcon)
	        	playerVrIcon:SetIsVisible(playerVrIconShouldDisplay)
	        	local playerVrIconShouldBeDisabled = isVring or (Client.GetLocalClientTeamNumber() == kSpectatorIndex) or (TGNS.Contains(targetPrefix, "!") and not vrConfirmed[clientIndex])
		        playerVrIcon:SetTexture(playerVrIconShouldBeDisabled and getDisabledVrTexture(clientIndex) or getTeamVrTexture(clientIndex, teamNumber))
	        end
	        local playerQueryIcon = player["PlayerQueryIcon"]
	        if playerQueryIcon then
	        	table.insert(guiItemsWhichShouldPreventNs2PlusHighlight, playerQueryIcon)
	        	playerQueryIcon:SetIsVisible(playerQueryIconShouldDisplay)
		        playerQueryIcon:SetTexture(isQuerying[clientIndex] and QUERY_TEXTURE_DISABLED or getTeamQueryTexture(teamNumber))
	        end
		    local color = GUIScoreboard.kSpectatorColor
		    if teamNumber == kTeam1Index then
		        color = GUIScoreboard.kBlueColor
		    elseif teamNumber == kTeam2Index then
		        color = GUIScoreboard.kRedColor
		    end
	        local playerApproveStatusItem = player["PlayerApproveStatusItem"]
	        if playerApproveStatusItem then
	        	table.insert(guiItemsWhichShouldPreventNs2PlusHighlight, playerApproveStatusItem)
	        	local playerApproveStatusItemShouldDisplay = (clientIndex == Client.GetLocalClientIndex() and showOptionals) or Shared.GetDevMode()
	        	playerApproveStatusItem:SetIsVisible(playerApproveStatusItemShouldDisplay)
	        	playerApproveStatusItem:SetText(tostring(approveSentTotal) .. ":" .. tostring(approveReceivedTotal))
	        	playerApproveStatusItem:SetColor(color)
	        end

	        local playerNoteItem = player["PlayerNoteItem"]
	        if playerNoteItem then
	        	local playerNoteItemShouldDisplay = (teamNumber == kMarineTeamType or teamNumber == kAlienTeamType) and ((teamNumber == Client.GetLocalClientTeamNumber()) or (PlayerUI_GetIsSpecating() and Client.GetLocalClientTeamNumber() ~= kMarineTeamType and Client.GetLocalClientTeamNumber() ~= kAlienTeamType))
	        	playerNoteItem:SetIsVisible(playerNoteItemShouldDisplay)
	        	playerNoteItem:SetText(string.format("%s", notes[clientIndex] and notes[clientIndex] or ""))
	        	playerNoteItem:SetColor(color)
	        end

			if MouseTracker_GetIsVisible() then
				local mouseX, mouseY = Client.GetCursorPosScreen()
				for i = 1, #guiItemsWhichShouldPreventNs2PlusHighlight do
					local guiItem = guiItemsWhichShouldPreventNs2PlusHighlight[i]
					if GUIItemContainsPoint(guiItem, mouseX, mouseY) and guiItem:GetIsVisible() then
						player["Background"]:SetColor(updateTeam["Color"])
						break
					end
				end
			end

	        currentPlayerIndex = currentPlayerIndex + 1
		end
	end

	local originalGUIScoreboardSendKeyEvent = GUIScoreboard.SendKeyEvent
	GUIScoreboard.SendKeyEvent = function(self, key, down)
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
		            local playerQueryIcon = playerItem["PlayerQueryIcon"]
		            if playerQueryIcon and playerQueryIcon:GetIsVisible() and GUIItemContainsPoint(playerQueryIcon, mouseX, mouseY) then
		            	if self.hoverMenu then
		            		self.hoverMenu:Hide()
		            	end
		            	if not isQuerying[clientIndex] then
			                isQuerying[clientIndex] = true
			                TGNS.SendNetworkMessage(Plugin.QUERY_REQUESTED, {c=clientIndex})
		            	end
		            end
		            local playerVrIcon = playerItem["PlayerVrIcon"]
		            local playerVrIconShouldBeDisabled = isVring or (Client.GetLocalClientTeamNumber() == kSpectatorIndex)
		            if playerVrIcon and playerVrIcon:GetIsVisible() and GUIItemContainsPoint(playerVrIcon, mouseX, mouseY) then
		            	if self.hoverMenu then
		            		self.hoverMenu:Hide()
		            	end
		            	if not playerVrIconShouldBeDisabled then
			                isVring = true
			                TGNS.SendNetworkMessage(Plugin.VR_REQUESTED, {c=clientIndex})
		            	end
		            end
		        end

		    end
		end
		return result
	end
	TGNS.HookNetworkMessage(Plugin.APPROVE_MAY_TRY_AGAIN, function(message)
		isApproved[message.c] = false
	end)
	TGNS.HookNetworkMessage(Plugin.APPROVE_ALREADY_APPROVED, function(message)
		isApproved[message.c] = true
	end)
	TGNS.HookNetworkMessage(Plugin.VR_CONFIRMED, function(message)
		vrConfirmed[message.c] = true
	end)
	TGNS.HookNetworkMessage(Plugin.APPROVE_RESET, function(message)
		isApproved = {}
	end)
	TGNS.HookNetworkMessage(Plugin.QUERY_ALLOWED, function(message)
		isQuerying[message.c] = false
	end)
	TGNS.HookNetworkMessage(Plugin.VR_ALLOWED, function(message)
		isVring = false
	end)
	TGNS.HookNetworkMessage(Plugin.BADGE_QUERY_ALLOWED, function(message)
		isQueryingBadge[message.c] = false
	end)
	TGNS.HookNetworkMessage(Plugin.APPROVE_RECEIVED_TOTAL, function(message)
		if message.t > approveReceivedTotal then
			Shared.PlaySound(Client.GetLocalPlayer(), approveSoundEventName, 0.015)
		end
		approveReceivedTotal = message.t
	end)
	TGNS.HookNetworkMessage(Plugin.APPROVE_SENT_TOTAL, function(message)
		approveSentTotal = message.t
	end)
	TGNS.HookNetworkMessage(Plugin.TOGGLE_CUSTOM_NUMBERS_COLUMN, function(message)
		showCustomNumbersColumn = message.t
	end)
	TGNS.HookNetworkMessage(Plugin.TOGGLE_OPTIONALS, function(message)
		showOptionals = message.t
	end)
	TGNS.HookNetworkMessage(Plugin.PLAYER_NOTE, function(message)
		local clientIndex = message.c
		local note = message.n
		notes[clientIndex] = note
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


    local originalGetBadgeFormalName = GetBadgeFormalName
    GetBadgeFormalName = function(name)
    	local result = originalGetBadgeFormalName(name)
    	if result == "Custom Badge" then
    		local badgeLabel = badgeLabels[name]
    		if badgeLabel then
    			result = badgeLabel
    		end
    	end
    	return result
	end

	TGNS.HookNetworkMessage(Plugin.BADGE_DISPLAY_LABEL, function(message)
		badgeLabels[string.format("ui/badges/%s.dds", message.n)] = message.l
	end)

	local originalGUIHoverTooltipShow = GUIHoverTooltip.Show
	GUIHoverTooltip.Show = function(self, displayTimeInSeconds)
		if self.tooltip and self.tooltip.GetText and self.tooltip:GetText():find("TGNS") then
			displayTimeInSeconds = 2
		end
		originalGUIHoverTooltipShow(self, displayTimeInSeconds)
	end

	TGNS.HookNetworkMessage(Plugin.WINORLOSE_WARNING, function(message)
		Shared.PlaySound(Client.GetLocalPlayer(), countdownSoundEventName, 0.025)
	end)

	return true
end

function Plugin:Cleanup()
    --Cleanup your extra stuff like timers, data etc.
    self.BaseClass.Cleanup( self )
end