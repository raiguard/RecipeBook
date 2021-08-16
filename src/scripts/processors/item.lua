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

    local burnt_result = prototype.burnt_result
    if burnt_result then
      burnt_result = {class = "item", name = burnt_result.name}
    end

    local fuel_value = prototype.fuel_value
    local has_fuel_value = prototype.fuel_value > 0
    local fuel_acceleration_multiplier = prototype.fuel_acceleration_multiplier
    local fuel_emissions_multiplier = prototype.fuel_emissions_multiplier
    local fuel_top_speed_multiplier = prototype.fuel_top_speed_multiplier

    local module_effects = {}
    if prototype.type == "module" then
      -- Add to internal list of modules
      modules[name] = table.invert(prototype.limitations)
      -- Process effects
      for effect_name, effect in pairs(prototype.module_effects or {}) do
        module_effects[#module_effects + 1] = {
          type = "plain",
          label = effect_name.."_bonus",
          value = effect.bonus,
          formatter = "percent",
        }
      end
      -- Process which crafters this module is compatible with
      for crafter_name, crafter_data in pairs(recipe_book.crafter) do
        local allowed_effects = metadata.allowed_effects[crafter_name]
        local compatible = true
        if allowed_effects then
          for effect_name in pairs(prototype.module_effects or {}) do
            if not allowed_effects[effect_name] then
              compatible = false
              break
            end
          end
        end
        if compatible then
          crafter_data.compatible_modules[#crafter_data.compatible_modules + 1] = {class = "item", name = name}
        end
      end
    end

    local fuel_category = util.convert_to_ident("fuel_category", prototype.fuel_category)
    if fuel_category then
      local items = recipe_book.fuel_category[fuel_category.name].items
      items[#items + 1] = {class = "item", name = name}
    end

    recipe_book.item[name] = {
      burned_in = {},
      burnt_result = burnt_result,
      burnt_result_of = {},
      class = "item",
      fuel_acceleration_multiplier = has_fuel_value
        and fuel_acceleration_multiplier ~= 1
        and fuel_acceleration_multiplier
        or nil,
      fuel_category = fuel_category,
      fuel_emissions_multiplier = has_fuel_value
        and fuel_emissions_multiplier ~= 1
        and fuel_emissions_multiplier
        or nil,
      fuel_top_speed_multiplier = has_fuel_value
        and fuel_top_speed_multiplier ~= 1
        and fuel_top_speed_multiplier
        or nil,
      fuel_value = has_fuel_value and fuel_value or nil,
      group = {class = "group", name = group.name},
      hidden = prototype.has_flag("hidden"),
      ingredient_in = {},
      mined_from = {},
      module_category = util.convert_to_ident("module_category", prototype.category),
      module_effects = module_effects,
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

function item_proc.process_burned_in(recipe_book)
  -- Iterate machines
  for _, machine_class in pairs(constants.machine_classes) do
    for machine_name, machine_data in pairs(recipe_book[machine_class]) do
      -- Burned in
      local compatible_fuels = machine_data.compatible_fuels
      for i, category_ident in pairs(machine_data.fuel_categories or {}) do
        local category_data = recipe_book.fuel_category[category_ident.name]
        if category_data then
          -- Add fluids and items to the compatible fuels, and add the machine to the material's burned in table
          for _, objects in pairs{category_data.fluids, category_data.items} do
            for _, obj_ident in pairs(objects) do
              local obj_data = recipe_book[obj_ident.class][obj_ident.name]
              obj_data.burned_in[#obj_data.burned_in + 1] = {class = machine_class, name = machine_name}
              compatible_fuels[#compatible_fuels + 1] = table.shallow_copy(obj_ident)
            end
          end
        else
          -- Remove this category from the machine
          table.remove(machine_data.fuel_categories, i)
        end
      end

      -- Hidden / disabled for machines
      local placed_by_len = #(machine_data.placed_by or {})
      if placed_by_len == 0 then
        machine_data.enabled = false
      elseif placed_by_len == 1 then
        local item_ident = machine_data.placed_by[1]
        local item_data = recipe_book.item[item_ident.name]
        if item_data.hidden then
          machine_data.hidden = true
        end
      end
    end
  end

  -- Iterate items
  for item_name, item_data in pairs(recipe_book.item) do
    local burnt_result = item_data.burnt_result
    if burnt_result then
      local result_data = recipe_book.item[burnt_result.name]
      result_data.burnt_result_of[#result_data.burnt_result_of + 1] = {class = "item", name = item_name}
    end
  end
end

-- When calling the module directly, call fluid_proc.build
setmetatable(item_proc, { __call = function(_, ...) return item_proc.build(...) end })

return item_proc
