local flib_dictionary = require("__flib__/dictionary-lite")
local flib_migration = require("__flib__/migration")

local database = require("__RecipeBook__/scripts/database")
local gui = require("__RecipeBook__/scripts/gui")
local researched = require("__RecipeBook__/scripts/researched")

local by_version = {
  ["4.0.0"] = function()
    global = {}

    flib_dictionary.on_init()

    database.on_init()
    gui.on_init()
    researched.on_init()
  end,
}

local migrations = {}

--- @param e ConfigurationChangedData
function migrations.on_configuration_changed(e)
  flib_migration.on_config_changed(e, by_version)
end

return migrations
