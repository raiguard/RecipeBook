local util = require("scripts.util")

--- @type table<SpritePath, GenericPrototype>
local grouping = {}

--- @param recipe LuaRecipePrototype
--- @return GenericPrototype?
local function get_simple_product(recipe)
  local main_product = recipe.main_product
  if main_product and main_product.name == recipe.name then
    return prototypes[main_product.type][main_product.name]
  end
  local products = recipe.products
  if #products ~= 1 then
    return
  end
  local first_product = products[1]
  if first_product.name ~= recipe.name or first_product.type == "research-progress" then
    return
  end
  return prototypes[first_product.type][first_product.name]
end

--- @param prototype LuaEntityPrototype|LuaTilePrototype
--- @return LuaItemPrototype?
local function get_simple_item_to_place_this(prototype)
  local items_to_place_this = prototype.items_to_place_this
  if not items_to_place_this then
    return
  end
  local first_item = items_to_place_this[1]
  if not first_item then
    return
  end
  if first_item.name ~= prototype.name then
    return
  end
  return prototypes.item[first_item.name]
end

for _, entity in pairs(prototypes.entity) do
  local item = get_simple_item_to_place_this(entity)
  if item and util.get_hidden(item) == util.get_hidden(entity) then
    grouping[util.get_path(entity)] = item
  end
end
for _, recipe in pairs(prototypes.recipe) do
  local material = get_simple_product(recipe)
  if material and util.get_hidden(material) == util.get_hidden(recipe) then
    grouping[util.get_path(recipe)] = material
  end
end
for _, tile in pairs(prototypes.tile) do
  local material = get_simple_item_to_place_this(tile)
  if material and util.get_hidden(material) == util.get_hidden(tile) then
    grouping[util.get_path(tile)] = material
  end
end
-- Space location
-- Asteroid chunk
-- Ammo
-- Space Connection
-- Virtual signal
-- Surface

return grouping
