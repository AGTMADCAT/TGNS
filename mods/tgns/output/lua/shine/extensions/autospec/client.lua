local Plugin = Plugin

-- TGNS.HookNetworkMessage(Plugin.FOO, function(message)
-- end)

-- function Plugin:Foo()
-- end

function Plugin:Initialise()
	self.Enabled = true

	return true
end

function Plugin:Cleanup()
    --Cleanup your extra stuff like timers, data etc.
    self.BaseClass.Cleanup( self )
end