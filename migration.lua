local dictionary = require("__flib__.dictionary")

local gui = require("__RecipeBook__.gui.index")

local database = require("__RecipeBook__.database")
local util = require("__RecipeBook__.util")

local migration = {}

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

  local existing_gui = util.get_gui(player)
  if existing_gui then
    existing_gui:destroy()
  end
  gui.new(player, player_table)
  gui.refresh_overhead_button(player)
end

return migration
