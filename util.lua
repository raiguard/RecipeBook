local util = {}

--- @param prototype ObjectPrototype
--- @return boolean
function util.is_hidden(prototype)
  if prototype.object_name == "LuaFluidPrototype" or prototype.object_name == "LuaRecipePrototype" then
    return prototype.hidden
  elseif prototype.object_name == "LuaItemPrototype" then
    return prototype.has_flag("hidden")
  end
  return false
end

return util
