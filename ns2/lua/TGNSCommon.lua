// TGNS Common

TGNS = {}
local scheduledActions = {}

TGNS.HIGHEST_EVENT_HANDLER_PRIORITY = 2000
TGNS.VERY_HIGH_EVENT_HANDLER_PRIORITY = 1000

function TGNS.PlayerIsRookie(player)
	local result = player:GetIsRookie()
	return result
end

function TGNS.GetClientCommunityDesignationCharacter(client)
	local result
	if TGNS.IsClientSM(client) then
		result = "S"
	elseif TGNS.IsPrimerOnlyClient(client) then
		result = "P"
	else
		result = "?"
	end
	return result
end

function TGNS.EndsWith(s, send)
	return #s >= #send and s:find(send, #s-#send+1, true) and true or false
end

function TGNS.RespawnPlayer(player)
	GetGamerules():RespawnPlayer(player)
end

function TGNS.SendToRandomTeam(player)
	local playerList = TGNS.GetPlayerList()
	local marinesCount = #TGNS.GetMarineClients(playerList)
	local aliensCount = #TGNS.GetAlienClients(playerList)
	local teamNumber
	if marinesCount == aliensCount then
		teamNumber = math.random(1,2)
	else
		teamNumber = marinesCount < aliensCount and 1 or 2
	end
	TGNS.SendToTeam(player, teamNumber)
end

function TGNS.SendToTeam(player, teamNumber)
	GetGamerules():JoinTeam(player, teamNumber)
end

function TGNS.Join(list, delimiter)
  if #list == 0 then 
    return "" 
  end
  local string = list[1]
  for i = 2, #list do 
    string = string .. delimiter .. list[i] 
  end
  return string
end

function TGNS.GetPlayerTeamName(player)
	local result = TGNS.GetTeamName(TGNS.GetPlayerTeamNumber(player))
	return result
end

function TGNS.GetPlayerTeamNumber(player)
	local result = player:GetTeamNumber()
	return result
end

function TGNS.PlayersAreTeammates(player1, player2)
	local result = TGNS.GetPlayerTeamNumber(player1) == TGNS.GetPlayerTeamNumber(player2)
	return result
end

function TGNS.TableValueCount(tt, item)
  local count
  count = 0
  for ii,xx in pairs(tt) do
    if item == xx then count = count + 1 end
  end
  return count
end

