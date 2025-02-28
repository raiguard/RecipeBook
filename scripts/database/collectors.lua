local flib_table = require("__flib__.table")

local util = require("scripts.util")

--- @alias DatabaseIDType
--- | "entity"
--- | "equipment"
--- | "fluid"
--- | "item"
--- | "recipe"
--- | "technology"
--- | "tile"

--- @class DatabaseID
--- @field type DatabaseIDType
--- @field name string
--- @field amount number?
--- @field amount_min number?
--- @field amount_max number?
--- @field probability number?
--- @field temperature number?
--- @field minimum_temperature number?
--- @field maximum_temperature number?

--- @class Collectors
local collectors = {}

--- @param prototype LuaRecipePrototype
--- @return DatabaseID[]
function collectors.ingredients(prototype)
  local output = util.unique_id_array()

  for _, ingredient in pairs(prototype.ingredients) do
    output[#output + 1] = {
      type = ingredient.type,
      name = ingredient.name,
      amount = ingredient.amount,
      minimum_temperature = ingredient.minimum_temperature,
      maximum_temperature = ingredient.maximum_temperature,
    }
  end

  return output
end

--- @param prototype LuaRecipePrototype
--- @return DatabaseID[]
function collectors.products(prototype)
  local output = util.unique_id_array()

  for _, product in pairs(prototype.products) do
    if product.type ~= "research-progress" then
      output[#output + 1] = {
        type = product.type,
        name = product.name,
        amount = product.amount,
        amount_min = product.amount_min,
        amount_max = product.amount_max,
        temperature = product.temperature,
      }
    end
  end

  return output
end

--- @param prototype LuaRecipePrototype
--- @return DatabaseID[]
function collectors.made_in(prototype)
  local output = util.unique_id_array()

  --- @diagnostic disable-next-line unused-fields
  for _, character in pairs(prototypes.get_entity_filtered({ { filter = "type", type = "character" } })) do
    if character.crafting_categories[prototype.category] then
      output[#output + 1] = {
        type = "entity",
        name = character.name,
        amount = prototype.energy,
      }
    end
  end

  local item_ingredients = flib_table.reduce(prototype.ingredients, function(accumulator, ingredient)
    return accumulator + (ingredient.type == "item" and 1 or 0)
  end, 0) --[[@as integer]]

  for _, crafter in
    pairs(prototypes.get_entity_filtered({
      --- @diagnostic disable-next-line unused-fields
      { filter = "crafting-category", crafting_category = prototype.category },
    }))
  do
    local ingredient_count = crafter.ingredient_count
    if ingredient_count == 0 or ingredient_count >= item_ingredients then
      output[#output + 1] = {
        type = "entity",
        name = crafter.name,
        amount = prototype.energy / crafter.get_crafting_speed(), -- TODO: Quality
      }
    end
  end

  return output
end

