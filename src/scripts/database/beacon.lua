local area = require("__flib__.area")

local util = require("scripts.util")

return function(database, metadata)
  metadata.beacon_allowed_effects = {}
  for name, prototype in pairs(global.prototypes.beacon) do
    local size = util.get_size(prototype)
    local effect_area = area.load(area.from_dimensions(size, { x = 0, y = 0 })):expand(prototype.supply_area_distance)

    database.entity[name] = {
      accepted_modules = {},
      blueprintable = util.is_blueprintable(prototype),
      class = "entity",
      distribution_effectivity = prototype.distribution_effectivity,
      effect_area = { height = effect_area:height(), width = effect_area:width() },
      energy_usage = prototype.energy_usage,
      entity_type = { class = "entity_type", name = prototype.type },
      module_slots = prototype.module_inventory_size
          and prototype.module_inventory_size > 0
          and prototype.module_inventory_size
        or nil,
      placed_by = util.process_placed_by(prototype),
      prototype_name = name,
      science_packs = {},
      size = size,
      unlocked_by = {},
    }

    util.add_to_dictionary("entity", name, prototype.localised_name)
    util.add_to_dictionary("entity_description", name, prototype.localised_description)

    metadata.beacon_allowed_effects[name] = prototype.allowed_effects
  end
end
