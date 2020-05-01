local gui = require("__flib__.control.gui")
local translation = require("__flib__.control.translation")

return {
  ["1.1.0"] = function()
    -- update active_translations_count to properly reflect the active translations
    local __translation = global.__lualib.translation
    local count = 0
    for _, player_table in pairs(__translation.players) do
      count = count + player_table.active_translations_count
    end
    __translation.active_translations_count = count
  end,
  ["1.1.5"] = function()
    -- delete all mod GUI buttons
    for _, player_table in pairs(global.players) do
      player_table.gui.mod_gui_button.destroy()
      player_table.gui.mod_gui_button = nil
    end
    -- remove GUI lualib table - it is no longer needed
    global.__lualib.gui = nil
  end,
  ["1.2.0"] = function()
    -- migrate recipe quick reference data format
    for _, player_table in pairs(global.players) do
      local rqr_gui = player_table.gui.recipe_quick_reference
      local new_t = {}
      if rqr_gui then
        -- add an empty filters table to prevent crashes
        rqr_gui.filters = {}
        -- nest into a parent table
        new_t = {[rqr_gui.recipe_name]=rqr_gui}
      end
      player_table.gui.recipe_quick_reference = new_t
    end
  end,
  ["1.2.3"] = function()
    -- remove global.dictionaries, it hasn't been needed since v1.1.0
    global.dictionaries = {}
  end,
  ["1.3.0"] = function()
    -- init flib modules
    gui.init()
    translation.init()
    -- remove RaiLuaLib table
    global.__lualib = nil
  end
}