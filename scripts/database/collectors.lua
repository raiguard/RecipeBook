local flib_table = require("__flib__.table")

local util = require("scripts.util")

--- @alias DatabaseIDType
--- | "entity"
--- | "equipment"
--- | "fluid"
--- | "item"
--- | "recipe"
--- | "technology"
--- | "tile"

--- @class DatabaseID
--- @field type DatabaseIDType
--- @field name string
--- @field amount number?
--- @field amount_min number?
--- @field amount_max number?
--- @field probability number?
--- @field temperature number?
--- @field minimum_temperature number?
--- @field maximum_temperature number?

--- @class Collectors
local collectors = {}

--- Collects recipe ingredients.
--- @param prototype LuaRecipePrototype
--- @return DatabaseID[]
function collectors.ingredients(prototype)
  local output = util.unique_id_array()

  for _, ingredient in pairs(prototype.ingredients) do
    output[#output + 1] = {
      type = ingredient.type,
      name = ingredient.name,
      amount = ingredient.amount,
      minimum_temperature = ingredient.minimum_temperature,
      maximum_temperature = ingredient.maximum_temperature,
    }
  end

  return output
end

--- Collects recipe products.
--- @param prototype LuaRecipePrototype
--- @return DatabaseID[]
function collectors.products(prototype)
  local output = util.unique_id_array()

  for _, product in pairs(prototype.products) do
    if product.type ~= "research-progress" then
      output[#output + 1] = {
        type = product.type,
        name = product.name,
        amount = product.amount,
        amount_min = product.amount_min,
        amount_max = product.amount_max,
        temperature = product.temperature,
      }
    end
  end

  return output
end

--- Collects machines that a recipe can be made in.
--- @param prototype LuaRecipePrototype
--- @return DatabaseID[]
function collectors.made_in(prototype)
  local output = util.unique_id_array()

  --- @diagnostic disable-next-line unused-fields
  for _, character in pairs(prototypes.get_entity_filtered({ { filter = "type", type = "character" } })) do
    if character.crafting_categories[prototype.category] then
      output[#output + 1] = {
        type = "entity",
        name = character.name,
        amount = prototype.energy,
      }
    end
  end

  local item_ingredients = flib_table.reduce(prototype.ingredients, function(accumulator, ingredient)
    return accumulator + (ingredient.type == "item" and 1 or 0)
  end, 0) --[[@as integer]]

  for _, crafter in
    pairs(prototypes.get_entity_filtered({
      --- @diagnostic disable-next-line unused-fields
      { filter = "crafting-category", crafting_category = prototype.category },
    }))
  do
    local ingredient_count = crafter.ingredient_count
    if ingredient_count == 0 or ingredient_count >= item_ingredients then
      output[#output + 1] = {
        type = "entity",
        name = crafter.name,
        amount = prototype.energy / crafter.get_crafting_speed(), -- TODO: Quality
      }
    end
  end

  return output
end

return collectors
