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

util.prototype_type = {
  LuaEntityPrototype = "entity",
  LuaFluidPrototype = "fluid",
  LuaItemPrototype = "item",
  LuaRecipePrototype = "recipe",
  LuaTechnologyPrototype = "technology",
}

return util
