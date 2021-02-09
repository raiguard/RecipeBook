local info_list_box = require("scripts.gui.main.info-list-box")

local fluid_page = {}

function fluid_page.build()
  return {
    info_list_box.build({"rb-gui.ingredient-in"}, 1, {"fluid", "ingredient_in"}),
    info_list_box.build({"rb-gui.product-of"}, 1, {"fluid", "product_of"}),
    info_list_box.build({"rb-gui.mined-from"}, 1, {"fluid", "mined_from"}),
    info_list_box.build({"rb-gui.pumped-by"}, 1, {"fluid", "pumped_by"}),
    info_list_box.build({"rb-gui.unlocked-by"}, 1, {"fluid", "unlocked_by"}),
    info_list_box.build({"rb-gui.temperature-variants"}, 1, {"fluid", "temperatures"})
  }
end

function fluid_page.update(int_name, gui_data, player_data)
  local refs = gui_data.refs

  local obj_data = global.recipe_book.fluid[int_name]

  info_list_box.update(obj_data.ingredient_in, refs.fluid.ingredient_in, player_data)
  info_list_box.update(obj_data.product_of, refs.fluid.product_of, player_data)
  info_list_box.update(obj_data.mined_from, refs.fluid.mined_from, player_data)
  info_list_box.update(obj_data.pumped_by, refs.fluid.pumped_by, player_data)
  info_list_box.update(obj_data.unlocked_by, refs.fluid.unlocked_by, player_data)
  info_list_box.update(obj_data.temperatures, refs.fluid.temperatures, player_data)
end

return fluid_page
