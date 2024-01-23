local data_util = {}

-- --- @param spec RecipeBookPrototypeSpec
-- --- @return data.PrototypeBase
-- function util.get_prototype_from_spec(spec)
--   if type(spec) == "string" then
--     return get_prototype_from_sprite_path(spec --[[@as SpritePath]])
--   end
--   return spec --[[@as data.PrototypeBase]]
-- end

--- @param prototype data.PrototypeBase
--- @return string
function data_util.get_prototype_base_type(prototype)
  for name, tbl in pairs(defines.prototypes) do
    if tbl[prototype.type] then
      return name
    end
  end
  error("Failed to find prototype type of " .. prototype.type .. "/" .. prototype.name)
end

--- @param prototype data.PrototypeBase
--- @return SpritePath
function data_util.get_sprite_path(prototype)
  return data_util.get_prototype_base_type(prototype) .. "/" .. prototype.name
end

-- --- @param type string
-- --- @param name string
-- --- @return data.PrototypeBase
-- function util.get_valid_prototype(type, name)
--   local typetbl = data.raw[type]
--   if not typetbl then
--     error("Invalid prototype requested: " .. type .. "/" .. name)
--   end
--   local prototype = typetbl[name]
--   if not prototype then
--     error("Invalid prototype requested: " .. type .. "/" .. name)
--   end
--   return prototype --[[@as data.PrototypeBase]]
-- end

--- @generic T
--- @param arg T?
--- @return T
function data_util.assert_exists(arg, arg_name)
  if arg == nil then
    error("Missing argument '" .. arg_name .. "'.")
  end
  return arg
end

--- @param value boolean
--- @param arg_name string
function data_util.assert_is_boolean(value, arg_name)
  data_util.assert_exists(value, arg_name)
  if type(value) ~= "boolean" then
    error("Argument '" .. arg_name .. "' must be a boolean.")
  end
end

--- @param prototype data.PrototypeBase
--- @param arg_name string
function data_util.assert_is_prototype(prototype, arg_name)
  data_util.assert_exists(prototype, arg_name)
  if
    type(prototype) ~= "table"
    or not prototype.type
    or not prototype.name
    or not data.raw[prototype.type][prototype.name]
  then
    error("Argument '" .. arg_name .. "' must be a valid prototype that has been added to data.raw.")
  end
end

return data_util
