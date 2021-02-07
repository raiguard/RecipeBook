local math = require("__flib__.math")
local table = require("__flib__.table")

local util = {}

function util.append(tbl, name)
  local new_tbl = table.shallow_copy(tbl)
  new_tbl[#new_tbl+1] = name
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

  -- second return is the "average" amount
  return amount_string -- , amount == nil and ((material.amount_min + material.amount_max) / 2) or nil
end

function util.build_temperature_string(fluid)
  -- temperature
  local temperature = fluid.temperature
  local temp_min = fluid.minimum_temperature
  local temp_max = fluid.maximum_temperature
  if temperature then
    return tostring(math.round_to(temperature, 2))
  elseif temp_min and temp_max then
    if temp_min == math.min_double then
      return "≤"..math.round_to(temp_max, 2)
    elseif temp_max == math.max_double then
      return "≥"..math.round_to(temp_min, 2)
    else
      return ""..math.round_to(temp_min, 2).."-"..math.round_to(temp_max, 2)
    end
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

function util.technology_array()
  local hash = {}
  return setmetatable({}, {
    __newindex = function(tbl, key, value)
      if not hash[value.name] then
        hash[value.name] = true
        rawset(tbl, key, value)
      end
    end
  })
end

return util

