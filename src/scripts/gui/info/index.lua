local info_gui = {}

function info_gui.build(player, player_table, context)
  local id = player_table.guis.info._nextid
  player_table.guis.info._nextid = id + 1
  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      visible = false,
      ref = {"info", "window", "frame"},
      actions = {
        on_closed = {gui = "info", id = id, action = "close"}
      },
      {type = "frame", style = "inner_frame_in_outer_frame"}
    }
  })
end

function info_gui.destroy(player_table, id)

end

function info_gui.destroy_all(player_table)

end

function info_gui.handle_action(msg, e)

end

return info_gui
