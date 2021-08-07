local util = require("scripts.util")

return function(recipe_book, dictionaries)
  for name, prototype in pairs(global.prototypes.fuel_category) do
    recipe_book.fuel_category[name] = {
      class = "fuel_category",
      enabled_at_start = true,
      fluids = util.unique_obj_array{},
      items = util.unique_obj_array{},
      prototype_name = name,
    }
    dictionaries.fuel_category:add(name, prototype.localised_name)
    dictionaries.fuel_category_description:add(name, prototype.localised_description)
  end
end

