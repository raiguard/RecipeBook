local util = require("scripts.util")

local offshore_pump_proc = {}

function offshore_pump_proc.build(database, dictionaries)
  -- Iterate offshore pumps
  for name, prototype in pairs(global.prototypes.offshore_pump) do
    -- Add to material
    local fluid = prototype.fluid
    local fluid_data = database.fluid[fluid.name]
    if fluid_data then
      fluid_data.pumped_by[#fluid_data.pumped_by + 1] = { class = "offshore_pump", name = name }
    end

    database.machine[name] = {
      class = "machine",
      enabled = true,
      fluid = { class = "fluid", name = fluid.name },
      hidden = prototype.has_flag("hidden"),
      placed_by = util.process_placed_by(prototype),
      prototype_name = name,
      pumping_speed = prototype.pumping_speed * 60,
      size = util.get_size(prototype),
      unlocked_by = {},
    }
    dictionaries.machine:add(name, prototype.localised_name)
    dictionaries.machine_description:add(name, prototype.localised_description)
  end
end

function offshore_pump_proc.check_enabled_at_start(database)
  for name in pairs(global.prototypes.offshore_pump) do
    local pump_data = database.machine[name]
    if not pump_data.researched_forces then
      local fluid_data = database.fluid[pump_data.fluid.name]
      fluid_data.researched_forces = nil
      fluid_data.unlocked_by = {}
    end
  end
end

-- When calling the module directly, call fluid_proc.build
setmetatable(offshore_pump_proc, {
  __call = function(_, ...)
    return offshore_pump_proc.build(...)
  end,
})

return offshore_pump_proc
