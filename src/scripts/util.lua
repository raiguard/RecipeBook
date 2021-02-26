local math = require("__flib__.math")
local table = require("__flib__.table")

local util = {}

function util.append(tbl, name)
  local new_tbl = table.shallow_copy(tbl)
  new_tbl[#new_tbl + 1] = name
  return new_tbl
end

function util.build_amount_string(material)
  -- amount
  local amount = material.amount
  local amount_string = (
    amount
    and math.round_to(amount, 2).."x"
    or material.amount_min.." - "..material.amount_max.."x"
  )

  -- probability
  local probability = material.probability
  if probability and probability < 1 then
    amount_string = (probability * 100).."% "..amount_string
  end

  -- quick ref string
  local quick_ref_string = (
    amount == nil
    and "~"..((material.amount_min + material.amount_max) / 2)
    or tostring(math.round_to(amount, 1))
  )

  -- first return is the standard, second return is what is shown in the quick ref GUI
  return amount_string, quick_ref_string
end

function util.build_temperature_data(fluid, fluid_data, is_product)
  local temperature = fluid.temperature
  local temperature_min = fluid.minimum_temperature
  local temperature_max = fluid.maximum_temperature
  local temperature_string
  local is_default

  local fluid_min = fluid_data.default_temperature
  local fluid_max = fluid_data.max_temperature or fluid_data.default_temperature

  if not temperature and not temperature_min and not temperature_max then
      if is_product then
        temperature = fluid_min
      else
        temperature_min = fluid_min
        temperature_max = fluid_max
      end

     is_default = true
  end

  if temperature then
    temperature_string = tostring(math.round_to(temperature, 2))
    temperature_min = temperature
    temperature_max = temperature
  elseif temperature_min and temperature_max then
    if (temperature_min == math.min_double or temperature_min == fluid_min) and (temperature_max == math.max_double or temperature_max == fluid_max) then
      temperature_string = nil
    elseif temperature_min == math.min_double or temperature_min == fluid_min then
      temperature_string = "≤"..math.round_to(temperature_max, 2)
    elseif temperature_max == math.max_double or temperature_max == fluid_max then
      temperature_string = "≥"..math.round_to(temperature_min, 2)
    else
      temperature_string = math.round_to(temperature_min, 2).."-"..math.round_to(temperature_max, 2)
    end
  end

  if temperature_string or is_default then
    return {string = temperature_string, min = temperature_min, max = temperature_max, skip_add = is_default and not is_product}
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
  local hash = {}
  return setmetatable(initial_tbl or {}, {
    __newindex = function(tbl, key, value)
      if not hash[value] then
        hash[value] = true
        rawset(tbl, key, value)
      end
    end
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
    end
  })
end

return util

