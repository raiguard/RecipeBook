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
    elseif gui then
      gui:destroy()
      gui = gui.new(player, player_table)
      player.print({ "message.rb-recreated-gui" })
      return gui
    end
  end
end

--- @param group PrototypeEntry
--- @param player_crafting boolean?
function util.group_is_hidden(group, player_crafting)
  local key, prototype = next(group)
  if key == "recipe" then
    local hidden = prototype.hidden
    if not hidden and player_crafting then
      return prototype.hidden_from_player_crafting
    end
  elseif key == "item" or key == "entity" then
    return prototype.has_flag("hidden")
  elseif key == "fluid" then
    return prototype.hidden
  end
end

--- @param prototype ObjectPrototype
--- @return boolean
function util.is_hidden(prototype)
  if prototype.object_name == "LuaFluidPrototype" then
    return prototype.hidden
  elseif prototype.object_name == "LuaItemPrototype" then
    return prototype.has_flag("hidden")
  elseif prototype.object_name == "LuaRecipePrototype" then
    return prototype.hidden
  end
  return false
end

util.sprite_path = {
  ["LuaEntityPrototype"] = "entity",
  ["LuaFluidPrototype"] = "fluid",
  ["LuaItemPrototype"] = "item",
  ["LuaRecipePrototype"] = "recipe",
}

return util
