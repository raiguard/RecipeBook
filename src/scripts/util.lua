local math = require("__flib__.math")
local misc = require("__flib__.misc")
local table = require("__flib__.table")
local translation = require("__flib__.translation-new")

local constants = require("constants")

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

local function format_number(number)
  return misc.delineate_number(math.round_to(number, 2))
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
      temperature_string = "≤"..format_number(temperature_max)
    elseif temperature_max == math.max_double then
      temperature_string = "≥"..format_number(temperature_min)
    else
      temperature_string = ""..format_number(temperature_min).."-"..format_number(temperature_max)
    end
  end

  if temperature_string then
    return {string = temperature_string, min = temperature_min, max = temperature_max}
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

function util.build_initial_dictionaries()
  local output = {}
  for dictionary_name, initial_contents in pairs(constants.initial_dictionaries) do
    output[dictionary_name] = translation.new(dictionary_name, initial_contents)
  end
  return output
end

return util

