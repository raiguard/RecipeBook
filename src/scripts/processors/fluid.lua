local util = require("scripts.util")

local fluid_proc = {}

function fluid_proc.build(recipe_book, strings)
  for name, prototype in pairs(game.fluid_prototypes) do
    recipe_book.fluid[name] = {
      available_to_forces = {},
      class = "fluid",
      default_temperature = prototype.default_temperature,
      fuel_value = prototype.fuel_value > 0 and prototype.fuel_value or nil,
      hidden = prototype.hidden,
      ingredient_in = {},
      product_of = {},
      prototype_name = name,
      pumped_by = {},
      recipe_categories = {},
      type = "fluid",
      unlocked_by = util.technology_array()
    }
    util.add_string(strings, {dictionary = "fluid", internal = name, localised = prototype.localised_name})
    util.add_string(strings, {dictionary = "fluid", internal = name, localised = prototype.localised_description})
  end
end

-- when calling the module directly, call fluid_proc.build
setmetatable(fluid_proc, { __call = function(_, ...) return fluid_proc.build(...) end })

return fluid_proc
