local event = require("__flib__.control.event")
local gui = require("__flib__.control.gui")
local migration = require("__flib__.control.migration")
local translation = require("__flib__.control.translation")

require("scripts.gui.common")

local constants = require("scripts.constants")
local global_data = require("scripts.global-data")
local info_gui = require("scripts.gui.info-base")
local migrations = require("scripts.migrations")
local player_data = require("scripts.player-data")
local recipe_quick_reference_gui = require("scripts.gui.recipe-quick-reference")
local search_gui = require("scripts.gui.search")

local open_fluid_types = {
  ["fluid-wagon"] = true,
  ["infinity-pipe"] = true,
  ["offshore-pump"] = true,
  ["pipe-to-ground"] = true,
  ["pipe"] = true,
  ["pump"] = true,
  ["storage-tank"] = true
}

local string_sub = string.sub

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS

-- BOOTSTRAP

event.on_init(function()
  gui.init()
  translation.init()

  global_data.init()
  for i, player in pairs(game.players) do
    player_data.init(player, i)
  end

  gui.build_lookup_tables()
end)

event.on_load(function()
  gui.build_lookup_tables()
end)

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, migrations) then
    global_data.build_recipe_book()

    for i, player in pairs(game.players) do
      player_data.refresh(player, global.players[i])
    end
  end
end)

-- INTERACTION

event.register("rb-toggle-search", function(e)
  local player = game.get_player(e.player_index)
  -- open held item, if it has a material page
  if player.mod_settings["rb-open-item-hotkey"].value then
    local cursor_stack = player.cursor_stack
    if cursor_stack and cursor_stack.valid and cursor_stack.valid_for_read and global.recipe_book.material["item,"..cursor_stack.name] then
      event.raise(constants.open_gui_event, {player_index=e.player_index, gui_type="material", object={"item", cursor_stack.name}})
      return
    end
  end
  -- get player's currently selected entity to check for a fluid filter
  local selected = player.selected
  if player.mod_settings["rb-open-fluid-hotkey"].value then
    if selected and selected.valid and open_fluid_types[selected.type] then
      local fluidbox = selected.fluidbox
      if fluidbox and fluidbox.valid then
        local locked_fluid = fluidbox.get_locked_fluid(1)
        if locked_fluid then
          -- check recipe book to see if this fluid has a material page
          if global.recipe_book.material["fluid,"..locked_fluid] then
            event.raise(constants.open_gui_event, {player_index=e.player_index, gui_type="material", object={"fluid", locked_fluid}})
            return
          end
        end
      end
    end
  end
  event.raise(constants.open_gui_event, {player_index=e.player_index, gui_type="search"})
end)

event.on_lua_shortcut(function(e)
  if e.prototype_name == "rb-toggle-search" then
    -- read player's cursor stack to see if we should open the material GUI
    local player = game.get_player(e.player_index)
    local cursor_stack = player.cursor_stack
    if cursor_stack and cursor_stack.valid and cursor_stack.valid_for_read and global.recipe_book.material["item,"..cursor_stack.name] then
      -- the player is holding something, so open to its material GUI
      event.raise(constants.open_gui_event, {player_index=e.player_index, gui_type="material", object={"item", cursor_stack.name}})
    else
      event.raise(constants.open_gui_event, {player_index=e.player_index, gui_type="search"})
    end
  end
end)

-- INTERFACE

event.register(constants.reopen_source_event, function(e)
  local source_data = e.source_data
  if source_data.mod_name == "RecipeBook" and source_data.gui_name == "search" then
    search_gui.toggle(game.get_player(e.player_index), global.players[e.player_index], source_data)
  end
end)

event.register(constants.open_gui_event, function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local gui_type = e.gui_type
  -- protected open
  if player_table.flags.can_open_gui then
    -- check for existing GUI
    if gui_type == "search" then
      -- don"t do anything if it"s already open
      if player_table.gui.search then return end
      search_gui.open(player, player_table)
    elseif constants.info_guis[gui_type] then
      if gui_type == "material" then
        if type(e.object) ~= "table" then
          error("Invalid material object, it must be a table!")
        end
        e.object = e.object[1]..","..e.object[2]
      end
      info_gui.open_or_update(player, player_table, gui_type, e.object, e.source_data)
    elseif gui_type == "recipe_quick_reference" then
      if not player_table.gui.recipe_quick_reference[e.object] then
        recipe_quick_reference_gui.open(player, player_table, e.object)
      end
    else
      error("["..gui_type.."] is not a valid GUI type!")
    end
  else
    -- set flag and tell the player that they cannot open it
    player_table.flags.tried_to_open_gui = true
    player.print{"rb-message.translation-not-finished"}
  end
end)

-- PLAYER

event.on_player_created(function(e)
  local player = game.get_player(e.player_index)
  player_data.init(player, e.player_index)
end)

event.on_player_removed(function(e)
  global.players[e.player_index] = nil
end)

event.on_player_joined_game(function(e)
  if global.players[e.player_index].flags.translate_on_join then
    player_data.sorted_translations(e.player_index)
  end
end)

-- SETTINGS

event.on_runtime_mod_setting_changed(function(e)
  if string_sub(e.setting, 1, 3) == "rb-" then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    player_data.update_settings(player, player_table)
  end
end)

-- TICK

event.on_tick(function()
  if global.__flib.translation.active_translations_count > 0 then
    translation.translate_batch()
  end
end)

-- TRANSLATIONS

event.on_string_translated(function(e)
  translation.sort_string(e)
end)

translation.on_finished(function(e)
  local player_table = global.players[e.player_index]
  if not player_table.dictionary then player_table.dictionary = {} end

  -- add to player table
  player_table.dictionary[e.dictionary_name] = {
    lookup = e.lookup,
    sorted_translations = e.sorted_translations,
    translations = e.translations
  }

  -- set flag if we're done
  if global.__flib.translation.players[e.player_index].active_translations_count == 0 then
    local player = game.get_player(e.player_index)
    player.set_shortcut_available("rb-toggle-search", true)
    player_table.flags.can_open_gui = true
    if player_table.flags.tried_to_open_gui then
      player_table.flags.tried_to_open_gui = false
      player.print{"rb-message.translation-finished"}
    end
  end
end)