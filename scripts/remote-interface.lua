local main_gui = require("scripts.gui.main")

local remote_interface = {}

--- Open the given page in Recipe Book.
--- @param player_index uint
--- @param prototype GenericPrototype
--- @return boolean success
function remote_interface.open_page(player_index, prototype)
  -- TODO: Validate that the prototype is valid.
  local player_gui = main_gui.get(player_index)
  if player_gui then
    player_gui:show_page(prototype)
  end
  return true
end

function remote_interface.version()
  return 5
end

remote.add_interface("RecipeBook", remote_interface)
