local constants = require("constants")
local main_gui = require("scripts.gui.main.base")

local remote_interface = {}

function remote_interface.open_page(player_index, class, name)
  if not class then return false, "Did not provide a class" end

  if not constants.interface_classes[class] then
    return false, "Did not provide a valid class"
  end
  if not name then return false, "Did not provide a name" end
  local data = global.recipe_book[class][name]
  if not data then return false, "Did not provide a valid object" end

  local player = game.get_player(player_index)
  local player_table = global.players[player_index]

  main_gui.open_page(player, player_table, class, name)

  if not player_table.flags.gui_open then
    main_gui.open(player, player_table, true)
  end

  return true
end

function remote_interface.version() return constants.interface_version end

return remote_interface
