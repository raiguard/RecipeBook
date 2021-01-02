local info_list_box = require("scripts.gui.main.info-list-box")

local material_page = {}

function material_page.build()
  return {
    info_list_box.build({"rb-gui.ingredient-in"}, 1, {"material", "ingredient_in"}),
    info_list_box.build({"rb-gui.product-of"}, 1, {"material", "product_of"}),
    info_list_box.build({"rb-gui.rocket-launch-payloads"}, 1, {"material", "rocket_launch_payloads"}),
    info_list_box.build({"rb-gui.rocket-launch-products"}, 1, {"material", "rocket_launch_products"}),
    info_list_box.build({"rb-gui.mined-from"}, 1, {"material", "mined_from"}),
    info_list_box.build({"rb-gui.pumped-by"}, 1, {"material", "pumped_by"}),
    info_list_box.build({"rb-gui.usable-in"}, 1, {"material", "usable_in"}),
    info_list_box.build({"rb-gui.burnable-in"}, 1, {"material", "burnable_in"}, {"rb-gui.burnable-in-tooltip"}),
    info_list_box.build({"rb-gui.unlocked-by"}, 1, {"material", "unlocked_by"})
  }
end

function material_page.update(int_name, gui_data, player_data)
  local refs = gui_data.refs

  local obj_data = global.recipe_book.material[int_name]

  info_list_box.update(obj_data.ingredient_in, "recipe", refs.material.ingredient_in, player_data)
  info_list_box.update(obj_data.product_of, "recipe", refs.material.product_of, player_data)
  info_list_box.update(obj_data.rocket_launch_payloads, "material", refs.material.rocket_launch_payloads, player_data)
  info_list_box.update(obj_data.rocket_launch_products, "material", refs.material.rocket_launch_products, player_data)
  info_list_box.update(obj_data.mined_from, "resource", refs.material.mined_from, player_data)
  info_list_box.update(obj_data.pumped_by, "offshore_pump", refs.material.pumped_by, player_data)
  info_list_box.update(obj_data.usable_in, "lab", refs.material.usable_in, player_data)
  info_list_box.update(obj_data.burnable_in, "crafter", refs.material.burnable_in, player_data)
  info_list_box.update(obj_data.unlocked_by, "technology", refs.material.unlocked_by, player_data)
end

return material_page
