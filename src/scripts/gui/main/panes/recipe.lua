local recipe_pane = {}

local gui = require("__flib__.gui")

function recipe_pane.update(parent, gui_data, translations)

end

function recipe_pane.build()
  return {
    gui.templates.info_list_box({"rb-gui.ingredients"}, 1, "recipe.ingredients"),
    gui.templates.info_list_box({"rb-gui.products"}, 1, "recipe.products"),
    gui.templates.info_list_box({"rb-gui.made-in"}, 1, "recipe.made_in"),
    gui.templates.info_list_box({"rb-gui.unlocked-by"}, 1, "recipe.unlocked_by")
  }
end

return recipe_pane