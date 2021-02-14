local constants = require("constants")
local main_gui = require("scripts.gui.main.base")

local remote_interface = {}

function remote_interface.open_page(player_index, class, name)
  if not class then return false, "Did not provide a class" end
  local int_class = constants.interface_classes[class]
  if not int_class then
    return false, "Did not provide a valid class"
  end
  if not name then return false, "Did not provide a name" end
  local data = global.recipe_book[int_class][name]
  if not data then return false, "Did not provide a valid object" end

  local player = game.get_player(player_index)
  local player_table = global.players[player_index]

  main_gui.open_page(player, player_table, class, name)

  if not player_table.flags.gui_open then
    main_gui.open(player, player_table, true)
  end

  return true
end

-- interface for other mods to signalize they changed game.tick_paused value
-- only used to change the ipause icon in title bar
function remote_interface.tick_paused(player_index)
  local player = game.get_player(player_index)
  local player_table = global.players[player_index]

  main_gui.toggle_paused(player, player_table, game.tick_paused, true, false)
end

function remote_interface.version() return constants.interface_version end

return remote_interface
