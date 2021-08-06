local util = require("scripts.util")

local tile_proc = {}

function tile_proc.build(recipe_book, dictionaries)
  for name, prototype in pairs(global.prototypes.tile) do
    recipe_book.tile[name] = {
      class = "tile",
      placeable_by = util.process_placeable_by(prototype),
      pollution_absorption = prototype.emissions_per_second,
      prototype_name = name,
      -- TODO: Map color?
      unlocked_by = {},
      vehicle_friction = prototype.vehicle_friction_modifier,
      walking_speed = prototype.walking_speed_modifier,
    }
    dictionaries.tile:add(name, prototype.localised_name)
    dictionaries.tile_description:add(name, prototype.localised_description)
  end
end

-- When calling the module directly, call fluid_proc.build
setmetatable(tile_proc, { __call = function(_, ...) return tile_proc.build(...) end })

return tile_proc
