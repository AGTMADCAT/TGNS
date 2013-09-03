local originalGetPermission
local originalHasAccess
local originalIsInGroup
local dakData

local forEachDakUserData = function(delegate)
	TGNS.DoForPairs(dakData.users, function(userKey, userData)
		return delegate(userData)
	end)
end

local Plugin = {}

function Plugin:Initialise()
    self.Enabled = true
	dakData = TGNSJsonFileTranscoder.DecodeFromFile("config://ServerAdmin.json")
	originalGetPermission = TGNS.ReplaceClassMethod("Shine", "GetPermission", function(self, client, conCommand)
		local result = false
		if client then
			result = originalGetPermission(self, client, conCommand)
			if not result then
				local Command = self.Commands[ conCommand ]
				if Command then
					result = Command.NoPerm or self:HasAccess(client, conCommand)
				end
			end
		end
		return result
	end)

	originalHasAccess = TGNS.ReplaceClassMethod("Shine", "HasAccess", function(self, client, conCommand)
		local result = false
		if client then
			result = TGNS.IsClientAdmin(client)
			TGNS.DoForPairs(self.UserData.Groups, function(groupName, group)
				if self:IsInGroup(client, groupName) then
					local groupIncludesCommand = TGNS.Any(group.Commands, function(commandName) return commandName == conCommand end)
					if groupIncludesCommand then
						if group.IsBlacklist then
							result = false
							return true
						else
							result = true
						end
					end
				end
			end)
		end
		return result
	end)
	
	TGNS.ReplaceClassMethod("Shine", "CanTarget", function(self, client, target) return true end)

	originalIsInGroup = TGNS.ReplaceClassMethod("Shine", "IsInGroup", function(self, client, groupName)
		local result = false
		if client then
			result = originalIsInGroup(self, client, groupName)
			if not result then
				local steamId = TGNS.GetClientSteamId(client)
				result = Shine.Plugins.permissions:IsSteamIdInGroup(steamId, groupName)
			end
		end
		return result or false
	end)
    return true
end

function Plugin:IsSteamIdInGroup(steamId, groupName)
	local result = false
	TGNS.DoForPairs(dakData.users, function(userKey, userData)
		if userData.id == steamId and TGNS.Any(userData.groups, function(x) return x == groupName end) then
			result = true
		end
		return result
	end)
	return result
end

function Plugin:Cleanup()
    --Cleanup your extra stuff like timers, data etc.
    self.BaseClass.Cleanup( self )
end

Shine:RegisterExtension("permissions", Plugin )