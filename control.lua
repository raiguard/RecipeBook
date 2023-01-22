local handler = require("__core__/lualib/event_handler")

handler.add_lib(require("__RecipeBook__/migrations"))

handler.add_lib(require("__flib__/dictionary-lite"))
handler.add_lib(require("__flib__/gui-lite"))

handler.add_lib(require("__RecipeBook__/database"))
handler.add_lib(require("__RecipeBook__/gui"))
