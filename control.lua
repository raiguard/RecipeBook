local handler = require("__core__.lualib.event_handler")

handler.add_libraries({
  require("scripts.migrations"),

  require("__flib__.dictionary"),
  require("__flib__.gui"),

  require("scripts.database"),
  require("scripts.gui"),
  require("scripts.researched"),
})

--- @class Set<T> { [T]: boolean }
