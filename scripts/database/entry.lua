local flib_table = require("__flib__.table")

local entry_id = require("scripts.database.entry-id")
local util = require("scripts.util")

--- @alias GenericPrototype LuaEquipmentPrototype|LuaEntityPrototype|LuaFluidPrototype|LuaItemPrototype|LuaRecipePrototype|LuaTechnologyPrototype

--- @class Entry
--- @field private database Database
--- @field private base GenericPrototype
--- @field private recipe LuaRecipePrototype?
--- @field private item LuaItemPrototype?
--- @field private fluid LuaFluidPrototype?
--- @field private equipment LuaEquipmentPrototype?
--- @field private entity LuaEntityPrototype?
--- @field private researched table<uint, boolean>?
local entry = {}
local mt = { __index = entry }
script.register_metatable("entry", mt)

--- @param prototype GenericPrototype
--- @param database Database
function entry.new(prototype, database)
  --- @type Entry
  local self = {
    database = database,
    base = prototype,
  }
  setmetatable(self, mt)

  self:add(prototype)

  return self
end

--- @param prototype GenericPrototype
function entry:add(prototype)
  self[util.object_name_to_type[prototype.object_name]] = prototype
end

--- @return string
function entry:get_name()
  return self.base.name
end

--- @return LocalisedString
function entry:get_localised_name()
  return self.base.localised_name
end

--- @return SpritePath
function entry:get_path()
  local base = self.base
  return util.object_name_to_type[base.object_name] .. "/" .. base.name
end

--- @return boolean
function entry:is_hidden()
  return util.is_hidden(self.base)
end

--- @param force_index uint
--- @return boolean
function entry:is_researched(force_index)
  local researched = self.researched
  return researched and researched[force_index] or false
end

--- @return LuaGroup
function entry:get_group()
  if self.base.object_name == "LuaEquipmentPrototype" then
    return game.item_group_prototypes["combat"]
  end
  return self.base.group
end

--- @return LuaGroup
function entry:get_subgroup()
  if self.base.object_name == "LuaEquipmentPrototype" then
    return game.item_subgroup_prototypes["rb-uncategorized-equipment"]
  end
  return self.base.subgroup
end

--- @return string
function entry:get_order()
  return self.base.order
end

--- @return string
function entry:get_type()
  return util.object_name_to_type[self.base.object_name]
end

-- PROPERTIES

--- @return double?
function entry:get_crafting_time()
  if not self.recipe then
    return
  end

  return self.recipe.energy
end

--- @return EntryID[]?
function entry:get_ingredients()
  if not self.recipe then
    return
  end

  return flib_table.map(self.recipe.ingredients, function(ingredient)
    return entry_id.new(ingredient, self.database)
  end)
end

--- @return EntryID[]?
function entry:get_products()
  if not self.recipe then
    return
  end

  return flib_table.map(self.recipe.products, function(product)
    return entry_id.new(product, self.database)
  end)
end

--- @return EntryID[]?
function entry:get_made_in()
  if not self.recipe then
    return
  end

  --- @type EntryID[]
  local output = {}

  --- @diagnostic disable-next-line unused-fields
  for _, character in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "character" } })) do
    if character.crafting_categories[self.recipe.category] then
      output[#output + 1] = entry_id.new({
        type = "entity",
        name = character.name,
        amount = self.recipe.energy,
      }, self.database)
    end
  end

  local item_ingredients = flib_table.reduce(self.recipe.ingredients, function(accumulator, ingredient)
    return accumulator + (ingredient.type == "item" and 1 or 0)
  end, 0) --[[@as integer]]

  for _, crafter in
    pairs(game.get_filtered_entity_prototypes({
      --- @diagnostic disable-next-line unused-fields
      { filter = "crafting-category", crafting_category = self.recipe.category },
    }))
  do
    local ingredient_count = crafter.ingredient_count
    local crafter_entry = self.database:get("entity/" .. crafter.name)
    if crafter_entry and (ingredient_count == 0 or ingredient_count >= item_ingredients) then
      output[#output + 1] = entry_id.new({
        type = "entity",
        name = crafter.name,
        amount = self.recipe.energy / crafter.crafting_speed,
      }, self.database)
    end
  end

  return output
end

return entry
