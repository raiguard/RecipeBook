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
  local int_name = (int_class == "material") and class.."."..name or name
  local data = global.recipe_book[int_class][int_name]
  if not data then return false, "Did not provide a valid object" end

  local player = game.get_player(player_index)
  local player_table = global.players[player_index]

  main_gui.open_page(player, player_table, class, name)

  return true
end

function remote_interface.version() return constants.interface_version end

return remote_interface
