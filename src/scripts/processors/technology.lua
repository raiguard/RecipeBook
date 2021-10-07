local math = require("__flib__.math")

local constants = require("constants")

local util = require("scripts.util")

return function(recipe_book, dictionaries, metadata)
  for name, prototype in pairs(global.prototypes.technology) do
    local unlocks_fluids = util.unique_obj_array()
    local unlocks_items = util.unique_obj_array()
    local unlocks_machines = util.unique_obj_array()
    local unlocks_recipes = util.unique_obj_array()
    local research_ingredients_per_unit = {}

    -- Research units and ingredients per unit
    for _, ingredient in ipairs(prototype.research_unit_ingredients) do
      research_ingredients_per_unit[#research_ingredients_per_unit + 1] = {
        class = ingredient.type,
        name = ingredient.name,
        amount_ident = util.build_amount_ident{amount = ingredient.amount}
      }
    end

    local research_unit_count
    local formula = prototype.research_unit_count_formula
    if not formula then
      research_unit_count = prototype.research_unit_count
    end

    -- Unlocks recipes, materials, machines
    for _, modifier in ipairs(prototype.effects) do
      if modifier.type == "unlock-recipe" then
        local recipe_data = recipe_book.recipe[modifier.recipe]

        -- Check if the category should be ignored for recipe availability
        local disabled = (recipe_data == nil) or constants.disabled_categories.recipe_category[recipe_data.recipe_category.name]
        if not disabled then
          recipe_data.unlocked_by[#recipe_data.unlocked_by + 1] = {class = "technology", name = name}
          recipe_data.researched_forces = {}
          unlocks_recipes[#unlocks_recipes + 1] = {class = "recipe", name = modifier.recipe}
          for _, product in pairs(recipe_data.products) do
            local product_name = product.name
            local product_data = recipe_book[product.class][product_name]
            local product_ident = {class = product_data.class, name = product_data.prototype_name}

            -- For "empty X barrel" recipes, do not unlock the fluid with the recipe
            -- This is to avoid fluids getting "unlocked" when they are in reality still 100 hours away
            local is_empty_barrel_recipe = string.find(modifier.recipe, "^empty%-.+%-barrel$")

            if product_data.class ~= "fluid" or not is_empty_barrel_recipe then
              product_data.researched_forces = {}
              product_data.unlocked_by[#product_data.unlocked_by + 1] = {class = "technology", name = name}
            end

            -- Materials
            if product_data.class == "item" then
              unlocks_items[#unlocks_items + 1] = product_ident
            elseif product_data.class == "fluid" and not is_empty_barrel_recipe then
              unlocks_fluids[#unlocks_fluids + 1] = product_ident
            end

            -- Machines
            local place_result = metadata.place_results[product_name]
            if place_result and constants.machine_classes_lookup[place_result.class] then
              local machine_data = recipe_book[place_result.class][place_result.name]
              if machine_data then
                machine_data.researched_forces = {}
                machine_data.unlocked_by[#machine_data.unlocked_by + 1] = {class = "technology", name = name}
                unlocks_machines[#unlocks_machines + 1] = place_result
              end
            end
          end
        end
      end
    end

    local level = prototype.level
    local max_level = prototype.max_level

    recipe_book.technology[name] = {
      class = "technology",
      hidden = prototype.hidden,
      max_level = max_level,
      min_level = level,
      prerequisite_of = {},
      prerequisites = {},
      prototype_name = name,
      research_ingredients_per_unit = research_ingredients_per_unit,
      research_unit_count = research_unit_count,
      research_unit_count_formula = formula,
      research_unit_energy = prototype.research_unit_energy / 60,
      researched_forces = {},
      unlocks_fluids = unlocks_fluids,
      unlocks_items = unlocks_items,
      unlocks_machines = unlocks_machines,
      unlocks_recipes = unlocks_recipes,
      upgrade = prototype.upgrade
    }

    -- Assemble name
    local localised_name
    if level ~= max_level then
      localised_name = {
        "",
        prototype.localised_name,
        " ("..level.."-"..(max_level == math.max_uint and "∞" or max_level)..")"
      }
    else
      localised_name = prototype.localised_name
    end

    dictionaries.technology:add(prototype.name, localised_name)
    dictionaries.technology_description:add(name, prototype.localised_description)
  end

  -- Generate prerequisites and prerequisite_of
  for name, technology in pairs(recipe_book.technology) do
    local prototype = global.prototypes.technology[name]

    if prototype.prerequisites then
      for prerequisite_name in pairs(prototype.prerequisites) do
        technology.prerequisites[#technology.prerequisites + 1] = {class = "technology", name = prerequisite_name}
        local prerequisite_data = recipe_book.technology[prerequisite_name]
        prerequisite_data.prerequisite_of[#prerequisite_data.prerequisite_of + 1] = {class = "technology", name = name}
      end
    end
  end
end
