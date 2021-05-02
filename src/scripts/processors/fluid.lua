local util = require("scripts.util")

local fluid_proc = {}

function fluid_proc.build(recipe_book, strings, metadata)
  local localised_fluids = {}
  for name, prototype in pairs(game.fluid_prototypes) do
    recipe_book.fluid[name] = {
      class = "fluid",
      default_temperature = prototype.default_temperature,
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

-- local function append(tbl_1, tbl_2)
--   for i = 1, #tbl_2 do
--     tbl_1[#tbl_1 + 1] = tbl_2[i]
--   end
-- end

-- function fluid_proc.add_temperature(recipe_book, strings, metadata, fluid_data, temperature_data)
--   local fluid_name = fluid_data.prototype_name
--   local combined_name = fluid_name.."."..temperature_data.string
--   local data = {
--     class = "fluid",
--     default_temperature = fluid_data.default_temperature,
--     fuel_value = fluid_data.fuel_value,
--     hidden = fluid_data.hidden,
--     ingredient_in = util.unique_obj_array(),
--     name = combined_name,
--     product_of = util.unique_obj_array(),
--     prototype_name = fluid_name,
--     recipe_categories = util.unique_string_array(),
--     temperature_data = temperature_data,
--     unlocked_by = util.unique_obj_array()
--   }

--   -- import properties from other temperatures
--   for _, subfluid_data in pairs(fluid_data.temperatures) do
--     if fluid_proc.is_within_range(temperature_data, subfluid_data.temperature_data) then
--       for _, tbl_name in ipairs{"ingredient_in", "product_of", "recipe_categories", "unlocked_by"} do
--         append(data[tbl_name], subfluid_data[tbl_name])
--       end
--     end
--   end

--   -- save
--   recipe_book.fluid[combined_name] = data
--   fluid_data.temperatures[temperature_data.string] = data

--   -- strings
--   util.add_string(strings, {
--     dictionary = "fluid",
--     internal = combined_name,
--     localised = {
--       "",
--       metadata.localised_fluids[fluid_name],
--       " (",
--       {"format-degrees-c-compact", temperature_data.string},
--       ")"
--     }
--   })

--   -- return
--   return data
-- end

-- function fluid_proc.add_to_matching_temperatures(recipe_book, strings, metadata, fluid_data, temperature_data, sets)
--   -- create current temperature table, if it doesn't yet exist
--   if not fluid_data.temperatures[temperature_data.string] then
--     fluid_proc.add_temperature(recipe_book, strings, metadata, fluid_data, temperature_data)
--   end

--   for _, subfluid_data in pairs(fluid_data.temperatures) do
--     if fluid_proc.is_within_range(temperature_data, subfluid_data.temperature_data) then
--       for lookup_type, obj in pairs(sets) do
--         if lookup_type == "unlocked_by" then
--           subfluid_data.researched_forces = {}
--         end
--         local list = subfluid_data[lookup_type]
--         list[#list + 1] = obj
--       end
--       if fluid_data.enabled_at_start then
--         subfluid_data.enabled_at_start = true
--       end
--     end
--   end
-- end

-- function fluid_proc.is_within_range(temperature_data_1, temperature_data_2)
--   return temperature_data_1.min >= temperature_data_2.min and temperature_data_1.max <= temperature_data_2.max
-- end

-- function fluid_proc.check_temperatures(recipe_book, strings, metadata)
--   for name, fluid in pairs(recipe_book.fluid) do
--     if fluid.temperatures and table_size(fluid.temperatures) > 0 then
--       -- Create a default temperature variant and assign all temperatureless products to output that temperature
--       local default_temperature_data = util.build_temperature_data({temperature = fluid.default_temperature})
--       local default_temperature = fluid.temperatures[default_temperature_data.string]
--       if not default_temperature then
--         default_temperature = fluid_proc.add_temperature(
--           recipe_book,
--           strings,
--           metadata,
--           fluid,
--           default_temperature_data
--         )
--       end

--       local combined_name = name.."."..default_temperature_data.string

--       -- Iterate all recipes that produce this fluid at the default temperature
--       local recipes = metadata.default_temp_products[name]
--       if recipes then
--         for _, recipe_name in ipairs(recipes) do
--           local recipe = recipe_book.recipe[recipe_name]
--           -- Find this product in the list
--           for _, product in ipairs(recipe.products) do
--             if product.name == name then
--               -- Set that product's name to be the default temperature object
--               product.name = combined_name
--               break
--             end
--           end
--         end
--       end
--     end
--   end
-- end

-- when calling the module directly, call fluid_proc.build
setmetatable(fluid_proc, { __call = function(_, ...) return fluid_proc.build(...) end })

return fluid_proc
