local event = require("__flib__.event")
local gui = require("__flib__.gui")
local migration = require("__flib__.migration")
local translation = require("__flib__.translation")

local global_data = require("scripts.global-data")
local migrations = require("scripts.migrations")
local player_data = require("scripts.player-data")

local base_gui = require("scripts.gui.base")

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS

-- BOOTSTRAP

event.on_init(function()
  gui.init()
  translation.init()

  global_data.init()
  for i, player in pairs(game.players) do
    player_data.init(i)
    player_data.refresh(player, global.players[i])
  end

  gui.build_lookup_tables()
end)

event.on_load(function()
  gui.build_lookup_tables()
end)

event.on_configuration_changed(function(e)
  migration.on_config_changed(e, migrations)
end)

-- GUI

gui.register_handlers()

-- INTERACTION

event.register({defines.events.on_lua_shortcut, "rb-toggle-gui"}, function(e)
  if e.input_name or e.prototype_name == "rb-toggle-gui" then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    if player_table.flags.can_open_gui then
      base_gui.toggle(player, player_table)
    else
      player.print{"rb-message.cannot-open-gui"}
    end
  end
end)

-- PLAYER

event.on_player_created(function(e)
  player_data.init(e.player_index)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  player_data.refresh(player, player_table)
  --! TEMPORARY
  base_gui.create(player, player_table)
end)

event.on_player_joined_game(function(e)
  local player_table = global.players[e.player_index]
  if player_table.flags.translate_on_join then
    player_table.flags.translate_on_join = false
    player_data.request_translations(e.player_index)
  end
end)

event.on_player_removed(function(e)
  player_data.remove(e.player_index)
end)