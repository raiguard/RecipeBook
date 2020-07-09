local recipe_page = {}

local gui = require("__flib__.gui")

function recipe_page.build()
  return {
    gui.templates.info_list_box.build({"rb-gui.ingredients"}, 1, "recipe.ingredients"),
    gui.templates.info_list_box.build({"rb-gui.products"}, 1, "recipe.products"),
    gui.templates.info_list_box.build({"rb-gui.made-in"}, 1, "recipe.made_in"),
    gui.templates.info_list_box.build({"rb-gui.unlocked-by"}, 1, "recipe.unlocked_by")
  }
end

function recipe_page.update(int_name, gui_data, player_info)
  local obj_data = global.recipe_book.recipe[int_name]

  local update_list_box = gui.templates.info_list_box.update

  update_list_box(obj_data.ingredients, "material", util.format_material_item, gui_data.recipe.ingredients, player_info)
  update_list_box(obj_data.products, "material", util.format_material_item, gui_data.recipe.products, player_info)
  update_list_box(obj_data.made_in, "machine", util.format_crafter_item, gui_data.recipe.made_in, player_info, obj_data)
  update_list_box(obj_data.unlocked_by, "technology", util.format_technology_item, gui_data.recipe.unlocked_by, player_info)
end

return recipe_page