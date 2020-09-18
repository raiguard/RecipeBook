local on_tick = {}

local event = require("__flib__.event")
local translation = require("__flib__.translation")

function on_tick.handler(e)
  if translation.translating_players_count() > 0 then
    translation.iterate_batch(e)
  else
    event.on_tick(nil)
  end
end

-- TODO rename
function on_tick.update()
  if global.__flib and translation.translating_players_count() > 0 then
    event.on_tick(on_tick.handler)
  end
end

return on_tick