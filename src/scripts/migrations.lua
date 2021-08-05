local on_tick_n = require("__flib__.on-tick-n")
local translation = require("__flib__.translation")

local global_data = require("scripts.global-data")
local player_data = require("scripts.player-data")
local recipe_book = require("scripts.recipe-book")

return {
  ["2.0.0"] = function()
    -- NUKE EVERYTHING
    global = {}

    -- re-init
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
      local settings = player_table.settings
      settings.show_detailed_tooltips = settings.show_detailed_recipe_tooltips
    end
  end,
  ["3.0.0"] = function()
    -- NUKE EVERYTHING
    global = {}

    -- Re-init everything
    translation.init()

    global_data.init()
    global_data.build_prototypes()

    recipe_book.build()
    recipe_book.check_forces()

    on_tick_n.init()
    for i, player in pairs(game.players) do
      -- Destroy all old Recipe Book GUIs
      for _, window in pairs(player.gui.screen.children) do
        if window.get_mod() == "RecipeBook" then
          window.destroy()
        end
      end

      -- Re-init player
      player_data.init(i)
      player_data.refresh(player, global.players[i])
    end
  end
}
