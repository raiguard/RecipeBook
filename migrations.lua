local dictionary = require("__flib__/dictionary-lite")
local migration = require("__flib__/migration")

local database = require("__RecipeBook__/database")
local gui = require("__RecipeBook__/gui")

local by_version = {
  ["4.0.0"] = function()
    -- NUKE EVERYTHING
    global = {}
    -- Re-init
    dictionary.on_init()
    database.on_init()
    gui.on_init()
  end,
}

local migrations = {}

migrations.on_configuration_changed = function(e)
  migration.on_config_changed(e, by_version)
end

return migrations
