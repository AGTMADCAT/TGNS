Plugin.HasConfig = true
Plugin.ConfigName = "scoreboard.json"

local changers = {}
local clientsReadyForScoreboardData = {}
local approvalCounts = {}
local vrConfirmed = {}
local vrConfirmedBy = {}
local teamScoresDatas = {}
local vouches = {}
local squadNumbers = {}
local NUMBER_OF_GAMEPLAY_SECONDS_TO_SHOW_LIFEFORM_ICONS = 180
local tunnelDescriptions = {}
local streamingWebAddresses = {}
local approveCache = {}
local approveCacheWasPreloaded = false

local function PlayerCanSeeAfkStatus(sourcePlayer, targetPlayer)
	local result = false
	if sourcePlayer ~= nil and targetPlayer ~= nil then
	end
		local sendToPlayerCanKickAfkPlayers = TGNS.ClientAction(targetPlayer, function(c)
				local playerIsAdmin = TGNS.IsClientAdmin(c)
				local playerIsGuardian = TGNS.IsClientGuardian(c)
				return playerIsAdmin or playerIsGuardian
			end
		)
		local sameTeams = TGNS.PlayersAreTeammates(sourcePlayer, targetPlayer)
		result = sameTeams or sendToPlayerCanKickAfkPlayers
	return result
end

local function GetPlayerPrefix(sourcePlayer, targetPlayer)
	local result = ""

	local client = TGNS.GetClient(sourcePlayer)
	if client then
		local groupIcons = Shine.Plugins.scoreboard.Config.GroupIcons
		table.sort(groupIcons, function(t1, t2) return t1.sort < t2.sort end)
		for _, groupicon in ipairs(groupIcons) do
			if TGNS.ClientIsInGroup(client, groupicon.group) then
				result = groupicon.icon
				break
			end
		end
		if result == nil then
			result = Shine.Plugins.scoreboard.Config.CatchAll
		end
		if TGNS.IsPlayerAFK(sourcePlayer) and PlayerCanSeeAfkStatus(sourcePlayer, targetPlayer) then
			result = Shine.Plugins.scoreboard.Config.AFK .. result
		end
		if Shine.Plugins.betterknownas and Shine.Plugins.betterknownas.Enabled and Shine.Plugins.betterknownas.IsPlayingWithoutBkaName and Shine.Plugins.betterknownas:IsPlayingWithoutBkaName(sourcePlayer) then
			result = result .. "*"
		end
	end
	return result
end

local function GetReadyPlayerList()
	local result = TGNS.GetPlayers(TGNS.Where(TGNS.GetClientList(), function(c) return TGNS.Has(clientsReadyForScoreboardData, c) end))
	return result
end

local function SendNetworkMessage(sourcePlayer, targetPlayer)
	if sourcePlayer and targetPlayer then
		local sourceClient = TGNS.GetClient(sourcePlayer)
		local sourcePlayerHasWelder = TGNS.IsPlayerAlive(sourcePlayer) and sourcePlayer:GetWeapon(Welder.kMapName) ~= nil
		local sourcePlayerHasMines = TGNS.IsPlayerAlive(sourcePlayer) and sourcePlayer:GetWeapon(LayMines.kMapName) ~= nil
		local sourcePlayerHasClusterGrenades = TGNS.IsPlayerAlive(sourcePlayer) and sourcePlayer:GetWeapon(ClusterGrenadeThrower.kMapName) ~= nil
		local sourcePlayerHasGasGrenades = TGNS.IsPlayerAlive(sourcePlayer) and sourcePlayer:GetWeapon(GasGrenadeThrower.kMapName) ~= nil
		local sourcePlayerHasPulseGrenades = TGNS.IsPlayerAlive(sourcePlayer) and sourcePlayer:GetWeapon(PulseGrenadeThrower.kMapName) ~= nil
		local sourcePlayerTunnelDescription = tunnelDescriptions[sourcePlayer:GetClientIndex()] or ""
		local sourcePlayerHasCelerity = TGNS.IsPlayerAlive(sourcePlayer) and GetHasCelerityUpgrade(sourcePlayer)
		local sourcePlayerHasAdrenaline = TGNS.IsPlayerAlive(sourcePlayer) and GetHasAdrenalineUpgrade(sourcePlayer)
		local sourcePlayerHasRegeneration = TGNS.IsPlayerAlive(sourcePlayer) and GetHasRegenerationUpgrade(sourcePlayer)
		local sourcePlayerHasCarapace = TGNS.IsPlayerAlive(sourcePlayer) and GetHasCarapaceUpgrade(sourcePlayer)
		local sourcePlayerHasSilence = TGNS.IsPlayerAlive(sourcePlayer) and GetHasSilenceUpgrade(sourcePlayer)
		local sourcePlayerHasAura = TGNS.IsPlayerAlive(sourcePlayer) and GetHasAuraUpgrade(sourcePlayer)
		TGNS.SendNetworkMessageToPlayer(targetPlayer, Shine.Plugins.scoreboard.SCOREBOARD_DATA, {i=sourcePlayer:GetClientIndex(), p=GetPlayerPrefix(sourcePlayer, targetPlayer), c=TGNS.ClientIsInGroup(sourceClient, "captains_group"),s=Shine.Plugins.speclisten:GetIsUsingSvi(sourceClient), b=(Shine.Plugins.betterknownas and Shine.Plugins.betterknownas:PlayerFailsBkaPrerequisite(sourcePlayer)), w=sourcePlayerHasWelder, m=sourcePlayerHasMines, cg=sourcePlayerHasClusterGrenades, gg=sourcePlayerHasGasGrenades, pg=sourcePlayerHasPulseGrenades, t=sourcePlayerTunnelDescription, u1=sourcePlayerHasCelerity, u2=sourcePlayerHasAdrenaline, u3=sourcePlayerHasRegeneration, u4=sourcePlayerHasCarapace, u5=sourcePlayerHasSilence, u6=sourcePlayerHasAura, streaming=streamingWebAddresses[sourceClient] or ""})
	end
