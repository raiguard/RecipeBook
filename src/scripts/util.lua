local table = require("__flib__.table")

local util = {}

function util.append(tbl, name)
  local new_tbl = table.shallow_copy(tbl)
  new_tbl[#new_tbl+1] = name
  return new_tbl
end

function util.parse_fluid_temperature_key(key)
  local min, max
  local absolute_min = -0X1.FFFFFFFFFFFFFP+1023
  local absolute_max = 0X1.FFFFFFFFFFFFFP+1023

  min, max = string.match(key, '^(%d+)%-(%d+)$')
  if min and max then
    return tonumber(min), tonumber(max)
  end

  min = string.match(key, '^(%d+)$')

  if min then
    return tonumber(min), tonumber(min)
  end

  max = string.match(key, '^≤(%d+)$')

  if max then
    return absolute_min, tonumber(max)
  end

  min = string.match(key, '^≥(%d+)$')

  if min then
    return tonumber(min), absolute_max
  end

  return min, max
end

return util