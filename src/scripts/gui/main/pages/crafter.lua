local info_list_box = require("scripts.gui.main.info-list-box")

local crafter_page = {}

function crafter_page.build()
  local elems =  {
    info_list_box.build({"rb-gui.recipes"}, 1, {"crafter", "recipes"}),
  }

  return elems
end

function crafter_page.update(int_name, gui_data, player_data)
  local refs = gui_data.refs
  local obj_data = global.recipe_book.crafter[int_name]

  info_list_box.update(obj_data.recipes, "recipe", refs.crafter.recipes, player_data)
end

return crafter_page
