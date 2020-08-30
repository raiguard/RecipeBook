local remote_interface = {}

local event = require("__flib__.event")

local constants = require("constants")

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

  event.raise(constants.events.open_page, {player_index=player_index, obj_class=class, obj_name=name})

  return true
end

function remote_interface.version() return constants.interface_version end

return remote_interface