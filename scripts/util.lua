local flib_format = require("__flib__.format")
local flib_math = require("__flib__.math")

--- @class Util
local util = {}

util.crafting_machine = {
  ["assembling-machine"] = true,
  ["character"] = true,
  ["furnace"] = true,
  ["rocket-silo"] = true,
}

--- @param player LuaPlayer
--- @param text LocalisedString
function util.flying_text(player, text)
  player.create_local_flying_text({
    text = text,
    create_at_cursor = true,
  })
  player.play_sound({ path = "utility/cannot_build" })
end

--- @param num number
--- @return string
function util.format_number(num)
  return flib_format.number(flib_math.round(num, 0.01))
end

function util.get_natural_entities()
  return prototypes.get_entity_filtered({
    --- @diagnostic disable-next-line unused-fields
    { filter = "type", type = "resource" },
    --- @diagnostic disable-next-line unused-fields
    { filter = "type", type = "fish" },
    --- @diagnostic disable-next-line unused-fields
    { filter = "type", type = "tree" },
    --- @diagnostic disable-next-line unused-fields
    { filter = "type", type = "simple-entity" },
  })
end

--- @param prototype GenericPrototype
--- @return string path
--- @return string type
function util.get_path(prototype)
  local type = util.object_name_to_type[prototype.object_name]
  return type .. "/" .. prototype.name, type
end

--- @param obj Ingredient|Product
--- @return GenericPrototype
function util.get_prototype(obj)
  return prototypes[obj.type][obj.name]
end

util.object_name_to_type = {
  LuaEntity = "entity",
  LuaEntityPrototype = "entity",
  LuaEquipmentPrototype = "equipment",
  LuaFluidPrototype = "fluid",
  LuaItemPrototype = "item",
  LuaRecipePrototype = "recipe",
  LuaRecipe = "recipe",
  LuaTechnologyPrototype = "technology",
  LuaTechnology = "technology",
  LuaTilePrototype = "tile",
}

--- @return EntryID[]
function util.unique_id_array()
  local hash = {}

  return setmetatable({}, {
    --- @param self EntryID[]
    --- @param index integer
    --- @param value EntryID
    __newindex = function(self, index, value)
      if not value then
        return
      end
      -- Use the base path to work with alternatives, etc.
      local key = value:get_entry():get_path()
      if hash[key] then
        return
      end
      hash[key] = true
      rawset(self, index, value)
    end,
  })
end

--- @param prototype GenericPrototype
--- @return LuaGroup
function util.get_group(prototype)
  if prototype.object_name == "LuaEquipmentPrototype" then
    return prototypes.item_group["combat"]
  end
  return prototype.group
end

--- @param prototype GenericPrototype
--- @return LuaGroup
function util.get_subgroup(prototype)
  if prototype.object_name == "LuaEquipmentPrototype" then
    return prototypes.item_subgroup["rb-uncategorized-equipment"]
  end
  return prototype.subgroup
end

return util
