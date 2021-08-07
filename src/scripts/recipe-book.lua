local dictionary = require("__flib__.dictionary")
dictionary.set_use_local_storage(true)

local constants = require("constants")

local crafter_proc = require("scripts.processors.crafter")
local fluid_proc = require("scripts.processors.fluid")
local fuel_category_proc = require("scripts.processors.fuel-category")
local group_proc = require("scripts.processors.group")
local item_proc = require("scripts.processors.item")
local lab_proc = require("scripts.processors.lab")
local mining_drill_proc = require("scripts.processors.mining-drill")
local offshore_pump_proc = require("scripts.processors.offshore-pump")
local recipe_category_proc = require("scripts.processors.recipe-category")
local recipe_proc = require("scripts.processors.recipe")
local resource_category_proc = require("scripts.processors.resource-category")
local resource_proc = require("scripts.processors.resource")
local technology_proc = require("scripts.processors.technology")

local recipe_book = {}

function recipe_book.build()
  -- Create class tables
  for _, class in pairs(constants.classes) do
    recipe_book[class] = {}
  end

  -- Dictionaries for translation
  local dictionaries = {}
  for _, class in pairs(constants.classes) do
    dictionaries[class] = dictionary.new(class, true)
    local desc_name = class.."_description"
    dictionaries[desc_name] = dictionary.new(desc_name)
  end
  dictionary.new("gui", true, constants.gui_strings)

  -- Data that is needed for generation but will not be saved
  local metadata = {}

  fuel_category_proc(recipe_book, dictionaries)
  group_proc(recipe_book, dictionaries)
  recipe_category_proc(recipe_book, dictionaries)
  resource_category_proc(recipe_book, dictionaries)

  crafter_proc(recipe_book, dictionaries, metadata)
  fluid_proc(recipe_book, dictionaries, metadata)
  item_proc(recipe_book, dictionaries, metadata)
  lab_proc(recipe_book, dictionaries)
  mining_drill_proc(recipe_book, dictionaries)
  offshore_pump_proc(recipe_book, dictionaries)
  recipe_proc(recipe_book, dictionaries, metadata)
  resource_proc(recipe_book, dictionaries)
  technology_proc(recipe_book, dictionaries, metadata)

  offshore_pump_proc.check_enabled_at_start(recipe_book)
  fluid_proc.process_temperatures(recipe_book, dictionaries, metadata)
  mining_drill_proc.add_resources(recipe_book)
  fuel_category_proc.check_fake_category(recipe_book, dictionaries)
end

local function update_launch_products(launch_products, force_index, to_value)
  for _, launch_product in ipairs(launch_products) do
    local product_data = recipe_book.item[launch_product.name]
    if product_data.researched_forces then
      product_data.researched_forces[force_index] = to_value
    end
    update_launch_products(recipe_book, product_data.rocket_launch_products, force_index)
  end
end

function recipe_book.handle_research_updated(technology, to_value)
  local force_index = technology.force.index
  -- Technology
  local technology_data = recipe_book.technology[technology.name]
  -- Other mods can update technologies during on_configuration_changed before RB gets a chance to config change
  if not technology_data then return end
  technology_data.researched_forces[force_index] = to_value

  for _, objects in pairs{
    technology_data.unlocks_fluids,
    technology_data.unlocks_items,
    technology_data.unlocks_machines,
    technology_data.unlocks_recipes
  } do
    for _, obj_ident in ipairs(objects) do
      local class = obj_ident.class
      local obj_data = recipe_book[class][obj_ident.name]

      -- Unlock this object
      if obj_data.researched_forces then
        obj_data.researched_forces[force_index] = to_value
      end

      if class == "fluid" and obj_data.temperature_ident then
        -- Unlock base fluid
        local base_fluid_data = recipe_book.fluid[obj_data.prototype_name]
        if base_fluid_data.researched_forces then
          base_fluid_data.researched_forces[force_index] = to_value
        end
      elseif class == "item" then
        -- Unlock rocket launch products
        update_launch_products(obj_data.rocket_launch_products, force_index, to_value)
      elseif class == "offshore_pump" then
        -- Unlock pumped fluid
        local fluid = obj_data.fluid
        local fluid_data = recipe_book.fluid[fluid.name]
        if fluid_data.researched_forces then
          fluid_data.researched_forces[force_index] = to_value
        end
      end
    end
  end
end

function recipe_book.check_force(force)
  for _, technology in pairs(force.technologies) do
    if technology.enabled and technology.researched then
      recipe_book.handle_research_updated(technology, true)
    end
  end
end

function recipe_book.check_forces()
  for _, force in pairs(global.forces) do
    recipe_book.check_force(force)
  end
end

return recipe_book
