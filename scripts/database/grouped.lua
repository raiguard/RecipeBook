local util = require("scripts.util")

--- @class Grouped
local grouped = {
  --- @type table<SpritePath, LuaEntityPrototype>
  entity = {},
  --- @type table<SpritePath, LuaEquipmentPrototype>
  equipment = {},
  --- @type table<SpritePath, LuaFluidPrototype|LuaItemPrototype>
  material = {},
  --- @type table<SpritePath, LuaRecipePrototype>
  recipe = {},
  --- @type table<SpritePath, LuaTilePrototype>
  tile = {},
}

--- @param recipe LuaRecipePrototype
--- @return (LuaFluidPrototype|LuaItemPrototype)?
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

for entity_name, entity in pairs(prototypes.entity) do
  local item = get_simple_item_to_place_this(entity)
  if item and item.hidden_in_factoriopedia == entity.hidden_in_factoriopedia then
    grouped.material[util.get_path(entity)] = item
    grouped.entity[util.get_path(item)] = entity
    goto continue
  end
  local mineable = entity.mineable_properties
  if mineable then
    local products = mineable.products
    if products and #products == 1 then
      local product = products[1]
      if product.type == "item" and product.name == entity_name and product.amount then
        grouped.material[util.get_path(entity)] = prototypes.item[product.name]
        grouped.entity["item/" .. product.name] = entity
      end
    end
  end
  ::continue::
end
for _, recipe in pairs(prototypes.recipe) do
  local material = get_simple_product(recipe)
  if material and material.hidden_in_factoriopedia == recipe.hidden_in_factoriopedia then
    grouped.material[util.get_path(recipe)] = material
    grouped.recipe[util.get_path(material)] = recipe
  end
end
for _, tile in pairs(prototypes.tile) do
  local items_to_place_this = tile.items_to_place_this
  if items_to_place_this then
    for _, item in pairs(items_to_place_this) do
      local item_prototype = prototypes.item[item.name]
      if tile.hidden_in_factoriopedia == item_prototype.hidden_in_factoriopedia then
        grouped.material[util.get_path(tile)] = item_prototype
        grouped.tile[util.get_path(item_prototype)] = tile
        break
      end
    end
  end
end
-- TODO: Equipment
-- Space location
-- Asteroid chunk
-- Ammo
-- Space Connection
-- Virtual signal
-- Surface

return grouped
