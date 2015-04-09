local PLAYER_COUNT_THRESHOLD = 14
local BOT_COUNT_THRESHOLD = 25
local originalEndRoundOnTeamUnbalanceSetting = 0.4
local originalForceEvenTeamsOnJoinSetting = true
local originalAutoTeamBalanceSetting = { enabled_after_seconds = 10, enabled_on_unbalance_amount = 2 }
local originalHatchCooldown = kHatchCooldown
local originalAlienSpawnTime = kAlienSpawnTime
local originalkEggGenerationRate = kEggGenerationRate
local originalkMarineRespawnTime = kMarineRespawnTime
local originalkMatureHiveHealth = kMatureHiveHealth
local originalkMatureHiveArmor = kMatureHiveArmor

local winOrLoseOccurredRecently
local md
local botAdvisory
local alltalk = false
local originalGetCanPlayerHearPlayer
local spawnReprieveAction = function() end
local surrenderBotsIfConditionsAreRight = function() end
local pushSentForThisMap = false

local Plugin = {}

function Plugin:GetTotalNumberOfBots()
	local result = #TGNS.Where(TGNS.GetClientList(), TGNS.GetIsClientVirtual)
	return result
end

local function setBotConfig()
	if not originalEndRoundOnTeamUnbalanceSetting then
		originalEndRoundOnTeamUnbalanceSetting = Server.GetConfigSetting("end_round_on_team_unbalance")
	end
	Server.SetConfigSetting("end_round_on_team_unbalance", 0)
	if not originalForceEvenTeamsOnJoinSetting then
		originalForceEvenTeamsOnJoinSetting = Server.GetConfigSetting("force_even_teams_on_join")
	end
	Server.SetConfigSetting("force_even_teams_on_join", false)
	if not originalAutoTeamBalanceSetting then
		originalAutoTeamBalanceSetting = Server.GetConfigSetting("auto_team_balance")
	end
	Server.SetConfigSetting("auto_team_balance", nil)

	kHatchCooldown = 1
	kAlienSpawnTime = 0.5
	kEggGenerationRate = 0
	kMarineRespawnTime = kMarineRespawnTime / 2
	kMatureHiveHealth = LiveMixin.kMaxHealth
	kMatureHiveArmor = LiveMixin.kMaxArmor

	TGNS.ScheduleAction(2, function()
		alltalk = true
		md:ToAllNotifyInfo("All talk enabled during bots play.")
	end)

	spawnReprieveAction = function()
		TGNS.ScheduleAction(5, function()
			if kEggGenerationRate == 0 then
				kEggGenerationRate = originalkEggGenerationRate
				TGNS.ScheduleAction(20, function()
					if Shine.Plugins.bots:GetTotalNumberOfBots() > 0 then
						kEggGenerationRate = 0
					end
				end)
			end
		end)
	end

	surrenderBotsIfConditionsAreRight = function()
		local numberOfNonAfkHumans = #TGNS.Where(TGNS.GetClientList(), function(c) return not TGNS.GetIsClientVirtual(c) and not TGNS.IsPlayerAFK(TGNS.GetPlayer(c)) end)
		if Shine.Plugins.bots:GetTotalNumberOfBots() > 0 and numberOfNonAfkHumans >= PLAYER_COUNT_THRESHOLD and TGNS.IsGameInProgress() and not winOrLoseOccurredRecently then
			md:ToAllNotifyInfo(string.format("Server has seeded to %s+ players. Bots surrender! Killing bots does not lower the WinOrLose timer.", PLAYER_COUNT_THRESHOLD))
			Shine.Plugins.winorlose:CallWinOrLose(kAlienTeamType)
			winOrLoseOccurredRecently = true
			TGNS.ScheduleAction(65, function() winOrLoseOccurredRecently = false end)
		end
	end

end

local function setOriginalConfig()
	spawnReprieveAction = function() end
	surrenderBotsIfConditionsAreRight = function() end
	if originalEndRoundOnTeamUnbalanceSetting then
		Server.SetConfigSetting("end_round_on_team_unbalance", originalEndRoundOnTeamUnbalanceSetting)
	end
	if originalForceEvenTeamsOnJoinSetting then
		Server.SetConfigSetting("force_even_teams_on_join", originalForceEvenTeamsOnJoinSetting)
	end
	if originalAutoTeamBalanceSetting then
		Server.SetConfigSetting("auto_team_balance", originalAutoTeamBalanceSetting)
	end
	kHatchCooldown = originalHatchCooldown
	kAlienSpawnTime = originalAlienSpawnTime
	kEggGenerationRate = originalkEggGenerationRate
	kMarineRespawnTime = originalkMarineRespawnTime
	kMatureHiveHealth = originalkMatureHiveHealth
	kMatureHiveArmor = originalkMatureHiveArmor

	if alltalk then
		alltalk = false
		TGNS.ScheduleAction(TGNS.ENDGAME_TIME_TO_READYROOM, function()
			md:ToAllNotifyInfo("All talk disabled.")
		end)
	end
