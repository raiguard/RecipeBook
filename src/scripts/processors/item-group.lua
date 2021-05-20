local util = require("scripts.util")

return function(recipe_book, strings)
  for name, prototype in pairs(game.item_group_prototypes) do
    recipe_book.item_group[name] = {
      class = "item_group",
      enabled_at_start = true,
      prototype_name = name,
      recipes = {},
    }
    util.add_string(strings, {dictionary = "item_group", internal = name, localised = prototype.localised_name})
    -- NOTE: Item groups do not have descriptions
  end
end
