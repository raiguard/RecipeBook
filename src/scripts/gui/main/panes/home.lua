local home_pane = {}

local gui = require("__flib__.gui")

function home_pane.build()
  return {
    gui.templates.info_list_box({"rb-gui.favorites"}, 7, "home.favorites"),
    {template="pushers.vertical"},
    gui.templates.info_list_box({"rb-gui.history"}, 7, "home.history")
  }
end

function home_pane.update()

end

return home_pane