local handler = require("__core__/lualib/event_handler")

handler.add_lib(require("__flib__/dictionary-lite"))
handler.add_lib(require("__flib__/gui-lite"))

handler.add_lib(require("__RecipeBook__/scripts/database"))
handler.add_lib(require("__RecipeBook__/scripts/gui"))
handler.add_lib(require("__RecipeBook__/scripts/researched"))

--- @class Set<T> { [T]: boolean }
