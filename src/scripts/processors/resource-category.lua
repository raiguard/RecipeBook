local util = require("scripts.util")

return function(recipe_book, dictionaries)
  for name, prototype in pairs(global.prototypes.resource_category) do
    recipe_book.resource_category[name] = {
      class = "resource_category",
      enabled_at_start = true,
      mining_drills = {},
      prototype_name = name,
      resources = util.unique_obj_array{},
    }
    dictionaries.resource_category:add(name, prototype.localised_name)
    dictionaries.resource_category_description:add(name, prototype.localised_description)
  end
end
