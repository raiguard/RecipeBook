local info_list_box = require("scripts.gui.main.info-list-box")

local crafter_page = {}

function crafter_page.build()
  local elems =  {
    info_list_box.build({"rb-gui.compatible-recipes"}, 1, {"crafter", "recipes"}),
    info_list_box.build({"rb-gui.unlocked-by"}, 1, {"crafter", "unlocked_by"}),
    info_list_box.build({"rb-gui.placeable-by"}, 1, {"crafter", "placeable_by"})
  }

  return elems
end

function crafter_page.update(int_name, gui_data, player_data)
  local refs = gui_data.refs
  local obj_data = global.recipe_book.crafter[int_name]

  info_list_box.update(
    obj_data.compatible_recipes,
    refs.crafter.recipes,
    player_data,
    {max_listbox_height = obj_data.researched_forces and 11 or 15}
  )
  info_list_box.update(obj_data.unlocked_by, refs.crafter.unlocked_by, player_data)
  info_list_box.update(obj_data.placeable_by, refs.crafter.placeable_by, player_data)
end

return crafter_page
