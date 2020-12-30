local info_list_box = require("scripts.gui.main.info-list-box")

local material_page = {}

function material_page.build()
  local build_list_box = info_list_box.build
  return {
    build_list_box({"rb-gui.ingredient-in"}, 1, {"material", "ingredient_in"}),
    build_list_box({"rb-gui.product-of"}, 1, {"material", "product_of"}),
    build_list_box({"rb-gui.rocket-launch-payloads"}, 1, {"material", "rocket_launch_payloads"}),
    build_list_box({"rb-gui.rocket-launch-products"}, 1, {"material", "rocket_launch_products"}),
    build_list_box({"rb-gui.mined-from"}, 1, {"material", "mined_from"}),
    build_list_box({"rb-gui.pumped-by"}, 1, {"material", "pumped_by"}),
    build_list_box({"rb-gui.usable-in"}, 1, {"material", "usable_in"}),
    build_list_box({"rb-gui.unlocked-by"}, 1, {"material", "unlocked_by"})
  }
end

function material_page.update(int_name, gui_data, player_data)
  local refs = gui_data.refs

  local obj_data = global.recipe_book.material[int_name]

  local update_list_box = info_list_box.update

  update_list_box(obj_data.ingredient_in, "recipe", refs.material.ingredient_in, player_data)
  update_list_box(obj_data.product_of, "recipe", refs.material.product_of, player_data)
  update_list_box(obj_data.rocket_launch_payloads, "material", refs.material.rocket_launch_payloads, player_data)
  update_list_box(obj_data.rocket_launch_products, "material", refs.material.rocket_launch_products, player_data)
  update_list_box(obj_data.mined_from, "resource", refs.material.mined_from, player_data)
  update_list_box(obj_data.pumped_by, "offshore_pump", refs.material.pumped_by, player_data)
  update_list_box(obj_data.usable_in, "lab", refs.material.usable_in, player_data)
  update_list_box(obj_data.unlocked_by, "technology", refs.material.unlocked_by, player_data)
end

return material_page
