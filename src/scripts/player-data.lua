local player_data = {}

local translation = require("__flib__.translation")

local constants = require("constants")
local on_tick = require("scripts.on-tick")
local util = require("scripts.util")

function player_data.init(player_index)
  local data = {
    favorites = {},
    flags = {
      can_open_gui = false,
      gui_open = false,
      show_message_after_translation = false,
      translate_on_join = false,
    },
    gui = {},
    history = {},
    settings = {},
    translations = util.shallow_copy(constants.empty_translations_table)
  }
  global.players[player_index] = data
end

function player_data.update_settings(player, player_table)
  -- TODO
end

function player_data.start_translations(player_index)
  translation.add_requests(player_index, global.translation_data)
  on_tick.update()
end

function player_data.refresh(player, player_table)
  -- TODO destroy GUIs
  -- set flag
  player_table.flags.can_open_gui = false

  -- set shortcut state
  player.set_shortcut_toggled("rb-toggle-gui", false)
  player.set_shortcut_available("rb-toggle-gui", false)

  -- update settings
  player_data.update_settings(player, player_table)

  -- run translations
  player_table.translations = constants.empty_translations_table
  if player.connected then
    player_data.start_translations(player.index)
  else
    player_table.flags.translate_on_join = true
  end
end

function player_data.remove(player_index)
  -- TODO
end

function player_data.add_to_history()

end

function player_data.clear_history()

end

function player_data.add_to_favorites()

end

function player_data.remove_from_favorites()

end

return player_data