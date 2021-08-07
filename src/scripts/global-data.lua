local table = require("__flib__.table")

local constants = require("constants")

local global_data = {}

function global_data.init()
  global.flags = {}
  global.forces = {}
  global.players = {}
  global.prototypes = {}
end

function global_data.build_prototypes()
  global.forces = table.shallow_copy(game.forces)

  local prototypes = {}

  for key, filters in pairs(constants.prototypes.filtered_entities) do
    prototypes[key] = table.shallow_copy(game.get_filtered_entity_prototypes(filters))
  end
  for _, type in pairs(constants.prototypes.straight_conversions) do
    prototypes[type] = table.shallow_copy(game[type.."_prototypes"])
  end

  global.prototypes = prototypes
end

function global_data.add_force(force)
  table.insert(global.forces, force)
end

return global_data
