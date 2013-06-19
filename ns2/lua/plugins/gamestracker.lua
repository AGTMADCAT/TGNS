Script.Load("lua/TGNSCommon.lua")
Script.Load("lua/TGNSAverageCalculator.lua")
Script.Load("lua/TGNSDataRepository.lua")
Script.Load("lua/TGNSMonthlyNumberGetter.lua")

local GameCountIncrementer = {}
GameCountIncrementer.Create = function(tableToUpdate, totalSetter, averageSetter)
	local result = {}
	result.Increment = function(steamId)
		steamId = tostring(steamId)
		tableToUpdate[steamId] = (tableToUpdate[steamId] or 0) + 1
		local totalGames = 0
		local playersCount = 0
		TGNS.DoForPairs(tableToUpdate, function(steamId, gamesCount)
			totalGames = totalGames + gamesCount
			playersCount = playersCount + 1
		end)
		totalSetter(totalGames)
		averageSetter(TGNSAverageCalculator.Calculate(totalGames, playersCount))
	end
	return result
end

local GameCountIncrementerFactory = {}
GameCountIncrementerFactory.Create = function(c, data)
	local result = {}
	if TGNS.IsClientSM(c) then
		result = GameCountIncrementer.Create(data.supportingMembers, function(x) data.supportingMembersGamesCountTotal = x end, function(x) data.supportingMembersGamesCountAverage = x end)
	elseif TGNS.IsPrimerOnlyClient(c) then
		result = GameCountIncrementer.Create(data.primerOnlys, function(x) data.primerOnlysGamesCountTotal = x end, function(x) data.primerOnlysGamesCountAverage = x end)
	else
		result = GameCountIncrementer.Create(data.strangers, function(x) data.strangersGamesCountTotal = x end, function(x) data.strangersGamesCountAverage = x end)
	end
	return result
end

local steamIdsWhichStartedGame = {}

local dr = TGNSDataRepository.Create("gamestracker", function(data)
	data.supportingMembers = data.supportingMembers ~= nil and data.supportingMembers or {}
	data.supportingMembersGamesCountTotal = data.supportingMembersGamesCountTotal ~= nil and data.supportingMembersGamesCountTotal or 0
	data.supportingMembersGamesCountAverage = data.supportingMembersGamesCountAverage ~= nil and data.supportingMembersGamesCountAverage or 0
	data.primerOnlys = data.primerOnlys ~= nil and data.primerOnlys or {}
	data.primerOnlysGamesCountTotal = data.primerOnlysGamesCountTotal ~= nil and data.primerOnlysGamesCountTotal or 0
	data.primerOnlysGamesCountAverage = data.primerOnlysGamesCountAverage ~= nil and data.primerOnlysGamesCountAverage or 0
	data.strangers = data.strangers ~= nil and data.strangers or {}
	data.strangersGamesCountTotal = data.strangersGamesCountTotal ~= nil and data.strangersGamesCountTotal or 0
	data.strangersGamesCountAverage = data.strangersGamesCountAverage ~= nil and data.strangersGamesCountAverage or 0
	return data
end, TGNSMonthlyNumberGetter.Get)

local function OnSetGameState(self, state, currentstate)
	if state ~= currentstate and TGNS.IsGameStartingState(state) then
		steamIdsWhichStartedGame = {}
		TGNS.DoFor(TGNS.GetPlayingClients(TGNS.GetPlayerList()), function(c) table.insert(steamIdsWhichStartedGame, TGNS.GetClientSteamId(c)) end)
	end
end
TGNS.RegisterEventHook("OnSetGameState", OnSetGameState)

local function OnGameEnd()
	local data = dr.Load()
	TGNS.DoForClientsWithId(TGNS.GetPlayingClients(TGNS.GetPlayerList()), function(c, steamId)
		if TGNS.Has(steamIdsWhichStartedGame, steamId) then
			local gameCountIncrementer = GameCountIncrementerFactory.Create(c, data)
			gameCountIncrementer.Increment(steamId)
		end
	end)
	dr.Save(data)
end
TGNS.RegisterEventHook("OnGameEnd", OnGameEnd)