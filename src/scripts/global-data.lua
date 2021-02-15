local constants = require("constants")

local crafter_proc = require("scripts.processors.crafter")
local fluid_proc = require("scripts.processors.fluid")
local item_proc = require("scripts.processors.item")
local lab_proc = require("scripts.processors.lab")
local offshore_pump_proc = require("scripts.processors.offshore-pump")
local recipe_proc = require("scripts.processors.recipe")
local resource_proc = require("scripts.processors.resource")
local technology_proc = require("scripts.processors.technology")

local global_data = {}

function global_data.init()
  global.flags = {}
  global.players = {}
end

function global_data.build_recipe_book()
  -- the data that will actually be saved and used
  local recipe_book = {
    bonus = {},
    crafter = {},
    fluid = {},
    item = {},
    lab = {},
    offshore_pump = {},
    recipe = {},
    resource = {},
    technology = {}
  }
  -- localised strings for translation
  local strings = {__index = 0}
  -- data that is needed for generation but will not be saved
  local metadata = {}

  crafter_proc(recipe_book, strings, metadata)
  fluid_proc(recipe_book, strings, metadata)
  item_proc(recipe_book, strings, metadata)
  lab_proc(recipe_book, strings)
  offshore_pump_proc(recipe_book, strings)
  recipe_proc(recipe_book, strings, metadata)
  resource_proc(recipe_book, strings)
  technology_proc(recipe_book, strings)

  strings.__index = nil
  global.recipe_book = recipe_book
  global.strings = strings
end

local function update_launch_products(recipe_book, launch_products, force_index, to_value)
  for _, launch_product in ipairs(launch_products) do
    local product_data = recipe_book.item[launch_product.name]
    if product_data.researched_forces then
      product_data.researched_forces[force_index] = to_value
    end
    update_launch_products(recipe_book, product_data.rocket_launch_products, force_index)
  end
end

local function update_recipe(recipe_book, recipe_data, force_index, to_value)
  -- check if the category should be ignored for recipe availability
  local disabled = constants.disabled_recipe_categories[recipe_data.category]
  if disabled and disabled == 0 then return end

  recipe_data.researched_forces[force_index] = to_value

  -- products
  for _, product in ipairs(recipe_data.products) do
    local product_data = recipe_book[product.class][product.name]

    local temperature_data = product_data.temperature_data
    if product_data.temperature_data then
      -- add to matching fluid temperatures
      for _, subfluid_data in pairs(recipe_book.fluid[product_data.prototype_name].temperatures) do
        if fluid_proc.is_within_range(temperature_data, subfluid_data.temperature_data) then
          subfluid_data.researched_forces[force_index] = to_value
        end
      end
    else
      product_data.researched_forces[force_index] = to_value
    end

    if product.class == "item" then
      -- rocket launch products
      update_launch_products(recipe_book, product_data.rocket_launch_products, force_index, to_value)
    end
  end

  -- crafters
  for _, crafter_name in ipairs(recipe_data.associated_crafters) do
    local crafter_data = recipe_book.crafter[crafter_name]
    crafter_data.researched_forces[force_index] = to_value
  end

  -- labs
  for _, lab_name in ipairs(recipe_data.associated_labs) do
    local lab_data = recipe_book.lab[lab_name]
    lab_data.researched_forces[force_index] = to_value
  end
end

function global_data.handle_research_updated(technology, to_value)
  local force_index = technology.force.index
  local recipe_book = global.recipe_book
  -- technology
  local technology_data = recipe_book.technology[technology.name]
  technology_data.researched_forces[force_index] = to_value

  for _, recipe in ipairs(technology_data.associated_recipes) do
    local recipe_data = recipe_book.recipe[recipe.name]
    update_recipe(recipe_book, recipe_data, force_index, to_value)
  end
end

function global_data.check_force_recipes(force)
  local recipe_book = global.recipe_book
  local force_index = force.index
  for name, recipe in pairs(force.recipes) do
    if recipe.enabled then
      local recipe_data = recipe_book.recipe[name]
      if recipe_data.researched_forces then
        update_recipe(recipe_book, recipe_data, force_index, true)
      end
    end
  end
end

function global_data.check_force_technologies(force)
  local force_index = force.index
  local technologies = global.recipe_book.technology
  for name, technology in pairs(force.technologies) do
    if technology.enabled and technology.researched then
      local technology_data = technologies[name]
      if technology_data then
        technology_data.researched_forces[force_index] = true
      end
    end
  end
end

function global_data.check_forces()
  for _, force in pairs(game.forces) do
    global_data.check_force_recipes(force)
    global_data.check_force_technologies(force)
  end
end

return global_data
