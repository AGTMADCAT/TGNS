--local notifiedPlayerIds = {}
local md = TGNSMessageDisplayer.Create()

local Plugin = {}

function Plugin:Initialise()
    self.Enabled = true
	local originalGetIsPlayerValidForCommander
	originalGetIsPlayerValidForCommander = TGNS.ReplaceClassMethod("CommandStructure", "GetIsPlayerValidForCommander", function(self, player)
		local result = originalGetIsPlayerValidForCommander(self, player)
		if result then
			local numberOfAliveTeammates = #TGNS.Where(TGNS.GetPlayersOnSameTeam(player), TGNS.IsPlayerAlive)
			local rookieShouldBePreventedFromCommanding = TGNS.PlayerIsRookie(player) and Balance.GetTotalGamesPlayed(TGNS.GetClient(player)) < 20 and numberOfAliveTeammates > 2
			if rookieShouldBePreventedFromCommanding then
				--if not TGNS.Has(notifiedPlayerIds, playerId) then
					local playerName = TGNS.GetPlayerName(player)
					local teamName = TGNS.GetPlayerTeamName(player)
					md:ToTeamNotifyError(TGNS.GetPlayerTeamNumber(player), string.format("%s: Rookies may not command. %s: help %s fight from the ground!", playerName, teamName, playerName))
					--table.insert(notifiedPlayerIds, playerId)
					--TGNS.ScheduleAction(3, function() TGNS.RemoveAllMatching(notifiedPlayerIds, playerId) end)
				--end
			end
			result = not rookieShouldBePreventedFromCommanding
		end
		return result
	end)
    return true
end

function Plugin:Cleanup()
    --Cleanup your extra stuff like timers, data etc.
    self.BaseClass.Cleanup( self )
end

Shine:RegisterExtension("groundedrookies", Plugin )