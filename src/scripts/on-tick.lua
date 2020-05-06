local on_tick = {}

local event = require("__flib__.control.event")
local translation = require("__flib__.control.translation")

-- local global_data = require("scripts.global-data")
local search = require("scripts.search")

function on_tick.handler(e)
  local deregister = true
  if global.__flib.translation.translating_players_count > 0 then
    deregister = false
    translation.iterate_batch(e)
  end
  if #global.searching_players > 0 then
    deregister = false
    search.iterate(e)
  end
  if deregister then
    event.on_tick(nil)
  end
end

return on_tick