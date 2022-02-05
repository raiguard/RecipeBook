local dictionary = require("__flib__.dictionary")
dictionary.set_use_local_storage(true)

local constants = require("constants")

local burning_proc = require("scripts.processors.burning")
local crafter_proc = require("scripts.processors.crafter")
local equipment_category_proc = require("scripts.processors.equipment-category")
local equipment_proc = require("scripts.processors.equipment")
local fluid_proc = require("scripts.processors.fluid")
local fuel_category_proc = require("scripts.processors.fuel-category")
local group_proc = require("scripts.processors.group")
local item_proc = require("scripts.processors.item")
local lab_proc = require("scripts.processors.lab")
local machine_proc = require("scripts.processors.machine")
local machine_state_proc = require("scripts.processors.machine-state")
local mining_drill_proc = require("scripts.processors.mining-drill")
local offshore_pump_proc = require("scripts.processors.offshore-pump")
local recipe_category_proc = require("scripts.processors.recipe-category")
local recipe_proc = require("scripts.processors.recipe")
local resource_category_proc = require("scripts.processors.resource-category")
local resource_proc = require("scripts.processors.resource")
local technology_proc = require("scripts.processors.technology")

local database = {}

function database.build()
  -- Create class tables
  for _, class in pairs(constants.classes) do
    database[class] = {}
  end

  -- Dictionaries for translation
  local dictionaries = {}
  for _, class in pairs(constants.classes) do
    dictionaries[class] = dictionary.new(class, true)
    local desc_name = class .. "_description"
    dictionaries[desc_name] = dictionary.new(desc_name)
  end
  dictionary.new("gui", true, constants.gui_strings)

  -- Data that is needed for generation but will not be saved
  local metadata = {}

  equipment_category_proc(database, dictionaries)
  fuel_category_proc(database, dictionaries)
  group_proc(database, dictionaries)
  recipe_category_proc(database, dictionaries)
  resource_category_proc(database, dictionaries)

  equipment_proc(database, dictionaries)

  crafter_proc(database, dictionaries, metadata)
  machine_proc(database, dictionaries)
  mining_drill_proc(database, dictionaries)

  fluid_proc(database, dictionaries, metadata)
  item_proc(database, dictionaries, metadata)

  lab_proc(database, dictionaries)
  offshore_pump_proc(database, dictionaries)

  recipe_proc(database, dictionaries, metadata)
  resource_proc(database, dictionaries)
  technology_proc(database, dictionaries, metadata)

  offshore_pump_proc.check_enabled_at_start(database)
  fluid_proc.process_temperatures(database, dictionaries, metadata)
  mining_drill_proc.add_resources(database)
  fuel_category_proc.check_fake_category(database, dictionaries)

  burning_proc(database)
  machine_state_proc(database)

  database.generated = true
end

local function update_launch_products(launch_products, force_index, to_value)
  for _, launch_product in ipairs(launch_products) do
    local product_data = database.item[launch_product.name]
    if product_data.researched_forces then
      product_data.researched_forces[force_index] = to_value
    end
    update_launch_products(database, product_data.rocket_launch_products, force_index)
  end
end

function database.handle_research_updated(technology, to_value)
  local force_index = technology.force.index
  -- Technology
  local technology_data = database.technology[technology.name]
  -- Other mods can update technologies during on_configuration_changed before RB gets a chance to config change
  if not technology_data then
    return
  end
  technology_data.researched_forces[force_index] = to_value

  for _, objects in pairs({
    technology_data.unlocks_equipment,
    technology_data.unlocks_fluids,
    technology_data.unlocks_items,
    technology_data.unlocks_machines,
    technology_data.unlocks_recipes,
  }) do
    for _, obj_ident in ipairs(objects) do
      local class = obj_ident.class
      local obj_data = database[class][obj_ident.name]

      -- Unlock this object
      if obj_data.researched_forces then
        obj_data.researched_forces[force_index] = to_value
      end

      if class == "fluid" and obj_data.temperature_ident then
        -- Unlock base fluid
        local base_fluid_data = database.fluid[obj_data.prototype_name]
        if base_fluid_data.researched_forces then
          base_fluid_data.researched_forces[force_index] = to_value
        end
      elseif class == "item" then
        -- Unlock rocket launch products
        update_launch_products(obj_data.rocket_launch_products, force_index, to_value)
      elseif class == "offshore_pump" then
        -- Unlock pumped fluid
        local fluid = obj_data.fluid
        local fluid_data = database.fluid[fluid.name]
        if fluid_data.researched_forces then
          fluid_data.researched_forces[force_index] = to_value
        end
      end
    end
  end
end

function database.check_force(force)
  for _, technology in pairs(force.technologies) do
    if technology.enabled and technology.researched then
      database.handle_research_updated(technology, true)
    end
  end
end

function database.check_forces()
  for _, force in pairs(global.forces) do
    database.check_force(force)
  end
end

return database
