local flib_dictionary = require("__flib__.dictionary")
local flib_migration = require("__flib__.migration")

local dictionaries = require("scripts.database.dictionaries")
local researched = require("scripts.database.researched")
local gui = require("scripts.gui.main")

local by_version = {
  ["4.0.0"] = function()
    -- NUKE EVERYTHING
    global = {}
    -- Re-init
    flib_dictionary.on_init()
    dictionaries.on_init()
    researched.on_init()
    gui.on_init()
  end,
}

local migrations = {}

migrations.on_configuration_changed = function(e)
  flib_migration.on_config_changed(e, by_version)
end

return migrations
