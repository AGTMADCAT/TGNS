TGNSConnectedTimesTracker = {}

local DISCONNECTED_TIME_ALLOWED_IN_SECONDS = 300
local connectedTimes = {}
local pdr = TGNSPlayerDataRepository.Create("connectedtimes", function(data)
	data.when = data.when ~= nil and data.when or nil
	data.lastSeen = data.lastSeen ~= nil and data.lastSeen or nil
	return data
end)

function TGNSConnectedTimesTracker.SetClientConnectedTimeInSeconds(client, connectedTimeInSeconds)
	local steamId = TGNS.GetClientSteamId(client)
	if connectedTimeInSeconds then
		connectedTimes[steamId] = connectedTimeInSeconds
	end
	pdr:Load(steamId, function(loadResponse)
		if loadResponse.success then
			local data = loadResponse.value
			local tooLongHasPassedSinceLastSeen = data.lastSeen == nil or (Shared.GetSystemTime() - data.lastSeen > DISCONNECTED_TIME_ALLOWED_IN_SECONDS)
			local noExistingConnectionTimeIsOnRecord = data.when == nil
			if connectedTimeInSeconds or tooLongHasPassedSinceLastSeen or noExistingConnectionTimeIsOnRecord then
				data.when = connectedTimeInSeconds or Shared.GetSystemTime()
				pdr:Save(data, function(saveResponse)
					if not saveResponse.success then
						Shared.Message("ConnectedTimesTracker ERROR: unable to save data")
					end
				end)
			end
			connectedTimes[steamId] = data.when
		else
			Shared.Message("ConnectedTimesTracker ERROR: unable to access data")
		end
	end)
end

function TGNSConnectedTimesTracker.GetClientConnectedTimeInSeconds(client)
	local steamId = TGNS.GetClientSteamId(client)
	local result = connectedTimes[steamId]
	result = result ~= nil and result or 0
	return result
end

local function GetTrackedClients()
	local allConnectedClients = TGNS.Where(TGNS.GetClients(TGNS.GetPlayerList()), function(c) return not TGNS.GetIsClientVirtual(c) end)
	local result = TGNS.Where(allConnectedClients, function(c)
		local steamId = TGNS.GetClientSteamId(c)
		return connectedTimes[steamId] ~= nil
	end)
	return result
end

function TGNSConnectedTimesTracker.PrintConnectedDurations(client)
	local trackedClients = GetTrackedClients()
	TGNS.SortAscending(trackedClients, TGNSConnectedTimesTracker.GetClientConnectedTimeInSeconds)
	local trackedStrangers = TGNS.Where(trackedClients, TGNS.IsClientStranger)
	local trackedPrimerOnlys = TGNS.Where(trackedClients, TGNS.IsPrimerOnlyClient)
	local trackedSupportingMembers = TGNS.Where(trackedClients, TGNS.IsClientSM)
	local md = TGNSMessageDisplayer.Create("CONNECTEDTIMES")
	local printConnectedTime = function(c)
		local connectedTimeInSeconds = TGNSConnectedTimesTracker.GetClientConnectedTimeInSeconds(c)
		md:ToClientConsole(client, string.format("%s> %s: %s", TGNS.GetClientCommunityDesignationCharacter(c), TGNS.GetClientName(c), TGNS.SecondsToClock(Shared.GetSystemTime() - connectedTimeInSeconds)))
	end
	TGNS.DoFor(trackedStrangers, printConnectedTime)
	TGNS.DoFor(trackedPrimerOnlys, printConnectedTime)
	TGNS.DoFor(trackedSupportingMembers, printConnectedTime)
end

local function SetClientLastSeenNow(client)
	local steamId = TGNS.GetClientSteamId(client)
	pdr:Load(steamId, function(loadResponse)
		if not loadResponse.success then
			Shared.Message("ConnectedTimesTracker ERROR: unable to access data")
		end
		local data = loadResponse.value
		data.lastSeen = Shared.GetSystemTime()
		pdr:Save(data, function(saveResponse)
			if not saveResponse.success then
				Shared.Message("ConnectedTimesTracker ERROR: unable to save data")
			end
		end)
	end)
end

local function SetLastSeenTimes()
	TGNS.DoFor(GetTrackedClients(), SetClientLastSeenNow)
	TGNS.ScheduleAction(30, SetLastSeenTimes)
end
TGNS.ScheduleAction(30, SetLastSeenTimes)

local function StripConnectedTime(client)
	local steamId = TGNS.GetClientSteamId(client)
	connectedTimes[steamId] = 0
end
TGNS.RegisterEventHook("OnClientDisconnect", StripConnectedTime)