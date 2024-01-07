local util = require("scripts.util")

--- @alias GenericObject Ingredient|Product|CustomObject
--- @alias GenericPrototype LuaEquipmentPrototype|LuaEntityPrototype|LuaFluidPrototype|LuaItemPrototype|LuaRecipePrototype|LuaTechnologyPrototype

--- @class DatabaseEntry
--- @field base GenericPrototype
--- @field recipe LuaRecipePrototype?
--- @field item LuaItemPrototype?
--- @field fluid LuaFluidPrototype?
--- @field equipment LuaEquipmentPrototype?
--- @field entity LuaEntityPrototype?
--- @field researched table<uint, boolean>?
local entry = {}
local mt = { __index = entry }
script.register_metatable("entry", mt)

--- @param prototype GenericPrototype
function entry.new(prototype)
  --- @type DatabaseEntry
  local self = {
    base = prototype,
  }
  setmetatable(self, mt)

  self:add(prototype)

  return self
end

--- Add the given prototype to this entry.
--- @param prototype GenericPrototype
function entry:add(prototype)
  self[util.object_name_to_type[prototype.object_name]] = prototype
end

--- Return the internal name of the base prototype.
--- @return string
function entry:get_name()
  return self.base.name
end

--- Return the ID of the base prototype.
--- @return ElemID
function entry:get_id()
  return { type = self:get_type(), name = self:get_name() }
end

--- Return the sprite path of the base prototype.
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

--- Return the item group of the base prototype.
--- @return LuaGroup
function entry:get_group()
  if self.base.object_name == "LuaEquipmentPrototype" then
    return game.item_group_prototypes["combat"]
  end
  return self.base.group
end

--- Return the item subgroup of the base prototype.
--- @return LuaGroup
function entry:get_subgroup()
  if self.base.object_name == "LuaEquipmentPrototype" then
    return game.item_subgroup_prototypes["rb-uncategorized-equipment"]
  end
  return self.base.subgroup
end

--- Return the prototype order of the base prototype.
--- @return string
function entry:get_order()
  return self.base.order
end

--- Return the type of the base prototype.
--- @return string
function entry:get_type()
  return util.object_name_to_type[self.base.object_name]
end

return entry
