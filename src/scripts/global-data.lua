local table = require("__flib__.table")

local global_data = {}

function global_data.init()
  global.flags = {}
  global.forces = {}
  global.players = {}
  global.prototypes = {}
end

function global_data.build_prototypes()
  global.forces = table.shallow_copy(game.forces)
  global.prototypes = table.map(constants.class_to_type, function(type, class)
    return table.shallow_copy(game[type.."_prototypes"])
  end)
end

function global_data.add_force(force)
  table.insert(global.forces, force)
end

return global_data
