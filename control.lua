local handler = require("__core__.lualib.event_handler")

handler.add_libraries({
  require("scripts.migrations"),

  require("__flib__.dictionary-lite"),
  require("__flib__.gui-lite"),

  require("scripts.database.database"),
  require("scripts.gui.main"),
  require("scripts.gui.overhead-button"),

  require("scripts.debug"),
})

require("scripts.remote-interface")
