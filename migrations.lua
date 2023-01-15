local migration = require("__flib__/migration")

local by_version = {
	["4.0.0"] = function()
		-- NUKE EVERYTHING
		global = {}
		-- TODO: Re-init
	end,
}

local migrations = {}

migrations.on_configuration_changed = function(e)
	migration.on_config_changed(e, by_version)
end

return migrations
