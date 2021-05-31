local util = require("scripts.util")

local fluid_proc = {}

function fluid_proc.build(recipe_book, strings, metadata)
  local localised_fluids = {}
  for name, prototype in pairs(game.fluid_prototypes) do
    -- Group
    local group = prototype.group
    local group_data = recipe_book.group[group.name]
    group_data.fluids[#group_data.fluids + 1] = {class = "fluid", name = name}
    -- Save to recipe book
    recipe_book.fluid[name] = {
      class = "fluid",
      default_temperature = prototype.default_temperature,
      fuel_value = prototype.fuel_value > 0 and prototype.fuel_value or nil,
      group = {class = "group", name = group.name},
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
    -- Add strings
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
      base_fluid = {class = "fluid", name = fluid_data.prototype_name},
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

function fluid_proc.process_temperatures(recipe_book, strings, metadata)
  for fluid_name, fluid_data in pairs(recipe_book.fluid) do
    local temperatures = fluid_data.temperatures
    if temperatures and table_size(temperatures) > 0 then
      -- Step 1: Add a variant for the default temperature if one does not exist
      local default_temperature = fluid_data.default_temperature
      local default_temperature_ident = util.build_temperature_ident{temperature = default_temperature}
      if not temperatures[default_temperature_ident.string] then
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

      -- Step 3: Add properties from base fluid to temperature variants
      for recipe_tbl_name, fluid_tbl_name in pairs{ingredients = "ingredient_in", products = "product_of"} do
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
              local recipe_categories = temperature_data.recipe_categories
              recipe_categories[#recipe_categories + 1] = recipe_data.recipe_category.name
              -- If in product_of, append to unlocked_by
              -- Also add this fluid to that tech's `unlocks fluids` table
              -- This is to avoid variants being "unlocked" when you can't actually get them
              if fluid_tbl_name == "product_of" then
                local temp_unlocked_by = temperature_data.unlocked_by
                for _, technology_ident in pairs(recipe_data.unlocked_by) do
                  temp_unlocked_by[#temp_unlocked_by + 1] = technology_ident
                  local technology_data = recipe_book.technology[technology_ident.name]
                  -- Don't use fluid_ident becuase it has an amount
                  technology_data.unlocks_fluids[#technology_data.unlocks_fluids + 1] = {
                    class = "fluid",
                    name = temperature_data.name
                  }
                end
              end
            end
          end
        end
      end
    end
  end
end

-- When calling the module directly, call fluid_proc.build
setmetatable(fluid_proc, { __call = function(_, ...) return fluid_proc.build(...) end })

return fluid_proc
