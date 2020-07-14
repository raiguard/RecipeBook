local event = require("__flib__.event")
local gui = require("__flib__.gui")
local migration = require("__flib__.migration")
local translation = require("__flib__.translation")

local constants = require("constants")
local formatter = require("scripts.formatter")
local global_data = require("scripts.global-data")
local migrations = require("scripts.migrations")
local on_tick = require("scripts.on-tick")
local player_data = require("scripts.player-data")

local main_gui = require("scripts.gui.main.base")

-- -----------------------------------------------------------------------------
-- COMMANDS

commands.add_command("RecipeBook", {"rb-message.command-help"}, function(e)
  if e.parameter == "refresh-player-data" then
    local player = game.get_player(e.player_index)
    player.print{"rb-message.refreshing-player-data"}
    player_data.refresh(player, global.players[e.player_index])
  else
    game.get_player(e.player_index).print{"rb-message.invalid-command"}
  end
end)

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS

-- BOOTSTRAP

event.on_init(function()
  gui.init()
  gui.build_lookup_tables()
  translation.init()

  global_data.init()
  for i, player in pairs(game.players) do
    player_data.init(i)
    player_data.refresh(player, global.players[i])
  end
end)

event.on_load(function()
  gui.build_lookup_tables()
  formatter.create_all_caches()
  on_tick.update()
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

-- TODO: remove force data when deleted (needs a new event)

event.on_research_finished(function(e)
  global_data.update_available_objects(e.research)
end)

-- GUI

gui.register_handlers()

event.on_gui_closed(function(e)
  if not gui.dispatch_handlers(e) and e.gui_type == defines.gui_type.research then
    local player_table = global.players[e.player_index]
    if player_table.flags.technology_gui_open then
      player_table.flags.technology_gui_open = false
      local window_data = player_table.gui.main.base.window
      if not window_data.pinned then
        game.get_player(e.player_index).opened = window_data.frame
      end
    end
  end
end)

-- INTERACTION

event.on_lua_shortcut(function(e)
  if e.prototype_name == "rb-toggle-gui" then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]

    -- check player's cursor stack for an item we can open
    local item_to_open = player_data.check_cursor_stack(player)
    if item_to_open then
      main_gui.open_page(player, player_table, "item", item_to_open)
      if not player_table.flags.gui_open then
        main_gui.open(player, player_table)
      end
    else
      main_gui.toggle(player, player_table)
    end
  end
end)

event.register("rb-toggle-gui", function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]

  -- check player's cursor stack for an item we can open
  -- TODO read from global instead of mod_settings
  if player.mod_settings["rb-open-item-hotkey"].value then
    local item_to_open = player_data.check_cursor_stack(player)
    if item_to_open then
      main_gui.open_page(player, player_table, "item", item_to_open)
      if not player_table.flags.gui_open then
        main_gui.open(player, player_table)
      end
      return
    end
  end

  -- get player's currently selected entity to check for a fluid filter
  local selected = player.selected
  -- TODO read from global instead of mod_settings
  if player.mod_settings["rb-open-fluid-hotkey"].value then
    if selected and selected.valid and constants.open_fluid_types[selected.type] then
      local fluidbox = selected.fluidbox
      if fluidbox and fluidbox.valid then
        local locked_fluid = fluidbox.get_locked_fluid(1)
        if locked_fluid then
          -- check recipe book to see if this fluid has a material page
          if global.recipe_book.material["fluid."..locked_fluid] then
            main_gui.open_page(player, player_table, "fluid", locked_fluid)
            if not player_table.flags.gui_open then
              main_gui.open(player, player_table)
            end
            return
          end
        end
      end
    end
  end
  main_gui.toggle(player, player_table)
end)

-- PLAYER

event.on_player_created(function(e)
  player_data.init(e.player_index)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  player_data.refresh(player, player_table)
  formatter.create_cache(e.player_index)
end)

event.on_player_joined_game(function(e)
  local player_table = global.players[e.player_index]
  if player_table.flags.translate_on_join then
    player_table.flags.translate_on_join = false
    player_data.start_translations(e.player_index)
  end
end)

event.on_player_removed(function(e)
  player_data.remove(e.player_index)
end)

-- SETTINGS

event.on_runtime_mod_setting_changed(function(e)
  if string.sub(e.setting, 1, 3) == "rb-" then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    player_data.update_settings(player, player_table)
    if player_table.flags.can_open_gui then
      main_gui.update_list_box_items(player, player_table)
    end
  end
end)

-- TRANSLATIONS

-- ! TEMPORARY
local settings_gui = require("scripts.gui.settings")

event.on_string_translated(function(e)
  local names, finished = translation.process_result(e)
  if names then
    local player_table = global.players[e.player_index]
    local translations = player_table.translations
    for dictionary_name, internal_names in pairs(names) do
      local dictionary = translations[dictionary_name]
      for i = 1, #internal_names do
        local internal_name = internal_names[i]
        local result = e.translated and e.result or internal_name
        dictionary[internal_name] = result
      end
    end
  end
  if finished then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    -- show message if needed
    if player_table.flags.show_message_after_translation then
      player.print{'rb-message.can-open-gui'}
    end
    -- create GUI
    main_gui.create(player, player_table)
    -- update flags
    player_table.flags.can_open_gui = true
    player_table.flags.translate_on_join = false -- not really needed, but is here just in case
    player_table.flags.show_message_after_translation = false
    -- enable shortcut
    player.set_shortcut_available("rb-toggle-gui", true)
    -- -- update on_tick
    on_tick.update()
    -- ! TEMPORARY
    settings_gui.create(player, player_table)
  end
end)

-- -----------------------------------------------------------------------------
-- REMOTE INTERFACE

remote.add_interface("RecipeBook", {
  open_page = function() return constants.events.open_page end,
  version = function() return constants.interface_version end
})

-- HANDLERS

event.register(constants.events.open_page, function(e)
  if e.mod_name ~= "RecipeBook" then
    -- TODO input validation
  end

  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  main_gui.open_page(player, player_table, e.obj_class, e.obj_name)
  if not player_table.flags.gui_open then
    main_gui.open(player, player_table)
  end
end)

event.register(constants.events.update_quick_ref_button, function(e)
  local player_table = global.players[e.player_index]
  main_gui.update_quick_ref_button(player_table)
end)