local util = require("scripts.util")

return function(database, dictionaries)
  for name, prototype in pairs(global.prototypes.entity) do
    local equipment_categories = util.unique_obj_array()
    local equipment = util.unique_obj_array()
    local equipment_grid = prototype.grid_prototype
    if equipment_grid then
      for _, equipment_category in pairs(equipment_grid.equipment_categories) do
        table.insert(equipment_categories, { class = "equipment_category", name = equipment_category })
        local category_data = database.equipment_category[equipment_category]
        if category_data then
          for _, equipment_name in pairs(category_data.equipment) do
            table.insert(equipment, equipment_name)
          end
        end
      end
    end

    local fuel_categories = util.process_energy_source(prototype) or {}

    database.entity[name] = {
      accepted_equipment = equipment,
      blueprintable = util.is_blueprintable(prototype),
      can_burn = {},
      class = "entity",
      equipment_categories = equipment_categories,
      fuel_categories = fuel_categories,
      placed_by = util.process_placed_by(prototype),
      prototype_name = name,
      science_packs = {},
      unlocked_by = {},
    }

    dictionaries.entity:add(name, prototype.localised_name)
    dictionaries.entity_description:add(name, prototype.localised_description)
  end
end
