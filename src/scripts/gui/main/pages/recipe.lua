local info_list_box = require("scripts.gui.main.info-list-box")

local recipe_page = {}

function recipe_page.build()
  local elems =  {
    info_list_box.build(
      {"rb-gui.ingredients"},
      1,
      {"recipe", "ingredients"},
      {
        {
          type = "button",
          style = "rb_list_box_item",
          tooltip = {"rb-gui.seconds-tooltip"},
          enabled = false,
          ref = {"recipe", "ingredients", "time_item"}
        }
      }
    ),
    info_list_box.build({"rb-gui.products"}, 1, {"recipe", "products"}),
    info_list_box.build({"rb-gui.made-in"}, 1, {"recipe", "made_in"}),
    info_list_box.build({"rb-gui.unlocked-by"}, 1, {"recipe", "unlocked_by"})
  }

  return elems
end

function recipe_page.update(int_name, gui_data, player_data)
  local refs = gui_data.refs

  local obj_data = global.recipe_book.recipe[int_name]

  -- set time item
  local time_item_prefix = player_data.settings.show_glyphs and "[font=RecipeBook]Z[/font]   " or ""
  local time_item = refs.recipe.ingredients.time_item
  time_item.caption = {
    "",
    time_item_prefix.."[img=quantity-time]   [font=default-bold]",
    {"rb-gui.seconds", obj_data.energy},
    "[/font]"
  }

  return
    info_list_box.update(
      obj_data.ingredients,
      refs.recipe.ingredients,
      player_data,
      {always_show = true, starting_index = 1}
    )
    + info_list_box.update(obj_data.products, refs.recipe.products, player_data, {always_show = true})
    + info_list_box.update(obj_data.made_in, refs.recipe.made_in, player_data, {blueprint_recipe = int_name})
    + info_list_box.update(obj_data.unlocked_by, refs.recipe.unlocked_by, player_data)
end

return recipe_page
