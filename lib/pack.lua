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

local MAX = 10 * 20 ^ 21 -- 20 parameters * 20 recursion depth

local function depth(n)
  return math.ceil(math.log(n / 10) / math.log(20)) - 1
end

local function insert(nodes, node, value)
  table.insert(node, value) -- store as parameter
  if 21 == #node then
    node = { "" }
    table.insert(nodes, node)
  end
  return node
end

local function encode(data)
  local node = { "" }
  local root = { node }
  local n = string.len(data)
  for i = 1, n, 200 do
    local value = string.sub(data, i, i + 199)
    node = insert(root, node, value)
  end
  while #root > 20 do
    local nodes, node = {}, { "" }
    for _, value in ipairs(root) do
      node = insert(nodes, node, value)
    end
    root = nodes
  end
  if #root == 1 then
    root = root[1]
  else
    table.insert(root, 1, "") -- no locale template
  end
  return #root < 3 and (root[2] or "") or root
end

local function bigpack(name, data)
  assert(type(name) == "string", "missing name!")
  assert(type(data) == "string", "not a string!")
  local n = string.len(data)
  assert(n <= MAX, "string too long!")
  if depth(n) > 4 then -- 10*20^(1+4) = 32MB
    log(
      string.format(
        "WARNING! '%s' exceeds reasonable recursion depth of 4 (32MB). Expect performance degradation!",
        name
      )
    )
  end
  return {
    type = "item",
    name = "big-data-" .. name,
    icon = "__core__/graphics/icons/unknown.png",
    hidden = true,
    stack_size = 1,
    localised_name = string.format("BIGDATA[%s]", name),
    localised_description = encode(data),
    order = "z",
  }
end

return bigpack
