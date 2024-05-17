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

-- TODO: Add button to cross-reference steam, water, etc.
--- @private
--- @param label LocalisedString
function info_description:add_header(label)
  self:add_internal({ type = "label", style = "tooltip_heading_label_category", caption = label })
  local line = self:add_internal({ type = "line", style = "tooltip_category_line" })
  line.style.left_margin = -8
  line.style.right_margin = -8
end

local mod_name_separator = " › "

--- Adds prototype history and localised description of the prototype.
--- @param prototype GenericPrototype?
function info_description:add_common(prototype)
  if not prototype then
    return
  end
  local history = script.get_prototype_history(get_prototype_type(prototype), prototype.name)
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

  self:add_separator()

  local stack_size = item.stack_size
  if stack_size > 0 then
    self:make_generic_row({ "description.rb-stack-size" }, flib_format.number(stack_size, true))
  end

  self:add_separator()

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
function info_description:add_fluid(entry)
  local fluid = entry.fluid
  if not fluid then
    return
  end

  local fuel_value = fluid.fuel_value
  if fuel_value > 0 then
    self:make_generic_row(
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

local vehicles = {
  ["car"] = true,
  ["artillery-wagon"] = true,
  ["cargo-wagon"] = true,
  ["fluid-wagon"] = true,
  ["locomotive"] = true,
  ["spider-vehicle"] = true,
}

--- @param entry Entry
function info_description:add_entity(entry)
  local entity = entry.entity
  if not entity then
    return
  end

  self:add_separator()

  local max_underground_distance = entity.max_underground_distance
  if max_underground_distance then
    self:make_generic_row(
      { "description.maximum-length" },
      flib_format.number(flib_math.round(max_underground_distance, 0.01), true)
    )
  end

  local belt_speed = entity.belt_speed
  if belt_speed then
    self:make_generic_row({ "description.belt-speed" }, {
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
      self:make_generic_row({ "description.storage-size" }, flib_format.number(storage_size, true))
    end
  end

  if entity.type == "storage-tank" or entity.type == "fluid-wagon" then
    self:make_generic_row({ "description.fluid-capacity" }, flib_format.number(entity.fluid_capacity, true))
  end

  if entity.type == "boiler" then
    local input_fluid_box = entity.fluidbox_prototypes[1]
    local input_filter = input_fluid_box.filter
    if input_filter then
      local minimum_temperature = input_fluid_box.minimum_temperature or input_filter.default_temperature
      local flow_per_tick = (entity.target_temperature - minimum_temperature) * input_filter.heat_capacity
      local flow_label = { "", entity.max_energy_usage / flow_per_tick * 60, { "per-second-suffix" } }

      self:add_separator()
      self:add_header({
        "",
        "[img=" .. entry.database:get_tooltip_category_sprite(input_filter, "consumption") .. "] ",
        { "tooltip-category.consumes" },
        " ",
        input_filter.localised_name,
      })
      self:make_generic_row({ "description.energy-consumption" }, flow_label)

      local output_fluid_box = entity.fluidbox_prototypes[2]
      local output_filter = output_fluid_box.filter
      if output_filter then
        self:add_separator()
        self:add_header({
          "",
          "[img=" .. entry.database:get_tooltip_category_sprite(output_filter, "production") .. "] ",
          { "tooltip-category.generates" },
          " ",
          output_filter.localised_name,
        })
        self:make_generic_row({ "description.fluid-output" }, flow_label)
        self:make_generic_row({ "description.temperature" }, { "format-degrees-c", entity.target_temperature })
      end
    end
  end

  local rotation_speed = entity.inserter_rotation_speed
  if rotation_speed then
    self:make_generic_row(
      { "description.rotation-speed" },
      { "", { "format-degrees", flib_format.number(rotation_speed * 360 * 60, false, 0) }, { "per-second-suffix" } }
    )
  end

  if entity.type == "inserter" then
    local force_bonus = 0
    local force = self.context.player.force
    if entity.stack then
      force_bonus = force.stack_inserter_capacity_bonus
    else
      force_bonus = force.inserter_stack_size_bonus
    end
    local stack_size = 1 + entity.inserter_stack_size_bonus --[[@as uint]]
    local label = flib_format.number(stack_size)
    if force_bonus ~= 0 then
      label = label .. " + " .. flib_format.number(force_bonus)
    end
    self:make_generic_row({ "description.hand-stack-size" }, label)
    if entity.filter_count > 0 then
      self:add_internal({ type = "label", style = "caption_label", caption = { "description.can-filter-items" } })
    end
  end

  if entity.type == "electric-pole" then
    self:make_generic_row({ "description.wire-reach" }, flib_format.number(entity.max_wire_distance))
    local supply_area = flib_format.number(entity.supply_area_distance * 2)
    self:make_generic_row({ "description.supply-area" }, supply_area .. "×" .. supply_area)
  end

  local pumping_speed = entity.pumping_speed
  if pumping_speed then
    self:make_generic_row(
      { "description.pumping-speed" },
      { "", flib_format.number(pumping_speed * 60, true), { "per-second-suffix" } }
    )
  end

  if vehicles[entity.type] then
    self:add_header({
      "",
      "[img=tooltip-category-vehicle] ",
      { "tooltip-category.vehicle" },
    })
    if not string.find(entity.type, "wagon") then
      local max_speed = entity.speed
      if max_speed then
        self:make_generic_row(
          { "description.max-speed" },
          { "", flib_format.number(max_speed * 60 * 60 * 60 / 1000, false, 0), { "si-unit-kilometer-per-hour" } }
        )
      end
      -- TODO: Add read for vehicle max acceleration power
      --   local burner = entity.burner_prototype
      --   if burner then
      --   end
      --   if acceleration_power then
      --     self:make_generic_row(
      --       { "description.max-speed" },
      --       { "", flib_format.number(acceleration_power * 60 * 60 * 60 / 1000, false, 0), { "si-unit-kilometer-per-hour" } }
      --     )
      --   end
    end
    local weight = entity.weight
    if weight then
      self:make_generic_row({ "description.weight" }, flib_format.number(weight))
    end
  end
end

function info_description:finalize()
  if #self.frame.children_names == 0 then
    self.frame.destroy()
  end
end

return info_description
