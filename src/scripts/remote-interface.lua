local constants = require("constants")

local shared = require("scripts.shared")

local remote_interface = {}

function remote_interface.open_page(player_index, class, name)
  if not class then return false, "Did not provide a class" end

  if not constants.pages[class] then
    return false, "Did not provide a valid class"
  end
  if not name then return false, "Did not provide a name" end
  local data = global.recipe_book[class][name]
  if not data then return false, "Did not provide a valid object" end

  local player = game.get_player(player_index)
  local player_table = global.players[player_index]

  if player_table.flags.can_open_gui then
    shared.open_page(player, player_table, {class = class, name = name})
    return true
  else
    return false, "Recipe Book is not yet ready to be opened"
  end
end

function remote_interface.version() return constants.interface_version end

return remote_interface
