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

-- Adds a fluid temperature definition if one doesn't exist yet
function fluid_proc.add_temperature(recipe_book, strings, metadata, fluid_data, temperature_ident)
  local temperature_string = temperature_ident.string

  local temperatures = fluid_data.temperatures
  if not temperatures[temperature_string] then
    local combined_name = fluid_data.prototype_name.."."..temperature_string

    local temperature_data = {
      class = "fluid",
      default_temperature = fluid_data.default_temperature,
      fuel_value = fluid_data.fuel_value,
      hidden = fluid_data.hidden,
      ingredient_in = {},
      name = combined_name,
      product_of = {},
      prototype_name = fluid_data.prototype_name,
      recipe_categories = util.unique_string_array(),
      temperature_ident = temperature_ident,
      unlocked_by = util.unique_obj_array()
    }
    temperatures[temperature_string] = temperature_data
    recipe_book.fluid[combined_name] = temperature_data
    util.add_string(strings, {
      dictionary = "fluid",
      internal = combined_name,
      localised = {
        "",
        metadata.localised_fluids[fluid_data.prototype_name],
        " (",
        {"format-degrees-c-compact", temperature_string},
        ")"
      }
    })
  end
end

-- Returns true if `comp` is within `base`
function fluid_proc.is_within_range(base, comp, flip)
  if flip then
    return base.min >= comp.min and base.max <= comp.max
  else
    return base.min <= comp.min and base.max >= comp.max
  end
end

local function append(tbl_1, tbl_2)
  for i = 1, #tbl_2 do
    tbl_1[#tbl_1 + 1] = tbl_2[i]
  end
end

function fluid_proc.process_temperatures(recipe_book, strings, metadata)
  for fluid_name, fluid_data in pairs(recipe_book.fluid) do
    local temperatures = fluid_data.temperatures
    if temperatures and table_size(temperatures) > 1 then
      -- Step 1: Add a variant for the default temperature if one does not exist
      local default_temperature = fluid_data.default_temperature
      local default_temperature_ident = util.build_temperature_ident{temperature = default_temperature}
      if not temperatures[tostring(default_temperature)] then
        fluid_proc.add_temperature(
          recipe_book,
          strings,
          metadata,
          fluid_data,
          default_temperature_ident
        )
      end

      -- Step 2: Add researched properties to temperature variants
      for _, temperature_data in pairs(fluid_data.temperatures) do
        temperature_data.enabled_at_start = fluid_data.enabled_at_start
        if fluid_data.researched_forces then
          temperature_data.researched_forces = {}
        end
      end

      -- Step 2: Add properties from base fluid to temperature variants
      for recipe_tbl_name, fluid_tbl_name in pairs{
        ingredients = "ingredient_in",
        products = "product_of"
      } do
        for _, recipe_ident in pairs(fluid_data[fluid_tbl_name]) do
          local recipe_data = recipe_book.recipe[recipe_ident.name]

          -- Get the matching fluid
          local fluid_ident
          -- SLOW: Find a way to do this without iterating all of the materials again
          for _, material_ident in pairs(recipe_data[recipe_tbl_name]) do
            if material_ident.name == fluid_name then
              fluid_ident = material_ident
              break
            end
          end

          -- Get the temperature identifier from the material table
          local temperature_ident = fluid_ident.temperature_ident
          if temperature_ident then
            -- Change the name of the material and remove the identifier
            fluid_ident.name = fluid_ident.name.."."..temperature_ident.string
            fluid_ident.temperature_ident = nil
          elseif recipe_tbl_name == "products" then
            -- Change the name of the material to the default temperature
            fluid_ident.name = fluid_ident.name.."."..default_temperature_ident.string
            -- Use the default temperature for matching
            temperature_ident = default_temperature_ident
          end

          -- Iterate over all temperature variants and compare their constraints
          for _, temperature_data in pairs(temperatures) do
            if not temperature_ident
              or fluid_proc.is_within_range(
                temperature_data.temperature_ident,
                temperature_ident,
                fluid_tbl_name == "ingredient_in"
              )
            then
              -- Add to recipes table
              temperature_data[fluid_tbl_name][#temperature_data[fluid_tbl_name] + 1] = recipe_ident
              -- Add recipe category
              temperature_data.recipe_categories[#temperature_data.recipe_categories + 1] = recipe_data.category
              -- If in product_of, append to unlocked_by
              -- This is to avoid variants being "unlocked" when you can't actually get them
              if fluid_tbl_name == "product_of" then
                append(temperature_data.unlocked_by, recipe_data.unlocked_by)
              end
            end
          end
        end
      end
    end
  end
end

-- when calling the module directly, call fluid_proc.build
setmetatable(fluid_proc, { __call = function(_, ...) return fluid_proc.build(...) end })

return fluid_proc
