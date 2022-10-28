local libevent = require("__flib__.event")
local libdictionary = require("__flib__.dictionary")
local libgui = require("__flib__.gui")
local libmigration = require("__flib__.migration")

local database = require("__RecipeBook__.database")
local gui = require("__RecipeBook__.gui.index")
local migration = require("__RecipeBook__.migration")
local util = require("__RecipeBook__.util")

libevent.on_init(function()
  migration.init()
end)

libevent.on_load(function()
  libdictionary.load()
  for _, player_table in pairs(global.players) do
    if player_table.gui then
      gui.load(player_table.gui)
    end
  end
end)

libevent.on_configuration_changed(function(e)
  if libmigration.on_config_changed(e, migration.by_version) then
    libdictionary.init()
    migration.generic()
    for _, player in pairs(game.players) do
      migration.migrate_player(player)
    end
  end
end)

libevent.on_player_created(function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  migration.init_player(player)
end)

libevent.on_player_joined_game(function(e)
  local player_table = global.players[e.player_index]
  if player_table and not player_table.search_strings then
    local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
    libdictionary.translate(player)
  end
end)

libevent.on_player_left_game(function(e)
  libdictionary.cancel_translation(e.player_index)
end)

libevent.register("rb-linked-focus-search", function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  local gui = util.get_gui(player)
  if gui and not gui.state.pinned and gui.refs.window.visible then
    if gui.state.search_open then
      gui:focus_search()
    else
      gui:toggle_search()
    end
  end
end)

libevent.register("rb-open-selected", function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  local selected_prototype = e.selected_prototype
  if not selected_prototype then
    return
  end
  local path = selected_prototype.base_type .. "/" .. selected_prototype.name
  if global.database[path] then
    local gui = util.get_gui(player)
    if gui and gui:show_page(path) then
      return
    end
  end
  player.create_local_flying_text({
    text = { "message.rb-no-info" },
    create_at_cursor = true,
  })
  player.play_sound({ path = "utility/cannot_build" })
end)

libevent.register("rb-toggle", function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  local gui = util.get_gui(player)
  if gui then
    gui:toggle()
  end
end)

libgui.hook_events(function(e)
  local action = libgui.read_action(e)
  if action then
    local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
    local gui = util.get_gui(player)
    if gui then
      gui:dispatch(e, action)
    end
  end
end)

libevent.on_research_finished(function(e)
  local profiler = game.create_profiler()
  local technology = e.research
  database.on_technology_researched(technology, technology.force.index)
  profiler.stop()
  log({ "", "Unlock Tech ", profiler })
  -- Update on the next tick in case multiple researches are done at once
  global.update_force_guis[technology.force.index] = true
end)

libevent.on_tick(function()
  libdictionary.check_skipped()
  if next(global.update_force_guis) then
    for force_index in pairs(global.update_force_guis) do
      local force = game.forces[force_index]
      if force then
        for _, player in pairs(force.players) do
          local gui = util.get_gui(player)
          if gui then
            gui:update_filter_panel()
          end
        end
      end
    end
    global.update_force_guis = {}
  end
end)

libevent.on_lua_shortcut(function(e)
  if e.prototype_name == "RecipeBook" then
    local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
    local gui = util.get_gui(player)
    if gui then
      gui:toggle()
    end
  end
end)

libevent.on_runtime_mod_setting_changed(function(e)
  if e.setting == "rb-show-overhead-button" then
    local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
    gui.refresh_overhead_button(player)
  end
end)

libevent.on_string_translated(function(e)
  local result = libdictionary.process_translation(e)
  if result then
    for _, player_index in pairs(result.players) do
      local player_table = global.players[player_index]
      if player_table then
        player_table.search_strings = result.dictionaries.search
        if player_table.gui and player_table.gui.refs.window.valid then
          player_table.gui:update_translation_warning()
        end
      end
    end
  end
end)
