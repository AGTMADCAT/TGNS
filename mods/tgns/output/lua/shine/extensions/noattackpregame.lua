local allowPostGameAttacksUntil = 0

local Plugin = {}

function Plugin:Initialise()
    self.Enabled = true
	local originalGetCanAttack
	originalGetCanAttack = TGNS.ReplaceClassMethod("Player", "GetCanAttack", function(self)
		local result = originalGetCanAttack(self)
		if result and not TGNS.IsPlayerReadyRoom(self) then
			local isPreGame = GetGamerules():GetGameState() == kGameState.PreGame or GetGamerules():GetGameState() == kGameState.NotStarted
			result = not isPreGame
		end
		return result
	end)

	local originalCanEntityDoDamageTo = CanEntityDoDamageTo
	CanEntityDoDamageTo = function(attacker, target, cheats, devMode, friendlyFire, damageType)
		local result = originalCanEntityDoDamageTo(attacker, target, cheats, devMode, friendlyFire, damageType)
		if not result and not GetGameInfoEntity():GetGameStarted() and not GetGameInfoEntity():GetWarmUpActive() and allowPostGameAttacksUntil > Shared.GetTime() then
			result = true
		end
		return result
	end

    return true
end

function Plugin:EndGame(gamerules, winningTeam)
	allowPostGameAttacksUntil = Shared.GetTime() + TGNS.ENDGAME_TIME_TO_READYROOM - 0.5
end


function Plugin:Cleanup()
    --Cleanup your extra stuff like timers, data etc.
    self.BaseClass.Cleanup( self )
end

Shine:RegisterExtension("noattackpregame", Plugin)