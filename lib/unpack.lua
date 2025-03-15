-- Based on "Big Data String Library" by dodo.the.last.
-- https://mods.factorio.com/mod/big-data-string
--
-- This is free and unencumbered software released into the public domain.
--
-- Anyone is free to copy, modify, publish, use, compile, sell, or
-- distribute this software, either in source code form or as a compiled
-- binary, for any purpose, commercial or non-commercial, and by any
-- means.
--
-- In jurisdictions that recognize copyright laws, the author or authors
-- of this software dedicate any and all copyright interest in the
-- software to the public domain. We make this dedication for the benefit
-- of the public at large and to the detriment of our heirs and
-- successors.

local function decode(data)
  if type(data) == "string" then
    return data
  end
  local str = {}
  for i = 2, #data do
    str[i - 1] = decode(data[i])
  end
  return table.concat(str, "")
end

local function bigunpack(name)
  assert(type(name) == "string", "missing name!")
  local prototype = assert(prototypes.item["big-data-" .. name], string.format("big data '%s' not defined!", name))
  return decode(prototype.localised_description)
end

-- please cache the result
return bigunpack
