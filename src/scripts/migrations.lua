local dictionary = require("__flib__.dictionary")
local on_tick_n = require("__flib__.on-tick-n")

local global_data = require("scripts.global-data")
local player_data = require("scripts.player-data")
local recipe_book = require("scripts.recipe-book")

return {
  -- Migrations from before 3.0 are no longer required
  ["3.0.0"] = function()
    -- NUKE EVERYTHING
    global = {}

    -- Re-init everything
    dictionary.init()

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