end

local function removeBots(players, count)
	local botClients = TGNS.GetMatchingClients(players, TGNS.GetIsClientVirtual)
	TGNS.DoFor(botClients, function(c, index)
		if count == nil or index <= count then
			TGNSClientKicker.Kick(c, "Managed bot removal.", nil, nil, false)
		end
	end)
end

local function showBotAdvisory(client)
	if Shine:IsValidClient(client) then
		md:ToPlayerNotifyInfo(TGNS.GetPlayer(client), botAdvisory)
	end
end

function Plugin:ClientConfirmConnect(client)
	if self:GetTotalNumberOfBots() > 0 and not TGNS.GetIsClientVirtual(client) then
		showBotAdvisory(client)
		TGNS.ScheduleAction(5, function() showBotAdvisory(client) end)
		TGNS.ScheduleAction(10, function() showBotAdvisory(client) end)
		TGNS.ScheduleAction(20, function() showBotAdvisory(client) end)
		TGNS.ScheduleAction(40, function() showBotAdvisory(client) end)
	end
end

function Plugin:JoinTeam(gamerules, player, newTeamNumber, force, shineForce)
	local client = TGNS.GetClient(player)
	if not (force or shineForce) then
		if self:GetTotalNumberOfBots() > 0 and TGNS.IsGameplayTeamNumber(newTeamNumber) and not TGNS.GetIsClientVirtual(client) then
			local alienHumanClients = TGNS.GetMatchingClients(TGNS.GetPlayerList(), function(c,p) return TGNS.GetPlayerTeamNumber(p) == kAlienTeamType and not TGNS.GetIsClientVirtual(c) end)
			if #alienHumanClients >= 1 and newTeamNumber ~= kMarineTeamType then
			--if newTeamNumber ~= kMarineTeamType then
				md:ToPlayerNotifyError(player, "Only one human player is allowed on the bot team.")
				return false
			end
		end
	end
end

function Plugin:EndGame(gamerules, winningTeam)
	TGNS.ScheduleAction(2, function()
		removeBots(TGNS.GetPlayerList())
	end)
	setOriginalConfig()
end

