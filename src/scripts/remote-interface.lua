local constants = require("constants")

local database = require("scripts.database")

local remote_interface = {}

--- Opens the given info page in a Recipe Book window.
--- @param player_index number
--- @param class string One of `crafter`, `equipment`, `equipment_category`, `fluid`, `fuel_category`, `group`, `item`, `lab`, `machine`, `mining_drill`, `offshore_pump`, `recipe`, `recipe_category`, `resource`, `resource_category`, or `technology`.
--- @param name string The name of the object to open.
--- @return boolean did_open Whether or not the page was opened.
--- @return string? error_message An explanation as to why the page did not open.
function remote_interface.open_page(player_index, class, name)
  if not class then
    return false, "Did not provide a class"
  end

  if not constants.pages[class] then
    return false, "Did not provide a valid class"
  end
  if not name then
    return false, "Did not provide a name"
  end
  local data = database[class][name]
  if not data then
    return false, "Did not provide a valid object"
  end

  local player = game.get_player(player_index)
  local player_table = global.players[player_index]

  if player_table.flags.can_open_gui then
    OPEN_PAGE(player, player_table, { class = class, name = name })
    return true
  else
    return false, "Recipe Book is not yet ready to be opened"
  end
end

--- Returns the current interface version.
---
--- This version will be incremented if breaking changes are made to the interface. Check against this version before calling interface functions to avoid crashing.
---
--- The current interface version is `4`.
--- @return number
function remote_interface.version()
  return constants.interface_version
end

return remote_interface
