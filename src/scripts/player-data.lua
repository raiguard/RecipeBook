local player_data = {}

local gui = require("__flib__.gui")
local translation = require("__flib__.translation")
local util = require("__core__.lualib.util")

local constants = require("constants")
local formatter = require("scripts.formatter")
local on_tick = require("scripts.on-tick")

local main_gui = require("scripts.gui.main.base")
local quick_ref_gui = require("scripts.gui.quick-ref")

function player_data.init(player_index)
  local data = {
    favorites = {},
    flags = {
      can_open_gui = false,
      gui_open = false,
      technology_gui_open = false,
      show_message_after_translation = false,
      translate_on_join = false,
      updating_setting = false,
    },
    gui = {
      quick_ref = {}
    },
    history = {
      global = {},
      session = {
        position = 1
      }
    },
    settings = {},
    translations = nil -- assigned its initial value in player_data.refresh
  }
  global.players[player_index] = data
end

function player_data.update_settings(player, player_table)
  -- static settings (stored as actual mod settings)
  local mod_settings = player.mod_settings
  local settings = {
    open_item_hotkey = mod_settings["rb-open-item-hotkey"].value,
    open_fluid_hotkey = mod_settings["rb-open-fluid-hotkey"].value,
    show_hidden = mod_settings["rb-show-hidden-objects"].value,
    show_unresearched = mod_settings["rb-show-unresearched-objects"].value,
    show_internal_names = mod_settings["rb-show-internal-names"].value,
    show_glyphs = mod_settings["rb-show-glyphs"].value,
    use_fuzzy_search = mod_settings["rb-use-fuzzy-search"].value,
  }
  -- dynamic settings (stored only on save game)
  local categories = player_table.settings.recipe_categories or {}
  for name in pairs(game.recipe_category_prototypes) do
    if categories[name] == nil then
      categories[name] = not constants.disabled_recipe_categories[name]
    end
  end
  settings.recipe_categories = categories

  player_table.settings = settings

  -- purge memoizer cache
  formatter.purge_cache(player.index)
end

function player_data.start_translations(player_index)
  translation.add_requests(player_index, global.translation_data)
  on_tick.update()
end

function player_data.refresh(player, player_table)
  -- destroy GUIs
  main_gui.close(player, player_table)
  main_gui.destroy(player, player_table)
  quick_ref_gui.destroy_all(player, player_table)

  -- set flag
  player_table.flags.can_open_gui = false

  -- set shortcut state
  player.set_shortcut_toggled("rb-toggle-gui", false)
  player.set_shortcut_available("rb-toggle-gui", false)

  -- update settings
  player_data.update_settings(player, player_table)

  -- run translations
  player_table.translations = util.table.deepcopy(constants.empty_translations_table)
  if player.connected then
    player_data.start_translations(player.index)
  else
    player_table.flags.translate_on_join = true
  end
end

function player_data.remove(player_index)
  gui.remove_player_filters(player_index)
  global.players[player_index] = nil
end

function player_data.check_cursor_stack(player)
    local cursor_stack = player.cursor_stack
    if
      cursor_stack
      and cursor_stack.valid
      and cursor_stack.valid_for_read
      and global.recipe_book.material["item."..cursor_stack.name]
    then
      return cursor_stack.name
    end
    return false
end

return player_data