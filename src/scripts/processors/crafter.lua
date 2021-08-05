local util = require("scripts.util")

return function(recipe_book, dictionaries, metadata)
  -- Characters as crafters
  for name, prototype in pairs(global.prototypes.character) do
    local ingredient_limit = prototype.ingredient_count
    if ingredient_limit == 255 then
      ingredient_limit = nil
    end
    recipe_book.crafter[name] = {
      blueprintable = false,
      class = "crafter",
      compatible_recipes = {},
      crafting_speed = 1,
      hidden = false,
      ingredient_limit = ingredient_limit,
      placeable_by = util.process_placeable_by(prototype),
      prototype_name = name,
      recipe_categories = util.convert_categories(prototype.crafting_categories, "recipe_category"),
      recipe_categories_lookup = prototype.crafting_categories,
      unlocked_by = {}
    }
    dictionaries.crafter:add(name, prototype.localised_name)
    dictionaries.crafter_description:add(name, prototype.localised_description)
  end

  -- Actual crafters
  metadata.fixed_recipes = {}
  local rocket_silo_categories = {}
  for name, prototype in pairs(global.prototypes.crafter) do
    -- Fixed recipe
    local fixed_recipe
    if prototype.fixed_recipe then
      metadata.fixed_recipes[prototype.fixed_recipe] = true
      fixed_recipe = {class = "recipe", name = prototype.fixed_recipe}
    end
    -- Rocket silo categories
    if prototype.rocket_parts_required then
      for category in pairs(prototype.crafting_categories) do
        rocket_silo_categories[category] = true
      end
    end

    local ingredient_limit = prototype.ingredient_count
    if ingredient_limit == 255 then
      ingredient_limit = nil
    end

    local is_hidden = prototype.has_flag("hidden")
    recipe_book.crafter[name] = {
      blueprintable = not is_hidden and not prototype.has_flag("not-blueprintable"),
      class = "crafter",
      compatible_recipes = {},
      crafting_speed = prototype.crafting_speed,
      fixed_recipe = fixed_recipe,
      hidden = is_hidden,
      ingredient_limit = ingredient_limit,
      placeable_by = util.process_placeable_by(prototype),
      prototype_name = name,
      recipe_categories = util.convert_categories(prototype.crafting_categories, "recipe_category"),
      recipe_categories_lookup = prototype.crafting_categories,
      rocket_parts_required = prototype.rocket_parts_required,
      unlocked_by = {}
    }
    dictionaries.crafter:add(name, prototype.localised_name)
    dictionaries.crafter_description:add(name, prototype.localised_description)
  end

  local processed_rocket_silo_categories = {}
  for category in pairs(rocket_silo_categories) do
    processed_rocket_silo_categories[#processed_rocket_silo_categories + 1] = category
  end
  metadata.rocket_silo_categories = processed_rocket_silo_categories
end
