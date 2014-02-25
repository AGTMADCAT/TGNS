local Plugin = Plugin

local prefixes = {}
local isCaptainsReady = {}
local isCaptainsCaptain = {}

local CaptainsReadyFontColor = Color(1, 1, 0, 1)
local CaptainsCaptainFontColor = Color(0, .933, 0, 1)

TGNS.HookNetworkMessage(Shine.Plugins.scoreboard.SCOREBOARD_DATA, function(message)
	prefixes[message.i] = message.p
	isCaptainsReady[message.i] = message.cr
	isCaptainsCaptain[message.i] = message.cc
end)

function Plugin:Initialise()
	self.Enabled = true
	-- lua\GUIScoreboard.lua
	local originalGUIScoreboardUpdateTeam = GUIScoreboard.UpdateTeam
	GUIScoreboard.UpdateTeam = function(self, updateTeam)
		originalGUIScoreboardUpdateTeam(self, updateTeam)
		local playerList = updateTeam["PlayerList"]
		local teamScores = updateTeam["GetScores"]()
		local currentPlayerIndex = 1
		for index, player in pairs(playerList) do
	        local playerRecord = teamScores[currentPlayerIndex]
	        local clientIndex = playerRecord.ClientIndex
	        local prefix = prefixes[clientIndex]
	        if TGNS.HasNonEmptyValue(prefix) then
		        player["Name"]:SetText(string.format("%s> %s", prefix, playerRecord.Name))
	        end
	        local numberColor = Color(0.5, 0.5, 0.5, 1)
	        if isCaptainsCaptain[clientIndex] == true then
	        	numberColor = CaptainsCaptainFontColor
	        elseif isCaptainsReady[clientIndex] == true then
	        	numberColor = CaptainsReadyFontColor
	        end
	        player["Number"]:SetColor(numberColor)
	        currentPlayerIndex = currentPlayerIndex + 1
	    end
	end
	return true
end

function Plugin:Cleanup()
    --Cleanup your extra stuff like timers, data etc.
    self.BaseClass.Cleanup( self )
end