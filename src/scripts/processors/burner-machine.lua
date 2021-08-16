local util = require("scripts.util")

return function(recipe_book, dictionaries)
  for name, prototype in pairs(global.prototypes.burner_machine) do
    local fuel_categories = util.process_energy_source(prototype)
    if fuel_categories then
      recipe_book.burner_machine[name] = {
        class = "burner_machine",
        compatible_fuels = {},
        fuel_categories = fuel_categories,
        placed_by = util.process_placed_by(prototype),
        prototype_name = name,
        unlocked_by = {},
      }

      dictionaries.burner_machine:add(name, prototype.localised_name)
      dictionaries.burner_machine_description:add(name, prototype.localised_description)
    end
  end
end
