local info_list_box = require("scripts.gui.main.info-list-box")

local home_page = {}

function home_page.build()
  return {
    info_list_box.build({"rb-gui.favorites"}, 7, {"home", "favorites"}),
    {type = "empty-widget", style = "flib_vertical_pusher"},
    info_list_box.build({"rb-gui.history"}, 8, {"home", "history"})
  }
end

function home_page.update(_, gui_data, player_data, home_data, options)
  local update = info_list_box.update_home
  update("favorites", gui_data, player_data, home_data)
  update("history", gui_data, player_data, home_data)
end

return home_page
