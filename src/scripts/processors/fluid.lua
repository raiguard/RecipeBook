local util = require("scripts.util")

local fluid_proc = {}

function fluid_proc.build(recipe_book, strings)
  for name, prototype in pairs(game.fluid_prototypes) do
    recipe_book.fluid[name] = {
      class = "fluid",
      default_temperature = tostring(prototype.default_temperature),
      fuel_value = prototype.fuel_value > 0 and prototype.fuel_value or nil,
      hidden = prototype.hidden,
      prototype_name = name,
      temperatures = {
        [tostring(prototype.default_temperature)] = {
          available_to_forces = {},
          ingredient_in = {},
          product_of = {},
          pumped_by = {},
          recipe_categories = {},
          unlocked_by = util.technology_array()
        }
      },
      type = "fluid"
    }
    util.add_string(strings, {dictionary = "fluid", internal = name, localised = prototype.localised_name})
    util.add_string(strings, {dictionary = "fluid", internal = name, localised = prototype.localised_description})
  end
end

function fluid_proc.add_or_update_temperature(material_data, lookup_type, temperature_string, object)
  local temperature_data = material_data.temperatures[temperature_string]
  if not temperature_data then
    local data = {
      available_to_forces = {},
      ingredient_in = {},
      product_of = {},
      pumped_by = {},
      recipe_categories = {},
      unlocked_by = util.technology_array()
    }
    temperature_data = data
    material_data.temperatures[temperature_string] = data
  end
  local lookup_table = temperature_data[lookup_type]
  lookup_table[#lookup_table + 1] = object
end

-- when calling the module directly, call fluid_proc.build
setmetatable(fluid_proc, { __call = function(_, ...) return fluid_proc.build(...) end })

return fluid_proc
