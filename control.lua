local event = require("__flib__.event")
local libgui = require("__flib__.gui")

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
  global.players = {}
end)

event.on_player_created(function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  global.players[e.player_index] = {}
  gui.new(player, global.players[e.player_index])
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
