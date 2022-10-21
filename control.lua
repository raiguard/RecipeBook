local event = require("__flib__.event")
local libgui = require("__flib__.gui")

local database = require("__RecipeBook__.database")
local gui = require("__RecipeBook__.gui.index")

--- @param player LuaPlayer
--- @return Gui?
local function get_gui(player)
  local player_table = global.players[player.index]
  if player_table then
    local gui = player_table.gui
    if gui and gui.refs.window.valid then
      return gui
    else
      -- TODO: Recreate GUI
    end
  end
end

event.on_init(function()
  --- @type table<uint, PlayerTable>
  global.players = {}
  database.build()
end)

-- event.on_configuration_changed(function(e)
--   database.build()
--   for player_index, player_table in pairs(global.players) do
--     if player_table.gui then
--       player_table.gui:destroy()
--     end
--     local player = game.get_player(player_index) --[[@as LuaPlayer]]
--     gui.new(player, player_table)
--   end
-- end)

event.on_player_created(function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  global.players[e.player_index] = {}
  gui.new(player, global.players[e.player_index])
end)

event.register("rb-toggle", function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  local gui = get_gui(player)
  if gui then
    gui:toggle()
  end
end)

event.register("rb-open-selected", function(e)
  local selected_prototype = e.selected_prototype
  if not selected_prototype then
    return
  end
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  local gui = get_gui(player)
  if gui then
    gui:show_page(selected_prototype.name)
    gui:show()
  end
end)

libgui.hook_events(function(e)
  local action = libgui.read_action(e)
  if action then
    local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
    local gui = get_gui(player)
    if gui then
      gui:dispatch(e, action)
    end
  end
end)
