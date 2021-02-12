local info_list_box = require("scripts.gui.main.info-list-box")

local home_page = {}

function home_page.build()
  return {
    info_list_box.build({"rb-gui.favorites"}, 7, {"home", "favorites"}),
    {type = "empty-widget", style = "flib_vertical_pusher"},
    info_list_box.build({"rb-gui.history"}, 8, {"home", "history"})
  }
end

function home_page.update(_, gui_data, player_data)
  local options = {
    always_show = true,
    ignore_last_selected = true,
    keep_listbox_properties = true
  }
  return
    info_list_box.update(player_data.favorites, gui_data.refs.home.favorites, player_data, options)
    + info_list_box.update(player_data.history, gui_data.refs.home.history, player_data, options)
end

return home_page
