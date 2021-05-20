local util = require("scripts.util")

return function(recipe_book, strings)
  for name, prototype in pairs(game.item_group_prototypes) do
    recipe_book.group[name] = {
      class = "group",
      enabled_at_start = true,
      fluids = {},
      items = {},
      prototype_name = name,
      recipes = {},
    }
    util.add_string(strings, {dictionary = "group", internal = name, localised = prototype.localised_name})
    -- NOTE: Groups do not have descriptions
  end
end
