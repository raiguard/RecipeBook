local constants = require("constants")

local crafter_proc = require("scripts.processors.crafter")
local fluid_proc = require("scripts.processors.fluid")
local item_proc = require("scripts.processors.item")
local item_group_proc = require("scripts.processors.item-group")
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
    item_group = {},
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
  item_group_proc(recipe_book, strings)
  lab_proc(recipe_book, strings)
  offshore_pump_proc(recipe_book, strings)
  recipe_proc(recipe_book, strings, metadata)
  resource_proc(recipe_book, strings)

  item_proc.place_results(recipe_book, metadata)

  technology_proc(recipe_book, strings)

  offshore_pump_proc.check_enabled_at_start(recipe_book)

  fluid_proc.process_temperatures(recipe_book, strings, metadata)

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

local function update_recipe(recipe_book, recipe_data, technology_name, force_index, to_value)
  -- check if the category should be ignored for recipe availability
  local disabled = constants.disabled_recipe_categories[recipe_data.category]
  if disabled and disabled == 0 then return end

  recipe_data.researched_forces[force_index] = to_value

  -- products
  for _, product in ipairs(recipe_data.products) do
    local product_data = recipe_book[product.class][product.name]

    if product_data.researched_forces then
      local temperature_ident = product_data.temperature_ident
      if temperature_ident then
        -- Unlock base fluid
        local base_fluid_data = recipe_book.fluid[product_data.prototype_name]
        base_fluid_data.researched_forces[force_index] = to_value

        -- Unlock all temperature variants that have this technology
        -- SLOW: Add a lookup table for unlocked_by so we don't have to iterate them like this
        for _, temperature_data in pairs(base_fluid_data.temperatures) do
          if temperature_data.researched_forces then
            for _, technology_ident in pairs(temperature_data.unlocked_by) do
              if technology_ident.name == technology_name then
                temperature_data.researched_forces[force_index] = to_value
                break
              end
            end
          end
        end
      else
        product_data.researched_forces[force_index] = to_value

        if product.class == "item" then
          -- rocket launch products
          update_launch_products(recipe_book, product_data.rocket_launch_products, force_index, to_value)
        end
      end
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

  -- offshore pumps
  for _, offshore_pump_name in ipairs(recipe_data.associated_offshore_pumps) do
    local offshore_pump_data = recipe_book.offshore_pump[offshore_pump_name]
    offshore_pump_data.researched_forces[force_index] = to_value

    -- research pump fluid if it's not already
    local fluid = offshore_pump_data.fluid
    local fluid_data = recipe_book.fluid[fluid]
    if fluid_data.researched_forces then
      fluid_data.researched_forces[force_index] = to_value
    end
  end
end

function global_data.handle_research_updated(technology, to_value)
  local force_index = technology.force.index
  local recipe_book = global.recipe_book
  -- technology
  local technology_data = recipe_book.technology[technology.name]
  -- other mods can update technologies during on_configuration_changed before RB gets a chance to config change
  if not technology_data then return end
  technology_data.researched_forces[force_index] = to_value

  for _, recipe in ipairs(technology_data.unlocks_recipes) do
    local recipe_data = recipe_book.recipe[recipe.name]
    update_recipe(recipe_book, recipe_data, technology.name, force_index, to_value)
  end
end

function global_data.check_force(force)
  for _, technology in pairs(force.technologies) do
    if technology.enabled and technology.researched then
      global_data.handle_research_updated(technology, true)
    end
  end
end

function global_data.check_forces()
  for _, force in pairs(game.forces) do
    global_data.check_force(force)
  end
end

return global_data
