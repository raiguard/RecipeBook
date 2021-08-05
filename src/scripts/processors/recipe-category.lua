local util = require("scripts.util")

return function(recipe_book, dictionaries)
  for name, prototype in pairs(global.prototypes.recipe_category) do
    recipe_book.recipe_category[name] = {
      class = "recipe_category",
      enabled_at_start = true,
      fluids = util.unique_obj_array{},
      items = util.unique_obj_array{},
      prototype_name = name,
      recipes = util.unique_obj_array{},
    }
    dictionaries.recipe_category:add(name, prototype.localised_name)
    dictionaries.recipe_category_description:add(name, prototype.localised_description)
  end
end