function TGNS.TableUnique(tt)
  local newtable
  newtable = {}
  for ii,xx in ipairs(tt) do
    if(TGNS.TableValueCount(newtable, xx) == 0) then
      newtable[#newtable+1] = xx
    end
  end
  return newtable
end

function TGNS.ScheduleAction(delayInSeconds, action)
	local scheduledAction = {}
	scheduledAction.when = Shared.GetTime() + delayInSeconds
	scheduledAction.what = action
	table.insert(scheduledActions, scheduledAction)
end

local function ProcessScheduledActions()
	for r = #scheduledActions, 1, -1 do
		local scheduledAction = scheduledActions[r]
		if scheduledAction.when < Shared.GetTime() then
			table.remove(scheduledActions, r)
			scheduledAction.what()
		end
	end
end

local function CommonOnServerUpdate(deltatime)
	ProcessScheduledActions()
end
DAKRegisterEventHook("kDAKOnServerUpdate", CommonOnServerUpdate, 5)

function TGNS.PlayerIsOnTeam(player, team)
	local result = player:GetTeam() == team
	return result
end

function TGNS.IsGameStartingState(gameState)
	local result = gameState == kGameState.Started
	return result
end

function TGNS.IsGameWinningState(gameState)
	local result = gameState == kGameState.Team1Won or gameState == kGameState.Team2Won
	return result
end

function TGNS.IsGameplayTeam(teamNumber)
	local result = teamNumber == kMarineTeamType or teamNumber == kAlienTeamType
	return result
end

function TGNS.GetTeamName(teamNumber)
	local result
	if teamNumber == kTeamReadyRoom then
		result = "Ready Room"
	elseif teamNumber == kMarineTeamType then
		result = "Marines"
	elseif teamNumber == kAlienTeamType then
		result = "Aliens"
	elseif teamNumber == kSpectatorIndex then
		result = "Spectator"
	end
	return result
end

function TGNS.IsPlayerReadyRoom(player)
	local result = player:GetTeamNumber() == kTeamReadyRoom
	return result
end

function TGNS.IsPlayerSpectator(player)
	local result = player:isa("Spectator") and player:GetTeamNumber() == kSpectatorIndex
	return result
end

function TGNS.GetNumericValueOrZero(countable)
	local result = countable == nil and 0 or countable
	return result
end

function TGNS.GetClientName(client)
	local result = client:GetControllingPlayer():GetName()
	return result
end

function TGNS.DoFor(elements, elementAction)
	if elements ~= nil then
		for i = 1, #elements, 1 do
			if elementAction(elements[i]) then
				break
			end
		end
	end
end

function TGNS.Where(elements, predicate)
	local result = {}
	TGNS.DoFor(elements, function(e)
		if predicate ~= nil and predicate(e) then
			table.insert(result, e)
		end
	end)
	return result
end

function TGNS.Any(elements, predicate)
	local result = #TGNS.Where(elements, predicate) > 0
	return result
end

function TGNS.IsClientCommander(client)
	local result = false
	if client ~= nil then
		local player = client:GetControllingPlayer()
		if player ~= nil then
			result = player:GetIsCommander()
		end
	end
	return result	
end

function TGNS.HasClientSignedPrimer(client)
	local result = false
	if client ~= nil then
		result = DAKGetClientCanRunCommand(client, "sv_hasprimersignature")
	end
	return result
end

function TGNS.IsClientAdmin(client)
	local result = false
	if client ~= nil then
		result = DAKGetClientCanRunCommand(client, "sv_hasadmin")
	end
	return result
end

function TGNS.IsClientTempAdmin(client)
	local result = false
	if client ~= nil then
		result = not TGNS.IsClientAdmin(client) and DAKGetClientCanRunCommand(client, "sv_istempadmin")
	end
	return result
end

function TGNS.IsClientSM(client)
	local result = false
	if client ~= nil then
		result = DAKGetClientCanRunCommand(client, "sv_hassupportingmembership")
	end
	return result
end

function TGNS.IsClientStranger(client)
	local result = not TGNS.IsClientSM(client) and not TGNS.HasClientSignedPrimer(client)
	return result
end

function TGNS.PlayerAction(client, action)
	local player = client:GetControllingPlayer()
	return action(player)
end

function TGNS.GetPlayerName(player)
	return player:GetName()
end

function TGNS.GetClientName(client)
	local result = TGNS.PlayerAction(client, TGNS.GetPlayerName)
	return result
end

function TGNS.ClientAction(player, action)
	local client = Server.GetOwner(player)
	return action(client)
end

function TGNS.ConsolePrint(client, message, prefix)
	if client ~= nil then
		if prefix == nil then
			prefix = "TGNS"
		end
		if message == nil then
			message = ""
		end
		ServerAdminPrint(client, "[" .. prefix .. "] " .. message)
	end
end

function TGNS.GetClientSteamId(client)
	result = client:GetUserId()
	return result
end

function TGNS.DoForClientsWithId(clients, clientAction)
	for i = 1, #clients, 1 do
		local client = clients[i]
		local steamId = TGNS.GetClientSteamId(client)
		if steamId == nil then
			// todo mlh report to admins so they can make sure there aren't rampant problems??
		else
			clientAction(client, steamId)
		end
	end
end

function TGNS.GetClientNameSteamIdCombo(client)
	local result = string.format("%s (%s)", TGNS.GetClientName(client), TGNS.GetClientSteamId(client))
	return result	
end

function TGNS.SendChatMessage(player, chatMessage, prefix)
	if player ~= nil then
		if prefix == nil or prefix == "" then
			prefix = "PM - " .. kDAKConfig.DAKLoader.MessageSender
		end
		chatMessage = string.sub(chatMessage, 1, kMaxChatLength)
		Server.SendNetworkMessage(player, "Chat", BuildChatMessage(false, prefix, -1, kTeamReadyRoom, kNeutralTeamType, chatMessage), true)
	end
end

function TGNS.SendAdminChat(chatMessage, prefix)
	TGNS.DoFor(TGNS.GetMatchingClients(TGNS.GetPlayerList(), TGNS.IsClientAdmin), function(c)
			TGNS.PlayerAction(c, function(p) TGNS.SendChatMessage(p, chatMessage, prefix) end)
		end
	)
end

function TGNS.SendAllChat(chatMessage, prefix)
	TGNS.DoFor(TGNS.GetPlayerList(), function(p)
		TGNS.SendChatMessage(p, chatMessage, prefix)
	end)
end

function TGNS.SendTeamChat(teamNumber, chatMessage, prefix)
	TGNS.DoFor(TGNS.GetTeamClients(teamNumber, TGNS.GetPlayerList()), function(c)
			TGNS.PlayerAction(c, function(p) TGNS.SendChatMessage(p, chatMessage, prefix) end)
		end
	)
end

function TGNS.SendAdminConsoles(message, prefix)
	TGNS.DoFor(TGNS.GetMatchingClients(TGNS.GetPlayerList(), TGNS.IsClientAdmin), function(c)
			TGNS.ConsolePrint(c, message, prefix)
		end
	)
end

function TGNS.DisconnectClient(client, reason)
	client.disconnectreason = reason
	Server.DisconnectClient(client)
end

function TGNS.GetPlayerList()

	local playerList = EntityListToTable(Shared.GetEntitiesWithClassname("Player"))
	table.sort(playerList, function(p1, p2) 
		return (p1 == nil and "" or p1:GetName()) < (p2 == nil and "" or p2:GetName())
	end)
	return playerList

end

function TGNS.GetPlayerCount() 
	local result = #TGNS.GetPlayerList()
	return result
end

function TGNS.AllPlayers(doThis)

	return function(client)
	
		local playerList = TGNS.GetPlayerList()
		for p = 1, #playerList do
		
			local player = playerList[p]
			doThis(player, client, p)
			
		end
		
	end
	
end

function TGNS.Has(elements, element)
	local found = false
	for i = 1, #elements, 1 do
		if not found and elements[i] == element then
			found = true
		end
	end
	return found
end

function TGNS.GetClient(player)
	local result = Server.GetOwner(player)
	return result
end

function TGNS.GetPlayer(client)
	local result = client:GetControllingPlayer()
	return result
end

function TGNS.GetPlayers(clients)
	local result = {}
	for i = 1, #clients, 1 do
		table.insert(result, clients[i]:GetControllingPlayer())
	end
	return result
end

function TGNS.GetMatchingClients(playerList, predicate)
	local result = {}
	playerList = playerList == nil and TGNS.GetPlayerList() or playerList
	for r = #playerList, 1, -1 do
		if playerList[r] ~= nil then
			local client = playerList[r]:GetClient()
			if client ~= nil then
				if predicate(client, playerList[r]) then
					table.insert(result, client)
				end
			end
		end
	end
	return result
end

function TGNS.GetPlayingClients(playerList)
	local result = TGNS.GetMatchingClients(playerList, function(c,p) return TGNS.IsGameplayTeam(p:GetTeamNumber()) end)
	return result
end

function TGNS.GetLastMatchingClient(playerList, predicate)
	local result = nil
	local playerList = playerList == nil and TGNS.GetPlayerList() or playerList
	for r = #playerList, 1, -1 do
		if playerList[r] ~= nil then
			local client = playerList[r]:GetClient()
			if client ~= nil then
				if predicate(client, playerList[r]) then
					result = client
				end
			end
		end
	end
	return result
end

function TGNS.UpdateAllScoreboards()
	TGNS.DoFor(TGNS.GetPlayerList(), function(p)
		p:SetScoreboardChanged(true)
	end)
end

function TGNS.GetTeamClients(teamNumber, playerList)
	local predicate = function(client, player) return player:GetTeamNumber() == teamNumber end
	local result = TGNS.GetMatchingClients(playerList, predicate)
	return result
end

function TGNS.GetSpectatorClients(playerList)
	local predicate = function(client, player) return TGNS.IsPlayerSpectator(player) end
	local result = TGNS.GetMatchingClients(playerList, predicate)
	return result
end

function TGNS.GetMarineClients(playerList)
	local result = TGNS.GetTeamClients(kMarineTeamType, playerList)
	return result
end

function TGNS.GetReadyRoomClients(playerList)
	local result = TGNS.GetTeamClients(kTeamReadyRoom, playerList)
	return result
end

function TGNS.GetAlienClients(playerList)
	local result = TGNS.GetTeamClients(kAlienTeamType, playerList)
	return result
end

function TGNS.GetReadyRoomPlayers(playerList)
	local result = TGNS.GetPlayers(TGNS.GetReadyRoomClients(playerList))
	return result
end

function TGNS.GetMarinePlayers(playerList)
	local result = TGNS.GetPlayers(TGNS.GetMarineClients(playerList))
	return result
end

function TGNS.GetAlienPlayers(playerList)
	local result = TGNS.GetPlayers(TGNS.GetAlienClients(playerList))
	return result
end

function TGNS.GetStrangersClients(playerList)
	local predicate = function(client, player) return TGNS.IsClientStranger(client) end
	local result = TGNS.GetMatchingClients(playerList, predicate)
	return result
end

function TGNS.IsPrimerOnlyClient(client)
	local result = TGNS.HasClientSignedPrimer(client) and not TGNS.IsClientSM(client)
	return result
end

function TGNS.GetPrimerOnlyClients(playerList)
	local predicate = function(client, player) return TGNS.IsPrimerOnlyClient(client) end
	local result = TGNS.GetMatchingClients(playerList, predicate)
	return result
end

function TGNS.GetSmClients(playerList)
	local predicate = function(client, player) return TGNS.IsClientSM(client) end
	local result = TGNS.GetMatchingClients(playerList, predicate)
	return result
end

function TGNS.KickClient(client, disconnectReason, onPreKick)
	if client ~= nil then
		local player = client:GetControllingPlayer()
		if player ~= nil then
			if onPreKick ~= nil then
				onPreKick(client, player)
			end
		end
		TGNS.ConsolePrint(client, disconnectReason)
		TGNS.ScheduleAction(2, function() TGNS.DisconnectClient(client, disconnectReason) end)
	end
end

function TGNS.KickPlayer(player, disconnectReason, onPreKick)
	if player ~= nil then
		TGNS.KickClient(player:GetClient(), disconnectReason, onPreKick)
	end
end

function TGNS.GetPlayerMatchingName(name, team)

	assert(type(name) == "string")
	
	local nameMatchCount = 0
	local match = nil
	
	local function Matches(player)
		if nameMatchCount == -1 then
			return // exact match found, skip others to avoid further partial matches
		end
		local playerName =  player:GetName()
		if player:GetName() == name then // exact match
			if team == nil or team == -1 or team == player:GetTeamNumber() then
				match = player
				nameMatchCount = -1
			end
		else
			local index = string.find(string.lower(playerName), string.lower(name)) // case insensitive partial match
			if index ~= nil then
				if team == nil or team == -1 or team == player:GetTeamNumber() then
					match = player
					nameMatchCount = nameMatchCount + 1
				end
			end
		end
		
	end
	TGNS.AllPlayers(Matches)()
	
	if nameMatchCount > 1 then
		match = nil // if partial match is not unique, clear the match
	end
	
	return match

end

function TGNS.GetPlayerMatchingSteamId(steamId, team)

	assert(type(steamId) == "number")
	
	local match = nil
	
	local function Matches(player)
	
		local playerClient = Server.GetOwner(player)
		if playerClient and playerClient:GetUserId() == steamId then
			if team == nil or team == -1 or team == player:GetTeamNumber() then
				match = player
			end
		end
		
	end
	TGNS.AllPlayers(Matches)()
	
	return match

end

function TGNS.GetPlayerMatching(id, team)

	local idNum = tonumber(id)
	if idNum then
		// note: using DAK's GetPlayerMatchingGameId
		return GetPlayerMatchingGameId(idNum, team) or TGNS.GetPlayerMatchingSteamId(idNum, team)
	elseif type(id) == "string" then
		return TGNS.GetPlayerMatchingName(id, team)
	end

end

if kDAKConfig and kDAKConfig.DAKLoader then

	// Returns:	builtChatMessage - a ChatMessage object
	//			consoleChatMessage - a similarly formed string for printing to the console
	function TGNS.BuildPMChatMessage(srcClient, message, command, showCommand)
		if srcClient then
			local srcPlayer = srcClient:GetControllingPlayer()
			if srcPlayer then
				srcName = srcPlayer:GetName()
			else
				srcName = kDAKConfig.DAKLoader.MessageSender
			end
		else
			srcName = kDAKConfig.DAKLoader.MessageSender
		end

		if showCommand then
			chatName =  command .. " - " .. srcName
		else
			chatName = srcName
		end

		consoleChatMessage = chatName ..": " .. message
		builtChatMessage = BuildChatMessage(false, chatName, -1, kTeamReadyRoom, kNeutralTeamType, message)
		return builtChatMessage, consoleChatMessage
	end
	
	function TGNS.PMAllPlayersWithAccess(srcClient, message, command, showCommand, selfIfNoAccess)
		builtChatMessage, consoleChatMessage = TGNS.BuildPMChatMessage(srcClient, message, command, showCommand)
		for _, player in pairs(TGNS.GetPlayerList()) do
			local client = Server.GetOwner(player)
			if client ~= nil then
				if DAKGetClientCanRunCommand(client, command) or (selfIfNoAccess and client == srcClient) then
					Server.SendNetworkMessage(player, "Chat", builtChatMessage, true)
					ServerAdminPrint(client, consoleChatMessage)
				end
			end
		end
	end
end

////////////////////////////////
// Intercept Network Messages //
////////////////////////////////

kTGNSNetworkMessageHooks = {}

function TGNS.RegisterNetworkMessageHook(messageName, func, priority)
	local eventName = "kTGNSOn" .. messageName
	DAKRegisterEventHook(eventName , func, priority)
end

local originalOnNetworkMessage = {}

local function onNetworkMessage(messageName, ...)
	local eventName = "kTGNSOn" .. messageName
	if not DAKExecuteEventHooks(eventName, ...) then
		originalOnNetworkMessage[messageName](...)
	end
end

local originalHookNetworkMessage = Server.HookNetworkMessage

Server.HookNetworkMessage = function(messageName, callback)

	Print("TGNS Hooking: %s", messageName)
	originalOnNetworkMessage[messageName] = callback
	callback = function(...) onNetworkMessage(messageName, ...) end
	kTGNSNetworkMessageHooks[messageName] = callback

	originalHookNetworkMessage(messageName, callback)

end