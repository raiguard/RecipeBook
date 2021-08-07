local event = require("__flib__.event")
local dictionary = require("__flib__.dictionary")
local gui = require("__flib__.gui")
local migration = require("__flib__.migration")
local on_tick_n = require("__flib__.on-tick-n")

local constants = require("constants")
local formatter = require("scripts.formatter")
local global_data = require("scripts.global-data")
local migrations = require("scripts.migrations")
local player_data = require("scripts.player-data")
local recipe_book = require("scripts.recipe-book")
local remote_interface = require("scripts.remote-interface")
local shared = require("scripts.shared")

local info_gui = require("scripts.gui.info.index")
local quick_ref_gui = require("scripts.gui.quick-ref.index")
local search_gui = require("scripts.gui.search.index")
local settings_gui = require("scripts.gui.settings.index")

-- -----------------------------------------------------------------------------
-- COMMANDS

-- User-facing command
commands.add_command("RecipeBook", {"command-help.RecipeBook"}, function(e)
  if e.parameter == "refresh-player-data" then
    local player = game.get_player(e.player_index)
    player.print{"message.rb-refreshing-player-data"}
    player_data.refresh(player, global.players[e.player_index])
  elseif e.parameter == "clear-memoizer-cache" then
    formatter.create_cache(e.player_index)
    local player = game.get_player(e.player_index)
    player.print{"message.rb-memoizer-cache-cleared"}
  else
    game.get_player(e.player_index).print{"message.rb-invalid-command"}
  end
end)

-- Debug commands

commands.add_command("rb-print-object", nil, function(e)
  local player = game.get_player(e.player_index)
  local _, _, class, name = string.find(e.parameter, "^(.+) (.+)$")
  if not class or not name then
    player.print("Invalid arguments format")
    return
  end
  local obj = recipe_book[class][name]
  if __DebugAdapter then
    __DebugAdapter.print(obj)
    player.print("Object data has been printed to the debug console.")
  else
    log(serpent.block(obj))
    player.print("Object data has been printed to the log file.")
  end
end)

commands.add_command("rb-count-objects", nil, function(e)
  local player = game.get_player(e.player_index)
  for name, tbl in pairs(recipe_book) do
    if type(tbl) == "table" then
      local output = name..": "..table_size(tbl)
      player.print(output)
      log(output)
    end
  end
end)

commands.add_command("rb-dump-data", nil, function(e)
  local player = game.get_player(e.player_index)
  if not player.admin then
    player.print("You must be an admin to use this command.")
    return
  end
  if __DebugAdapter and e.parameter and #e.parameter == 0 then
    __DebugAdapter.print(recipe_book)
    game.print("Recipe Book data has been dumped to the debug console.")
  else
    game.print("[color=red]DUMPING ALL RECIPE BOOK DATA[/color]")
    game.print("Get comfortable, this could take a while!")
    on_tick_n.add(game.tick + 1, {action = "dump_data", player_index = e.player_index, raw = e.parameter == "raw"})
  end
end)

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS

-- BOOTSTRAP

event.on_init(function()
  dictionary.init()
  on_tick_n.init()

  global_data.init()
  global_data.build_prototypes()

  recipe_book.build()
  recipe_book.check_forces()

  for i, player in pairs(game.players) do
    player_data.init(i)
    player_data.refresh(player, global.players[i])
  end
end)

event.on_load(function()
  dictionary.load()

  formatter.create_all_caches()

  recipe_book.build()
  recipe_book.check_forces()
end)

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, migrations) then
    dictionary.init()

    global_data.build_prototypes()

    recipe_book.build()
    recipe_book.check_forces()

    for i, player in pairs(game.players) do
      player_data.refresh(player, global.players[i])
    end
  end
end)

-- FORCE

event.on_force_created(function(e)
  global_data.add_force(e.force)
  recipe_book.check_force(e.force)
end)