end

function Plugin:SendTeamScoresDatas()
	local marineTeamName = "Marine Team"
	local marineTeamScore = 0
	local alienTeamName = "Alien Team"
	local alienTeamScore = 0
	local teamNameCreator = function(c) return string.format("Team %s", TGNS.Truncate(TGNS.GetClientName(c), kMaxNameLength)) end
	TGNS.DoFor(teamScoresDatas, function(d)
		local client = TGNS.GetClientByNs2Id(d.i)
		if client ~= nil then
			if TGNS.GetClientTeamNumber(client) == kMarineTeamType then
				marineTeamName = teamNameCreator(client)
				marineTeamScore = d.s or 0
			elseif TGNS.GetClientTeamNumber(client) == kAlienTeamType then
				alienTeamName = teamNameCreator(client)
				alienTeamScore = d.s or 0
			end
		end
	end)
	TGNS.DoFor(TGNS.GetPlayerList(), function(p)
		TGNS.SendNetworkMessageToPlayer(p, Shine.Plugins.scoreboard.TEAM_SCORES_DATA, {mn=marineTeamName,an=alienTeamName,ms=marineTeamScore,as=alienTeamScore})
	end)
end

function Plugin:SetTeamScoresData(client, teamScore) 
	local steamId = TGNS.GetClientSteamId(client)
	TGNS.DoForReverse(teamScoresDatas, function(d, index)
		if d.i == steamId then
			table.remove(teamScoresDatas, index)
		end
	end)
	table.insert(teamScoresDatas, {i=steamId,s=teamScore})
	TGNS.ScheduleAction(1, function()
		self:SendTeamScoresDatas()
	end)
end

function Plugin:AnnouncePlayerPrefix(player)
	TGNS.DoFor(GetReadyPlayerList(), function(p)
		SendNetworkMessage(player, p)
	end)
end

local function UpdatePlayerPrefixes(player)
	TGNS.DoFor(GetReadyPlayerList(), function(p)
		SendNetworkMessage(p, player)
	end)
end

local function initScoreboardDecorations(client)
	if Shine:IsValidClient(client) then
		local sourcePlayer = TGNS.GetPlayer(client)
		local sourceSteamId = TGNS.GetClientSteamId(client)
		table.insert(clientsReadyForScoreboardData, client)
		if sourcePlayer then
			TGNS.SendNetworkMessageToPlayer(sourcePlayer, Shine.Plugins.scoreboard.TOGGLE_OPTIONALS, {t=not TGNS.IsClientStranger(client)})
			UpdatePlayerPrefixes(sourcePlayer)
			Shine.Plugins.scoreboard:AnnouncePlayerPrefix(sourcePlayer)
			local approvedSentTotal = 0
			local approvedReceivedTotal = 0
			TGNS.DoFor(TGNS.GetClientList(), function(c)
				if c then
					local p = TGNS.GetPlayer(c)
					local targetSteamId = TGNS.GetClientSteamId(c)
					if Shine.Plugins.targetedcommands:GetApprovedClients(targetSteamId)[sourceSteamId] then
						TGNS.SendNetworkMessageToPlayer(p, Shine.Plugins.scoreboard.APPROVE_ALREADY_APPROVED, {c=sourcePlayer:GetClientIndex()})
						approvedReceivedTotal = approvedReceivedTotal + 1
					end
					if Shine.Plugins.targetedcommands:GetApprovedClients(sourceSteamId)[targetSteamId] then
						TGNS.SendNetworkMessageToPlayer(sourcePlayer, Shine.Plugins.scoreboard.APPROVE_ALREADY_APPROVED, {c=p:GetClientIndex()})
						approvedSentTotal = approvedSentTotal + 1
					end
					TGNS.SendNetworkMessageToPlayer(sourcePlayer, Shine.Plugins.scoreboard.SQUAD_CONFIRMED, {c=TGNS.GetClientIndex(c),s=squadNumbers[c]})
					TGNS.SendNetworkMessageToPlayer(p, Shine.Plugins.scoreboard.SQUAD_CONFIRMED, {c=TGNS.GetClientIndex(client),s=squadNumbers[client]})


					local recentCaptainsData = Shine.Plugins.captains:GetRecentCaptainsData()
					local recentCaptainClientIndexes = {}
					TGNS.DoFor(recentCaptainsData, function(d)
						local recentCaptainClient = TGNS.GetClientByNs2Id(d.steamId)
						if recentCaptainClient then
							local recentCaptainClientIndex = TGNS.GetClientIndex(recentCaptainClient)
							table.insert(recentCaptainClientIndexes, recentCaptainClientIndex)
						end
					end)
					if #recentCaptainClientIndexes > 0 then
						local recentCaptainClientIndexesString = TGNS.Join(recentCaptainClientIndexes, ",")
						TGNS.SendNetworkMessageToPlayer(p, Shine.Plugins.scoreboard.RECENT_CAPTAINS, {c=recentCaptainClientIndexesString})
					end
				end
			end)
			TGNS.SendNetworkMessageToPlayer(sourcePlayer, Shine.Plugins.scoreboard.APPROVE_RECEIVED_TOTAL, {t=approvedReceivedTotal})
			TGNS.SendNetworkMessageToPlayer(sourcePlayer, Shine.Plugins.scoreboard.APPROVE_SENT_TOTAL, {t=approvedSentTotal})
		end
	end
