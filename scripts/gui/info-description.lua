local flib_dictionary = require("__flib__.dictionary")
local flib_format = require("__flib__.format")
local flib_gui = require("__flib__.gui")
local flib_math = require("__flib__.math")
local util = require("scripts.util")

local gui_util = require("scripts.gui.util")

--- @class InfoDescription
--- @field context MainGuiContext
--- @field callback flib.GuiElemHandler
--- @field frame LuaGuiElement
--- @field has_content boolean
local info_description = {}
local mt = { __index = info_description }
script.register_metatable("info_description", mt)

--- @param parent LuaGuiElement
--- @param context MainGuiContext
--- @param callback flib.GuiElemHandler
--- @return InfoDescription
function info_description.new(parent, context, callback)
  local frame = parent.add({
    type = "frame",
    style = "rb_description_frame",
    horizontal_scroll_policy = "never",
    direction = "vertical",
  })
  local self = {
    context = context,
    frame = frame,
    callback = callback,
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

function info_description:add_separator()
  self.new_section = true
end

--- @private
--- @param args LuaGuiElement.add_param
--- @return LuaGuiElement
function info_description:add_internal(args)
  if self.new_section then
    self.new_section = false
    if #self.frame.children_names > 0 then
      self.frame.add({ type = "line", style = "rb_description_line", direction = "horizontal" })
    end
  end
  return self.frame.add(args)
end

--- @param icon SpritePath
--- @param caption LocalisedString
--- @param id DatabaseID?
function info_description:add_category_header(icon, caption, id)
  if id then
    local flow = self:add_internal({ type = "flow" })
    flow.style.vertical_align = "center"
    flow.add({
      type = "label",
      style = "tooltip_heading_label_category",
      caption = { "", "[img=" .. icon .. "]  ", caption },
    })
    flow.add({
      type = "button",
      style = "rb_description_heading_id_button",
      caption = { "", "[img=" .. id.type .. "/" .. id.name .. "]  ", util.get_prototype(id).localised_name }, --- @diagnostic disable-line:assign-type-mismatch
      elem_tooltip = { type = id.type, name = id.name },
      tags = flib_gui.format_handlers(
        { [defines.events.on_gui_click] = self.callback },
        { id = { type = id.type, name = id.name } }
      ),
    })
    flow.style.top_margin = -4
    flow.style.bottom_margin = -4
  else
    self:add_internal({
      type = "label",
      style = "tooltip_heading_label_category",
      caption = { "", "[img=" .. icon .. "] ", caption },
    })
  end
  local line = self:add_internal({ type = "line", style = "tooltip_category_line" })
  line.style.left_margin = -8
  line.style.right_margin = -8
end

local mod_name_separator = " › "

--- Adds prototype history and localised description of the prototype.
--- @param prototype GenericPrototype
function info_description:add_history_and_description(prototype)
  local history = prototypes.get_history(get_prototype_type(prototype), prototype.name)
  if history.created ~= "base" or #history.changed > 0 then
    --- @type LocalisedString
    local output = { "", mod_name_string(history.created) }
    local x = 2
    for _, changed in pairs(history.changed) do
      local mod_name = mod_name_string(changed)
      x = x + 2
      if x > 20 then
        x = 4
        output = { "", output, mod_name_separator, mod_name }
      else
        output[#output + 1] = mod_name_separator
        output[#output + 1] = mod_name
      end
    end
    self:add_internal({ type = "label", style = "info_label", caption = output })
    self:add_separator()
  end
  local descriptions = flib_dictionary.get(self.context.player.index, "description") or {}
  local path = util.get_path(prototype)
  local description = descriptions[path]
  if description then
    local label = self:add_internal({ type = "label", caption = description })
    label.style.single_line = false
    self:add_separator()
  end
end

--- @param label LocalisedString
--- @param value LocalisedString
--- @return LuaGuiElement
function info_description:add_generic_row(label, value)
  local flow = self:add_internal({ type = "flow" })
  flow.add({ type = "label", style = "caption_label", caption = { "", label, ":" } })
  flow.add({ type = "label", caption = value })
  return flow
end

--- @param label LocalisedString
--- @param id DatabaseID
--- @return LuaGuiElement
function info_description:add_id_row(label, id)
  local flow = self:add_internal({ type = "flow" })
  flow.style.vertical_align = "center"
  flow.add({ type = "label", style = "caption_label", caption = { "", label, ":" } })
  flow.add({
    type = "button",
    style = "rb_description_id_button",
    caption = { "", "[img=" .. id.type .. "/" .. id.name .. "]  ", gui_util.format_caption(id) },
    elem_tooltip = { type = id.type, name = id.name },
    tags = flib_gui.format_handlers(
      { [defines.events.on_gui_click] = self.callback },
      { id = { type = id.type, name = id.name } }
    ),
  })
  return flow
end

--- @param recipe LuaRecipePrototype
function info_description:add_recipe_properties(recipe)
  local pollution = recipe.emissions_multiplier
  if pollution ~= 1 then
    self:add_generic_row({ "description.recipe-pollution" }, flib_format.number(pollution * 100, false, 0) .. "%")
  end
end

--- @param item LuaItemPrototype
function info_description:add_item_properties(item)
  local stack_size = item.stack_size
  if stack_size > 0 then
    self:add_generic_row({ "description.rb-stack-size" }, flib_format.number(stack_size, true))
  end

  local fuel_category = item.fuel_category
  if fuel_category then
    self:add_internal({
      type = "label",
      style = "caption_label",
      caption = prototypes.fuel_category[fuel_category].localised_name, --- @diagnostic disable-line:assign-type-mismatch
    })
  end

  local fuel_value = item.fuel_value
  if fuel_value > 0 then
    self:add_generic_row(
      { "description.fuel-value" },
      { "", flib_format.number(flib_math.round(fuel_value, 0.01), true), { "si-unit-symbol-joule" } }
    )
  end

  local fuel_pollution = item.fuel_emissions_multiplier
  if fuel_pollution ~= 1 then
    self:add_generic_row(
      { "description.fuel-pollution" },
      { "format-percent", flib_format.number(flib_math.round(fuel_pollution * 100, 0.01), true) }
    )
  end

  local fuel_acceleration_multiplier = item.fuel_acceleration_multiplier
  if fuel_acceleration_multiplier ~= 1 then
    self:add_generic_row(
      { "description.fuel-acceleration" },
      { "format-percent", flib_format.number(flib_math.round(fuel_acceleration_multiplier * 100, 0.01), true) }
    )
  end

  local fuel_top_speed_multiplier = item.fuel_top_speed_multiplier
  if fuel_top_speed_multiplier ~= 1 then
    self:add_generic_row(
      { "description.fuel-top-speed" },
      { "format-percent", flib_format.number(flib_math.round(fuel_top_speed_multiplier * 100, 0.01), true) }
    )
  end

  local module_effects = item.module_effects
  if module_effects then
    self:add_separator()
    for key, value in pairs(module_effects) do
      local caption = flib_format.number(value * 100, false, 2) .. "%"
      if value > 0 then
        caption = "+" .. caption
      end
      self:add_generic_row({ "description." .. key .. "-bonus" }, caption)
    end
  end
end

--- @param fluid LuaFluidPrototype
function info_description:add_fluid_properties(fluid)
  local fuel_value = fluid.fuel_value
  if fuel_value > 0 then
    self:add_generic_row(
      { "description.fuel-value" },
      { "", flib_format.number(flib_math.round(fuel_value, 0.01), true), { "si-unit-symbol-joule" } }
    )
  end
end

local container_types = {
  ["container"] = true,
  ["logistic-container"] = true,
  ["infinity-container"] = true,
  ["cargo-wagon"] = true,
}

--- @param entity LuaEntityPrototype
function info_description:add_entity_properties(entity)
  local max_underground_distance = entity.max_underground_distance
  if max_underground_distance then
    self:add_generic_row(
      { "description.maximum-length" },
      flib_format.number(flib_math.round(max_underground_distance, 0.01), true)
    )
  end

  local belt_speed = entity.belt_speed
  if belt_speed then
    self:add_generic_row({ "description.belt-speed" }, {
      "",
      flib_format.number(flib_math.round(belt_speed * 8 * 60, 0.01), true),
      " ",
      { "description.belt-items" },
      { "per-second-suffix" },
    })
  end

  if container_types[entity.type] then
    local storage_size = entity.get_inventory_size(defines.inventory.chest)
    if storage_size then
      self:add_generic_row({ "description.storage-size" }, flib_format.number(storage_size, true))
    end
  end

  if entity.type == "storage-tank" or entity.type == "fluid-wagon" then
    self:add_generic_row({ "description.fluid-capacity" }, flib_format.number(entity.fluid_capacity, true))
  end

  local rotation_speed = entity.get_inserter_rotation_speed() -- TODO: Quality
  if rotation_speed then
    self:add_generic_row(
      { "description.rotation-speed" },
      { "", { "format-degrees", flib_format.number(rotation_speed * 360 * 60, false, 0) }, { "per-second-suffix" } }
    )
  end

  if entity.type == "inserter" then
    local force_bonus = 0
    local force = self.context.player.force
    if entity.bulk then
      force_bonus = force.bulk_inserter_capacity_bonus
    else
      force_bonus = force.inserter_stack_size_bonus
    end
    local stack_size = 1 + entity.inserter_stack_size_bonus --[[@as uint]]
    local label = flib_format.number(stack_size)
    if force_bonus ~= 0 then
      label = label .. " + " .. flib_format.number(force_bonus)
    end
    self:add_generic_row({ "description.hand-stack-size" }, label)
    if entity.filter_count > 0 then
      self:add_internal({ type = "label", style = "caption_label", caption = { "description.can-filter-items" } })
    end
  end

  if entity.type == "electric-pole" then
    self:add_generic_row({ "description.wire-reach" }, flib_format.number(entity.get_max_wire_distance())) -- TODO: Quality
    local supply_area = flib_format.number(entity.get_supply_area_distance() * 2) -- TODO: Quality
    self:add_generic_row({ "description.supply-area" }, supply_area .. "×" .. supply_area)
  end

  if entity.type == "pump" or entity.type == "offshore-pump" then
    local pumping_speed = entity.pumping_speed
    if pumping_speed then
      self:add_generic_row(
        { "description.pumping-speed" },
        { "", flib_format.number(pumping_speed * 60, true), { "per-second-suffix" } }
      )
    end
  end

  if entity.type == "resource" then
    local mineable_properties = entity.mineable_properties
    local fluid_name = mineable_properties.required_fluid
    if fluid_name then
      local fluid_id = { type = "fluid", name = fluid_name }
      if fluid_id then
        self:add_id_row({ "description.rb-mining-fluid" }, fluid_id)
      end
    end
  end

  local burner = entity.burner_prototype
  if burner then
    for pollutant_name, pollution in pairs(burner.emissions_per_joule) do
      if pollution ~= 0 then
        self:add_generic_row(
          prototypes.airborne_pollutant[pollutant_name].localised_name, --- @diagnostic disable-line:param-type-mismatch
          {
            "",
            flib_format.number(pollution * entity.get_max_energy_usage() * 60 * 60, false), -- TODO: Quality
            { "per-minute-suffix" },
          }
        )
      end
    end
  end

  local electric_energy_source_prototype = entity.electric_energy_source_prototype
  if electric_energy_source_prototype then
    for pollutant_name, pollution in pairs(electric_energy_source_prototype.emissions_per_joule) do
      if pollution ~= 0 then
        self:add_generic_row(
          prototypes.airborne_pollutant[pollutant_name].localised_name, --- @diagnostic disable-line:param-type-mismatch
          {
            "",
            flib_format.number(pollution * entity.get_max_energy_usage() * 60 * 60, false), -- TODO: Quality
            { "per-minute-suffix" },
          }
        )
      end
    end
  end
end

--- @param id DatabaseID
function info_description:add_consumption(id)
  self:add_category_header(gui_util.get_tooltip_category_sprite(id, "consumes"), { "tooltip-category.consumes" }, id)
  assert(id.amount)
  self:add_generic_row(
    { "description.energy-consumption" },
    { "", flib_format.number(id.amount), { "per-second-suffix" } }
  )
  if id.minimum_temperature then
    self:add_generic_row(
      { "description.minimum-temperature" },
      { "", flib_format.number(id.minimum_temperature), " ", { "si-unit-degree-celsius" } }
    )
  end
  if id.maximum_temperature then
    self:add_generic_row(
      { "description.maximum-temperature" },
      { "", flib_format.number(id.maximum_temperature), " ", { "si-unit-degree-celsius" } }
    )
  end
end

--- @param id DatabaseID
function info_description:add_production(id)
  self:add_category_header(gui_util.get_tooltip_category_sprite(id, "produces"), { "tooltip-category.generates" }, id)
  assert(id.amount)
  self:add_generic_row({ "description.fluid-output" }, { "", flib_format.number(id.amount), { "per-second-suffix" } })
  if id.temperature then
    self:add_generic_row(
      { "description.temperature" },
      { "", flib_format.number(id.temperature), " ", { "si-unit-degree-celsius" } }
    )
  end
  if id.minimum_temperature then
    self:add_generic_row(
      { "description.minimum-temperature" },
      { "", flib_format.number(id.minimum_temperature), " ", { "si-unit-degree-celsius" } }
    )
  end
  if id.maximum_temperature then
    self:add_generic_row(
      { "description.maximum-temperature" },
      { "", flib_format.number(id.maximum_temperature), " ", { "si-unit-degree-celsius" } }
    )
  end
end

--- @param entity LuaEntityPrototype
function info_description:add_vehicle_properties(entity)
  if not gui_util.vehicles[entity.type] then
    return
  end

  self:add_category_header("tooltip-category-vehicle", { "tooltip-category.vehicle" })
  if not string.find(entity.type, "wagon") then
    local max_speed = entity.speed
    if max_speed then
      self:add_generic_row(
        { "description.max-speed" },
        { "si-unit-kilometer-per-hour", flib_format.number(max_speed * 60 * 60 * 60 / 1000, false, 0) }
      )
    end
    -- TODO: Add read for vehicle max acceleration power
    --   local burner = entity.burner_prototype
    --   if burner then
    --   end
    --   if acceleration_power then
    --     self:add_generic_row(
    --       { "description.max-speed" },
    --       { "", flib_format.number(acceleration_power * 60 * 60 * 60 / 1000, false, 0), { "si-unit-kilometer-per-hour" } }
    --     )
    --   end
  end
  local weight = entity.weight
  if weight then
    self:add_generic_row({ "description.weight" }, flib_format.number(weight))
  end
end

function info_description:finalize()
  if #self.frame.children_names == 0 then
    self.frame.destroy()
  end
end

return info_description
