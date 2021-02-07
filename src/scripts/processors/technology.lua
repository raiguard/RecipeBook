local util = require("scripts.util")

local fluid_proc = require("scripts.processors.fluid")

return function(recipe_book, strings)
  for name, prototype in pairs(game.technology_prototypes) do
    if prototype.enabled then
      for _, modifier in ipairs(prototype.effects) do
        if modifier.type == "unlock-recipe" then
          local recipe_data = recipe_book.recipe[modifier.recipe]
          if recipe_data then
            recipe_data.unlocked_by[#recipe_data.unlocked_by + 1] = {class = "technology", name = name}

            for _, product in pairs(recipe_data.products) do
              local product_name = product.name
              local product_data = recipe_book[product.class][product_name]
              if product_data then
                if product.class == "fluid" then
                  local default_temperature = product_data.default_temperature
                  local temperature_string = product.temperature_string
                  if temperature_string and temperature_string ~= default_temperature then
                    -- add to default temperature
                    fluid_proc.add_or_update_temperature(
                      product_data,
                      "unlocked_by",
                      default_temperature,
                      {class = "technology", name = name}
                    )
                  end
                  fluid_proc.add_or_update_temperature(
                    product_data,
                    "unlocked_by",
                    temperature_string or default_temperature,
                    {class = "technology", name = name}
                  )
                else
                  product_data.unlocked_by[#product_data.unlocked_by + 1] = {class = "technology", name = name}
                end
              end
            end
          end
        end
      end

      recipe_book.technology[name] = {
        class = "technology",
        hidden = prototype.hidden,
        prototype_name = name,
        researched_forces = {},
        type = "technology"
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