end

function Plugin:GetApprovalsCount(client)
	local approvalCount = TGNS.FirstOrNil(approvalCounts, function(c) return c[1] == client end)
	local result = (client and approvalCount) and approvalCount[1] or 0
	return result
end

function Plugin:ClientConnect(client)
	if not TGNS.GetIsClientVirtual(client) then
		local steamId = TGNS.GetClientSteamId(client)
		if approveCache[steamId] ~= nil and not TGNS.Any(approvalCounts, function(c) return c[1] == client end) then
			table.insert(approvalCounts, {client, approveCache[steamId]})
		elseif not approveCacheWasPreloaded then
			local approvalsUrl = string.format("%s&i=%s&t=14", TGNS.Config.ApproveEndpointBaseUrl, steamId)
			TGNS.GetHttpAsync(approvalsUrl, function(approvalsResponseJson)
				if Shine:IsValidClient(client) then
					local approvalsResponse = json.decode(approvalsResponseJson) or {}
					if approvalsResponse.success then
						table.insert(approvalCounts, {client, approvalsResponse.result})
					else
						TGNS.DebugPrint(string.format("approvals ERROR: Unable to access approvals count data for NS2ID %s. msg: %s | response: %s | stacktrace: %s", steamId, approvalsResponse.msg, approvalsResponseJson, approvalsResponse.stacktrace))
					end
				end
			end)
		end
	end
end

function Plugin:AlertApplicationIconForPlayer(player)
	TGNS.SendNetworkMessageToPlayer(player, self.ALERT_ICON)
end

function Plugin:ClientConfirmConnect(client)
	local steamId = TGNS.GetClientSteamId(client)
	if TGNS.Has(vouches, steamId) then
		vrConfirmed[client] = true
	end
	TGNS.ScheduleAction(2, function()
		if Shine:IsValidClient(client) then
			local player = TGNS.GetPlayer(client)
			initScoreboardDecorations(client)
			TGNS.DoFor(TGNS.GetClientList(), function(c)
				if vrConfirmed[c] then
					TGNS.SendNetworkMessageToPlayer(player, self.VR_CONFIRMED, {c=TGNS.GetClientId(c)})
				end
				if vrConfirmed[client] then
					TGNS.SendNetworkMessageToPlayer(TGNS.GetPlayer(c), self.VR_CONFIRMED, {c=TGNS.GetClientId(client)})
				end
			end)
			TGNS.SendNetworkMessageToPlayer(player, self.GAME_IN_PROGRESS, {b=TGNS.IsGameInProgress()})
			TGNS.SendNetworkMessageToPlayer(player, self.SERVER_SIMPLE_NAME, {n=TGNS.GetSimpleServerName()})
			TGNS.SendNetworkMessageToPlayer(player, self.DESIGNATION, {c=TGNS.GetClientCommunityDesignationCharacter(client)})
		end
	end)
	self:AlertApplicationIconForPlayer(TGNS.GetPlayer(client))
end

function Plugin:PlayerNameChange(player, newName, oldName)
	self:AnnouncePlayerPrefix(player)
end

function Plugin:OnEntityKilled(gamerules, victimEntity, attackerEntity, inflictorEntity, point, direction)
	if victimEntity and victimEntity:isa("JetpackMarine") then
		TGNS.DoFor(TGNS.GetPlayerList(), function(p)
			TGNS.SendNetworkMessageToPlayer(p, self.HAS_JETPACK, {c=victimEntity:GetClientIndex(),h=false})
		end)
	end
end

