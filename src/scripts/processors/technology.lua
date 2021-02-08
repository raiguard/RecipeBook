local util = require("scripts.util")

local fluid_proc = require("scripts.processors.fluid")

return function(recipe_book, strings)

  for name, prototype in pairs(game.technology_prototypes) do
    if prototype.enabled then
      local associated_recipes = {}

      for _, modifier in ipairs(prototype.effects) do
        if modifier.type == "unlock-recipe" then
          local recipe_data = recipe_book.recipe[modifier.recipe]
          recipe_data.unlocked_by[#recipe_data.unlocked_by + 1] = {class = "technology", name = name}
          associated_recipes[#associated_recipes + 1] = modifier.recipe
          for _, product in pairs(recipe_data.products) do
            local product_name = product.name
            local product_data = recipe_book[product.class][product_name]

            if product_data.temperature_data then
              fluid_proc.add_to_matching_temperatures(
                recipe_book,
                strings,
                recipe_book.fluid[product_data.prototype_name],
                product_data.temperature_data,
                {unlocked_by = {class = "technology", name = name}}
              )
            else
              product_data.unlocked_by[#product_data.unlocked_by + 1] = {class = "technology", name = name}
            end

          end
        end
      end

      recipe_book.technology[name] = {
        associated_recipes = associated_recipes,
        class = "technology",
        hidden = prototype.hidden,
        prototype_name = name,
        researched_forces = {}
      }
      util.add_string(strings, {
        dictionary = "technology",
        internal = prototype.name,
        localised = prototype.localised_name
      })
      util.add_string(strings, {
        dictionary = "technology_description",
        internal = name,
        localised = prototype.localised_description
      })
    end
  end
end
