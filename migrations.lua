local dictionary = require("__flib__/dictionary-lite")
local flib_migration = require("__flib__/migration")

local database = require("__RecipeBook__/database")
local gui = require("__RecipeBook__/gui")

local migrations = {}

function migrations.on_init()
  dictionary.on_init()

  gui.init()
  --- @type table<uint, boolean>
  global.update_force_guis = {} --

  database.build()

  for _, player in pairs(game.players) do
    migrations.init_player(player)
  end
end

--- @param e ConfigurationChangedData
function migrations.on_configuration_changed(e)
  if flib_migration.on_config_changed(e, migrations.by_version) then
    dictionary.on_configuration_changed()
    database.build()
    for _, player in pairs(game.players) do
      migrations.migrate_player(player)
    end
  end
end

--- @param player LuaPlayer
function migrations.migrate_player(player)
  gui.new(player) -- TODO: Defer this until they open it?
  gui.refresh_overhead_button(player)
end

migrations.by_version = {
  ["4.0.0"] = function()
    -- NUKE EVERYTHING
    global = {}
    -- Re-init
    migrations.on_init()
  end,
}

return migrations