function Plugin:PostJoinTeam(gamerules, player, oldTeamNumber, newTeamNumber, force, shineForce)
	local client = TGNS.GetClient(player)
	if newTeamNumber == kMarineTeamType then
		local updateJetpackStatus = function(p)
			TGNS.SendNetworkMessageToPlayer(player, self.HAS_JETPACK, {c=p:GetClientIndex(),h=p:isa("JetpackMarine")})
		end
		local playerList = TGNS.GetPlayerList()
		TGNS.DoFor(TGNS.GetMarinePlayers(playerList), updateJetpackStatus)
		TGNS.DoFor(TGNS.GetSpectatorPlayers(playerList), updateJetpackStatus)
	end
	squadNumbers[client] = 0
	initScoreboardDecorations(client)
end

function Plugin:EndGame(gamerules, winningTeam)
	tunnelDescriptions = {}
	TGNS.DoFor(TGNS.GetPlayerList(), function(p)
		TGNS.SendNetworkMessageToPlayer(p, self.HAS_JETPACK_RESET, {})
		TGNS.SendNetworkMessageToPlayer(p, self.GAME_IN_PROGRESS, {b=false})
		self:AnnouncePlayerPrefix(p)
	end)
	TGNS.ScheduleAction(TGNS.ENDGAME_TIME_TO_READYROOM, function()
		TGNS.DoFor(TGNS.GetPlayerList(), function(p)
			TGNS.DoFor(TGNS.GetClientList(), function(c)
				squadNumbers[c] = 0
				TGNS.SendNetworkMessageToPlayer(p, self.SQUAD_CONFIRMED, {c=TGNS.GetClientIndex(c),s=squadNumbers[c]})	
			end)
		end)
	end)
	local captainsModeEnabled = Shine.Plugins.captains and Shine.Plugins.captains.IsCaptainsModeEnabled and Shine.Plugins.captains:IsCaptainsModeEnabled()
	if not captainsModeEnabled then
		TGNS.ScheduleAction(TGNS.ENDGAME_TIME_TO_READYROOM + 240, function()
			if not TGNS.IsGameInProgress() then
				local md = TGNSMessageDisplayer.Create("APPROVALS")
				TGNS.DoFor(TGNS.GetClientList(), function(c)
					if c and not TGNS.IsClientStranger(c) then
						local p = TGNS.GetPlayer(c)
						local message = math.random() < 0.5 and "Someone impress you lately? Click a chevron (^) on the scoreboard to show your Approval!" or "Do you like to watch? Opt into FullSpec to join the server when it's full! http://rr.tacticalgamer.com/FullSpec/Manage"
						md:ToPlayerNotifyInfo(p, message)
					end
				end)
			end
		end)
	end
end

function Plugin:CreateCommands()
	local approvalsCountsCommand = self:BindCommand( "sh_approvalcounts", nil, function(client)
		local md = TGNSMessageDisplayer.Create("APPROVALS")
		local approvalCountsToDisplay = TGNS.Where(approvalCounts, function(c) return Shine:IsValidClient(c[1]) end)
		TGNS.SortAscending(approvalCountsToDisplay, function(c) return c[2] end)
		TGNS.DoFor(approvalCountsToDisplay, function(c)
			md:ToClientConsole(client, string.format("%s: %s", TGNS.GetClientName(c[1]), c[2]))
		end)
	end)
	approvalsCountsCommand:Help( "Show approval counts." )

	local textTestCommand = self:BindCommand( "sh_texttest", "tt", function(client, message, x, y)
		-- Shine:SendText(client, Shine.BuildScreenMessage(81, x, y, message, 15, 255, 255, 255, 1, 1, 0 ) )
		Shine.ScreenText.Add(81, {X = x, Y = y, Text = message, Duration = 15, R = 255, G = 255, B = 255, Alignment = TGNS.ShineTextAlignmentCenter, Size = 1, FadeIn = 0, IgnoreFormat = true}, client)
	end)
	textTestCommand:AddParam{ Type = "string" }
	textTestCommand:AddParam{ Type = "number", Min = 0, Max = 1 }
	textTestCommand:AddParam{ Type = "number", Min = 0, Max = 1 }
	textTestCommand:Help( "Show test text to yourself." )

	local wyzCommand = self:BindCommand( "otherserverall", nil, function(client)
		TGNS.DoFor(TGNS.GetPlayerList(), function(p)
			TGNS.SendNetworkMessageToPlayer(p, self.WYZ)
		end)
	end)

	local streamingCommand = self:BindCommand( "sh_streaming", "streaming", function(client, webAddress)
		local player = TGNS.GetPlayer(client)
		local steamId = TGNS.GetClientSteamId(client)
		local md = TGNSMessageDisplayer.Create("STREAMING")
		if TGNS.HasNonEmptyValue(webAddress) then
			md:ToPlayerNotifyInfo(player, string.format("Streaming icon created for web address '%s'.", webAddress))
			md:ToPlayerNotifyInfo(player, "To remove the icon, execute this command again with no web address.")
		else
			if TGNS.HasNonEmptyValue(streamingWebAddresses[client]) then
				md:ToPlayerNotifyInfo(player, "Streaming icon removed.")
			end
			md:ToPlayerNotifyInfo(player, "To show a streaming icon, execute this command again with a web address parameter.")
		end
		streamingWebAddresses[client] = webAddress
		self:AnnouncePlayerPrefix(player)
	end, true)
	streamingCommand:AddParam{ Type = "string", TakeRestOfLine = true, Optional = true }
	streamingCommand:Help( "<webaddress> Show your 'I'm Streaming' icon on the scoreboard" )

