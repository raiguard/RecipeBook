local event = require("__flib__.event")
local gui = require("__flib__.gui")
local migration = require("__flib__.migration")
local translation = require("__flib__.translation")

require("scripts.gui.common")

local constants = require("scripts.constants")
local global_data = require("scripts.global-data")
local info_gui = require("scripts.gui.info-base")
local lookup_tables = require("scripts.lookup-tables")
local migrations = require("scripts.migrations")
local on_tick = require("scripts.on-tick")
local player_data = require("scripts.player-data")
local recipe_quick_reference_gui = require("scripts.gui.recipe-quick-reference")
local search_gui = require("scripts.gui.search")

local string_sub = string.sub

-- TODO pyanodon's causes EE items to not be removed
-- TODO rocket silos as crafters
-- TODO pumped from for offshore pumps

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS
-- on_tick's handler is in scripts.on-tick

-- BOOTSTRAP

event.on_init(function()
  gui.init()
  translation.init()

  global_data.init()
  for i, player in pairs(game.players) do
    player_data.init(player, i)
  end

  lookup_tables.generate()

  gui.build_lookup_tables()
end)

event.on_load(function()
  lookup_tables.generate()
  if global.__flib then
    on_tick.update()
  end

  gui.build_lookup_tables()
end)

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, migrations) then
    global_data.build_recipe_book()
    global_data.check_forces()

    for i, player in pairs(game.players) do
      player_data.refresh(player, global.players[i])
    end
  end
end)

-- FORCE

event.on_force_created(function(e)
  local force = e.force
  global_data.check_force_recipes(force)
  global_data.check_force_technologies(force)
end)

-- TODO remove force data when deleted (needs a new event)

event.on_research_finished(function(e)
  global_data.update_available_objects(e.research)
end)

-- GUI

gui.register_handlers()

event.register("rb-results-nav-confirm", function(e)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.gui.search
  if not gui_data then return end
  if gui_data.state == "select_category" then
    search_gui.confirm_category(e)
  elseif gui_data.state == "select_result" then
    search_gui.confirm_result(e)
  end
end)

event.register("rb-cycle-category", function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.gui.search
  if gui_data and gui_data.state == "select_category" then
    search_gui.cycle_category(player, player_table)
  end
end)

-- INTERACTION

event.on_lua_shortcut(function(e)
  if e.prototype_name == "rb-toggle-search" then
    -- read player's cursor stack to see if we should open the material GUI
    local player = game.get_player(e.player_index)
    local cursor_stack = player.cursor_stack
    if cursor_stack and cursor_stack.valid and cursor_stack.valid_for_read and global.recipe_book.material["item,"..cursor_stack.name] then
      -- the player is holding something, so open to its material GUI
      event.raise(constants.open_gui_event, {player_index=e.player_index, gui_type="material", object={"item", cursor_stack.name}})
    else
      event.raise(constants.open_gui_event, {player_index=e.player_index, gui_type="search", toggle=true})
    end
  end
end)

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
    if selected and selected.valid and constants.open_fluid_types[selected.type] then
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

-- INTERFACE

event.register(constants.open_gui_event, function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local gui_type = e.gui_type
  -- protected open
  if player_table.flags.can_open_gui then
    -- check for existing GUI
    if gui_type == "search" then
      -- don"t do anything if it"s already open
      if e.toggle then
        search_gui.toggle(player, player_table)
      elseif not player_table.gui.search then
        search_gui.open(player, player_table)
      end
    elseif constants.category_to_index[gui_type] then
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

event.register(constants.reopen_source_event, function(e)
  local source_data = e.source_data
  if source_data.mod_name == "RecipeBook" and source_data.gui_name == "search" then
    search_gui.toggle(game.get_player(e.player_index), global.players[e.player_index], source_data)
  end
end)

-- PLAYER

event.on_player_created(function(e)
  local player = game.get_player(e.player_index)
  player_data.init(player, e.player_index)
end)

event.on_player_removed(function(e)
  global.players[e.player_index] = nil
  lookup_tables.destroy(e.player_index)
end)

event.on_player_joined_game(function(e)
  local player_table = global.players[e.player_index]
  if player_table.flags.translate_on_join then
    player_data.start_translations(e.player_index, player_table)
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

-- TRANSLATIONS

event.on_string_translated(function(e)
  local names, finished = translation.process_result(e)
  local player_table = global.players[e.player_index]
  if names then
    local translations = player_table.translations
    for dictionary_name, internal_names in pairs(names) do
      local dictionary = translations[dictionary_name]
      for i = 1, #internal_names do
        local internal_name = internal_names[i]
        local result = e.translated and e.result or internal_name
        dictionary[internal_name] = result
        lookup_tables.add_lookup(player_table, dictionary_name, internal_name, result)
        if not e.translated then
          lookup_tables.add_translation(player_table, dictionary_name, result)
        end
      end
      if e.translated then
        lookup_tables.add_translation(player_table, dictionary_name, e.result)
      end
    end
  end
  if finished then
    local player = game.get_player(e.player_index)
    player.set_shortcut_available("rb-toggle-search", true)
    player_table.flags.can_open_gui = true
    if player_table.flags.tried_to_open_gui then
      player_table.flags.tried_to_open_gui = false
      player.print{"rb-message.translation-finished"}
    end
    player_table.flags.translating = false
    lookup_tables.transfer(e.player_index, player_table)
  end
end)

-- -----------------------------------------------------------------------------
-- REMOTE INTERFACE
-- documentation: https://github.com/raiguard/Factorio-RecipeBook/wiki/Remote-Interface-Documentation

remote.add_interface("RecipeBook", {
  open_gui = function(player_index, gui_type, object, source_data)
    -- error checking
    if not object then error("Must provide an object!") end
    if source_data and (not source_data.mod_name or not source_data.gui_name) then
      error("Incomplete source_data table!")
    end
    -- raise internal mod event
    event.raise(constants.open_gui_event, {player_index=player_index, gui_type=gui_type, object=object, source_data=source_data})
  end,
  reopen_source_event = function() return constants.reopen_source_event end,
  version = function() return constants.interface_version end
})