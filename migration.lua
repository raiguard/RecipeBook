local dictionary = require("__flib__.dictionary")

local gui = require("__RecipeBook__.gui.index")

local database = require("__RecipeBook__.database")
local util = require("__RecipeBook__.util")

local migration = {}

function migration.init()
  dictionary.init()

  --- @type table<uint, PlayerTable>
  global.players = {}
  --- @type table<uint, boolean>
  global.update_force_guis = {} --

  migration.generic()
  for _, player in pairs(game.players) do
    migration.init_player(player)
  end
end

function migration.generic()
  database.build_groups()
end

--- @param player LuaPlayer
function migration.init_player(player)
  global.players[player.index] = {}

  migration.migrate_player(player)
end

--- @param player LuaPlayer
function migration.migrate_player(player)
  local player_table = global.players[player.index]
  if not player_table then
    return
  end

  player_table.search_strings = nil
  if player.connected then
    dictionary.translate(player)
  end

  local existing_gui = gui.get(player)
  if existing_gui then
    gui.destroy(existing_gui)
  end
  gui.new(player, player_table) -- TODO: Defer this until they open it?
  gui.refresh_overhead_button(player)
end

migration.by_version = {
  ["4.0.0"] = function()
    -- NUKE EVERYTHING
    global = {}
    -- Re-init
    migration.init()
  end,
}

return migration
