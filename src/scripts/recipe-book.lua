local constants = require("constants")

local crafter_proc = require("scripts.processors.crafter")
local fluid_proc = require("scripts.processors.fluid")
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

  -- localised strings for translation
  local strings = {__index = 0}
  -- data that is needed for generation but will not be saved
  local metadata = {}

  group_proc(recipe_book, strings)
  recipe_category_proc(recipe_book, strings)
  resource_category_proc(recipe_book, strings)

  crafter_proc(recipe_book, strings, metadata)
  fluid_proc(recipe_book, strings, metadata)
  item_proc(recipe_book, strings, metadata)
  lab_proc(recipe_book, strings)
  mining_drill_proc(recipe_book, strings)
  offshore_pump_proc(recipe_book, strings)
  recipe_proc(recipe_book, strings, metadata)
  resource_proc(recipe_book, strings)
  technology_proc(recipe_book, strings, metadata)

  offshore_pump_proc.check_enabled_at_start(recipe_book)

  fluid_proc.process_temperatures(recipe_book, strings, metadata)

  mining_drill_proc.add_resources(recipe_book)

  strings.__index = nil
  global.recipe_book = recipe_book
  global.strings = strings
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
        base_fluid_data.researched_forces[force_index] = to_value
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
  for _, force in pairs(game.forces) do
    recipe_book.check_force(force)
  end
end


return recipe_book
