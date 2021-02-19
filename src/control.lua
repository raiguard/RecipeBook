local event = require("__flib__.event")
local gui = require("__flib__.gui-beta")
local migration = require("__flib__.migration")
local translation = require("__flib__.translation")

local constants = require("constants")
local formatter = require("scripts.formatter")
local global_data = require("scripts.global-data")
local migrations = require("scripts.migrations")
local player_data = require("scripts.player-data")
local remote_interface = require("scripts.remote-interface")
local shared = require("scripts.shared")

local main_gui = require("scripts.gui.main.base")
local quick_ref_gui = require("scripts.gui.quick-ref")

-- -----------------------------------------------------------------------------
-- COMMANDS

commands.add_command("RecipeBook", {"rb-message.command-help"}, function(e)
  if e.parameter == "refresh-player-data" then
    local player = game.get_player(e.player_index)
    player.print{"rb-message.refreshing-player-data"}
    player_data.refresh(player, global.players[e.player_index])
  elseif e.parameter == "purge-memoizer-cache" then
    formatter.purge_cache(e.player_index)
    local player = game.get_player(e.player_index)
    player.print{"rb-message.memoizer-cache-purged"}
  else
    game.get_player(e.player_index).print{"rb-message.invalid-command"}
  end
end)

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS

-- BOOTSTRAP

event.on_init(function()
  translation.init()
  shared.register_on_tick()

  global_data.init()
  global_data.build_recipe_book()
  global_data.check_forces()
  for i, player in pairs(game.players) do
    player_data.init(i)
    player_data.refresh(player, global.players[i])
  end
end)

event.on_load(function()
  formatter.create_all_caches()
  shared.register_on_tick()
end)

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, migrations) then
    translation.init()
    shared.register_on_tick()

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

event.register({defines.events.on_research_finished, defines.events.on_research_reversed}, function(e)
  if not global.players then return end
  global_data.handle_research_updated(e.research, e.name == defines.events.on_research_finished and true or nil)

  -- refresh all GUIs to reflect finished research
  for _, player in pairs(e.research.force.players) do
    local player_table = global.players[player.index]
    if player_table and player_table.flags.can_open_gui then
      if player_table.flags.gui_open or player_table.settings.preserve_session then
        main_gui.refresh_contents(player, player_table)
      end
      quick_ref_gui.refresh_all(player, player_table)
    end
  end
end)

-- GUI

gui.hook_events(function(e)
  local msg = gui.read_action(e)
  if msg then
    if msg.gui == "main" then
      main_gui.handle_action(msg, e)
    elseif msg.gui == "quick_ref" then
      quick_ref_gui.handle_action(msg, e)
    end
  elseif e.name == defines.events.on_gui_closed and e.gui_type == defines.gui_type.research then
    local player_table = global.players[e.player_index]
    if player_table.flags.technology_gui_open then
      player_table.flags.technology_gui_open = false
      local gui_data = player_table.guis.main
      if not gui_data.state.pinned then
        game.get_player(e.player_index).opened = gui_data.refs.base.window.frame
      end
    end
  -- bring frame to front if clicking on Factory Planner dimmer frame
  elseif e.name == defines.events.on_gui_click and e.element.name == "fp_frame_background_dimmer" then
    local player_table = global.players[e.player_index]
    local gui_data = player_table.guis.main
    if gui_data then
      gui_data.refs.base.window.frame.bring_to_front()
    end
  end
end)

-- INTERACTION

event.on_lua_shortcut(function(e)
  if e.prototype_name == "rb-toggle-gui" then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]

    -- only bother if we actually can open the GUI
    if main_gui.check_can_open(player, player_table) then
      -- check player's cursor stack for an item we can open
      local item_to_open = player_data.check_cursor_stack(player)
      if item_to_open then
        main_gui.open_page(player, player_table, "item", item_to_open)
        if not player_table.flags.gui_open then
          main_gui.open(player, player_table, true)
        end
      else
        main_gui.toggle(player, player_table)
      end
    end
  end
end)

