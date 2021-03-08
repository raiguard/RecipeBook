local util = require("scripts.util")

local fluid_post_proc = {}

function fluid_post_proc.run(recipe_book, strings, metadata)
  for name, _ in pairs(game.fluid_prototypes) do
    local fluid_data = recipe_book.fluid[name]

    local count = 0

    local need_research = true

    for _, sub_fluid in pairs(fluid_data.temperatures) do
      count = count + 1

      if sub_fluid.enabled_at_start then
        need_research = false
      end
    end

    if need_research then
      fluid_data.researched_forces = {}
    else
      fluid_data.enabled_at_start = true
    end

    if count == 1 then
      for _, temperature in pairs(fluid_data.temperatures) do
        for _, recipe in ipairs(temperature.ingredient_in) do
          local recipe_data = recipe_book.recipe[recipe.name]
          for i, ingredient in ipairs(recipe_data.ingredients) do
            if ingredient.name == temperature.name then
              recipe_data.ingredients[i].name = name
            end
          end
        end

        for _, recipe in ipairs(temperature.product_of) do
          local recipe_data = recipe_book.recipe[recipe.name]
          for i, product in ipairs(recipe_data.products) do
            if product.name == temperature.name then
              recipe_data.products[i].name = name
            end
          end
        end

        for _, tech in ipairs(temperature.unlocked_by) do
          local tech_data = recipe_book.technology[tech.name]
          for i, fluid in ipairs(tech_data.unlocks_fluids) do
            if fluid.name == temperature.name then
              tech_data.unlocks_fluids[i].name= name
            end
          end
        end

        recipe_book.fluid[temperature.name] = nil
      end

      fluid_data.temperatures = {}
    else
      for temp_name, temperature in pairs(fluid_data.temperatures) do
          -- strings
          util.add_string(strings, {
            dictionary = "fluid",
            internal = temperature.name,
            localised = {
              "",
              metadata.localised_fluids[temperature.prototype_name],
              " (",
              {"format-degrees-c-compact", temp_name},
              ")"
            }
          })
      end

    end
  end
end

-- when calling the module directly, call fluid_proc.build
setmetatable(fluid_post_proc, { __call = function(_, ...) return fluid_post_proc.run(...) end })

return fluid_post_proc