event.register({defines.events.on_research_finished, defines.events.on_research_reversed}, function(e)
  if not global.players then return end
  recipe_book.handle_research_updated(e.research, e.name == defines.events.on_research_finished and true or nil)


  -- Refresh all GUIs to reflect finished research
  for _, player in pairs(e.research.force.players) do
    local player_table = global.players[player.index]
    if player_table and player_table.flags.can_open_gui then
      shared.refresh_contents(player, player_table, true)
    end
  end
end)

-- GUI

local function handle_gui_action(msg, e)
  if msg.gui == "info" then
    info_gui.handle_action(msg, e)
  elseif msg.gui == "quick_ref" then
    quick_ref_gui.handle_action(msg, e)
  elseif msg.gui == "search" then
    search_gui.handle_action(msg, e)
  elseif msg.gui == "settings" then
    settings_gui.handle_action(msg, e)
  end
end

local function read_gui_action(e)
  local msg = gui.read_action(e)
  if msg then
    handle_gui_action(msg, e)
    return true
  end
  return false
end

gui.hook_events(read_gui_action)

event.on_gui_click(function(e)
  -- If clicking on the Factory Planner dimmer frame
  if not read_gui_action(e) and e.element.style.name == "fp_frame_semitransparent" then
    -- Bring all GUIs to the front
    local player_table = global.players[e.player_index]
    if player_table.flags.can_open_gui then
      info_gui.root.bring_all_to_front(player_table)
      quick_ref_gui.actions.bring_all_to_front(player_table)
    end
  end
end)

event.register("rb-linked-focus-search", function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  if player_table.flags.can_open_gui and not player.opened then
    local info_guis = player_table.guis.info
    local active_id = info_guis._active_id
    if active_id and info_guis[active_id] then
      info_gui.handle_action({id = active_id, action = "toggle_search"}, {player_index = e.player_index})
    end
  else
    local gui_data = player_table.guis.settings
    if gui_data and player.opened == gui_data.refs.window then
      settings_gui.handle_action({action = "toggle_search"}, {player_index = e.player_index})
    end
  end
end)

-- INTERACTION

event.on_lua_shortcut(function(e)
  if e.prototype_name == "rb-search" then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]

    local cursor_stack = player.cursor_stack
    if cursor_stack and cursor_stack.valid_for_read then
      local data = recipe_book.item[cursor_stack.name]
      if data then
        shared.open_page(player, player_table, {class = "item", name = cursor_stack.name})
      else
        -- If we're here, the selected object has no page in RB
        player.create_local_flying_text{
          text = {"message.rb-object-has-no-page"},
          create_at_cursor = true
        }
        player.play_sound{path = "utility/cannot_build"}
      end
      return
    end

    -- Open search GUI
    search_gui.root.toggle(player, player_table)
  end
end)

event.register({"rb-search", "rb-open-selected"}, function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]

  if player_table.flags.can_open_gui then
    if e.input_name == "rb-open-selected" then
      -- Open the selected prototype
      local selected_prototype = e.selected_prototype
      if selected_prototype then
        local class = constants.derived_type_to_class[selected_prototype.base_type]
          or constants.derived_type_to_class[selected_prototype.derived_type]
        -- Not everything will have a Recipe Book entry
        if class then
          local name = selected_prototype.name
          local obj_data = recipe_book[class][name]
          if obj_data then
            local context = {class = class, name = name}
            shared.open_page(player, player_table, context)
            return
          end
        end

        -- If we're here, the selected object has no page in RB
        player.create_local_flying_text{
          text = {"message.rb-object-has-no-page"},
          create_at_cursor = true
        }
        player.play_sound{path = "utility/cannot_build"}
        return
      end
      -- If we're here, the player did not have an object selected
      player.create_local_flying_text{
        text = {"message.rb-did-not-select-object"},
        create_at_cursor = true
      }
      player.play_sound{path = "utility/cannot_build"}
    else
      search_gui.root.toggle(player, player_table)
    end
  else
    player.print{"message.rb-cannot-open-gui"}
    player_table.flags.show_message_after_translation = true
  end
end)