end

function Plugin:Initialise()
    self.Enabled = true
    self:CreateCommands()
	TGNS.RegisterEventHook("AfkChanged", function(player, playerIsAfk)
		self:AnnouncePlayerPrefix(player)
	end)
	TGNS.RegisterEventHook("SviChanged", function(client, sviEnabled)
		self:AnnouncePlayerPrefix(TGNS.GetPlayer(client))
	end)
	TGNS.RegisterEventHook("ClientGroupsChanged", function(client)
		if client and Shine:IsValidClient(client) then
			local player = TGNS.GetPlayer(client)
			if player then
				self:AnnouncePlayerPrefix(player)
			end
		end
	end)
	TGNS.RegisterEventHook("BkaChanged", function(client)
		if Shine:IsValidClient(client) then
			self:AnnouncePlayerPrefix(TGNS.GetPlayer(client))
		end
	end)
	TGNS.RegisterEventHook("GameStarted", function(secondsSinceEpoch)
		TGNS.DoFor(TGNS.GetPlayerList(), function(p)
			TGNS.SendNetworkMessageToPlayer(p, self.GAME_IN_PROGRESS, {b=true})
		end)
		TGNS.ScheduleAction(NUMBER_OF_GAMEPLAY_SECONDS_TO_SHOW_LIFEFORM_ICONS, function()
			if TGNS.IsGameInProgress() and TGNS.GetCurrentGameDurationInSeconds() > NUMBER_OF_GAMEPLAY_SECONDS_TO_SHOW_LIFEFORM_ICONS - 2 then
				TGNS.DoFor(TGNS.GetAlienClients(TGNS.GetPlayerList()), function(c)
					squadNumbers[c] = 0
					TGNS.DoFor(TGNS.GetPlayerList(), function(p)
						TGNS.SendNetworkMessageToPlayer(p, self.SQUAD_CONFIRMED, {c=TGNS.GetClientIndex(c),s=squadNumbers[c]})	
					end)
				end)
			end
		end)
	end)

	TGNS.HookNetworkMessage(self.CHATTING_OR_MENUING_STARTED_RECENTLY, function(client)
		TGNS.ClearPlayerAFK(TGNS.GetPlayer(client))
	end)

	TGNS.HookNetworkMessage(self.APPROVE_REQUESTED, function(client, message)
		local md = TGNSMessageDisplayer.Create("APPROVE")
		local targetClientIndex = message.c
		local player = TGNS.GetPlayer(client)
		if player then
			local targetClient = TGNS.GetClientById(targetClientIndex)
			if targetClient and Shine:IsValidClient(targetClient) then
				if client ~= targetClient then
					local targetPlayer = TGNS.GetPlayer(targetClient)
					if (TGNS.PlayersAreTeammates(player, targetPlayer) or TGNS.IsPlayerSpectator(player)) and not TGNS.HasClientSignedPrimerWithGames(targetClient) and not vrConfirmed[targetClient] then
						vrConfirmed[targetClient] = true
						vrConfirmedBy[targetClient] = TGNS.GetClientName(client)
						local sourceSteamId = TGNS.GetClientSteamId(client)
						local targetSteamId = TGNS.GetClientSteamId(targetClient)
						table.insertunique(vouches, targetSteamId)

						local vouchUrl = string.format("%s&i=%s&v=%s", TGNS.Config.VouchesEndpointBaseUrl, sourceSteamId, targetSteamId)
						TGNS.GetHttpAsync(vouchUrl, function(vouchResponseJson)
							local vouchResponse = json.decode(vouchResponseJson) or {}
							if not vouchResponse.success then
								TGNS.DebugPrint(string.format("scoreboard ERROR: Unable to vouch NS2ID %s. msg: %s | response: %s | stacktrace: %s", targetSteamId, vouchResponse.msg, vouchResponseJson, vouchResponse.stacktrace))
							end
						end)
						TGNS.Karma(sourceSteamId, "VouchingVoicecomm")
						if TGNS.IsClientStranger(targetClient) and Balance.GetTotalGamesPlayed(targetClient) <= 20 then
							TGNS.Karma(targetSteamId, "ConfirmingYouCanHearVoicecomm")
						end
						TGNS.ExecuteEventHooks("VrConfirmed", targetClient)
						TGNS.DoFor(TGNS.GetPlayerList(), function(p)
							TGNS.SendNetworkMessageToPlayer(p, self.VR_CONFIRMED, {c=targetClientIndex})
						end)
						md:ToTeamConsole(TGNS.GetPlayerTeamNumber(player), string.format("%s confirmed that %s responded to voicecomm.", TGNS.GetPlayerName(player), TGNS.GetClientName(targetClient)))
						TGNS.SendNetworkMessageToPlayer(player, self.APPROVE_MAY_TRY_AGAIN, {c=targetClientIndex})
					else
						Shine.Plugins.targetedcommands:Approve(client, targetClient, nil, md)
					end
				else
					md:ToPlayerNotifyError(player, "Your modesty knows no bounds.")
				end
			else
				md:ToPlayerNotifyError(player, "There was a problem approving.")
				TGNS.SendNetworkMessageToPlayer(player, self.APPROVE_MAY_TRY_AGAIN, {c=targetClientIndex})
			end
		else
			TGNS.ScheduleAction(1, function()
				if Shine:IsValidClient(client) then
					local retryPlayer = TGNS.GetPlayer(client)
					if retryPlayer then
						md:ToPlayerNotifyError(retryPlayer, "There was a problem approving.")
						TGNS.SendNetworkMessageToPlayer(retryPlayer, self.APPROVE_MAY_TRY_AGAIN, {c=targetClientIndex})
					end
				end
			end)
		end
	end)
	TGNS.HookNetworkMessage(self.QUERY_REQUESTED, function(client, message)
		local player = TGNS.GetPlayer(client)
		local targetClientIndex = message.c
		local targetClient = TGNS.GetClientById(targetClientIndex)
		local md = TGNSMessageDisplayer.Create("QUERY")
		if targetClient and Shine:IsValidClient(targetClient) then
			TGNS.ScheduleAction(5, function()
				if Shine:IsValidClient(client) then
					TGNS.SendNetworkMessageToPlayer(TGNS.GetPlayer(client), self.QUERY_ALLOWED, {c=targetClientIndex})
				end
			end)
			local sourceSteamId = TGNS.GetClientSteamId(client)
			local targetSteamId = TGNS.GetClientSteamId(targetClient)
			local targetClientName = TGNS.GetClientName(targetClient)
			Shine.Plugins.betterknownas:ShowCurrentBka(client, targetSteamId, "BKA", "AKAs", "BKA")
			if Balance then
				local totalGamesCount = Balance.GetTotalGamesPlayedBySteamId(targetSteamId)
				if totalGamesCount > 0 then
					local targetPlayer = TGNS.GetPlayer(targetClient)
					md:ToPlayerNotifyInfo(player, string.format("%s has played %s on TGNS.", targetClientName, totalGamesCount < 50 and string.format("%s games so far", totalGamesCount) or "more than 50 games"))
				end
			end
		else
			md:ToPlayerNotifyError(player, "There was a problem querying.")
		end
	end)

	TGNS.HookNetworkMessage(self.VR_REQUESTED, function(client, message)
		local player = TGNS.GetPlayer(client)
		local targetClientIndex = message.c
		local targetClient = TGNS.GetClientById(targetClientIndex)
		local md = TGNSMessageDisplayer.Create("VR")
		if targetClient and Shine:IsValidClient(targetClient) then
			TGNS.ScheduleAction(10, function()
				if Shine:IsValidClient(client) then
					TGNS.SendNetworkMessageToPlayer(TGNS.GetPlayer(client), self.VR_ALLOWED, {})
				end
			end)
			if vrConfirmed[targetClient] then
				md:ToPlayerNotifyInfo(player, string.format("%s already confirmed that %s responded to voicecomm. Learn more: M > Info > TGNS FAQ", vrConfirmedBy[targetClient] or "Someone", TGNS.GetClientName(targetClient)))
			elseif TGNS.PlayerAction(targetClient, TGNS.IsPlayerAFK) then
				md:ToPlayerNotifyError(player, string.format("This icon is disabled because %s is AFK.", TGNS.GetClientName(targetClient)))
			else
				local targetPlayer = TGNS.GetPlayer(targetClient)
				Shine.Plugins.voicecommreminder:SendVoicecommReminder(client, targetPlayer)
			end
		else
			md:ToPlayerNotifyError(player, "There was a problem showing the voicecomm reminder.")
		end
	end)

	TGNS.HookNetworkMessage(self.SQUAD_REQUESTED, function(client, message)
		local player = TGNS.GetPlayer(client)
		local targetClientIndex = message.c
		local squadNumberDelta = message.d
		local targetClient = TGNS.GetClientById(targetClientIndex)
		local md = TGNSMessageDisplayer.Create("SQUADS")
		if TGNS.IsGameInProgress() and TGNS.ClientIsAlien(targetClient) and TGNS.GetCurrentGameDurationInSeconds() > 30 then
			md:ToPlayerNotifyError(player, "Aliens may not alter planned lifeform scoreboard icons during gameplay.")
		else
			local clientIsCaptain = Shine.Plugins.captains and Shine.Plugins.captains.IsClientCaptain and Shine.Plugins.captains:IsClientCaptain(client)
			local clientIsCommander = TGNS.IsClientCommander(client)
			if (clientIsCaptain or clientIsCommander or (TGNS.ClientIsAlien(client) and client == targetClient)) then
				if targetClient and Shine:IsValidClient(targetClient) then
					squadNumbers[targetClient] = squadNumbers[targetClient] or 0
					squadNumbers[targetClient] = squadNumbers[targetClient] + squadNumberDelta
					local highestSquadNumber = TGNS.ClientIsAlien(targetClient) and 6 or 9
					if squadNumbers[targetClient] > highestSquadNumber then
						squadNumbers[targetClient] = 0
					elseif squadNumbers[targetClient] < 0 then
						squadNumbers[targetClient] = highestSquadNumber
					end
					TGNS.DoFor(TGNS.GetPlayerList(), function(p)
						TGNS.SendNetworkMessageToPlayer(p, self.SQUAD_CONFIRMED, {c=targetClientIndex,s=squadNumbers[targetClient]})	
					end)
				else
					md:ToPlayerNotifyError(player, "There was a problem setting a squad.")
				end
			else
				md:ToPlayerNotifyError(player, string.format("Captains and Commanders may set teammates' %s.", TGNS.ClientIsAlien(client) and "planned lifeforms" or "squads"))
			end
		end
		TGNS.SendNetworkMessageToPlayer(player, self.SQUAD_ALLOWED, {})
	end)

	TGNS.HookNetworkMessage(self.REQUEST_AFKRR, function(client, message)
		local targetClientIndex = message.c
		local targetClient = TGNS.GetClientById(targetClientIndex)
		local md = TGNSMessageDisplayer.Create("PREGAMEAFK")
		Shine.Plugins.targetedcommands:AfkRr(client, targetClient, md)
	end)

	TGNS.RegisterEventHook("LookDownChanged", function(player, isLookingDown)
		local isLookingUp = not isLookingDown
		TGNS.SendNetworkMessageToPlayer(player, self.TOGGLE_CUSTOM_NUMBERS_COLUMN, {t=isLookingUp})
	end)
 	TGNS.RegisterEventHook("FullGamePlayed", function(clients, winningTeam, gameDurationInSeconds)
 		local md = TGNSMessageDisplayer.Create()
 		md:ToAllConsole(string.format("Gametime: %s", string.DigitalTime(gameDurationInSeconds)))
 	end)


 	originalMarineGiveJetpack = Marine.GiveJetpack
 	Marine.GiveJetpack = function(marineSelf)
 		originalMarineGiveJetpack(marineSelf)
 		local updateJetpackStatus = function(p)
			TGNS.SendNetworkMessageToPlayer(p, self.HAS_JETPACK, {c=marineSelf:GetClientIndex(),h=true})
		end
		local playerList = TGNS.GetPlayerList()
		TGNS.DoFor(TGNS.GetMarinePlayers(playerList), updateJetpackStatus)
		TGNS.DoFor(TGNS.GetSpectatorPlayers(playerList), updateJetpackStatus)
 	end

 	TGNS.ScheduleAction(5, function()
	 	local originalAfkkickPrePlayerInfoUpdate = Shine.Plugins.afkkick.PrePlayerInfoUpdate
	 	Shine.Plugins.afkkick.PrePlayerInfoUpdate = function(self, playerInfo, player) end

	 	local originalAfkkickPostPlayerInfoUpdate = Shine.Plugins.afkkick.PostPlayerInfoUpdate
	 	Shine.Plugins.afkkick.PostPlayerInfoUpdate = function(self, playerInfo, player) end
 	end)

 	local getRecentVouchData
 	getRecentVouchData = function()
	 	if TGNS.Config and TGNS.Config.VouchesEndpointBaseUrl then
			local vouchesUrl = string.format("%s&h=3", TGNS.Config.VouchesEndpointBaseUrl)
			TGNS.GetHttpAsync(vouchesUrl, function(vouchesResponseJson)
				local vouchesResponse = json.decode(vouchesResponseJson) or {}
				if vouchesResponse.success then
					vouches = vouchesResponse.result
				else
					TGNS.DebugPrint(string.format("vouches ERROR: Unable to access vouches data. msg: %s | response: %s | stacktrace: %s", vouchesResponse.msg, vouchesResponseJson, vouchesResponse.stacktrace))
				end
			end)
	 	else
	 		TGNS.ScheduleAction(0, getRecentVouchData)
	 	end
 	end
 	getRecentVouchData();

 	local originalSelectableMixinSetHotGroupNumber = SelectableMixin.SetHotGroupNumber
 	SelectableMixin.SetHotGroupNumber = function(mixinSelf, hotGroupNumber)
 		originalSelectableMixinSetHotGroupNumber(mixinSelf, hotGroupNumber)
 		if mixinSelf:isa("Player") then
 			local mixinClient = TGNS.GetClient(mixinSelf)
 			squadNumbers[mixinClient] = hotGroupNumber
 			TGNS.DoFor(TGNS.GetPlayerList(), function(p)
 				TGNS.SendNetworkMessageToPlayer(p, Shine.Plugins.scoreboard.SQUAD_CONFIRMED, {c=TGNS.GetClientIndex(mixinClient),s=squadNumbers[mixinClient]})
 			end)		
 		end
 	end

 	local isShownOnMarineScoreboard = function(weapon)
 		local result = weapon:isa("Welder") or weapon:isa("LayMines") or weapon:isa("GrenadeThrower")
 		return result
	end

 	local originalWeaponOwnerMixinAddWeapon = WeaponOwnerMixin.AddWeapon
 	WeaponOwnerMixin.AddWeapon = function(weaponOwnerMixinSelf, weapon, setActive)
 		local result = originalWeaponOwnerMixinAddWeapon(weaponOwnerMixinSelf, weapon, setActive)
 		if isShownOnMarineScoreboard(weapon) then
	 		self:AnnouncePlayerPrefix(weaponOwnerMixinSelf)
 		end
 		return result
 	end

 	local originalWeaponOwnerMixinRemoveWeapon = WeaponOwnerMixin.RemoveWeapon
 	WeaponOwnerMixin.RemoveWeapon = function(weaponOwnerMixinSelf, weapon)
 		originalWeaponOwnerMixinRemoveWeapon(weaponOwnerMixinSelf, weapon)
 		if isShownOnMarineScoreboard(weapon) then
	 		self:AnnouncePlayerPrefix(weaponOwnerMixinSelf)
 		end
 	end

 	local OnTunnelExitAddedOrRemoved = function(tunnelSelf, exit, original)
 		original(tunnelSelf, exit)
 		local unnamedLocationName = "<Unnamed Location>"
 		local exitLocationNames = {}
 		if tunnelSelf.exitAId and tunnelSelf.exitAId ~= Entity.invalidId then
 			local location = GetLocationForPoint(tunnelSelf.exitAEntityPosition)
			local locationName = location and (location:GetName() and location:GetName() or unnamedLocationName) or unnamedLocationName
			table.insert(exitLocationNames, locationName)
 		end
 		if tunnelSelf.exitBId and tunnelSelf.exitBId ~= Entity.invalidId then
 			local location = GetLocationForPoint(tunnelSelf.exitBEntityPosition)
			local locationName = location and (location:GetName() and location:GetName() or unnamedLocationName) or unnamedLocationName
			table.insert(exitLocationNames, locationName)
 		end
 		if #exitLocationNames == 2 and tunnelSelf.timeExitBChanged < tunnelSelf.timeExitAChanged then
 			exitLocationNames = {exitLocationNames[2], exitLocationNames[1]}
 		end
 		local tunnelDescription = TGNS.Join(exitLocationNames, " / ")
 		local client = TGNS.GetClientByNs2Id(tunnelSelf.ownerClientId)
 		if client then
	 		local clientIndex = TGNS.GetClientIndex(client)
	 		tunnelDescriptions[clientIndex] = tunnelDescription
	 		self:AnnouncePlayerPrefix(TGNS.GetPlayer(client))
 		end
 	end

 	local originalTunnelAddExit = Tunnel.AddExit
 	Tunnel.AddExit = function(tunnelSelf, exit)
 		OnTunnelExitAddedOrRemoved(tunnelSelf, exit, originalTunnelAddExit)
 	end
 	local originalTunnelRemoveExit = Tunnel.RemoveExit
 	Tunnel.RemoveExit = function(tunnelSelf, exit)
 		OnTunnelExitAddedOrRemoved(tunnelSelf, exit, originalTunnelRemoveExit)
 	end

	local originalEmbryoSetGestationData = Embryo.SetGestationData
	Embryo.SetGestationData = function(embryoSelf, techIds, previousTechId, healthScalar, armorScalar)
		originalEmbryoSetGestationData(embryoSelf, techIds, previousTechId, healthScalar, armorScalar)
		self:AnnouncePlayerPrefix(embryoSelf)
	end

	local function getApprovals()
		if TGNS.Config and TGNS.Config.ApproveEndpointBaseUrl then
			local url = TGNS.Config.ApproveEndpointBaseUrl
			TGNS.GetHttpAsync(url, function(approveResponseJson)
				-- Shared.Message("approveResponseJson: " .. approveResponseJson)
				local approveResponse = json.decode(approveResponseJson) or {}
				if approveResponse.success then
					TGNS.DoForPairs(approveResponse.result, function(steamId, count)
						approveCache[tonumber(steamId)] = count
					end)
					approveCacheWasPreloaded = true
				else
					TGNS.DebugPrint(string.format("approvals ERROR: Unable to access approve data. url: %s | msg: %s | response: %s | stacktrace: %s", url, approveResponse.msg, approveResponseJson, approveResponse.stacktrace))
				end
			end)
		else
			TGNS.ScheduleAction(0, getApprovals)
		end
	end
	getApprovals()





	return true
end

function Plugin:Cleanup()
    --Cleanup your extra stuff like timers, data etc.
    self.BaseClass.Cleanup( self )
end