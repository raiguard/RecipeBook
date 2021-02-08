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

  -- CRAFTERS
  crafter_proc(recipe_book, strings, metadata)
  -- FLUIDS
  fluid_proc(recipe_book, strings)
  -- ITEMS
  item_proc(recipe_book, strings, metadata)
  -- LABS
  lab_proc(recipe_book, strings)
  -- OFFSHORE PUMPS
  offshore_pump_proc(recipe_book, strings)
  -- RECIPES
  recipe_proc(recipe_book, strings, metadata)
  -- RESOURCES
  resource_proc(recipe_book, strings)
  -- TECHNOLOGIES
  technology_proc(recipe_book, strings)

  for _, class in ipairs{"fluid", "item"} do
    for _, material_data in pairs(recipe_book[class]) do
      if #material_data.unlocked_by == 0 then
        -- set unlocked by default
        material_data.available_to_forces = nil
        material_data.available_to_all_forces = true
      end
    end
  end

  strings.__index = nil
  global.recipe_book = recipe_book
  global.strings = strings
end

local function unlock_launch_products(recipe_book, launch_products, force_index)
  for _, launch_product in ipairs(launch_products) do
    local product_data = recipe_book.item[launch_product.name]
    if product_data.available_to_forces then
      product_data.available_to_forces[force_index] = true
    end
    unlock_launch_products(recipe_book, product_data.rocket_launch_products, force_index)
  end
end

local function set_recipe_available(recipe_book, recipe_data, force_index)
  -- check if the category should be ignored for recipe availability
  local disabled = constants.disabled_recipe_categories[recipe_data.category]
  if disabled and disabled == 0 then return end

  recipe_data.available_to_forces[force_index] = true

  for _, product in ipairs(recipe_data.products) do
    local product_data = recipe_book[product.class][product.name]

    local temperature_data = product_data.temperature_data
    if product_data.temperature_data then
      -- add to matching fluid temperatures
      for _, subfluid_data in pairs(recipe_book.fluid[product_data.prototype_name].temperatures) do
        if
          fluid_proc.is_within_range(temperature_data, subfluid_data.temperature_data)
          and subfluid_data.available_to_forces
        then
          subfluid_data.available_to_forces[force_index] = true
        end
      end
    elseif product_data.available_to_forces then
      product_data.available_to_forces[force_index] = true
    end

    if product.class == "item" then
      -- crafter / lab
      local place_result = product_data.place_result
      if place_result then
        local entity_data = recipe_book.crafter[place_result] or recipe_book.lab[place_result]
        if entity_data and entity_data.available_to_forces then
          entity_data.available_to_forces[force_index] = true
        end
      end

      -- rocket launch products
      unlock_launch_products(recipe_book, product_data.rocket_launch_products, force_index)
    end
  end
end

function global_data.handle_research_finished(technology)
  local force_index = technology.force.index
  local recipe_book = global.recipe_book
  -- technology
  local technology_data = recipe_book.technology[technology.name]
  technology_data.researched_forces[force_index] = true

  for _, recipe_name in ipairs(technology_data.associated_recipes) do
    local recipe_data = recipe_book.recipe[recipe_name]
    set_recipe_available(recipe_book, recipe_data, force_index)
  end
end

function global_data.check_force_recipes(force)
  local recipe_book = global.recipe_book
  local force_index = force.index
  for name, recipe in pairs(force.recipes) do
    if recipe.enabled then
      local recipe_data = recipe_book.recipe[name]
      if recipe_data then
        set_recipe_available(recipe_book, recipe_data, force_index)
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