function Plugin:CreateCommands()
	local botsCommand = self:BindCommand( "sh_bots", "bots", function(client, countModifier)
		countModifier = tonumber(countModifier)
		local errorMessage
		local players = TGNS.GetPlayerList()
		if countModifier then
			if self:GetTotalNumberOfBots() == 0 then
				local atLeastOnePlayerIsOnGameplayTeam = #TGNS.GetAlienClients(players) + #TGNS.GetMarineClients(players) > 0
				if #players >= PLAYER_COUNT_THRESHOLD then
					errorMessage = string.format("Bots are used only for seeding the server to %s players.", PLAYER_COUNT_THRESHOLD)
				elseif atLeastOnePlayerIsOnGameplayTeam then
					errorMessage = "All players must be in the ReadyRoom before adding initial bots."
				elseif Shine.Plugins.mapvote:VoteStarted() then
					errorMessage = "Bots cannot be managed during a map vote."
				elseif Shine.Plugins.captains and Shine.Plugins.captains:IsCaptainsModeEnabled() then
					errorMessage = "Bots cannot be managed during a Captains Game."
				end
			end
		else
			errorMessage = "Specify a positive or negative bot count modifier."
		end
		if TGNS.HasNonEmptyValue(errorMessage) then
			md:ToPlayerNotifyError(TGNS.GetPlayer(client), errorMessage)
		else
			local proposedTotalCount = self:GetTotalNumberOfBots() + countModifier
			countModifier = proposedTotalCount <= BOT_COUNT_THRESHOLD and countModifier or (countModifier - (proposedTotalCount - BOT_COUNT_THRESHOLD))
			if countModifier > 0 then
				setBotConfig()
				if not TGNS.IsGameInProgress() then
					local humanNonSpectators = TGNS.Where(players, function(p)
						local client = TGNS.GetClient(p)
						return not TGNS.GetIsClientVirtual(client) and not TGNS.IsPlayerSpectator(p)
					end)
					TGNS.DoFor(humanNonSpectators, function(p)
						TGNS.SendToTeam(p, kMarineTeamType, true)
					end)
					Shine.Plugins.forceroundstart:ForceRoundStart()
					if not pushSentForThisMap then
						Shine.Plugins.push:Push("tgns-bots", "TGNS bots round started!", string.format("%s on %s\\n\\nServer Info: http://rr.tacticalgamer.com/ServerInfo", TGNS.GetCurrentMapName(), TGNS.GetSimpleServerName()))
						pushSentForThisMap = true
					end
				end
				local command = string.format("addbot %s %s", countModifier, kAlienTeamType)
				TGNS.ScheduleAction(TGNS.IsGameInProgress() and 0 or 2, function()
					TGNS.ExecuteServerCommand(command)
				end)
			else
				local numberOfBotsToRemove = math.abs(countModifier)
				numberOfBotsToRemove = numberOfBotsToRemove < self:GetTotalNumberOfBots() and numberOfBotsToRemove or self:GetTotalNumberOfBots() - 1
				removeBots(players, numberOfBotsToRemove)
			end
		end
	end)
	botsCommand:AddParam{ Type = "string", TakeRestOfLine = true, Optional = true }
	botsCommand:Help( "<countModifier> +/- the count of alien bots." )

	local botsMaxCommand = self:BindCommand( "sh_botsmax", "botsmax", function(client, maxCandidate)
		local player = TGNS.GetPlayer(client)
		local max = tonumber(maxCandidate)
		if max <= 0 then
			md:ToPlayerNotifyError(player, "Bots maximum must be a positive number.")
		else
			BOT_COUNT_THRESHOLD = max
			local excessBotCount = self:GetTotalNumberOfBots() - BOT_COUNT_THRESHOLD
			if excessBotCount > 0 then
				removeBots(TGNS.GetPlayerList(), excessBotCount)
			end
			md:ToPlayerNotifyInfo(player, string.format("Maximum possible bots set to %s.", max))
		end
	end)
	botsMaxCommand:AddParam{ Type = "string", TakeRestOfLine = true, Optional = true }
	botsMaxCommand:Help( "<max> Set the maximum possible count of bots." )

	local humansMaxCommand = self:BindCommand( "sh_botsplayerthreshold", nil, function(client, maxCandidate)
		local player = TGNS.GetPlayer(client)
		local max = tonumber(maxCandidate)
		if max <= 0 then
			md:ToPlayerNotifyError(player, "Bots player threshold must be a positive number.")
		else
			PLAYER_COUNT_THRESHOLD = max
			md:ToPlayerNotifyInfo(player, string.format("Bots player threshold set to %s.", max))
			botAdvisory = string.format("Server switches to NS after %s players join.", PLAYER_COUNT_THRESHOLD)
		end
	end)
	humansMaxCommand:AddParam{ Type = "string", TakeRestOfLine = true, Optional = true }
	humansMaxCommand:Help( "<threshold> Set the player threshold count for bots." )
end

function Plugin:OnEntityKilled(gamerules, victimEntity, attackerEntity, inflictorEntity, point, direction)
	if victimEntity and victimEntity:isa("Player") and TGNS.GetIsClientVirtual(TGNS.GetClient(victimEntity)) and attackerEntity and attackerEntity:isa("Player") then
		local humanSameTeamPlayersWithFewerThan100Resources = TGNS.Where(TGNS.GetPlayersOnSameTeam(attackerEntity), function(p) return TGNS.GetPlayerResources(p) < 100 and not TGNS.ClientAction(p, TGNS.GetIsClientVirtual) end)
		if #humanSameTeamPlayersWithFewerThan100Resources > 0 then
			TGNS.DoFor(humanSameTeamPlayersWithFewerThan100Resources, function(p)
				TGNS.AddPlayerResources(p, 1 / #humanSameTeamPlayersWithFewerThan100Resources)
			end)
		end
	end
end

function Plugin:Initialise()
    self.Enabled = true
	md = TGNSMessageDisplayer.Create("BOTS")
	TGNS.ScheduleAction(10, setOriginalConfig)
	self:CreateCommands()
	botAdvisory = string.format("Server switches to NS after %s players join.", PLAYER_COUNT_THRESHOLD)

	originalGetCanPlayerHearPlayer = TGNS.ReplaceClassMethod("NS2Gamerules", "GetCanPlayerHearPlayer", function(self, listenerPlayer, speakerPlayer)
		local result = alltalk or originalGetCanPlayerHearPlayer(self, listenerPlayer, speakerPlayer)
		return result
	end)

	TGNS.ScheduleActionInterval(120, spawnReprieveAction)
	TGNS.ScheduleActionInterval(10, function() surrenderBotsIfConditionsAreRight() end)

    return true
end

function Plugin:Cleanup()
    --Cleanup your extra stuff like timers, data etc.
    self.BaseClass.Cleanup( self )
end

Shine:RegisterExtension("bots", Plugin )

					-- if p:GetTeamNumber() == kTeam2Index then
					-- 	p.client.variantData.gorgeVariant = kGorgeVariant.shadow
					-- 	p.client.variantData.lerkVariant = kLerkVariant.shadow
					-- 	p:Replace("fade", p:GetTeamNumber())
					-- end
