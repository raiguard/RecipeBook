local actions = require("scripts.gui.quick-ref.actions")
local root = require("scripts.gui.quick-ref.root")

local function handle_action(msg, e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]

  local gui_data = player_table.guis.quick_ref[msg.id]
  if not gui_data then
    return
  end

  local data = {
    e = e,
    gui_data = gui_data,
    msg = msg,
    player = player,
    player_table = player_table,
    refs = gui_data.refs,
    state = gui_data.state,
  }

  if type(msg) == "string" then
    actions[msg](data)
  else
    actions[msg.action](data)
  end
end

return {
  actions = actions,
  handle_action = handle_action,
  root = root,
}
