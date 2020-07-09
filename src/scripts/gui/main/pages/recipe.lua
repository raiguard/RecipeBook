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

function recipe_page.update(parent, gui_data, translations)

end

return recipe_page