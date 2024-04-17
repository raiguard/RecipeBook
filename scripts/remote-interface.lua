local main_gui = require("scripts.gui.main")

local remote_interface = {}

--- Open the given page in Recipe Book.
--- @param player_index uint
--- @param class string
--- @param name string
--- @return boolean success
function remote_interface.open_page(player_index, class, name)
  local path = class .. "/" .. name
  local entry = global.database:get_entry(path)
  if not entry then
    return false
  end
  local player_gui = main_gui.get(player_index)
  if player_gui then
    player_gui.history:push(entry)
    player_gui:update_info()
    player_gui:show()
  end
  return true
end

function remote_interface.version()
  -- TODO raiguard: Bump version
  return 4
end

remote.add_interface("RecipeBook", remote_interface)
