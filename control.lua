local libevent = require("__flib__.event")
local libgui = require("__flib__.gui")
local libmigration = require("__flib__.migration")
local mod_gui = require("__core__.lualib.mod-gui")

local database = require("__RecipeBook__.database")
local gui = require("__RecipeBook__.gui.index")
local migration = require("__RecipeBook__.migration")
local util = require("__RecipeBook__.util")

libevent.on_init(function()
  --- @type table<uint, PlayerTable>
  global.players = {}
  --- @type table<uint, boolean>
  global.update_force_guis = {} --

  migration.generic()
  for _, player in pairs(game.players) do
    migration.init_player(player)
  end
end)

libevent.on_load(function()
  for _, player_table in pairs(global.players) do
    if player_table.gui then
      gui.load(player_table.gui)
    end
  end
end)

libevent.on_configuration_changed(function(e)
  if libmigration.on_config_changed(e, {}) then
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
  local selected_prototype = e.selected_prototype
  if not selected_prototype then
    return
  end
  local path = selected_prototype.base_type .. "/" .. selected_prototype.name
  if not global.database[path] then
    return
  end
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  local gui = util.get_gui(player)
  if gui then
    gui:show_page(path)
    gui:show()
  end
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
