local format = require("__flib__/format")
local math = require("__flib__/math")

local util = {}

util.crafting_machine = {
  ["assembling-machine"] = true,
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
  return format.number(math.round(num, 0.01))
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
  LuaFluidPrototype = "fluid",
  LuaItemPrototype = "item",
  LuaRecipePrototype = "recipe",
  LuaTechnologyPrototype = "technology",
}

util.type_locale = {
  entity = { "description.rb-entity" },
  fluid = { "gui-train.fluid" },
  item = { "description.rb-item" },
  recipe = { "description.recipe" },
}

return util
