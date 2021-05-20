local table = require("__flib__.table")

local util = require("scripts.util")

local item_proc = {}

function item_proc.build(recipe_book, strings, metadata)
  local place_results = {}
  local rocket_launch_payloads = {}

  for name, prototype in pairs(game.item_prototypes) do
    -- Group
    local group = prototype.group
    local group_data = recipe_book.group[group.name]
    group_data.items[#group_data.items + 1] = {class = "item", name = name}
    -- Rocket launch products
    local launch_products = {}
    for i, product in ipairs(prototype.rocket_launch_products or {}) do
      -- Add to products table w/ amount string
      local amount_string, quick_ref_amount_string = util.build_amount_string(product)
      launch_products[i] = {
        class = product.type,
        name = product.name,
        amount_string = amount_string,
        quick_ref_amount_string = quick_ref_amount_string
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
      place_result = place_result.name
      place_results[name] = place_result
    end

    local fuel_value = prototype.fuel_value
    local has_fuel_value = prototype.fuel_value > 0
    local fuel_acceleration_multiplier = prototype.fuel_acceleration_multiplier
    local fuel_emissions_multiplier = prototype.fuel_emissions_multiplier
    local fuel_top_speed_multiplier = prototype.fuel_top_speed_multiplier

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
    util.add_string(strings, {dictionary = "item", internal = name, localised = prototype.localised_name})
    util.add_string(strings, {
      dictionary = "item_description",
      internal = name,
      localised = prototype.localised_description
    })
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

  metadata.place_results = place_results
end

function item_proc.place_results(recipe_book, metadata)
  for item_name, result_name in pairs(metadata.place_results) do
    local result_data = recipe_book.crafter[result_name]
      or recipe_book.lab[result_name]
      or recipe_book.offshore_pump[result_name]
    if result_data then
      result_data.placeable_by[#result_data.placeable_by + 1] = {class = "item", name = item_name}
    -- FIXME: What was this used for?
    -- else
    --   place_result = nil
    end
  end
end

-- When calling the module directly, call fluid_proc.build
setmetatable(item_proc, { __call = function(_, ...) return item_proc.build(...) end })

return item_proc
