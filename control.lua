local handler = require("__core__/lualib/event_handler")

handler.add_libraries({
  require("__RecipeBook__/scripts/migrations"),

  require("__flib__/dictionary-lite"),
  require("__flib__/gui-lite"),

  require("__RecipeBook__/scripts/database"),
  require("__RecipeBook__/scripts/gui/main"),
  require("__RecipeBook__/scripts/gui/overhead-button"),
})
