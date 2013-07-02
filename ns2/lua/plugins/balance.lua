Script.Load("lua/TGNSCommon.lua")
Script.Load("lua/TGNSPlayerDataRepository.lua")
Script.Load("lua/TGNSNs2StatsProxy.lua")
Script.Load("lua/TGNSAverageCalculator.lua")
Script.Load("lua/TGNSScoreboardPlayerHider.lua")
local steamIdsWhichStartedGame = {}
local balanceLog = {}
local balanceInProgress = false
local lastBalanceStartTimeInSeconds = 0
local SCORE_PER_MINUTE_DATAPOINTS_TO_KEEP = 30
local RECENT_BALANCE_DURATION_IN_SECONDS = 15
local NS2STATS_SCORE_PER_MINUTE_VALID_DATA_THRESHOLD = 30
local LOCAL_DATAPOINTS_COUNT_THRESHOLD = 10

local pdr = TGNSPlayerDataRepository.Create("balance", function(balance)
			balance.wins = balance.wins ~= nil and balance.wins or 0
			balance.losses = balance.losses ~= nil and balance.losses or 0
			balance.total = balance.total ~= nil and balance.total or 0
			balance.scoresPerMinute = balance.scoresPerMinute ~= nil and balance.scoresPerMinute or {}
			return balance
		end
	)
	
Balance = {}
function Balance.IsInProgress()
	return balanceInProgress
end
function Balance.GetTotalGamesPlayed(client)
	local steamId = TGNS.GetClientSteamId(client)
	local data = pdr:Load(steamId)
	local result = data.total
	return result
end

local addWinToBalance = function(balance)
		balance.wins = balance.wins + 1
		balance.total = balance.total + 1
		if balance.wins + balance.losses > 100 then
			balance.losses = balance.losses - 1
		end
	end
local addLossToBalance = function(balance) 
		balance.losses = balance.losses + 1 
		balance.total = balance.total + 1
		if balance.wins + balance.losses > 100 then
			balance.wins = balance.wins - 1
		end
	end

local function BalanceStartedRecently()
	local result = Shared.GetTime() > RECENT_BALANCE_DURATION_IN_SECONDS and Shared.GetTime() - lastBalanceStartTimeInSeconds < RECENT_BALANCE_DURATION_IN_SECONDS
	return result
end
	
local function AddScorePerMinuteData(balance, scorePerMinute)
	table.insert(balance.scoresPerMinute, scorePerMinute)
	local scoresPerMinuteToKeep = {}
	TGNS.DoForReverse(balance.scoresPerMinute, function(scorePerMinute)
		if #scoresPerMinuteToKeep < SCORE_PER_MINUTE_DATAPOINTS_TO_KEEP then
			table.insert(scoresPerMinuteToKeep, scorePerMinute)
		end
	end)
	balance.scoresPerMinute = scoresPerMinuteToKeep
end
	
local function GetWinLossRatio(player, balance)
	local result = 0.5
	if balance ~= nil then
		local totalGames = balance.losses + balance.wins
		local notEnoughGamesToMatter = totalGames < LOCAL_DATAPOINTS_COUNT_THRESHOLD
		if notEnoughGamesToMatter then
			result = TGNS.PlayerIsRookie(player) and 0 or .5
		else
			result = balance.wins / totalGames
		end
	end
	return result
end

local function GetPlayerBalance(player)
	local result
	TGNS.ClientAction(player, function(c) 
		local steamId = TGNS.GetClientSteamId(c)
		result = pdr:Load(steamId)
		end
	)
	return result
end

local function GetPlayerScorePerMinuteAverage(player)
	local result
	if not TGNS.PlayerIsRookie(player) then
		local balance = GetPlayerBalance(player)
		result = #balance.scoresPerMinute >= LOCAL_DATAPOINTS_COUNT_THRESHOLD and TGNSAverageCalculator.CalculateFor(balance.scoresPerMinute) or nil
		if result == nil and ns2statsProxy ~= nil then
			local steamId = TGNS.ClientAction(player, TGNS.GetClientSteamId)
			local ns2StatsPlayerRecord = ns2statsProxy.GetPlayerRecord(steamId)
			if ns2StatsPlayerRecord.HasData then
				local cumulativeScore = ns2StatsPlayerRecord.GetCumulativeScore()
				local timePlayedInMinutes = TGNS.ConvertSecondsToMinutes(ns2StatsPlayerRecord.GetTimePlayedInSeconds())
				result = TGNSAverageCalculator.Calculate(cumulativeScore, timePlayedInMinutes)
				result = result < NS2STATS_SCORE_PER_MINUTE_VALID_DATA_THRESHOLD and result or nil
			end
		end
	end
	return result or 0
