local info_list_box = require("scripts.gui.main.info-list-box")

local item_page = {}

function item_page.build()
  return {
    info_list_box.build({"rb-gui.ingredient-in"}, 1, {"item", "ingredient_in"}),
    info_list_box.build({"rb-gui.product-of"}, 1, {"item", "product_of"}),
    info_list_box.build({"rb-gui.rocket-launch-payloads"}, 1, {"item", "rocket_launch_payloads"}),
    info_list_box.build({"rb-gui.rocket-launch-products"}, 1, {"item", "rocket_launch_products"}),
    info_list_box.build({"rb-gui.mined-from"}, 1, {"item", "mined_from"}),
    info_list_box.build({"rb-gui.usable-in"}, 1, {"item", "usable_in"}),
    info_list_box.build({"rb-gui.unlocked-by"}, 1, {"item", "unlocked_by"})
  }
end

function item_page.update(int_name, gui_data, player_data)
  local refs = gui_data.refs

  local obj_data = global.recipe_book.item[int_name]

  info_list_box.update(obj_data.ingredient_in, refs.item.ingredient_in, player_data)
  info_list_box.update(obj_data.product_of, refs.item.product_of, player_data)
  info_list_box.update(obj_data.rocket_launch_payloads, refs.item.rocket_launch_payloads, player_data)
  info_list_box.update(obj_data.rocket_launch_products, refs.item.rocket_launch_products, player_data)
  info_list_box.update(obj_data.mined_from, refs.item.mined_from, player_data)
  info_list_box.update(obj_data.usable_in, refs.item.usable_in, player_data)
  info_list_box.update(obj_data.unlocked_by, refs.item.unlocked_by, player_data)
end

return item_page
