local util = require("scripts.util")

return function(recipe_book, strings)
  -- iterate offshore pumps
  for name, prototype in pairs(game.get_filtered_entity_prototypes{{filter = "type", type = "offshore-pump"}}) do
    -- add to material
    local fluid = prototype.fluid
    local fluid_data = recipe_book.fluid[fluid.name]
    if fluid_data then
      fluid_data.pumped_by[#fluid_data.pumped_by + 1] = {class = "offshore-pump", name = name}
    end

    recipe_book.offshore_pump[name] = {
      available_to_all_forces = true,
      class = "offshore_pump",
      fluid = fluid.name,
      hidden = prototype.has_flag("hidden"),
      prototype_name = name,
      pumping_speed = prototype.pumping_speed
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
