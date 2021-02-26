local util = require("scripts.util")
local fluid_proc = require("scripts.processors.fluid")
return function(recipe_book, strings, metadata)
  -- iterate offshore pumps
  for name, prototype in pairs(game.get_filtered_entity_prototypes{{filter = "type", type = "offshore-pump"}}) do
    -- add to material
    local fluid = prototype.fluid
    local fluid_data = recipe_book.fluid[fluid.name]

    fluid_data.pumped_by[#fluid_data.pumped_by + 1] = {class = "offshore_pump", name = name}

    local fluid_name = fluid.name

    if fluid_data then

      local temperature_data = util.build_temperature_data({}, fluid_data, true)

      if temperature_data then

        fluid_proc.add_to_matching_temperatures(
          recipe_book,
          strings,
          metadata,
          fluid_data,
          temperature_data
        )

        fluid_proc.import_properties(
          recipe_book,
          fluid_data,
          temperature_data,
          {["pumped_by"] = {class = "offshore_pump", name = name} },
          true
        )

        fluid_name = fluid_name.."."..temperature_data.string
      end
    end

    recipe_book.offshore_pump[name] = {
      class = "offshore_pump",
      fluid = fluid_name,
      hidden = prototype.has_flag("hidden"),
      prototype_name = name,
      pumping_speed = prototype.pumping_speed,
    }
    util.add_string(strings, {
      dictionary = "offshore_pump",
      internal = name,
      localised = prototype.localised_name
    })
    util.add_string(strings, {
      dictionary = "offshore_pump_description",
      internal = name,
      localised = prototype.localised_description
    })
  end
end