event.register("rb-toggle-gui", function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]

  -- only bother if we actually can open the GUI
  if main_gui.check_can_open(player, player_table) then
    -- check player's cursor stack for an item we can open
    if player_table.settings.open_item_hotkey then
      local item_to_open = player_data.check_cursor_stack(player)
      if item_to_open then
        main_gui.open_page(player, player_table, "item", item_to_open)
        if not player_table.flags.gui_open then
          main_gui.open(player, player_table, true)
        end
        return
      end
    end

    -- get player's currently selected entity to check for a fluid filter
    local selected = player.selected
    if player_table.settings.open_fluid_hotkey then
      if selected and selected.valid and constants.open_fluid_types[selected.type] then
        local fluidbox = selected.fluidbox
        if fluidbox and fluidbox.valid then
          local locked_fluid = fluidbox.get_locked_fluid(1)
          if locked_fluid then
            -- check recipe book to see if this fluid has a material page
            if global.recipe_book.fluid[locked_fluid] then
              main_gui.open_page(player, player_table, "fluid", locked_fluid)
              if not player_table.flags.gui_open then
                main_gui.open(player, player_table, true)
              end
              return
            end
          end
        end
      end
    end
    main_gui.toggle(player, player_table)
  end
end)

event.register({"rb-navigate-backward", "rb-navigate-forward", "rb-return-to-home", "rb-jump-to-front"}, function(e)
  local player_table = global.players[e.player_index]
  if player_table.flags.can_open_gui and player_table.flags.gui_open and not player_table.flags.technology_gui_open then
    local event_properties = constants.nav_event_properties[e.input_name]
    main_gui.handle_action(
      {gui = "main", action = event_properties.action_name},
      {player_index = e.player_index, shift = event_properties.shift}
    )
  end
end)

-- PLAYER

event.on_player_created(function(e)
  player_data.init(e.player_index)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  player_data.refresh(player, player_table)
  formatter.create_cache(e.player_index)
end)

event.on_player_removed(function(e)
  player_data.remove(e.player_index)
end)

event.on_player_joined_game(function(e)
  local player_table = global.players[e.player_index]
  if player_table.flags.translate_on_join then
    player_table.flags.translate_on_join = false
    player_data.start_translations(e.player_index)
  end
end)

event.on_player_left_game(function(e)
  if translation.is_translating(e.player_index) then
    translation.cancel(e.player_index)
    global.players[e.player_index].flags.translate_on_join = true
  end
end)

-- TICK

local function on_tick(e)
  if translation.translating_players_count() > 0 then
    translation.iterate_batch(e)
  else
    event.on_tick(nil)
  end
end

-- TRANSLATIONS

event.on_string_translated(function(e)
  local names, finished = translation.process_result(e)
  if names then
    local player_table = global.players[e.player_index]
    local translations = player_table.translations
    for dictionary_name, internal_names in pairs(names) do
      local is_name = not string.find(dictionary_name, "description")
      local dictionary = translations[dictionary_name]
      for i = 1, #internal_names do
        local internal_name = internal_names[i]
        local result = e.translated and e.result or (is_name and internal_name or nil)
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
    main_gui.build(player, player_table)
    -- update flags
    player_table.flags.can_open_gui = true
    player_table.flags.translate_on_join = false -- not really needed, but is here just in case
    player_table.flags.show_message_after_translation = false
    -- enable shortcut
    player.set_shortcut_available("rb-toggle-gui", true)
    -- update on_tick
    shared.register_on_tick()
  end
end)

-- -----------------------------------------------------------------------------
-- REMOTE INTERFACE

remote.add_interface("RecipeBook", remote_interface)

-- -----------------------------------------------------------------------------
-- SHARED FUNCTIONS

function shared.open_page(player, player_table, class, name)
  if main_gui.check_can_open(player, player_table) then
    main_gui.open_page(player, player_table, class, name)
    if not player_table.flags.gui_open then
      main_gui.open(player, player_table)
    end
  end
end

function shared.refresh_contents(player, player_table)
  formatter.purge_cache(player.index)
  main_gui.refresh_contents(player, player_table)
  quick_ref_gui.refresh_all(player, player_table)
end

function shared.register_on_tick()
  if global.__flib and translation.translating_players_count() > 0 then
    event.on_tick(on_tick)
  end
end

function shared.update_quick_ref_button(player_table)
  main_gui.update_quick_ref_button(player_table)
end
