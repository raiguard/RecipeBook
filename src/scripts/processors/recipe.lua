local math = require("__flib__.math")

local util = require("scripts.util")

local fluid_proc = require("scripts.processors.fluid")

return function(recipe_book, strings, metadata)
  -- local fluid_temperatures = {}

  for name, prototype in pairs(game.recipe_prototypes) do
    local category = prototype.category

    local enabled_at_start = prototype.enabled

    local data = {
      associated_crafters = {},
      associated_labs = {},
      associated_offshore_pumps = {},
      category = category,
      class = "recipe",
      enabled_at_start = enabled_at_start,
      energy = prototype.energy,
      hidden = prototype.hidden,
      made_in = {},
      prototype_name = name,
      unlocked_by = {},
      used_as_fixed_recipe = metadata.fixed_recipes[name]
    }

    -- ingredients / products
    for lookup_type, io_type in pairs{ingredient_in = "ingredients", product_of = "products"} do
      local output = {}
      for i, material in ipairs(prototype[io_type]) do
        local amount_string, quick_ref_amount_string = util.build_amount_string(material)
        local material_io_data = {
          class = material.type,
          name = material.name,
          amount_string = amount_string,
          quick_ref_amount_string = quick_ref_amount_string
        }
        local material_data = recipe_book[material.type][material.name]
        local lookup_table = material_data[lookup_type]
        lookup_table[#lookup_table + 1] = {class = "recipe", name = name}
        output[i] = material_io_data
        material_data.recipe_categories[#material_data.recipe_categories + 1] = category

        if enabled_at_start and io_type == "products" then
          material_data.enabled_at_start = true
        end

        -- fluid temperatures
        if material.type == "fluid" then
          local temperature_ident = util.build_temperature_ident(material)
          if temperature_ident then
            material_io_data.temperature_ident = temperature_ident
            fluid_proc.add_temperature(
              recipe_book,
              strings,
              metadata,
              recipe_book.fluid[material.name],
              temperature_ident
            )
          end
        end
      end

      data[io_type] = output
    end

    -- made in
    for crafter_name, crafter_data in pairs(recipe_book.crafter) do
      if crafter_data.categories[category] then
        local rocket_parts_str = crafter_data.rocket_parts_required and crafter_data.rocket_parts_required.."x  " or ""
        local crafting_time = math.round_to(prototype.energy / crafter_data.crafting_speed, 2)
        data.made_in[#data.made_in + 1] = {
          class = "crafter",
          name = crafter_name,
          amount_string = rocket_parts_str.."("..crafting_time.."s)",
          quick_ref_amount_string = tostring(math.round_to(crafting_time, 1))
        }
        crafter_data.compatible_recipes[#crafter_data.compatible_recipes + 1] = {class = "recipe", name = name}
      end
    end

    recipe_book.recipe[name] = data
    util.add_string(strings, {
      dictionary = "recipe",
      internal = name,
      localised = prototype.localised_name
    })
    util.add_string(strings, {
      dictionary = "recipe_description",
      internal = name,
      localised = prototype.localised_description
    })
  end

  -- metadata.fluid_temperatures = fluid_temperatures
end
