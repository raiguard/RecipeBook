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
      temperatures = {},
      type = "fluid",
      unlocked_by = util.unique_obj_array()
    }
    util.add_string(strings, {dictionary = "fluid", internal = name, localised = prototype.localised_name})
    util.add_string(strings, {dictionary = "fluid", internal = name, localised = prototype.localised_description})
  end
end

-- TODO: it might not actually need `class` and `type` anymore...

local function append(tbl_1, tbl_2)
  for i = 1, #tbl_2 do
    tbl_1[#tbl_1 + 1] = tbl_2[i]
  end
end

function fluid_proc.add_temperature(recipe_book, fluid_data, temperature_data)
  local fluid_name = fluid_data.prototype_name
  local data = {
    available_to_forces = {},
    class = "fluid",
    default_temperature = fluid_data.default_temperature,
    fuel_value = fluid_data.fuel_value,
    hidden = fluid_data.hidden,
    ingredient_in = util.unique_obj_array(),
    product_of = util.unique_obj_array(),
    prototype_name = fluid_name,
    pumped_by = {}, -- TODO: remove?
    recipe_categories = {},
    temperature_data = temperature_data,
    type = "fluid",
    unlocked_by = util.unique_obj_array()
  }

  -- import properties from other temperatures
  for _, subfluid_data in pairs(fluid_data.temperatures) do
    if fluid_proc.is_within_range(temperature_data, subfluid_data.temperature_data) then
      for _, tbl_name in ipairs{"ingredient_in", "product_of", "unlocked_by"} do
        append(data[tbl_name], subfluid_data[tbl_name])
      end
    end
  end

  -- save
  recipe_book.fluid[fluid_name.."."..temperature_data.string] = data
  fluid_data.temperatures[temperature_data.string] = data
end

function fluid_proc.add_to_matching_temperatures(recipe_book, fluid_data, temperature_data, lookup_type, obj)
  -- create current temperature table, if it doesn't yet exist
  if not fluid_data.temperatures[temperature_data.string] then
    fluid_proc.add_temperature(recipe_book, fluid_data, temperature_data)
  end

  for _, subfluid_data in pairs(fluid_data.temperatures) do
    if fluid_proc.is_within_range(temperature_data, subfluid_data.temperature_data) then
      local list = subfluid_data[lookup_type]
      list[#list + 1] = obj
    end
  end
end

function fluid_proc.is_within_range(temperature_data_1, temperature_data_2)
  if
    temperature_data_1.min >= temperature_data_2.min
    and temperature_data_1.max <= temperature_data_2.max
  then
    return true
  end
  return false
end

-- when calling the module directly, call fluid_proc.build
setmetatable(fluid_proc, { __call = function(_, ...) return fluid_proc.build(...) end })

return fluid_proc
