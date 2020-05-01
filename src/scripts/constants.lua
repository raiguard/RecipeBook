local event = require("__flib__.control.event")

return {
  info_guis = {crafter=true, material=true, recipe=true},
  interface_version = 2,
  open_gui_event = event.generate_id(),
  reopen_source_event = event.generate_id()
}