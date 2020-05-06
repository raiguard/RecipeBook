local player_data = {}

local event = require("__flib__.control.event")
local translation = require("__flib__.control.translation")

local constants = require("scripts.constants")
local info_gui = require("scripts.gui.info-base")
local on_tick = require("scripts.on-tick")
local recipe_quick_reference_gui = require("scripts.gui.recipe-quick-reference")
local search_gui = require("scripts.gui.search")

function player_data.init(player, index)
  local player_table = {
    flags = {
      can_open_gui = false,
      searching = false,
      translate_on_join = false,
      translating = false,
      tried_to_open_gui = false
    },
    history = {
      session = {position=0},
      overall = {}
    },
    gui = {
      recipe_quick_reference = {}
    },
    translation_lookup_tables = nil,
    translations = nil
  }
  global.players[index] = player_table
  player_data.refresh(player, global.players[index])
end

function player_data.start_translations(player_index, player_table)
  player_table.flags.translating = true
  translation.add_requests(player_index, global.translation_data)
  event.on_tick(on_tick.handler)
end

function player_data.update_settings(player, player_table)
  local mod_settings = player.mod_settings
  player_table.settings = {
    default_category = mod_settings["rb-default-search-category"].value,
    show_hidden = mod_settings["rb-show-hidden-objects"].value,
    show_unavailable = mod_settings["rb-show-unavailable-objects"].value,
    use_fuzzy_search = mod_settings["rb-use-fuzzy-search"].value
  }
end

function player_data.destroy_guis(player, player_table)
  local gui_data = player_table.gui
  player_table.flags.can_open_gui = false
  player.set_shortcut_available("rb-toggle-search", false)
  if gui_data.search then
    search_gui.close(player, player_table)
  end
  if gui_data.info then
    info_gui.close(player, player_table)
  end
  recipe_quick_reference_gui.close_all(player, player_table)
end

function player_data.refresh(player, player_table)
  player_data.destroy_guis(player, player_table)
  player_data.update_settings(player, player_table)

  player.set_shortcut_toggled("rb-toggle-search", false)
  player.set_shortcut_available("rb-toggle-search", false)

  player_table.translation_lookup_tables = table.deepcopy(constants.empty_lookup_tables)
  player_table.translations = table.deepcopy(constants.empty_translation_tables)

  if player.connected then
    player_data.start_translations(player.index, player_table)
  else
    player_table.flags.translate_on_join = true
  end
end

return player_data