local recipe_page = {}

local gui = require("__flib__.gui")

function recipe_page.build()
  local elems =  {
    gui.templates.info_list_box.build({"rb-gui.ingredients"}, 1, "recipe.ingredients"),
    gui.templates.info_list_box.build({"rb-gui.products"}, 1, "recipe.products"),
    gui.templates.info_list_box.build({"rb-gui.made-in"}, 1, "recipe.made_in"),
    gui.templates.info_list_box.build({"rb-gui.unlocked-by"}, 1, "recipe.unlocked_by")
  }

  -- add time item to ingredients
  elems[1].children[2].children[1].children = {
    {
      type = "button",
      name = "rb_list_box_item__1",
      style = "rb_list_box_item",
      tooltip = {"rb-gui.seconds-tooltip"},
      enabled = false,
      save_as = "recipe.ingredients.time_item"
    }
  }

  return elems
end

function recipe_page.update(int_name, gui_data, player_data)
  local obj_data = global.recipe_book.recipe[int_name]

  local update_list_box = gui.templates.info_list_box.update

  -- set time item
  local time_item_prefix = player_data.settings.show_glyphs and "[font=RecipeBook]Z[/font]   " or ""
  local time_item = gui_data.recipe.ingredients.time_item
  time_item.caption = {
    "",
    time_item_prefix.."[img=quantity-time]   [font=default-bold]",
    {"rb-gui.seconds", obj_data.energy},
    "[/font]"
  }

  update_list_box(obj_data.ingredients, "material", gui_data.recipe.ingredients, player_data, true, 1)
  update_list_box(obj_data.products, "material", gui_data.recipe.products, player_data, true)
  update_list_box(obj_data.made_in, "crafter", gui_data.recipe.made_in, player_data)
  update_list_box(obj_data.unlocked_by, "technology", gui_data.recipe.unlocked_by, player_data)
end

return recipe_page