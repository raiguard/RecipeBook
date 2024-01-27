local flib_dictionary = require("__flib__.dictionary-lite")
local flib_format = require("__flib__.format")
local flib_math = require("__flib__.math")
local util = require("scripts.util")

--- @class InfoDescription
--- @field context MainGuiContext
--- @field frame LuaGuiElement
--- @field has_content boolean
local info_description = {}
local mt = { __index = info_description }
script.register_metatable("info_description", mt)

--- @param parent LuaGuiElement
--- @param context MainGuiContext
--- @return InfoDescription
function info_description.new(parent, context)
  local frame = parent.add({
    type = "frame",
    style = "rb_description_frame",
    horizontal_scroll_policy = "never",
    direction = "vertical",
  })
  local self = {
    context = context,
    frame = frame,
    has_content = false,
  }
  setmetatable(self, mt)
  return self
end

--- @param prototype GenericPrototype
--- @return string
local function get_prototype_type(prototype)
  local object_name = prototype.object_name
  if
    object_name == "LuaEquipmentPrototype"
    or object_name == "LuaEntityPrototype"
    or object_name == "LuaItemPrototype"
  then
    return prototype.type
  end
  return util.object_name_to_type[object_name]
end

--- @return LocalisedString
local function mod_name_string(internal_name)
  return { "?", { "mod-name." .. internal_name }, internal_name }
end

--- @param args LuaGuiElement.add_param
--- @return LuaGuiElement
function info_description:add_internal(args)
  if #self.frame.children_names > 0 then
    self.frame.add({ type = "line", style = "rb_description_line", direction = "horizontal" })
  end
  return self.frame.add(args)
end

--- Adds prototype history and localised description of the prototype.
--- @param prototype GenericPrototype?
function info_description:add_common(prototype)
  if not prototype then
    return
  end
  local history = script.get_prototype_history(get_prototype_type(prototype), prototype.name)
  if history.created ~= "base" or #history.changed > 0 then
    local output = mod_name_string(history.created)
    for _, changed in pairs(history.changed) do
      output = { "", output, " -> ", mod_name_string(changed) }
    end
    self:add_internal({ type = "label", style = "info_label", caption = output })
  end
  local descriptions = flib_dictionary.get(self.context.player.index, "description") or {}
  local path = util.get_path(prototype)
  local description = descriptions[path]
  if description then
    local label = self:add_internal({ type = "label", caption = description })
    label.style.single_line = false
  end
end

-- --- @param entry Entry
-- function info_description:add_recipe(entry)
--   local recipe = entry.recipe
--   if not recipe then
--     return
--   end
-- end

--- @private
--- @param label LocalisedString
--- @param value LocalisedString
--- @return LuaGuiElement
function info_description:make_generic_row(label, value)
  local flow = self:add_internal({ type = "flow" })
  flow.style.horizontal_spacing = 8
  flow.add({ type = "label", style = "caption_label", caption = { "", label, ":" } })
  flow.add({ type = "label", caption = value })
  return flow
end

--- @param entry Entry
function info_description:add_item(entry)
  local item = entry.item
  if not item then
    return
  end

  local fuel_category = item.fuel_category
  if fuel_category then
    self:add_internal({
      type = "label",
      style = "caption_label",
      caption = game.fuel_category_prototypes[fuel_category].localised_name,
    })
  end

  local fuel_value = item.fuel_value
  if fuel_value > 0 then
    self:make_generic_row(
      { "description.fuel-value" },
      { "", flib_format.number(flib_math.round(fuel_value, 0.01), true), { "si-unit-symbol-joule" } }
    )
  end

  local fuel_pollution = item.fuel_emissions_multiplier
  if fuel_pollution ~= 1 then
    self:make_generic_row(
      { "description.fuel-pollution" },
      { "format-percent", flib_format.number(flib_math.round(fuel_pollution * 100, 0.01), true) }
    )
  end

  local fuel_acceleration_multiplier = item.fuel_acceleration_multiplier
  if fuel_acceleration_multiplier ~= 1 then
    self:make_generic_row(
      { "description.fuel-acceleration" },
      { "format-percent", flib_format.number(flib_math.round(fuel_acceleration_multiplier * 100, 0.01), true) }
    )
  end

  local fuel_top_speed_multiplier = item.fuel_top_speed_multiplier
  if fuel_top_speed_multiplier ~= 1 then
    self:make_generic_row(
      { "description.fuel-top-speed" },
      { "format-percent", flib_format.number(flib_math.round(fuel_top_speed_multiplier * 100, 0.01), true) }
    )
  end
end

--- @param entry Entry
function info_description:add_fluid(entry) end

function info_description:finalize()
  if #self.frame.children_names == 0 then
    self.frame.destroy()
  end
end

return info_description
