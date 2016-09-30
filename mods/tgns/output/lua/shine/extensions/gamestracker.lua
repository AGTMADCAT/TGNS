local GameCountIncrementer = {}
GameCountIncrementer.Create = function(tableToUpdate, gamesCountTotalSetter, gamesCountAverageSetter, playersCountSetter)
	local result = {}
	result.Increment = function(steamId)
		steamId = tostring(steamId)
		tableToUpdate[steamId] = (tableToUpdate[steamId] or 0) + 1
		local totalGamesCount = 0
		local playersCount = 0
		TGNS.DoForPairs(tableToUpdate, function(steamId, gamesCount)
			totalGamesCount = totalGamesCount + gamesCount
			playersCount = playersCount + 1
		end)
		gamesCountTotalSetter(totalGamesCount)
		playersCountSetter(playersCount)
		gamesCountAverageSetter(TGNSAverageCalculator.Calculate(totalGamesCount, playersCount))
	end
	return result
end

local GameCountIncrementerFactory = {}
GameCountIncrementerFactory.Create = function(c, data)
	local result = {}
	if TGNS.IsClientSM(c) then
		result = GameCountIncrementer.Create(data.supportingMembers, function(x) data.supportingMembersGamesCountTotal = x end, function(x) data.supportingMembersGamesCountAverage = x end, function(x) data.supportingMembersCount = x end)
	elseif TGNS.IsPrimerOnlyClient(c) then
		result = GameCountIncrementer.Create(data.primerOnlys, function(x) data.primerOnlysGamesCountTotal = x end, function(x) data.primerOnlysGamesCountAverage = x end, function(x) data.primerOnlysCount = x end)
	else
		result = GameCountIncrementer.Create(data.strangers, function(x) data.strangersGamesCountTotal = x end, function(x) data.strangersGamesCountAverage = x end, function(x) data.strangersCount = x end)
	end
	return result
end

local dr = TGNSDataRepository.Create("gamestracker", function(data)
	data.supportingMembers = data.supportingMembers ~= nil and data.supportingMembers or {}
	data.supportingMembersCount = data.supportingMembersCount ~= nil and data.supportingMembersCount or 0
	data.supportingMembersGamesCountAverage = data.supportingMembersGamesCountAverage ~= nil and data.supportingMembersGamesCountAverage or 0
	data.supportingMembersGamesCountTotal = data.supportingMembersGamesCountTotal ~= nil and data.supportingMembersGamesCountTotal or 0
	data.primerOnlys = data.primerOnlys ~= nil and data.primerOnlys or {}
	data.primerOnlysCount = data.primerOnlysCount ~= nil and data.primerOnlysCount or 0
	data.primerOnlysGamesCountAverage = data.primerOnlysGamesCountAverage ~= nil and data.primerOnlysGamesCountAverage or 0
	data.primerOnlysGamesCountTotal = data.primerOnlysGamesCountTotal ~= nil and data.primerOnlysGamesCountTotal or 0
	data.strangers = data.strangers ~= nil and data.strangers or {}
	data.strangersCount = data.strangersCount ~= nil and data.strangersCount or 0
	data.strangersGamesCountAverage = data.strangersGamesCountAverage ~= nil and data.strangersGamesCountAverage or 0
	data.strangersGamesCountTotal = data.strangersGamesCountTotal ~= nil and data.strangersGamesCountTotal or 0
	return data
end)

local Plugin = {}

function Plugin:Initialise()
    self.Enabled = true
	TGNS.RegisterEventHook("FullGamePlayed", function(clients)
		local monthlyNumber = TGNSMonthlyNumberGetter.Get()
		dr.Load(monthlyNumber, function(loadResponse)
			if loadResponse.success then
				local data = loadResponse.value
				TGNS.DoFor(clients, function(c)
					if Shine:IsValidClient(c) then
						local gameCountIncrementer = GameCountIncrementerFactory.Create(c, data)
						local steamId = TGNS.GetClientSteamId(c)
						gameCountIncrementer.Increment(steamId)
					end
				end)
				dr.Save(data, monthlyNumber, function(saveResponse)
					if not saveResponse.success then
						TGNS.DebugPrint(string.format("gamestracker ERROR: Unable to save data. msg: '%s'; stacktrace: '%s'", saveResponse.msg, saveResponse.stacktrace), true)
					end
				end)
			else
				TGNS.DebugPrint("gamestracker ERROR: Unable to access data.", true)
			end
		end)
	end)
    return true
end

function Plugin:Cleanup()
    --Cleanup your extra stuff like timers, data etc.
    self.BaseClass.Cleanup( self )
end

Shine:RegisterExtension("gamestracker", Plugin )