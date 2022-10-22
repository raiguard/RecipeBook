local libevent = require("__flib__.event")
local libgui = require("__flib__.gui")
local libmigration = require("__flib__.migration")

local database = require("__RecipeBook__.database")
local migration = require("__RecipeBook__.migration")
local util = require("__RecipeBook__.util")

libevent.on_init(function()
  --- @type table<uint, PlayerTable>
  global.players = {}

  migration.generic()
  for _, player in pairs(game.players) do
    migration.init_player(player)
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
  database.on_technology_researched(e.research)
  profiler.stop()
  log({ "", "Unlock Tech ", profiler })
end)
