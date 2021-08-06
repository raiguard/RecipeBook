local table = require("__flib__.table")

local global_data = {}

function global_data.init()
  global.flags = {}
  global.forces = {}
  global.players = {}
  global.prototypes = {}
end

local filtered_entities = {
  character = {{filter = "type", type = "character"}},
  crafter = {
    {filter = "type", type = "assembling-machine"},
    {filter = "type", type = "furnace"},
    {filter = "type", type = "rocket-silo"},
  },
  lab = {{filter = "type", type = "lab"}},
  mining_drill = {{filter = "type", type = "mining-drill"}},
  offshore_pump = {{filter = "type", type = "offshore-pump"}},
  resource = {{filter = "type", type = "resource"}},
}

local straight_conversions = {
  "fluid",
  "item",
  "item_group",
  "module_category",
  "recipe",
  "recipe_category",
  "resource_category",
  "technology",
  "tile",
}

function global_data.build_prototypes()
  global.forces = table.shallow_copy(game.forces)

  local prototypes = {}

  for key, filters in pairs(filtered_entities) do
    prototypes[key] = table.shallow_copy(game.get_filtered_entity_prototypes(filters))
  end
  for _, type in pairs(straight_conversions) do
    prototypes[type] = table.shallow_copy(game[type.."_prototypes"])
  end

  global.prototypes = prototypes
end

function global_data.add_force(force)
  table.insert(global.forces, force)
end

return global_data
