local recipe_page = {}

local gui = require("__flib__.gui")

function recipe_page.build()
  return {
    {type="frame", style="rb_crafting_time_frame", children={
      {type="label", style="bold_label", caption={"rb-gui.crafting-time"}},
      {template="pushers.horizontal"},
      {type="label", save_as="recipe.crafting_time"}
    }},
    gui.templates.info_list_box.build({"rb-gui.ingredients"}, 1, "recipe.ingredients"),
    gui.templates.info_list_box.build({"rb-gui.products"}, 1, "recipe.products"),
    gui.templates.info_list_box.build({"rb-gui.made-in"}, 1, "recipe.made_in"),
    gui.templates.info_list_box.build({"rb-gui.unlocked-by"}, 1, "recipe.unlocked_by")
  }
end

function recipe_page.update(int_name, gui_data, player_data)
  local obj_data = global.recipe_book.recipe[int_name]

  gui_data.recipe.crafting_time.caption = obj_data.energy.."s"

  local update_list_box = gui.templates.info_list_box.update

  update_list_box(obj_data.ingredients, "material", gui_data.recipe.ingredients, player_data, true)
  update_list_box(obj_data.products, "material", gui_data.recipe.products, player_data, true)
  update_list_box(obj_data.made_in, "crafter", gui_data.recipe.made_in, player_data)
  update_list_box(obj_data.unlocked_by, "technology", gui_data.recipe.unlocked_by, player_data)
end

return recipe_page