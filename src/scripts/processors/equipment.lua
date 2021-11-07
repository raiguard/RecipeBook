local table = require("__flib__.table")

local util = require("scripts.util")

local equipment_proc = {}

-- WORKAROUND: Many equipment propertis will error if you call them on the wrong kind of equipment
local function pget(prototype, name)
  local success, property = pcall(function()
    return prototype[name]
  end)
  if success then
    return property
  end
end

local function get_equipment_property(properties, prototype, name, formatter, label)
  local value = pget(prototype, name)
  if value and value > 0 then
    table.insert(properties, {
      type = "plain",
      label = label or name,
      value = value,
      formatter = formatter,
    })
  end
end

function equipment_proc.build(recipe_book, dictionaries)
  for name, prototype in pairs(global.prototypes.equipment) do
    local fuel_categories
    local burner = prototype.burner_prototype
    if burner then
      fuel_categories = util.convert_categories(burner.fuel_categories, "fuel_category")
    end

    for _, category in pairs(prototype.equipment_categories) do
      local category_data = recipe_book.equipment_category[category]
      category_data.equipment[#category_data.equipment + 1] = { class = "equipment", name = name }
    end

    local properties = {}
    get_equipment_property(properties, prototype, "energy_consumption", "energy")
    get_equipment_property(properties, prototype, "energy_production", "energy")
    get_equipment_property(properties, prototype, "shield", "number", "shield_points")
    get_equipment_property(properties, prototype, "energy_per_shield", "energy_storage", "energy_per_shield_point")
    get_equipment_property(properties, prototype, "movement_bonus", "percent")

    local logistic_parameters = pget(prototype, "logistic_parameters")
    if logistic_parameters then
      get_equipment_property(properties, logistic_parameters, "logistic_radius", "number")
      get_equipment_property(properties, logistic_parameters, "construction_radius", "number")
      get_equipment_property(properties, logistic_parameters, "robot_limit", "number")
      get_equipment_property(properties, logistic_parameters, "charging_energy", "energy")
    end

    recipe_book.equipment[name] = {
      class = "equipment",
      compatible_fuels = {},
      fuel_categories = fuel_categories,
      enabled = true,
      equipment_categories = table.map(prototype.equipment_categories, function(category)
        return { class = "equipment_category", name = category }
      end),
      equipment_properties = properties,
      hidden = false,
      placed_by = {},
      prototype_name = name,
      size = prototype.shape and prototype.shape.width or nil, -- Equipments can have irregular shapes
      take_result = prototype.take_result and { class = "item", name = prototype.take_result.name } or nil,
      unlocked_by = {},
    }
    dictionaries.equipment:add(name, prototype.localised_name)
    dictionaries.equipment_description:add(name, prototype.localised_description)
  end
end

-- When calling the module directly, call equipment_proc.build
setmetatable(equipment_proc, {
  __call = function(_, ...)
    return equipment_proc.build(...)
  end,
})

return equipment_proc
