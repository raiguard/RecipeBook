local on_tick = {}

local event = require("__flib__.event")
local translation = require("__flib__.translation")

function on_tick.handler(e)
  local deregister = true
  if global.__flib.translation.translating_players_count > 0 then
    deregister = false
    translation.iterate_batch(e)
  end

  if deregister then
    event.on_tick(nil)
  end
end

function on_tick.update()
  if global.__flib and global.__flib.translation.translating_players_count > 0 then
    event.on_tick(on_tick.handler)
  end
end

return on_tick