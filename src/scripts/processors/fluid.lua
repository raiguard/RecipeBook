local util = require("scripts.util")

local fluid_proc = {}

function fluid_proc.build(recipe_book, strings, metadata)
  local localised_fluids = {}
  for name, prototype in pairs(game.fluid_prototypes) do
    recipe_book.fluid[name] = {
      class = "fluid",
      default_temperature = prototype.default_temperature,
      max_temperature = prototype.max_temperature or prototype.default_temperature,
      fuel_value = prototype.fuel_value > 0 and prototype.fuel_value or nil,
      hidden = prototype.hidden,
      ingredient_in = {},
      mined_from = {},
      product_of = {},
      prototype_name = name,
      pumped_by = {},
      recipe_categories = util.unique_string_array(),
      temperatures = {},
      unlocked_by = util.unique_obj_array()
    }
    util.add_string(strings, {dictionary = "fluid", internal = name, localised = prototype.localised_name})
    util.add_string(strings, {
      dictionary = "fluid_description",
      internal = name,
      localised = prototype.localised_description
    })
    localised_fluids[name] = prototype.localised_name
  end
  metadata.localised_fluids = localised_fluids
end

local function append(tbl_1, tbl_2)
  for i = 1, #tbl_2 do
    tbl_1[#tbl_1 + 1] = tbl_2[i]
  end
end

function fluid_proc.add_temperature(recipe_book, strings, metadata, fluid_data, temperature_data)
  local fluid_name = fluid_data.prototype_name
  local combined_name = fluid_name.."."..temperature_data.string
  local data = {
    class = "fluid",
    default_temperature = fluid_data.default_temperature,
    max_temperature = fluid_data.max_temperature or fluid_data.default_temperature,
    fuel_value = fluid_data.fuel_value,
    hidden = fluid_data.hidden,
    ingredient_in = util.unique_obj_array(),
    name = combined_name,
    product_of = util.unique_obj_array(),
    prototype_name = fluid_name,
    pumped_by = util.unique_obj_array(),
    recipe_categories = util.unique_string_array(),
    temperature_data = temperature_data,
    unlocked_by = util.unique_obj_array()
  }
  -- save
  recipe_book.fluid[combined_name] = data
  fluid_data.temperatures[temperature_data.string] = data


end

function fluid_proc.import_properties(recipe_book, fluid_data, temperature_data, sets)
  local fluid_name = fluid_data.prototype_name
  local main_data = recipe_book.fluid[fluid_name]

  -- import properties from other temperatures
  if not temperature_data.skip_add then

    local combined_name = fluid_name.."."..temperature_data.string
  
    local data = recipe_book.fluid[combined_name]

    for _, subfluid_data in pairs(fluid_data.temperatures) do
      for _, tbl_name in ipairs{"ingredient_in", "product_of", "unlocked_by"} do
        if fluid_proc.is_within_range(temperature_data, subfluid_data.temperature_data, tbl_name ~= "ingredient_in") then
          append(data[tbl_name], subfluid_data[tbl_name])
        end
      end
    end
  end

  for _, subfluid_data in pairs(fluid_data.temperatures) do
    for lookup_type, obj in pairs(sets) do
      if fluid_proc.is_within_range(temperature_data, subfluid_data.temperature_data, lookup_type ~= "ingredient_in") then
        if lookup_type == "unlocked_by" then
          subfluid_data.researched_forces = {}
          if not main_data.enabled_at_start then
            main_data.researched_forces = {}
          end
        end
        local list = subfluid_data[lookup_type]
        list[#list + 1] = obj

        if fluid_data.enabled_at_start then
          subfluid_data.enabled_at_start = true
        end
      end
    end
  end
end

function fluid_proc.add_to_matching_temperatures(recipe_book, strings, metadata, fluid_data, temperature_data)
  -- create current temperature table, if it doesn't yet exist
  if not fluid_data.temperatures[temperature_data.string] and not temperature_data.skip_add then
    fluid_proc.add_temperature(recipe_book, strings, metadata, fluid_data, temperature_data)
  end
end

function fluid_proc.is_within_range(temperature_data_1, temperature_data_2, is_product)
  if is_product then
    if temperature_data_1.min >= temperature_data_2.min and temperature_data_1.max <= temperature_data_2.max then
      return true
    end
  else
    if temperature_data_2.min >= temperature_data_1.min and temperature_data_2.max <= temperature_data_1.max then
      return true
    end
  end

  return false
end

-- when calling the module directly, call fluid_proc.build
setmetatable(fluid_proc, { __call = function(_, ...) return fluid_proc.build(...) end })

return fluid_proc
