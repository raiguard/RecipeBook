local on_tick_manager = {}

local event = require("__flib__.control.event")
local translation = require("__flib__.control.translation")

local function handler()
  if global.__flib.translation.active_translations_count > 0 then
    translation.translate_batch()
  end
end

function on_tick_manager.update()
  if global.__flib.translation.active_translations_count > 0 then
    event.on_tick(handler)
    return
  end
  event.on_tick(nil)
end

return on_tick_manager