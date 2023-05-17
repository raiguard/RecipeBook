local handler = require("__core__/lualib/event_handler")

handler.add_lib(require("__flib__/dictionary-lite"))
handler.add_lib(require("__flib__/gui-lite"))

handler.add_lib(require("__RecipeBook__/scripts/data"))
handler.add_lib(require("__RecipeBook__/scripts/gui"))

--- @class Set<T> { [T]: boolean }