event.register({"rb-navigate-backward", "rb-navigate-forward", "rb-return-to-home", "rb-jump-to-front"}, function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  if player_table.flags.can_open_gui and not player.opened then
    local event_properties = constants.nav_event_properties[e.input_name]
    local info_guis = player_table.guis.info
    local active_id = info_guis._active_id
    if active_id and info_guis[active_id] then
      info_gui.handle_action(
        {id = active_id, action = "navigate", delta = event_properties.delta},
        {player_index = e.player_index, shift = event_properties.shift}
      )
    end
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
  dictionary.translate(game.get_player(e.player_index))
end)

event.on_player_left_game(function(e)
  dictionary.cancel_translation(e.player_index)
end)

-- TICK

event.on_tick(function(e)
  dictionary.check_skipped()

  local actions = on_tick_n.retrieve(e.tick)
  if actions then
    for _, msg in pairs(actions) do
      if msg.gui then
        handle_gui_action(msg, {player_index = msg.player_index})
      elseif msg.action == "dump_data" then
        local func = msg.raw and serpent.dump or serpent.block
        game.write_file("rb-dump.txt", func(recipe_book), false, msg.player_index)
        game.print("[color=green]Dumped RB data to script-output/rb-dump.txt[/color]")
      end
    end
  end
end)

-- TRANSLATIONS

event.on_string_translated(dictionary.process_translation)

event.register(dictionary.on_language_translated, function(e)
  for _, player_index in pairs(e.players) do
    local player = game.get_player(player_index)
    local player_table = global.players[player_index]

    player_table.translations = e.dictionaries

    -- Show message if needed
    if player_table.flags.show_message_after_translation then
      player.print{"message.rb-can-open-gui"}
      player_table.flags.show_message_after_translation = false
    end

    -- Create GUI
    search_gui.root.build(player, player_table)
    -- Update flags
    player_table.flags.can_open_gui = true
    -- Enable shortcut
    player.set_shortcut_available("rb-search", true)
  end
end)

-- -----------------------------------------------------------------------------
-- REMOTE INTERFACE

remote.add_interface("RecipeBook", remote_interface)

-- -----------------------------------------------------------------------------
-- SHARED FUNCTIONS

function shared.open_page(player, player_table, context)
  local existing_id = info_gui.root.find_open_context(player_table, context)[1]
  if existing_id then
    info_gui.handle_action({id = existing_id, action = "bring_to_front"}, {player_index = player.index})
  else
    info_gui.root.build(player, player_table, context)
  end
end

function shared.update_header_button(player, player_table, context, button, to_state)
  for _, id in pairs(info_gui.root.find_open_context(player_table, context)) do
    info_gui.handle_action(
      {id = id, action = "update_header_button", button = button, to_state = to_state},
      {player_index = player.index}
    )
  end
  if button == "favorite_button" then
    search_gui.handle_action({action = "update_favorites"}, {player_index = player.index})
  end
end

function shared.update_all_favorite_buttons(player, player_table)
  local favorites = player_table.favorites
  for id, gui_data in pairs(player_table.guis.info) do
    if id ~= "_next_id" and id ~= "_active_id" then
      local state = gui_data.state
      local opened_context = state.history[state.history._index]
      local to_state = favorites[opened_context.class.."."..opened_context.name]
      info_gui.handle_action(
        {id = id, action = "update_header_button", button = "favorite_button", to_state = to_state},
        {player_index = player.index}
      )
    end
  end
end

function shared.update_global_history(player, player_table, new_context)
  player_data.update_global_history(player_table.global_history, new_context)
  if player_table.guis.search and player_table.guis.search.refs.window.visible then
    search_gui.handle_action({action = "update_history"}, {player_index = player.index})
  end
end

function shared.refresh_contents(player, player_table, skip_memoizer_purge)
  if not skip_memoizer_purge then
    formatter.create_cache(player.index)
  end
  info_gui.root.update_all(player, player_table)
  quick_ref_gui.root.update_all(player, player_table)
  if player_table.guis.search and player_table.guis.search.refs.window.visible then
    search_gui.handle_action({action = "update_search_results"}, {player_index = player.index})
    search_gui.handle_action({action = "update_favorites"}, {player_index = player.index})
    search_gui.handle_action({action = "update_history"}, {player_index = player.index})
  end
end

