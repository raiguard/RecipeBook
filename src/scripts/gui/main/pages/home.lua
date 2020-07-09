local home_page = {}

local gui = require("__flib__.gui")

function home_page.build()
  return {
    gui.templates.info_list_box.build({"rb-gui.favorites"}, 7, "home.favorites"),
    {template="pushers.vertical"},
    gui.templates.info_list_box.build({"rb-gui.history"}, 7, "home.history")
  }
end

function home_page.update()

end

return home_page