return {
  ["1.1.0"] = function()
    -- update active_translations_count to properly reflect the active translations
    local __translation = global.__lualib.translation
    local count = 0
    for _,t in pairs(__translation.players) do
      count = count + t.active_translations_count
    end
    __translation.active_translations_count = count
  end,
  ["1.1.5"] = function()
    -- delete all mod GUI buttons
    for _,t in pairs(global.players) do
      t.gui.mod_gui_button.destroy()
      t.gui.mod_gui_button = nil
    end
    -- remove GUI lualib table - it is no longer needed
    global.__lualib.gui = nil
  end,
  ["1.2.0"] = function()
    -- migrate recipe quick reference data format
    for _,t in pairs(global.players) do
      local rqr_gui = t.gui.recipe_quick_reference
      local new_t = {}
      if rqr_gui then
        -- add an empty filters table to prevent crashes
        rqr_gui.filters = {}
        -- nest into a parent table
        new_t = {[rqr_gui.recipe_name]=rqr_gui}
      end
      t.gui.recipe_quick_reference = new_t
    end
  end,
  ["1.2.3"] = function()
    -- remove global.dictionaries, it hasn't been needed since v1.1.0
    global.dictionaries = {}
  end
}