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

local info_gui = require("scripts.gui.info.index")
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
  global_data.check_force(force)
end)

event.register({defines.events.on_research_finished, defines.events.on_research_reversed}, function(e)
  if not global.players then return end
  global_data.handle_research_updated(e.research, e.name == defines.events.on_research_finished and true or nil)

  -- refresh all GUIs to reflect finished research
  for _, player in pairs(e.research.force.players) do
    local player_table = global.players[player.index]
    if player_table and player_table.flags.can_open_gui then
      if player_table.flags.gui_open or player_table.settings.preserve_session then
        -- FIXME:
        -- main_gui.refresh_contents(player, player_table)
      end
      quick_ref_gui.refresh_all(player, player_table)
    end
  end
end)

-- GUI

local function read_action(e)
  local msg = gui.read_action(e)
  if msg then
    if msg.gui == "info" then
      info_gui.handle_action(msg, e)
    elseif msg.gui == "quick_ref" then
      quick_ref_gui.handle_action(msg, e)
    end
    return true
  end
  return false
end

gui.hook_events(read_action)

event.on_gui_opened(function(e)
  if not read_action(e) then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    player_table.last_opened_gui = player.opened or player.opened_gui_type
  end
end)

event.on_gui_closed(function(e)
  if not read_action(e) then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    local gui_data = player_table.guis.main
    if gui_data and gui_data.state.temp_opened then
      -- close RB
      gui_data.state.temp_opened = false
      -- FIXME:
      -- main_gui.close(player, player_table)
      -- re-open what was last open
      local last_open = player_table.last_opened_gui
      if last_open and (type(last_open) ~= "table" or last_open.valid) then
        player.opened = last_open
      end
    end
    if player_table.flags.technology_gui_open then
      player_table.flags.technology_gui_open = false
      if not gui_data.state.pinned then
        game.get_player(e.player_index).opened = gui_data.refs.base.window.frame
      end
    end
  end
end)

event.on_gui_click(function(e)
  if not read_action(e) and e.element.name == "fp_frame_background_dimmer" then
    -- bring frame to front if clicking on Factory Planner dimmer frame
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

    -- TODO: Open search GUI
    -- NOTE: Perhaps we should re-introduce holding an item to open it?
  end
end)

event.register("rb-toggle-gui", function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]

  -- Open the selected prototype
  if player_table.flags.can_open_gui then
    local selected_prototype = e.selected_prototype
    if selected_prototype then
      local class = (
        constants.type_to_class[selected_prototype.base_type]
        or constants.type_to_class[selected_prototype.derived_type]
      )
      -- Not everything will have a Recipe Book entry
      if class then
        local name = selected_prototype.name
        local obj_data = global.recipe_book[class][name]
        if obj_data then
          local context = {class = class, name = name}
          local existing_id = info_gui.find_open_context(player_table, context)
          if existing_id then
            info_gui.handle_action({id = existing_id, action = "bring_to_front"}, {player_index = e.player_index})
          else
            -- TODO: Check for and update an already existing temporary window
            info_gui.build(player, player_table, {class = class, name = name})
          end
          return
        end
      end

      -- If we're here, the selected object has no page in RB
      player.create_local_flying_text{
        text = {"message.rb-object-has-no-page"},
        create_at_cursor = true
      }
      player.play_sound{path = "utility/cannot_build"}
    else
      -- TODO: Open search GUI
    end
  end
end)

event.register({"rb-navigate-backward", "rb-navigate-forward", "rb-return-to-home", "rb-jump-to-front"}, function(e)
  local player_table = global.players[e.player_index]
  if player_table.flags.can_open_gui and player_table.flags.gui_open and not player_table.flags.technology_gui_open then
    local event_properties = constants.nav_event_properties[e.input_name]
    -- FIXME:
    -- main_gui.handle_action(
    --   {gui = "main", action = event_properties.action_name},
    --   {player_index = e.player_index, shift = event_properties.shift}
    -- )
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
  local deregister = true

  if translation.translating_players_count() > 0 then
    deregister = false
    translation.iterate_batch(e)
  end

  if deregister then
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
    -- FIXME: Create search GUI - info GUIs are created on demand
    -- main_gui.build(player, player_table)
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
  -- FIXME:
  -- if main_gui.check_can_open(player, player_table) then
  --   main_gui.open_page(player, player_table, class, name)
  --   if not player_table.flags.gui_open then
  --     main_gui.open(player, player_table)
  --   end
  -- end
end

function shared.refresh_contents(player, player_table)
  formatter.purge_cache(player.index)
  -- FIXME:
  -- main_gui.refresh_contents(player, player_table)
  quick_ref_gui.refresh_all(player, player_table)
end

function shared.register_on_tick()
  if global.__flib and translation.translating_players_count() > 0 then
    event.on_tick(on_tick)
  end
end

function shared.update_quick_ref_button(player_table)
  -- FIXME:
  -- main_gui.update_quick_ref_button(player_table)
end