--- @param prototype LuaFluidPrototype|LuaItemPrototype
--- @return DatabaseID[]
function collectors.gathered_from(prototype)
  local output = util.unique_id_array()

  if prototype.object_name == "LuaFluidPrototype" then
    for tile_name, tile in pairs(prototypes.tile) do
      if tile.fluid == prototype then
        output[#output + 1] = { type = "tile", name = tile_name }
      end
    end
  end

  local type = util.object_name_to_type[prototype.object_name]

  for entity_name, entity in pairs(util.get_natural_entities()) do
    if prototype.name ~= entity_name then
      local mineable_properties = entity.mineable_properties
      if mineable_properties.minable then
        for _, product in pairs(mineable_properties.products or {}) do
          if product.type == type and product.name == prototype.name then
            output[#output + 1] = { type = "entity", name = entity_name }
          end
        end
      end
    end
  end

  return output
end

--- @param prototype LuaItemPrototype
--- @return DatabaseID[]
function collectors.rocket_launch_products(prototype)
  local output = util.unique_id_array()

  for _, product in pairs(prototype.rocket_launch_products) do
    if product.type ~= "research-progress" then
      output[#output + 1] = {
        type = product.type,
        name = product.name,
        amount = product.amount,
        amount_min = product.amount_min,
        amount_max = product.amount_max,
        temperature = product.temperature,
      }
    end
  end

  return output
end

--- @param prototype LuaItemPrototype
--- @return DatabaseID[]
function collectors.rocket_launch_product_of(prototype)
  local output = util.unique_id_array()

  --- @diagnostic disable-next-line unused-fields
  for _, other_item in pairs(prototypes.get_item_filtered({ { filter = "has-rocket-launch-products" } })) do
    for _, product in pairs(other_item.rocket_launch_products) do
      if product.name == prototype.name then
        output[#output + 1] = { type = "item", name = other_item.name }
        break
      end
    end
  end

  return output
end

--- @param prototype LuaFluidPrototype
--- @return DatabaseID[]
function collectors.generated_by(prototype)
  local output = util.unique_id_array()

  for _, boiler_prototype in pairs(prototypes.get_entity_filtered({ { filter = "type", type = "boiler" } })) do
    local generates = collectors.generated_fluid(boiler_prototype)
    if generates and generates.name == prototype.name then
      output[#output + 1] = {
        type = "entity",
        name = boiler_prototype.name,
        temperature = boiler_prototype.target_temperature,
      }
    end
  end

  return output
end

--- @param prototype LuaEntityPrototype
--- @return DatabaseID?
function collectors.generated_fluid(prototype)
  if prototype.type ~= "boiler" then
    return
  end

  for _, fluidbox in pairs(prototype.fluidbox_prototypes) do
    if fluidbox.production_type == "output" and fluidbox.filter then
      return { type = "fluid", name = fluidbox.filter.name, temperature = prototype.target_temperature }
    end
  end
end

--- @param prototype LuaEntityPrototype
--- @return DatabaseID[]
function collectors.mined_by(prototype)
  local output = util.unique_id_array()

  local required_fluid = prototype.mineable_properties.required_fluid
  local resource_category = prototype.resource_category
  for _, drill in pairs(prototypes.get_entity_filtered({ { filter = "type", type = "mining-drill" } })) do
    if drill.resource_categories[resource_category] and (not required_fluid or drill.fluidbox_prototypes[1]) then
      output[#output + 1] = { type = "entity", name = drill.name }
    end
  end

  return output
end

--- @param prototype LuaFluidPrototype|LuaItemPrototype
--- @param grouped_recipe LuaRecipePrototype
--- @return DatabaseID[]
function collectors.alternative_recipes(prototype, grouped_recipe)
  local output = util.unique_id_array()
  if prototype.object_name == "LuaFluidPrototype" then
    for _, recipe in
      pairs(prototypes.get_recipe_filtered({
        --- @diagnostic disable-next-line unused-fields
        { filter = "has-product-fluid", elem_filters = { { filter = "name", name = prototype.name } } },
      }))
    do
      if recipe ~= grouped_recipe then
        local id = { type = "recipe", name = recipe.name }
        for _, product in pairs(recipe.products) do
          if product.name == prototype.name and product.temperature then
            id.temperature = product.temperature
            break
          end
        end
        output[#output + 1] = id
      end
    end
  else
    for _, recipe in
      pairs(prototypes.get_recipe_filtered({
        --- @diagnostic disable-next-line unused-fields
        { filter = "has-product-item", elem_filters = { { filter = "name", name = prototype.name } } },
      }))
    do
      if recipe ~= grouped_recipe then
        output[#output + 1] = { type = "recipe", name = recipe.name }
      end
    end
  end

  return output
end

--- @param prototype LuaFluidPrototype|LuaItemPrototype
--- @param grouped_recipe LuaRecipePrototype?
--- @return DatabaseID[]
function collectors.used_in(prototype, grouped_recipe)
  local output = util.unique_id_array()

  if prototype.object_name == "LuaFluidPrototype" then
    for _, recipe in
      pairs(prototypes.get_recipe_filtered({
        --- @diagnostic disable-next-line unused-fields
        { filter = "has-ingredient-fluid", elem_filters = { { filter = "name", name = prototype.name } } },
      }))
    do
      if recipe ~= grouped_recipe then
        local id = { type = "recipe", name = recipe.name }
        for _, ingredient in pairs(recipe.ingredients) do
          -- minimum_temperature and maximum_temperature are mutually inclusive.
          if ingredient.name == prototype.name and ingredient.minimum_temperature then
            id.minimum_temperature = ingredient.minimum_temperature
            id.maximum_temperature = ingredient.maximum_temperature
            break
          end
        end
        output[#output + 1] = id
      end
    end
  else
    for _, recipe in
      pairs(prototypes.get_recipe_filtered({
        --- @diagnostic disable-next-line unused-fields
        { filter = "has-ingredient-item", elem_filters = { { filter = "name", name = prototype.name } } },
      }))
    do
      if recipe ~= grouped_recipe then
        output[#output + 1] = { type = "recipe", name = recipe.name }
      end
    end
  end

  return output
end

--- @param prototype LuaFluidPrototype|LuaItemPrototype
--- @return DatabaseID[]
function collectors.burned_in(prototype)
  local output = util.unique_id_array()

  if prototype.object_name == "LuaFluidPrototype" then
    --- @diagnostic disable-next-line unused-fields
    for entity_name, entity in pairs(prototypes.get_entity_filtered({ { filter = "type", type = "generator" } })) do
      local fluid_box = entity.fluidbox_prototypes[1]
      if
        (fluid_box.filter and fluid_box.filter.name == prototype.name)
        or (not fluid_box.filter and prototype.fuel_value > 0)
      then
        output[#output + 1] = { type = "entity", name = entity_name }
      end
    end
    --- @diagnostic disable-next-line unused-fields
    for entity_name, entity in pairs(prototypes.get_entity_filtered({ { filter = "type", type = "boiler" } })) do
      for _, fluidbox in pairs(entity.fluidbox_prototypes) do
        if
          (fluidbox.production_type == "input" or fluidbox.production_type == "input-output")
          and fluidbox.filter
          and fluidbox.filter.name == prototype.name
        then
          output[#output + 1] = { type = "entity", name = entity_name }
        end
      end
    end
    if prototype.fuel_value then
      --- @diagnostic disable-next-line unused-fields
      for entity_name, entity in pairs(prototypes.get_entity_filtered({ { filter = "building" } })) do
        if entity.fluid_energy_source_prototype then
          output[#output + 1] = { type = "entity", name = entity_name }
        end
      end
    end
  else
    local fuel_category = prototype.fuel_category
    for entity_name, entity_prototype in pairs(prototypes.entity) do
      local burner = entity_prototype.burner_prototype
      if burner and burner.fuel_categories[fuel_category] then
        output[#output + 1] = { type = "entity", name = entity_name }
      end
    end
    for equipment_name, equipment_prototype in pairs(prototypes.equipment) do
      local burner = equipment_prototype.burner_prototype
      if burner and burner.fuel_categories[fuel_category] then
        output[#output + 1] = { type = "equipment", name = equipment_name }
      end
    end
  end

  return output
end

--- @param prototype LuaEntityPrototype
--- @return DatabaseID[]
function collectors.can_mine(prototype)
  local output = util.unique_id_array()

  -- TODO: This isn't working with uranium ore
  --- @type string|boolean?
  local filter
  for _, fluidbox_prototype in pairs(prototype.fluidbox_prototypes) do
    local production_type = fluidbox_prototype.production_type
    if production_type == "input" or production_type == "input-output" then
      filter = fluidbox_prototype.filter and fluidbox_prototype.filter.name or true
      break
    end
  end
  local resource_categories = prototype.resource_categories or {}
  for _, resource in pairs(prototypes.get_entity_filtered({ { filter = "type", type = "resource" } })) do
    local mineable = resource.mineable_properties
    local required_fluid = mineable.required_fluid
    if
      resource_categories[resource.resource_category]
      and (not required_fluid or filter == true or filter == required_fluid)
    then
      output[#output + 1] = { type = "entity", name = resource.name }
    end
  end

  return output
end

--- @param prototype LuaEntityPrototype
--- @return DatabaseID[]
function collectors.can_burn(prototype)
  local output = util.unique_id_array()

  local burner = prototype.burner_prototype
  if burner then
    for category in pairs(burner.fuel_categories) do
      for item_name in
        --- @diagnostic disable-next-line unused-fields
        pairs(prototypes.get_item_filtered({ { filter = "fuel-category", ["fuel-category"] = category } }))
      do
        output[#output + 1] = { type = "item", name = item_name }
      end
    end
  end
  local fluid_energy_source_prototype = prototype.fluid_energy_source_prototype
  if fluid_energy_source_prototype then
    local filter = fluid_energy_source_prototype.fluid_box.filter
    if filter then
      output[#output + 1] = { type = "fluid", name = filter.name }
    else
      for fluid_name in
        --- @diagnostic disable-next-line unused-fields
        pairs(prototypes.get_fluid_filtered({ { filter = "fuel-value", comparison = ">", value = 0 } }))
      do
        output[#output + 1] = { type = "fluid", name = fluid_name }
      end
    end
  end
  if prototype.type == "generator" then
    local fluid_box = prototype.fluidbox_prototypes[1]
    if fluid_box.filter then
      output[#output + 1] = { type = "fluid", name = fluid_box.filter.name }
    else
      for fluid_name in
        --- @diagnostic disable-next-line unused-fields
        pairs(prototypes.get_fluid_filtered({ { filter = "fuel-value", comparison = ">", value = 0 } }))
      do
        output[#output + 1] = { type = "fluid", name = fluid_name }
      end
    end
  end

  return output
end

local yields = {
  ["fish"] = true,
  ["resource"] = true,
  ["simple-entity"] = true,
  ["tree"] = true,
}

--- @param prototype LuaEntityPrototype
--- @param grouped_item LuaItemPrototype?
--- @return DatabaseID[]
function collectors.yields(prototype, grouped_item)
  local output = util.unique_id_array()

  if not yields[prototype.type] then
    return output
  end

  local mineable_properties = prototype.mineable_properties
  if not mineable_properties or not mineable_properties.minable then
    return output
  end

  local products = mineable_properties.products
  if not products then
    return output
  end

  if not (#products == 1 and grouped_item and products[1].type == "item" and products[1].name == grouped_item.name) then
    local products = mineable_properties.products
    if products then
      for _, product in pairs(products) do
        if product.type ~= "research-progress" then
          output[#output + 1] = {
            type = product.type,
            name = product.name,
            amount = product.amount,
            amount_min = product.amount_min,
            amount_max = product.amount_max,
            temperature = product.temperature,
          }
        end
      end
    end
  end

  return output
end

--- @param prototype LuaRecipePrototype
--- @return DatabaseID[]
function collectors.unlocked_by(prototype)
  local output = util.unique_id_array()

  if not prototype.unlock_results or prototype.enabled then
    return output
  end

  for technology_name in
    --- @diagnostic disable-next-line unused-fields
    pairs(prototypes.get_technology_filtered({ { filter = "unlocks-recipe", recipe = prototype.name } }))
  do
    output[#output + 1] = { type = "technology", name = technology_name }
  end

  return output
end

local crafting_entities = {
  ["assembling-machine"] = true,
  ["furnace"] = true,
  ["rocket-silo"] = true,
  ["character"] = true,
}

--- @param prototype LuaEntityPrototype
--- @return DatabaseID[]
function collectors.can_craft(prototype)
  local output = util.unique_id_array()

  if not crafting_entities[prototype.type] then
    return {}
  end

  --- @type RecipePrototypeFilter[]
  local filters = {}
  for category in pairs(prototype.crafting_categories) do
    filters[#filters + 1] = { filter = "category", category = category }
  end
  for _, recipe in pairs(prototypes.get_recipe_filtered(filters)) do
    local item_ingredients = 0
    for _, ingredient in pairs(recipe.ingredients) do
      if ingredient.type == "item" then
        item_ingredients = item_ingredients + 1
      end
    end
    local ingredient_count = prototype.ingredient_count
    if not ingredient_count or ingredient_count >= item_ingredients then
      output[#output + 1] = { type = "recipe", name = recipe.name }
    end
  end

  return output
end

--- @param prototype LuaEntityPrototype
--- @return DatabaseID[]
function collectors.can_extract_from(prototype)
  local output = util.unique_id_array()

  if prototype.type ~= "offshore-pump" then
    return output
  end

  for _, tile_prototype in pairs(prototypes.tile) do
    if tile_prototype.fluid then
      output[#output + 1] = { type = "tile", name = tile_prototype.name }
    end
  end

  return output
end

--- @param prototype LuaTilePrototype
--- @return DatabaseID[]
function collectors.source_of(prototype)
  local output = util.unique_id_array()
  local fluid = prototype.fluid
  if fluid then
    output[#output + 1] = { type = "fluid", name = fluid.name }
  end
  return output
end

--- @param prototype LuaTilePrototype
--- @return DatabaseID[]
function collectors.extracted_by(prototype)
  local output = util.unique_id_array()

  if not prototype.fluid then
    return output
  end

  for _, offshore_pump in pairs(prototypes.get_entity_filtered({ { filter = "type", type = "offshore-pump" } })) do
    output[#output + 1] = { type = "entity", name = offshore_pump.name }
  end

  return output
end

return collectors
