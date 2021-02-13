local gui = require("__flib__.gui-beta")
local translation = require("__flib__.translation")

local global_data = require("scripts.global-data")
local player_data = require("scripts.player-data")

return {
  ["2.0.0"] = function()
    -- NUKE EVERYTHING
    global = {}

    -- re-init
    gui.init()
    translation.init()
    global_data.init()
    for i in pairs(game.players) do
      player_data.init(i)
    end
  end,
  ["2.4.0"] = function()
    global.__flib.gui = nil

    for _, player_table in pairs(global.players) do
      local gui_data = player_table.gui.main
      if gui_data then
        gui_data.base.window.frame.destroy()
      end
      for _, refs in pairs(player_table.gui.quick_ref) do
        refs.window.destroy()
      end
      player_table.gui = nil
      player_table.guis = {
        quick_ref = {}
      }
    end
  end,
  ["2.5.0"] = function()
    global.translation_data = nil
    for _, player_table in pairs(global.players) do
      player_table.flags.updating_setting = nil
    end
  end
}
