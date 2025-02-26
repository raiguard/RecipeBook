-- local util = require("scripts.util")

--- @class DatabaseID
--- @field type string
--- @field name string

--- @class Collectors
local collectors = {}

--- Collects recipe products.
--- @param prototype GenericPrototype
--- @return DatabaseID[]
function collectors.products(prototype)
  local output = {}

  if prototype.object_name ~= "LuaRecipePrototype" then
    return output
  end

  for _, product in pairs(prototype.products) do
    if product.type ~= "research-progress" then
      output[#output + 1] = product
    end
  end

  return output
end

--- Collects recipes that this technology unlocks.
--- @param prototype GenericPrototype
--- @return GenericPrototype[]
function collectors.unlock_recipes(prototype)
  local output = {}

  if prototype.object_name ~= "LuaTechnologyPrototype" then
    return output
  end

  for _, effect in pairs(prototype.effects) do
    if effect.type == "unlock-recipe" then
      output[#output + 1]
    end
  end
end

return collectors
