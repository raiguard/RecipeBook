local flib_table = require("__flib__/table")

local util = require("__RecipeBook__/scripts/util")

--- @class EntryProperties
--- @field entry PrototypeEntry
--- @field hidden boolean?
--- @field researched boolean?
--- @field crafting_time double?
--- @field ingredients GenericObject[]?
--- @field products GenericObject[]?
--- @field made_in GenericObject[]?
--- @field ingredient_in GenericObject[]?
--- @field product_of GenericObject[]?
--- @field can_craft GenericObject[]?
--- @field mined_by GenericObject[]?
--- @field can_mine GenericObject[]?
--- @field burned_in GenericObject[]?
--- @field can_burn GenericObject[]?
--- @field placeable_by GenericObject[]?
--- @field unlocked_by GenericObject[]?

--- @param prototype GenericPrototype
--- @return PrototypeEntry?
local function get_entry(prototype)
  local type = util.prototype_type[prototype.object_name]
  if type then
    return global.database[type .. "/" .. prototype.name]
  end
end

--- @param properties EntryProperties
--- @param recipe LuaRecipePrototype
local function add_recipe_properties(properties, recipe)
  properties.ingredients = recipe.ingredients
  properties.products = recipe.products

  local item_ingredients = 0
  for _, ingredient in pairs(recipe.ingredients) do
    if ingredient.type == "item" then
      item_ingredients = item_ingredients + 1
    end
  end

  properties.crafting_time = recipe.energy

  properties.made_in = {}
  --- @diagnostic disable-next-line unused-fields
  for _, character in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "character" } })) do
    if character.crafting_categories[recipe.category] then
      table.insert(properties.made_in, {
        type = "entity",
        name = character.name,
        count = recipe.energy,
      })
    end
  end
  for _, crafter in
    pairs(game.get_filtered_entity_prototypes({
      --- @diagnostic disable-next-line unused-fields
      { filter = "crafting-category", crafting_category = recipe.category },
    }))
  do
    local ingredient_count = crafter.ingredient_count
    if get_entry(crafter) and (ingredient_count == 0 or ingredient_count >= item_ingredients) then
      table.insert(properties.made_in, {
        type = "entity",
        name = crafter.name,
        count = recipe.energy / crafter.crafting_speed,
      })
    end
  end

  properties.unlocked_by = {}
  for technology_name in
    --- @diagnostic disable-next-line unused-fields
    pairs(game.get_filtered_technology_prototypes({ { filter = "unlocks-recipe", recipe = recipe.name } }))
  do
    properties.unlocked_by[#properties.unlocked_by + 1] = { type = "technology", name = technology_name }
  end
end

--- @param properties EntryProperties
--- @param fluid LuaFluidPrototype
local function add_fluid_properties(properties, fluid)
  properties.ingredient_in = {}
  for _, recipe in
    pairs(game.get_filtered_recipe_prototypes({
      --- @diagnostic disable-next-line unused-fields
      { filter = "has-ingredient-fluid", elem_filters = { { filter = "name", name = fluid.name } } },
    }))
  do
    if get_entry(recipe) then
      table.insert(properties.ingredient_in, { type = "recipe", name = recipe.name })
    end
  end
  properties.product_of = {}
  local product_of_recipes = game.get_filtered_recipe_prototypes({
    --- @diagnostic disable-next-line unused-fields
    { filter = "has-product-fluid", elem_filters = { { filter = "name", name = fluid.name } } },
  })
  for _, recipe in pairs(product_of_recipes) do
    if get_entry(recipe) then
      table.insert(properties.product_of, { type = "recipe", name = recipe.name })
    end
  end

  properties.burned_in = {}
  --- @diagnostic disable-next-line unused-fields
  for entity_name, entity in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "generator" } })) do
    local fluid_box = entity.fluidbox_prototypes[1]
    if
      (fluid_box.filter and fluid_box.filter.name == fluid.name) or (not fluid_box.filter and fluid.fuel_value > 0)
    then
      table.insert(properties.burned_in, { type = "entity", name = entity_name })
    end
  end
  --- @diagnostic disable-next-line unused-fields
  for entity_name, entity in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "boiler" } })) do
    for _, fluidbox in pairs(entity.fluidbox_prototypes) do
      if
        (fluidbox.production_type == "input" or fluidbox.production_type == "input-output")
        and fluidbox.filter
        and fluidbox.filter.name == fluid.name
      then
        table.insert(properties.burned_in, { type = "entity", name = entity_name })
      end
    end
  end
  if fluid.fuel_value then
    -- TODO: Add energy source entity prototype filter to the API
    --- @diagnostic disable-next-line unused-fields
    for entity_name, entity in pairs(game.get_filtered_entity_prototypes({ { filter = "building" } })) do
      if entity.fluid_energy_source_prototype then
        table.insert(properties.burned_in, { type = "entity", name = entity_name })
      end
    end
  end

  properties.unlocked_by = properties.unlocked_by or {}
  for recipe_name, recipe in pairs(product_of_recipes) do
    if recipe.unlock_results then
      for technology_name in
        --- @diagnostic disable-next-line unused-fields
        pairs(game.get_filtered_technology_prototypes({ { filter = "unlocks-recipe", recipe = recipe_name } }))
      do
        -- TODO: This sucks
        if
          not flib_table.for_each(properties.unlocked_by, function(obj)
            return obj.name == technology_name
          end)
        then
          properties.unlocked_by[#properties.unlocked_by + 1] = { type = "technology", name = technology_name }
        end
      end
    end
  end
end

--- @param properties EntryProperties
--- @param item LuaItemPrototype
local function add_item_properties(properties, item)
  properties.ingredient_in = properties.ingredient_in or {}
  for _, recipe in
    pairs(game.get_filtered_recipe_prototypes({
      --- @diagnostic disable-next-line unused-fields
      { filter = "has-ingredient-item", elem_filters = { { filter = "name", name = item.name } } },
    }))
  do
    if get_entry(recipe) then
      table.insert(properties.ingredient_in, { type = "recipe", name = recipe.name })
    end
  end
  properties.product_of = properties.product_of or {}
  local product_of_recipes = game.get_filtered_recipe_prototypes({
    --- @diagnostic disable-next-line unused-fields
    { filter = "has-product-item", elem_filters = { { filter = "name", name = item.name } } },
  })
  for _, recipe in pairs(product_of_recipes) do
    if get_entry(recipe) then
      table.insert(properties.product_of, { type = "recipe", name = recipe.name })
    end
  end

  properties.unlocked_by = properties.unlocked_by or {}
  for recipe_name, recipe in pairs(product_of_recipes) do
    if recipe.unlock_results then
      for technology_name in
        --- @diagnostic disable-next-line unused-fields
        pairs(game.get_filtered_technology_prototypes({ { filter = "unlocks-recipe", recipe = recipe_name } }))
      do
        if
          not flib_table.for_each(properties.unlocked_by, function(obj)
            return obj.name == technology_name
          end)
        then
          properties.unlocked_by[#properties.unlocked_by + 1] = { type = "technology", name = technology_name }
        end
      end
    end
  end

  if not item.fuel_value then
    return
  end
  local fuel_category = item.fuel_category
  properties.burned_in = {}
  for entity_name, entity_prototype in pairs(game.entity_prototypes) do
    local burner = entity_prototype.burner_prototype
    if burner and burner.fuel_categories[fuel_category] then
      properties.burned_in[#properties.burned_in + 1] = { type = "entity", name = entity_name }
    end
  end
end

--- @param properties EntryProperties
--- @param entity LuaEntityPrototype
--- @param grouped_with_item string?
local function add_entity_properties(properties, entity, grouped_with_item)
  if util.crafting_machine[entity.type] then
    properties.can_craft = {}
    local filters = {}
    for category in pairs(entity.crafting_categories) do
      table.insert(filters, { filter = "category", category = category })
      table.insert(filters, { mode = "and", filter = "hidden-from-player-crafting", invert = true })
    end
    for _, recipe in pairs(game.get_filtered_recipe_prototypes(filters)) do
      local item_ingredients = 0
      for _, ingredient in pairs(recipe.ingredients) do
        if ingredient.type == "item" then
          item_ingredients = item_ingredients + 1
        end
      end
      local ingredient_count = entity.ingredient_count or 0
      if ingredient_count == 0 or ingredient_count >= item_ingredients then
        table.insert(properties.can_craft, { type = "recipe", name = recipe.name })
      end
    end
  elseif entity.type == "resource" then
    local required_fluid = entity.mineable_properties.required_fluid
    local resource_category = entity.resource_category
    properties.mined_by = {}
    --- @diagnostic disable-next-line unused-fields
    for _, entity in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "mining-drill" } })) do
      if entity.resource_categories[resource_category] and (not required_fluid or entity.fluidbox_prototypes[1]) then
        table.insert(properties.mined_by, { type = "entity", name = entity.name })
      end
    end
  elseif entity.type == "mining-drill" then
    --- @type string|boolean?
    local filter
    for _, fluidbox_prototype in pairs(entity.fluidbox_prototypes) do
      local production_type = fluidbox_prototype.production_type
      if production_type == "input" or production_type == "input-output" then
        filter = fluidbox_prototype.filter and fluidbox_prototype.filter.name or true
        break
      end
    end
    local resource_categories = entity.resource_categories --[[@as table<string, _>]]
    properties.can_mine = {}
    --- @diagnostic disable-next-line unused-fields
    for _, resource in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "resource" } })) do
      local mineable = resource.mineable_properties
      local required_fluid = mineable.required_fluid
      if
        resource_categories[resource.resource_category]
        and (not required_fluid or filter == true or filter == required_fluid)
      then
        table.insert(properties.can_mine, {
          type = "entity",
          name = resource.name,
          required_fluid = required_fluid
            and { type = "fluid", name = required_fluid, amount = mineable.fluid_amount / 10 },
        })
      end
    end
  end

  properties.can_burn = {}
  local burner = entity.burner_prototype
  if burner then
    for category in pairs(burner.fuel_categories) do
      for item_name in
        --- @diagnostic disable-next-line unused-fields
        pairs(game.get_filtered_item_prototypes({ { filter = "fuel-category", ["fuel-category"] = category } }))
      do
        properties.can_burn[#properties.can_burn + 1] = { type = "item", name = item_name }
      end
    end
  end
  local fluid_energy_source_prototype = entity.fluid_energy_source_prototype
  if fluid_energy_source_prototype then
    local filter = fluid_energy_source_prototype.fluid_box.filter
    if filter then
      properties.can_burn[#properties.can_burn + 1] = { type = "fluid", name = filter.name }
    else
      for fluid_name in
        --- @diagnostic disable-next-line unused-fields
        pairs(game.get_filtered_fluid_prototypes({ { filter = "fuel-value", comparison = ">", value = 0 } }))
      do
        properties.can_burn[#properties.can_burn + 1] = { type = "fluid", name = fluid_name }
      end
    end
  end
  if entity.type == "generator" then
    local fluid_box = entity.fluidbox_prototypes[1]
    if fluid_box.filter then
      table.insert(properties.can_burn, { type = "fluid", name = fluid_box.filter.name })
    else
      for fluid_name in
        --- @diagnostic disable-next-line unused-fields
        pairs(game.get_filtered_fluid_prototypes({ { filter = "fuel-value", comparison = ">", value = 0 } }))
      do
        table.insert(properties.can_burn, { type = "fluid", name = fluid_name })
      end
    end
  end

  -- TODO: Alternate items
  properties.placeable_by = {}
  local placeable_by = entity.items_to_place_this
  if not grouped_with_item and placeable_by then
    for _, item in pairs(placeable_by) do
      properties.placeable_by[#properties.placeable_by + 1] = { type = "item", name = item.name, count = item.count }
    end
  end
end

--- @type table<uint, table<string, EntryProperties>>
local cache = {}

--- @param path string
--- @return EntryProperties?
return function(path, force_index)
  local profiler = game.create_profiler()
  local force_cache = cache[force_index]
  if not force_cache then
    force_cache = {}
    cache[force_index] = force_cache
  end
  local cached = force_cache[path]
  if cached then
    return cached
  end

  local entry = global.database[path]
  if not entry then
    return
  end

  --- @type EntryProperties
  local properties = { entry = entry }

  local recipe = entry.recipe
  if recipe then
    add_recipe_properties(properties, recipe)
  end

  local fluid = entry.fluid
  if fluid then
    add_fluid_properties(properties, fluid)
  end

  local item = entry.item
  if item then
    add_item_properties(properties, item)
  end

  local entity = entry.entity
  if entity then
    add_entity_properties(properties, entity, item and item.name or nil)
  end

  -- Don't show product of if it just shows this recipe
  if recipe and item and #properties.product_of == 1 and properties.product_of[1].name == recipe.name then
    properties.product_of = nil
  end

  force_cache[path] = properties

  profiler.stop()
  log({ "", "[" .. path .. "] Get properties ", profiler })

  return properties
end
