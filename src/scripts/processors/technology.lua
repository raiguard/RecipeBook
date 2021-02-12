local util = require("scripts.util")

local fluid_proc = require("scripts.processors.fluid")

return function(recipe_book, strings, metadata)
  for name, prototype in pairs(game.technology_prototypes) do
    if prototype.enabled then
      local associated_recipes = {}
      local research_ingredients_per_unit = {}
      local research_unit_amount

      -- research units and ingredients per unit
      for _, ingredient in ipairs(prototype.research_unit_ingredients) do
        research_ingredients_per_unit[#research_ingredients_per_unit + 1] = {
          class = ingredient.type,
          name = ingredient.name,
          amount_string = ingredient.amount.."x"
        }
      end

      if not prototype.research_unit_count_formula then
        research_unit_amount = prototype.research_unit_count
      else
        research_unit_amount = game.evaluate_expression(
          prototype.research_unit_count_formula,
          {L = prototype.level, l = prototype.level}
        )
      end

      -- unlocks recipes, materials, crafter / lab
      for _, modifier in ipairs(prototype.effects) do
        if modifier.type == "unlock-recipe" then
          local recipe_data = recipe_book.recipe[modifier.recipe]
          recipe_data.unlocked_by[#recipe_data.unlocked_by + 1] = {class = "technology", name = name}
          recipe_data.researched_forces = {}
          associated_recipes[#associated_recipes + 1] = {class = "recipe", name = modifier.recipe}
          for _, product in pairs(recipe_data.products) do
            local product_name = product.name
            local product_data = recipe_book[product.class][product_name]

            product_data.researched_forces = {}

            -- material
            if product_data.temperature_data then
              local base_fluid_data = recipe_book.fluid[product_data.prototype_name]
              base_fluid_data.unlocked_by[#base_fluid_data.unlocked_by + 1] = {class = "technology", name = name}
              fluid_proc.add_to_matching_temperatures(
                recipe_book,
                strings,
                metadata,
                base_fluid_data,
                product_data.temperature_data,
                {unlocked_by = {class = "technology", name = name}}
              )
            else
              product_data.unlocked_by[#product_data.unlocked_by + 1] = {class = "technology", name = name}
            end

            -- crafter / lab
            local place_result = product_data.place_result
            if place_result then
              local machine_data = recipe_book.crafter[place_result] or recipe_book.lab[place_result]
              if machine_data then
                machine_data.researched_forces = {}
                machine_data.unlocked_by[#machine_data.unlocked_by + 1] = {class = "technology", name = name}

                local subtable_name = machine_data.class == "crafter" and "associated_crafters" or "associated_labs"
                recipe_data[subtable_name][#recipe_data[subtable_name] + 1] = place_result
              end
            end
          end
        end
      end

      recipe_book.technology[name] = {
        associated_recipes = associated_recipes,
        class = "technology",
        hidden = prototype.hidden,
        prerequisite_of = {},
        prerequisites = {},
        prototype_name = name,
        research_unit_energy = prototype.research_unit_energy / 60,
        research_unit_amount = research_unit_amount,
        research_ingredients_per_unit= research_ingredients_per_unit,
        researched_forces = {},
        upgrade = prototype.upgrade
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

  -- generate prerequisites and prerequisite_of
  for name, technology in pairs(recipe_book.technology) do
    local prototype = game.technology_prototypes[name]

    if prototype.prerequisites then
      for prerequisite_name, _ in pairs(prototype.prerequisites) do
        technology.prerequisites[#technology.prerequisites + 1] = {class = "technology", name = prerequisite_name}
        local prerequisite_data = recipe_book.technology[prerequisite_name]
        prerequisite_data.prerequisite_of[#prerequisite_data.prerequisite_of + 1] = {class = "technology", name = name}
      end
    end
  end
end
