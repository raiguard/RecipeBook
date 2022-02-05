local dictionary = require("__flib__.dictionary")
dictionary.set_use_local_storage(true)

local constants = require("constants")

local burning = require("scripts.database.burning")
local crafter = require("scripts.database.crafter")
local equipment_category = require("scripts.database.equipment-category")
local equipment = require("scripts.database.equipment")
local fluid = require("scripts.database.fluid")
local fuel_category = require("scripts.database.fuel-category")
local group = require("scripts.database.group")
local item = require("scripts.database.item")
local lab = require("scripts.database.lab")
local machine = require("scripts.database.machine")
local machine_state = require("scripts.database.machine-state")
local mining_drill = require("scripts.database.mining-drill")
local offshore_pump = require("scripts.database.offshore-pump")
local recipe_category = require("scripts.database.recipe-category")
local recipe = require("scripts.database.recipe")
local resource_category = require("scripts.database.resource-category")
local resource = require("scripts.database.resource")
local technology = require("scripts.database.technology")

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

  equipment_category(database, dictionaries)
  fuel_category(database, dictionaries)
  group(database, dictionaries)
  recipe_category(database, dictionaries)
  resource_category(database, dictionaries)

  equipment(database, dictionaries)

  crafter(database, dictionaries, metadata)
  machine(database, dictionaries)
  mining_drill(database, dictionaries)

  fluid(database, dictionaries, metadata)
  item(database, dictionaries, metadata)

  lab(database, dictionaries)
  offshore_pump(database, dictionaries)

  recipe(database, dictionaries, metadata)
  resource(database, dictionaries)
  technology(database, dictionaries, metadata)

  offshore_pump.check_enabled_at_start(database)
  fluid.process_temperatures(database, dictionaries, metadata)
  mining_drill.add_resources(database)
  fuel_category.check_fake_category(database, dictionaries)

  burning(database)
  machine_state(database)

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

  for _, objects in
    pairs({
      technology_data.unlocks_equipment,
      technology_data.unlocks_fluids,
      technology_data.unlocks_items,
      technology_data.unlocks_machines,
      technology_data.unlocks_recipes,
    })
  do
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
