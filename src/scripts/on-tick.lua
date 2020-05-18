local on_tick = {}

local event = require("__flib__.event")
local translation = require("__flib__.translation")

local search = require("scripts.search")

local function handler(e)
  local deregister = true
  if global.__flib.translation.translating_players_count > 0 then
    deregister = false
    translation.iterate_batch(e)
  end
  if #global.searching_players > 0 then
    deregister = false
    search.iterate()
  end
  if deregister then
    event.on_tick(nil)
  end
end

function on_tick.update()
  if global.__flib and global.__flib.translation.translating_players_count > 0
    or #global.searching_players > 0
  then
    event.on_tick(handler)
  else
    event.on_tick(nil)
  end
end

return on_tick