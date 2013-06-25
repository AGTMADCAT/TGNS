Script.Load("lua/TGNSCommon.lua")

local function GetChatMessage(...)

	local chatMessage = StringConcatArgs(...)
	if chatMessage then
		return string.sub(chatMessage, 1, kMaxChatLength)
	end
	
	return ""
	
end

local function ProcessChatCommand(client, channel, message)
	local label = channel.label
	local hasAccess = TGNS.ClientCanRunCommand(client, command)
	local name
	local chatMessage
	
	if hasAccess and channel.canPM then
		_, _, name, chatMessage = string.find(message, "([%w%p]*) (.*)")
		chatMessage = GetChatMessage(chatMessage)
		if name ~= nil and string.len(name) > 0 then
			local targetplayer = TGNS.GetPlayerMatchingName(name)
			if targetplayer ~= nil then
				TGNS.PMAllPlayersWithAccess(client, string.format("To %s: %s", targetplayer:GetName(), chatMessage), label, true, true)
				 if not TGNS.ClientCanRunCommand(Server.GetOwner(targetplayer), label) then
					Server.SendNetworkMessage(targetplayer, "Chat", TGNS.BuildPMChatMessage(client, chatMessage, label, true), true)
				end
			else
				Server.SendNetworkMessage(client:GetControllingPlayer(), "Chat", TGNS.BuildPMChatMessage(nil, string.format("'%s' does not uniquely match a player.", name), label, true), true)
			end
		elseif chatMessage ~= nil and string.len(chatMessage) > 0 then
			TGNS.PMAllPlayersWithAccess(client, chatMessage, label, true, true)
		else
			Server.SendNetworkMessage(client:GetControllingPlayer(), "Chat", TGNS.BuildPMChatMessage(nil, "Admin usage: @<name> <message>, if name is blank only admins are messaged", label, true), true)
		end
	// Non-admins will send the message to all admins
	else
		local chatMessage = GetChatMessage(message)
		if chatMessage then
			TGNS.PMAllPlayersWithAccess(client, chatMessage, label, true, true)
		else
			Server.SendNetworkMessage(client:GetControllingPlayer(), "Chat", TGNS.BuildPMChatMessage(nil, "Usage: @<message>", label, true), true)
		end
	end
end

for command, channel in pairs(DAK.config.chat.Channels) do
	TGNS.RegisterCommandHook("Console_" .. command, function(client, ...)
			local message = StringConcatArgs(...)
			if message == nil then message = "" end
			ProcessChatCommand(client, channel, message)
		end, channel.help)
end

local function CheckForChat(client, networkMessage)
	local message = networkMessage.message
	message = StringTrim(message)

	for command, channel in pairs(DAK.config.chat.Channels) do
		if message and string.sub(message, 1, 1) == channel.triggerChar then
			ProcessChatCommand(client, channel, string.sub(message, 2, -1))
			return true
		end
	end
end

TGNS.RegisterNetworkMessageHook("ChatClient", CheckForChat, 5)

local function OnClientDelayedConnect(client)
	TGNS.DoForPairs(DAK.config.chat.Channels, function(command, channel)
		if TGNS.ClientCanRunCommand(client, command) then
			local chatMessage = string.format("Start a chat with %s to use %s. Console for details.", channel.triggerChar, channel.label)
			TGNS.PlayerAction(client, function(p) TGNS.SendChatMessage(p, chatMessage, "CHAT TIP") end)
			local consoleMessage = string.format("Use %s: %s%s", channel.label, channel.triggerChar, channel.help)
			TGNS.ConsolePrint(client, consoleMessage, "CHAT TIP")
		end
	end)
end
TGNS.RegisterEventHook("OnClientDelayedConnect", OnClientDelayedConnect, TGNS.LOWEST_EVENT_HANDLER_PRIORITY)