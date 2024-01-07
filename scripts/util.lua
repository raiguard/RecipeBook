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
  return game.get_filtered_entity_prototypes({
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
  return game[obj.type .. "_prototypes"][obj.name]
end

--- @param prototype GenericPrototype
--- @return boolean
function util.is_hidden(prototype)
  local type = prototype.object_name
  if type == "LuaFluidPrototype" then
    return prototype.hidden
  elseif type == "LuaItemPrototype" then
    return prototype.has_flag("hidden")
  elseif type == "LuaRecipePrototype" then
    return prototype.hidden
  elseif type == "LuaTechnologyPrototype" then
    return prototype.hidden
  end
  return false
end

util.object_name_to_type = {
  LuaEntityPrototype = "entity",
  LuaEquipmentPrototype = "equipment",
  LuaFluidPrototype = "fluid",
  LuaItemPrototype = "item",
  LuaRecipePrototype = "recipe",
  LuaTechnologyPrototype = "technology",
}

return util
