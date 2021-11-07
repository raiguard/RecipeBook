local area = require("__flib__.area")
local math = require("__flib__.math")
local misc = require("__flib__.misc")
local table = require("__flib__.table")

local util = {}

function util.build_amount_ident(input)
  return {
    amount = input.amount or false,
    amount_min = input.amount_min or false,
    amount_max = input.amount_max or false,
    probability = input.probability or false,
    format = input.format or "format_amount",
  }
end

-- HACK: Requiring `formatter` in this file causes a dependency loop
local function format_number(value)
  return misc.delineate_number(math.round_to(value, 2))
end

function util.build_temperature_ident(fluid)
  local temperature = fluid.temperature
  local temperature_min = fluid.minimum_temperature
  local temperature_max = fluid.maximum_temperature
  local temperature_string
  if temperature then
    temperature_string = format_number(temperature)
    temperature_min = temperature
    temperature_max = temperature
  elseif temperature_min and temperature_max then
    if temperature_min == math.min_double then
      temperature_string = "≤" .. format_number(temperature_max)
    elseif temperature_max == math.max_double then
      temperature_string = "≥" .. format_number(temperature_min)
    else
      temperature_string = "" .. format_number(temperature_min) .. "-" .. format_number(temperature_max)
    end
  end

  if temperature_string then
    return { string = temperature_string, min = temperature_min, max = temperature_max }
  end
end

function util.convert_and_sort(tbl)
  for key in pairs(tbl) do
    tbl[#tbl + 1] = key
  end
  table.sort(tbl)
  return tbl
end

function util.add_string(strings, tbl)
  strings.__index = strings.__index + 1
  strings[strings.__index] = tbl
end

function util.unique_string_array(initial_tbl)
  initial_tbl = initial_tbl or {}
  local hash = {}
  for _, value in pairs(initial_tbl) do
    hash[value] = true
  end
  return setmetatable(initial_tbl, {
    __newindex = function(tbl, key, value)
      if not hash[value] then
        hash[value] = true
        rawset(tbl, key, value)
      end
    end,
  })
end

function util.unique_obj_array(initial_tbl)
  local hash = {}
  return setmetatable(initial_tbl or {}, {
    __newindex = function(tbl, key, value)
      if not hash[value.name] then
        hash[value.name] = true
        rawset(tbl, key, value)
      end
    end,
  })
end

function util.frame_action_button(sprite, tooltip, ref, action)
  return {
    type = "sprite-button",
    style = "frame_action_button",
    sprite = sprite .. "_white",
    hovered_sprite = sprite .. "_black",
    clicked_sprite = sprite .. "_black",
    tooltip = tooltip,
    mouse_button_filter = { "left" },
    ref = ref,
    actions = {
      on_click = action,
    },
  }
end

function util.process_placed_by(prototype)
  local placed_by = prototype.items_to_place_this
  if placed_by then
    return table.map(placed_by, function(item_stack)
      return {
        class = "item",
        name = item_stack.name,
        amount_ident = util.build_amount_ident({ amount = item_stack.count }),
      }
    end)
  end
end

function util.convert_categories(source_tbl, class)
  local categories = {}
  for category in pairs(source_tbl) do
    categories[#categories + 1] = { class = class, name = category }
  end
  return categories
end

function util.convert_to_ident(class, source)
  if source then
    return { class = class, name = source }
  end
end

function util.get_size(prototype)
  if prototype.selection_box then
    local box = area.load(prototype.selection_box)
    return { height = math.ceil(box:height()), width = math.ceil(box:width()) }
  end
end

function util.process_energy_source(prototype)
  local burner = prototype.burner_prototype
  local fluid_energy_source = prototype.fluid_energy_source_prototype
  if burner then
    return util.convert_categories(burner.fuel_categories, "fuel_category")
  elseif fluid_energy_source then
    return { { class = "fuel_category", name = "burnable-fluid" } }
  end
end

return util
