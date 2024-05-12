local boiler = table.deepcopy(data.raw.boiler.boiler)
boiler.name = "heating-boiler"
boiler.mode = "heat-water-inside"
boiler.target_temperature = 100
data:extend({ boiler })

data:extend({
  {
    type = "custom-input",
    name = "rb-debug-toggle-entity-selection",
    key_sequence = "ALT + K",
  },
})
