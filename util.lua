local util = {}

-- local coreutil = require("__core__.lualib.util")

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
--- @return string path
function util.get_type(prototype)
  return util.prototype_type[prototype.object_name]
end

--- @param group PrototypeEntry
--- @param player_crafting boolean?
function util.group_is_hidden(group, player_crafting)
  local key, prototype = next(group)
  if key == "recipe" then
    local hidden = prototype.hidden
    if not hidden and player_crafting then
      return prototype.hidden_from_player_crafting
    end
  elseif key == "item" or key == "entity" then
    return prototype.has_flag("hidden")
  elseif key == "fluid" then
    return prototype.hidden
  end
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
  ["LuaEntityPrototype"] = "entity",
  ["LuaFluidPrototype"] = "fluid",
  ["LuaItemPrototype"] = "item",
  ["LuaRecipePrototype"] = "recipe",
  ["LuaTechnologyPrototype"] = "technology",
}

return util