end

local function GetPlayerWinLossRatio(player)
	local balance = GetPlayerBalance(player)
	local result = GetWinLossRatio(player, balance)
	return result
end

local function GetPlayerProjectionAverage(clients, playerProjector)
	local values = TGNS.Select(clients, function(c)
		return TGNS.PlayerAction(c, playerProjector)
	end)
	local result = TGNSAverageCalculator.CalculateFor(values)
	return result
end

local function GetScorePerMinuteAverage(clients)
	local result = GetPlayerProjectionAverage(clients, GetPlayerScorePerMinuteAverage) or 0
	return result
end

local function GetWinLossAverage(clients)
	local result = GetPlayerProjectionAverage(clients, GetPlayerWinLossRatio) or 0
	return result
end

local function PrintBalanceLog()
	TGNS.DoFor(balanceLog, function(logline)
		TGNS.SendAdminConsoles(logline, "BALANCE")
	end)
end

local function SendNextPlayer()
	local wantToUseWinLossToBalance = false
	
	local playersBuilder
	local teamAverageGetter
	
	if wantToUseWinLossToBalance then
		playersBuilder = function(playerList)
			local playersWithFewerThanTenGames = TGNS.GetPlayers(TGNS.GetMatchingClients(playerList, function(c,p) return GetPlayerBalance(p).total < LOCAL_DATAPOINTS_COUNT_THRESHOLD end))
			local playersWithTenOrMoreGames = TGNS.GetPlayers(TGNS.GetMatchingClients(playerList, function(c,p) return GetPlayerBalance(p).total >= LOCAL_DATAPOINTS_COUNT_THRESHOLD end))
			TGNS.SortDescending(playersWithTenOrMoreGames, GetPlayerWinLossRatio)
			local result = playersWithFewerThanTenGames
			TGNS.DoFor(playersWithTenOrMoreGames, function(p)
				table.insert(result, p)
			end)
			return result
		end
		teamAverageGetter = GetWinLossAverage
	else
		playersBuilder = function(playerList)
			local result = playerList
			TGNS.SortDescending(result, GetPlayerScorePerMinuteAverage)
			return result
		end
		teamAverageGetter = GetScorePerMinuteAverage
	end

	local players = playersBuilder(TGNS.GetPlayerList())
	local eligiblePlayers = TGNS.Where(players, function(p) return TGNS.IsPlayerReadyRoom(p) and not TGNS.IsPlayerAFK(p) end)
	if #eligiblePlayers > 0 then
		local playerList = TGNS.GetPlayerList()
		local marineClients = TGNS.GetMarineClients(playerList)
		local alienClients = TGNS.GetAlienClients(playerList)
		local marineAvg = teamAverageGetter(marineClients)
		local alienAvg = teamAverageGetter(alienClients)
		local teamNumber
		local teamIsWeaker
		if #marineClients <= #alienClients then
			teamNumber = kMarineTeamType
			teamIsWeaker = marineAvg <= alienAvg
		else
			teamNumber = kAlienTeamType
			teamIsWeaker = alienAvg <= marineAvg
		end
		local player = TGNS.GetFirst(eligiblePlayers) // teamIsWeaker and TGNS.GetFirst(eligiblePlayers) or TGNS.GetLast(eligiblePlayers)
		local actionMessage = string.format("sent to %s", TGNS.GetTeamName(teamNumber))
		table.insert(balanceLog, string.format("%s: %s with %s = %s", TGNS.GetPlayerName(player), GetPlayerScorePerMinuteAverage(player), GetPlayerBalance(player).total, actionMessage))
		TGNS.SendToTeam(player, teamNumber)
		TGNS.ScheduleAction(0.25, SendNextPlayer)
	else
		TGNS.SendAdminConsoles("Balance finished.", "BALANCEDEBUG")
		Shared.Message("Balance finished.")
		balanceInProgress = false
		local playerList = TGNS.GetPlayerList()
		local marineClients = TGNS.GetMarineClients(playerList)
		local alienClients = TGNS.GetAlienClients(playerList)
		local marineAvg = teamAverageGetter(marineClients)
		local alienAvg = teamAverageGetter(alienClients)
		local averagesReport = string.format("MarineAvg: %s | AlienAvg: %s", marineAvg, alienAvg)
		table.insert(balanceLog, averagesReport)
		TGNS.ScheduleAction(1, PrintBalanceLog)
	end
