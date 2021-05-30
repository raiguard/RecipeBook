local util = require("scripts.util")

local offshore_pump_proc = {}

function offshore_pump_proc.build(recipe_book, strings)
  -- iterate offshore pumps
  for name, prototype in pairs(game.get_filtered_entity_prototypes{{filter = "type", type = "offshore-pump"}}) do
    -- add to material
    local fluid = prototype.fluid
    local fluid_data = recipe_book.fluid[fluid.name]
    if fluid_data then
      fluid_data.pumped_by[#fluid_data.pumped_by + 1] = {class = "offshore_pump", name = name}
    end

    recipe_book.offshore_pump[name] = {
      class = "offshore_pump",
      fluid = {class = "fluid", name = fluid.name},
      hidden = prototype.has_flag("hidden"),
      placeable_by = util.process_placeable_by(prototype),
      prototype_name = name,
      pumping_speed = prototype.pumping_speed * 60,
      unlocked_by = {}
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

function offshore_pump_proc.check_enabled_at_start(recipe_book)
  for _, data in pairs(recipe_book.offshore_pump) do
    if not data.researched_forces then
      local fluid_data = recipe_book.fluid[data.fluid.name]
      fluid_data.researched_forces = nil
      fluid_data.unlocked_by = {}
    end
  end
end

-- when calling the module directly, call fluid_proc.build
setmetatable(offshore_pump_proc, { __call = function(_, ...) return offshore_pump_proc.build(...) end })

return offshore_pump_proc
