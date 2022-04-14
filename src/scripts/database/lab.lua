local table = require("__flib__.table")

local util = require("scripts.util")

return function(database, dictionaries)
  for name, prototype in pairs(global.prototypes.lab) do
    -- Add to items
    for _, item_name in ipairs(prototype.lab_inputs) do
      local item_data = database.item[item_name]
      if item_data then
        item_data.researched_in[#item_data.researched_in + 1] = { class = "entity", name = name }
      end
    end

    database.entity[name] = {
      blueprintable = util.is_blueprintable(prototype),
      class = "entity",
      can_burn = {},
      fuel_categories = util.process_energy_source(prototype),
      hidden = prototype.has_flag("hidden"),
      inputs = table.map(prototype.lab_inputs, function(v)
        return { class = "item", name = v }
      end),
      placed_by = util.process_placed_by(prototype),
      prototype_name = name,
      researching_speed = prototype.researching_speed,
      size = util.get_size(prototype),
      unlocked_by = {},
    }
    dictionaries.entity:add(name, prototype.localised_name)
    dictionaries.entity_description:add(name, prototype.localised_description)
  end
end
