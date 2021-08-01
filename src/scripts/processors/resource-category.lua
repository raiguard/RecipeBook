local util = require("scripts.util")

return function(recipe_book, strings)
  for name, prototype in pairs(global.prototypes.resource_category) do
    recipe_book.resource_category[name] = {
      class = "resource_category",
      enabled_at_start = true,
      mining_drills = {},
      prototype_name = name,
      resources = util.unique_obj_array{},
    }
    util.add_string(strings, {dictionary = "resource_category", internal = name, localised = prototype.localised_name})
    util.add_string(strings, {
      dictionary = "resource_category_description",
      internal = name,
      localised = prototype.localised_description
    })
  end
end
