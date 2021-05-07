local util = require("scripts.util")

return function(recipe_book, strings, metadata)
  -- characters as crafters
  for name, prototype in pairs(game.get_filtered_entity_prototypes{{filter = "type", type = "character"}}) do
    recipe_book.crafter[name] = {
      blueprintable = false,
      categories = util.convert_and_sort(prototype.crafting_categories),
      class = "crafter",
      compatible_recipes = {},
      crafting_speed = 1,
      hidden = false,
      ingredient_limit = prototype.ingredient_count,
      placeable_by = {},
      prototype_name = name,
      unlocked_by = {}
    }
    util.add_string(strings, {dictionary = "crafter", internal = name, localised = prototype.localised_name})
    util.add_string(strings, {
      dictionary = "crafter_description",
      internal = name,
      localised = prototype.localised_description
    })
  end

  -- actual crafters
  local crafter_prototypes = game.get_filtered_entity_prototypes{
    {filter = "type", type = "assembling-machine"},
    {filter = "type", type = "furnace"},
    {filter = "type", type = "rocket-silo"}
  }
  metadata.fixed_recipes = {}
  metadata.rocket_silo_categories = {}
  for name, prototype in pairs(crafter_prototypes) do
    -- fixed recipe
    if prototype.fixed_recipe then
      metadata.fixed_recipes[prototype.fixed_recipe] = true
    end
    -- rocket silo categories
    if prototype.rocket_parts_required then
      for category in pairs(prototype.crafting_categories) do
        metadata.rocket_silo_categories[category] = true
      end
    end

    local is_hidden = prototype.has_flag("hidden")
    recipe_book.crafter[name] = {
      blueprintable = not is_hidden and not prototype.has_flag("not-blueprintable"),
      categories = util.convert_and_sort(prototype.crafting_categories),
      class = "crafter",
      compatible_recipes = {},
      crafting_speed = prototype.crafting_speed,
      fixed_recipe = prototype.fixed_recipe,
      hidden = is_hidden,
      placeable_by = {},
      prototype_name = name,
      rocket_parts_required = prototype.rocket_parts_required,
      unlocked_by = {}
    }
    util.add_string(strings, {dictionary = "crafter", internal = name, localised = prototype.localised_name})
    util.add_string(strings, {
      dictionary = "crafter_description",
      internal = name,
      localised = prototype.localised_description
    })
  end
end
