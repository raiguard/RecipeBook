local util = {}

-- local coreutil = require("__core__.lualib.util")

--- @param player LuaPlayer
--- @return Gui?
function util.get_gui(player)
  local player_table = global.players[player.index]
  if player_table then
    local gui = player_table.gui
    if gui and gui.refs.window.valid then
      return gui
    else
      -- TODO: Recreate GUI
    end
  end
end

--- @param prototype ObjectPrototype
--- @return boolean
function util.is_hidden(prototype)
  if prototype.object_name == "LuaFluidPrototype" or prototype.object_name == "LuaRecipePrototype" then
    return prototype.hidden
  elseif prototype.object_name == "LuaItemPrototype" then
    return prototype.has_flag("hidden")
  end
  return false
end

return util
