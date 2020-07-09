local material_page = {}

local gui = require("__flib__.gui")

local util = require("scripts.util")

function material_page.build()
  local build_list_box = gui.templates.info_list_box.build
  return {
    build_list_box({"rb-gui.ingredient-in"}, 1, "material.ingredient_in"),
    build_list_box({"rb-gui.product-of"}, 1, "material.product_of"),
    build_list_box({"rb-gui.mined-from"}, 1, "material.mined_from"),
    -- build_list_box({"rb-gui.pumped-by"}, 1, "material.pumped_by"),
    build_list_box({"rb-gui.unlocked-by"}, 1, "material.unlocked_by")
  }
end

function material_page.update(int_name, gui_data, player_info)
  local obj_data = global.recipe_book.material[int_name]

  local update_list_box = gui.templates.info_list_box.update

  update_list_box(obj_data.ingredient_in, "recipe", util.format_generic_item, gui_data.material.ingredient_in, nil, player_info)
  update_list_box(obj_data.product_of, "recipe", util.format_generic_item, gui_data.material.product_of, nil, player_info)
  update_list_box(
    obj_data.mined_from,
    "resource",
    util.format_resource_item,
    gui_data.material.mined_from,
    nil,
    player_info)
  update_list_box(
    obj_data.unlocked_by,
    "technology",
    util.format_technology_item,
    gui_data.material.unlocked_by,
    nil,
    player_info
  )
end

return material_page