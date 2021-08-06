local util = require("scripts.util")

return function(recipe_book, dictionaries)
  for name, prototype in pairs(global.prototypes.module_category) do
    recipe_book.module_category[name] = {
      class = "module_category",
      enabled_at_start = true,
      modules = util.unique_obj_array{},
      prototype_name = name,
    }
    dictionaries.module_category:add(name, prototype.localised_name)
    dictionaries.module_category_description:add(name, prototype.localised_description)
  end
end

