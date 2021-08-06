local table = require("__flib__.table")

local constants = require("constants")

local util = require("scripts.util")

local item_proc = {}

function item_proc.build(recipe_book, dictionaries, metadata)
  local modules = {}
  local place_results = {}
  local rocket_launch_payloads = {}

  for name, prototype in pairs(global.prototypes.item) do
    -- Group
    local group = prototype.group
    local group_data = recipe_book.group[group.name]
    group_data.items[#group_data.items + 1] = {class = "item", name = name}
    -- Rocket launch products
    local launch_products = {}
    for i, product in ipairs(prototype.rocket_launch_products or {}) do
      -- Add to products table w/ amount string
      local amount_ident = util.build_amount_ident(product)
      launch_products[i] = {
        class = product.type,
        name = product.name,
        amount_ident = amount_ident
      }
      -- Add to payloads table
      local product_payloads = rocket_launch_payloads[product.name]
      local ident = {class = "item", name = name}
      if product_payloads then
        product_payloads[#product_payloads + 1] = ident
      else
        rocket_launch_payloads[product.name] = {ident}
      end
    end
    local default_categories = util.unique_string_array(
      #launch_products > 0 and table.shallow_copy(metadata.rocket_silo_categories) or {}
    )

    local place_result = prototype.place_result
    if place_result then
      local class = constants.derived_type_to_class[place_result.type]
      if class then
        place_result = {class = class, name = place_result.name}
        place_results[name] = place_result
      else
        place_result = nil
      end
    end

    local fuel_value = prototype.fuel_value
    local has_fuel_value = prototype.fuel_value > 0
    local fuel_acceleration_multiplier = prototype.fuel_acceleration_multiplier
    local fuel_emissions_multiplier = prototype.fuel_emissions_multiplier
    local fuel_top_speed_multiplier = prototype.fuel_top_speed_multiplier

    local module_limitations = {}
    if prototype.type == "module" then
      -- Add to internal list of modules
      modules[name] = table.invert(prototype.limitations)
      -- Add to module category
      local module_category = prototype.category
      local category_data = recipe_book.module_category[module_category]
      category_data.modules[#category_data.modules + 1] = {class = "item", name = name}
    end

    recipe_book.item[name] = {
      class = "item",
      fuel_acceleration_multiplier = (
        has_fuel_value
        and fuel_acceleration_multiplier ~= 1
        and fuel_acceleration_multiplier
        or nil
      ),
      fuel_emissions_multiplier = (
        has_fuel_value
        and fuel_emissions_multiplier ~= 1
        and fuel_emissions_multiplier
        or nil
      ),
      fuel_top_speed_multiplier = (
        has_fuel_value
        and fuel_top_speed_multiplier ~= 1
        and fuel_top_speed_multiplier
        or nil
      ),
      fuel_value = has_fuel_value and fuel_value or nil,
      group = {class = "group", name = group.name},
      hidden = prototype.has_flag("hidden"),
      ingredient_in = {},
      mined_from = {},
      module_category = util.convert_to_ident("module_category", prototype.category),
      module_effects = prototype.module_effects,
      place_result = place_result,
      product_of = {},
      prototype_name = name,
      recipe_categories = default_categories,
      rocket_launch_payloads = {},
      rocket_launch_products = launch_products,
      researched_in = {},
      stack_size = prototype.stack_size,
      unlocked_by = util.unique_obj_array()
    }
    dictionaries.item:add(name, prototype.localised_name)
    dictionaries.item_description:add(name, prototype.localised_description)
  end

  -- Add rocket launch payloads to their material tables
  for product, payloads in pairs(rocket_launch_payloads) do
    local product_data = recipe_book.item[product]
    product_data.rocket_launch_payloads = table.array_copy(payloads)
    for i = 1, #payloads do
      local payload = payloads[i]
      local payload_data = recipe_book.item[payload.name]
      local payload_unlocked_by = payload_data.unlocked_by
      for j = 1, #payload_unlocked_by do
        product_data.unlocked_by[#product_data.unlocked_by + 1] = payload_unlocked_by[j]
      end
    end
  end

  metadata.modules = modules
  metadata.place_results = place_results
end

-- When calling the module directly, call fluid_proc.build
setmetatable(item_proc, { __call = function(_, ...) return item_proc.build(...) end })

return item_proc