end

local function BeginBalance()
	balanceLog = {}
	SendNextPlayer()
end

local function svBalance(client)
	local gameState = GetGamerules():GetGameState()
	if gameState == kGameState.NotStarted or gameState == kGameState.PreGame then
		TGNS.SendAllChat(string.format("%s is balancing teams using TG and ns2stats score-per-minute data.", TGNS.GetClientName(client)), "TacticalGamer.com")
		TGNS.SendAllChat("Scoreboard is hidden until you're placed on a team.", "TacticalGamer.com")
		balanceInProgress = true
		lastBalanceStartTimeInSeconds = Shared.GetTime()
		TGNS.ScheduleAction(5, BeginBalance)
		TGNS.ScheduleAction(RECENT_BALANCE_DURATION_IN_SECONDS + 1, TGNS.UpdateAllScoreboards)
		TGNS.UpdateAllScoreboards()
	end
end
TGNS.RegisterCommandHook("Console_sv_balance", svBalance, "Balances all players to teams.")

local function BalanceOnSetGameState(self, state, currentstate)
	if state ~= currentstate then
		if TGNS.IsGameStartingState(state) then
			steamIdsWhichStartedGame = {}
			TGNS.DoFor(TGNS.GetPlayingClients(TGNS.GetPlayerList()), function(c) table.insert(steamIdsWhichStartedGame, TGNS.GetClientSteamId(c)) end)
		end
	end
end
TGNS.RegisterEventHook("OnSetGameState", BalanceOnSetGameState)

local function BalanceOnGameEnd(self, winningTeam)
	TGNS.DoForClientsWithId(TGNS.GetPlayingClients(TGNS.GetPlayerList()), function(c, steamId)
			if TGNS.Has(steamIdsWhichStartedGame, steamId) then
				local player = TGNS.GetPlayer(c)
				local changeBalanceFunction = TGNS.PlayerIsOnTeam(player, winningTeam) and addWinToBalance or addLossToBalance
				local balance = pdr:Load(steamId)
				changeBalanceFunction(balance)
				AddScorePerMinuteData(balance, TGNS.GetPlayerScorePerMinute(player))
				pdr:Save(balance)
			end
		end
	)
end
TGNS.RegisterEventHook("OnGameEnd", BalanceOnGameEnd)

TGNS.RegisterEventHook("OnTeamJoin", function(self, player, newTeamNumber, force)
	local balanceStartedRecently = BalanceStartedRecently()
	local playerIsOnPlayingTeam = TGNS.PlayerIsOnPlayingTeam(player)
	local playerMustStayOnPlayingTeamUntilBalanceIsOver = not TGNS.ClientAction(player, TGNS.IsClientAdmin)
	if balanceStartedRecently then
		TGNS.UpdateAllScoreboards()
	end
	local cancel
	if balanceStartedRecently and playerIsOnPlayingTeam and playerMustStayOnPlayingTeamUntilBalanceIsOver then
		local playerTeamIsSizedCorrectly = not TGNS.PlayerTeamIsOverbalanced(player, TGNS.GetPlayerList())
		if playerTeamIsSizedCorrectly then
			cancel = true
			local message = string.format("%s may not switch teams within %s seconds of Balance.", TGNS.GetPlayerName(player), RECENT_BALANCE_DURATION_IN_SECONDS)
			TGNS.SendAllChat(message, "BALANCE")
		end
	end
	return cancel
end)

TGNSScoreboardPlayerHider.RegisterHidingPredicate(function(targetPlayer, message)
	return BalanceStartedRecently() and not TGNS.PlayerIsOnPlayingTeam(targetPlayer) and not TGNS.ClientAction(targetPlayer, TGNS.IsClientAdmin)
end)

local function OnClientDelayedConnect(client)
	local playerHasTooFewLocalScoresPerMinute = TGNS.PlayerAction(client, function(p) return #GetPlayerBalance(p).scoresPerMinute < LOCAL_DATAPOINTS_COUNT_THRESHOLD end)
	if playerHasTooFewLocalScoresPerMinute then
		local steamId = TGNS.GetClientSteamId(client)
		TGNSNs2StatsProxy.AddSteamId(steamId)
	end
end
TGNS.RegisterEventHook("OnClientDelayedConnect", OnClientDelayedConnect, TGNS.LOWEST_EVENT_HANDLER_PRIORITY)