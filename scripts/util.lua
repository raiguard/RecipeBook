local flib_format = require("__flib__/format")
local flib_math = require("__flib__/math")

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

--- @param prototype GenericPrototype
--- @return string group
--- @return string subgroup
function util.get_group(prototype)
  if prototype.object_name == "LuaEquipmentPrototype" then
    return "combat", "rb-uncategorized-equipment"
  end
  return prototype.group.name, prototype.subgroup.name
end

--- @param prototype GenericPrototype
--- @return string path
--- @return string type
function util.get_path(prototype)
  local type = util.prototype_type[prototype.object_name]
  return type .. "/" .. prototype.name, type
end

--- @param obj GenericObject
--- @return GenericPrototype
function util.get_prototype(obj)
  return game[obj.type .. "_prototypes"][obj.name]
end

--- @param prototype GenericPrototype
--- @return boolean
function util.is_hidden(prototype)
  if prototype.object_name == "LuaFluidPrototype" then
    return prototype.hidden
  elseif prototype.object_name == "LuaItemPrototype" then
    return prototype.has_flag("hidden")
  elseif prototype.object_name == "LuaRecipePrototype" then
    return prototype.hidden
  elseif prototype.object_name == "LuaTechnologyPrototype" then
    return prototype.hidden
  end
  return false
end

--- @param entry PrototypeEntry
--- @param force_index uint
--- @return boolean
function util.is_unresearched(entry, force_index)
  local researched = entry.researched or {}
  return not researched[force_index]
end

util.prototype_type = {
  LuaEntityPrototype = "entity",
  LuaEquipmentPrototype = "equipment",
  LuaFluidPrototype = "fluid",
  LuaItemPrototype = "item",
  LuaRecipePrototype = "recipe",
  LuaTechnologyPrototype = "technology",
}

return util
