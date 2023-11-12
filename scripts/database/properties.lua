local flib_table = require("__flib__/table")
local flib_technology = require("__flib__/technology")

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
--- @field gathered_from GenericObject[]?
--- @field burned_in GenericObject[]?
--- @field can_burn GenericObject[]?
--- @field rocket_launch_products GenericObject[]?
--- @field rocket_launch_product_of GenericObject[]?
--- @field placeable_by GenericObject[]?
--- @field unlocked_by GenericObject[]?
--- @field place_result GenericObject?
--- @field yields GenericObject[]?

--- @param prototype GenericPrototype
--- @return PrototypeEntry?
local function get_entry(prototype)
  local type = util.prototype_type[prototype.object_name]
  if type then
    return global.database[type .. "/" .. prototype.name]
  end
end

--- @param objects GenericObject[]
--- @param name string
local function contains_id(objects, name)
  for i = 1, #objects do
    if objects[i].name == name then
      return true
    end
  end
  return false
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
      properties.made_in[#properties.made_in + 1] = {
        type = "entity",
        name = character.name,
        amount = recipe.energy,
      }
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
      properties.made_in[#properties.made_in + 1] = {
        type = "entity",
        name = crafter.name,
        amount = recipe.energy / crafter.crafting_speed,
      }
    end
  end

  -- TODO: Recipes with no technologies to unlock them and are enabled by default should show as unlocked with their crafter
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
--- @param grouped_with_entity LuaEntityPrototype?
local function add_fluid_properties(properties, fluid, grouped_with_entity)
  properties.ingredient_in = {}
  for _, recipe in
    pairs(game.get_filtered_recipe_prototypes({
      --- @diagnostic disable-next-line unused-fields
      { filter = "has-ingredient-fluid", elem_filters = { { filter = "name", name = fluid.name } } },
    }))
  do
    local entry = get_entry(recipe)
    if entry then
      local id = { type = "recipe", name = recipe.name }
      properties.ingredient_in[#properties.ingredient_in + 1] = id
      for _, ingredient in pairs(recipe.ingredients) do
        -- minimum_temperature and maximum_temperature are mutually inclusive.
        if ingredient.name == fluid.name and ingredient.minimum_temperature then
          id.minimum_temperature = ingredient.minimum_temperature
          id.maximum_temperature = ingredient.maximum_temperature
          break
        end
      end
    end
  end
  properties.product_of = {}
  local product_of_recipes = game.get_filtered_recipe_prototypes({
    --- @diagnostic disable-next-line unused-fields
    { filter = "has-product-fluid", elem_filters = { { filter = "name", name = fluid.name } } },
  })
  for _, recipe in pairs(product_of_recipes) do
    local entry = get_entry(recipe)
    if entry then
      local id = { type = "recipe", name = recipe.name }
      properties.product_of[#properties.product_of + 1] = id
      for _, product in pairs(recipe.products) do
        if product.name == fluid.name and product.temperature then
          id.temperature = product.temperature
          break
        end
      end
    end
  end

  properties.burned_in = {}
  --- @diagnostic disable-next-line unused-fields
  for entity_name, entity in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "generator" } })) do
    local fluid_box = entity.fluidbox_prototypes[1]
    if
      (fluid_box.filter and fluid_box.filter.name == fluid.name) or (not fluid_box.filter and fluid.fuel_value > 0)
    then
      properties.burned_in[#properties.burned_in + 1] = { type = "entity", name = entity_name }
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
        properties.burned_in[#properties.burned_in + 1] = { type = "entity", name = entity_name }
      end
    end
  end
  if fluid.fuel_value then
    -- TODO: Add energy source entity prototype filter to the API
    --- @diagnostic disable-next-line unused-fields
    for entity_name, entity in pairs(game.get_filtered_entity_prototypes({ { filter = "building" } })) do
      if entity.fluid_energy_source_prototype then
        properties.burned_in[#properties.burned_in + 1] = { type = "entity", name = entity_name }
      end
    end
  end

  properties.gathered_from = {}
  for entity_name, entity in pairs(util.get_natural_entities()) do
    if not grouped_with_entity or grouped_with_entity.name ~= entity_name then
      local mineable_properties = entity.mineable_properties
      if mineable_properties.minable then
        for _, product in pairs(mineable_properties.products or {}) do
          if product.type == "fluid" and product.name == fluid.name then
            properties.gathered_from[#properties.gathered_from + 1] = { type = "entity", name = entity_name }
          end
        end
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
        if not contains_id(properties.unlocked_by, technology_name) then
          properties.unlocked_by[#properties.unlocked_by + 1] = { type = "technology", name = technology_name }
        end
      end
    end
  end
end

--- @param properties EntryProperties
--- @param item LuaItemPrototype
--- @param grouped_with_entity LuaEntityPrototype
local function add_item_properties(properties, item, grouped_with_entity)
  properties.ingredient_in = properties.ingredient_in or {}
  for _, recipe in
    pairs(game.get_filtered_recipe_prototypes({
      --- @diagnostic disable-next-line unused-fields
      { filter = "has-ingredient-item", elem_filters = { { filter = "name", name = item.name } } },
    }))
  do
    if get_entry(recipe) then
      properties.ingredient_in[#properties.ingredient_in + 1] = { type = "recipe", name = recipe.name }
    end
  end
  properties.product_of = properties.product_of or {}
  local product_of_recipes = game.get_filtered_recipe_prototypes({
    --- @diagnostic disable-next-line unused-fields
    { filter = "has-product-item", elem_filters = { { filter = "name", name = item.name } } },
  })
  for _, recipe in pairs(product_of_recipes) do
    if get_entry(recipe) then
      properties.product_of[#properties.product_of + 1] = { type = "recipe", name = recipe.name }
    end
  end

  properties.unlocked_by = properties.unlocked_by or {}
  for recipe_name, recipe in pairs(product_of_recipes) do
    if recipe.unlock_results then
      for technology_name in
        --- @diagnostic disable-next-line unused-fields
        pairs(game.get_filtered_technology_prototypes({ { filter = "unlocks-recipe", recipe = recipe_name } }))
      do
        if not contains_id(properties.unlocked_by, technology_name) then
          properties.unlocked_by[#properties.unlocked_by + 1] = { type = "technology", name = technology_name }
        end
      end
    end
  end

  if item.fuel_value then
    local fuel_category = item.fuel_category
    properties.burned_in = {}
    -- TODO: Prototype filter for burners
    for entity_name, entity_prototype in pairs(game.entity_prototypes) do
      local burner = entity_prototype.burner_prototype
      if burner and burner.fuel_categories[fuel_category] then
        properties.burned_in[#properties.burned_in + 1] = { type = "entity", name = entity_name }
      end
    end
    for equipment_name, equipment_prototype in pairs(game.equipment_prototypes) do
      local burner = equipment_prototype.burner_prototype
      if burner and burner.fuel_categories[fuel_category] then
        properties.burned_in[#properties.burned_in + 1] = { type = "equipment", name = equipment_name }
      end
    end
  end

  -- TODO: Display this
  local place_result = item.place_result
  if place_result and place_result ~= grouped_with_entity then
    properties.place_result = { type = "entity", name = place_result.name }
  end

  local rocket_launch_products = item.rocket_launch_products
  if #rocket_launch_products > 0 then
    properties.rocket_launch_products = {}
    for i = 1, #rocket_launch_products do
      properties.rocket_launch_products[i] =
        { type = "item", name = rocket_launch_products[i].name, amount = rocket_launch_products[i].amount }
    end
  end

  properties.rocket_launch_product_of = {}
  -- TODO: Refactor database to contain class functions in separate files to deduplicate all of this garbage
  --- @diagnostic disable-next-line unused-fields
  for _, other_item in pairs(game.get_filtered_item_prototypes({ { filter = "has-rocket-launch-products" } })) do
    for _, product in pairs(other_item.rocket_launch_products) do
      if product.name == item.name then
        properties.rocket_launch_product_of[#properties.rocket_launch_product_of + 1] =
          { type = "item", name = other_item.name }
        for recipe_name in
          pairs(game.get_filtered_recipe_prototypes({
            --- @diagnostic disable-next-line unused-fields
            { filter = "has-product-item", elem_filters = { { filter = "name", name = other_item.name } } },
          }))
        do
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

        break
      end
    end
  end

  properties.gathered_from = {}
  for entity_name, entity in pairs(util.get_natural_entities()) do
    if not grouped_with_entity or grouped_with_entity.name ~= entity_name then
      local mineable_properties = entity.mineable_properties
      if mineable_properties.minable then
        for _, product in pairs(mineable_properties.products or {}) do
          if product.type == "item" and product.name == item.name then
            properties.gathered_from[#properties.gathered_from + 1] = { type = "entity", name = entity_name }
          end
        end
      end
    end
  end
end

--- @param properties EntryProperties
--- @param equipment LuaEquipmentPrototype
--- @param grouped_with_item LuaItemPrototype?
local function add_equipment_properties(properties, equipment, grouped_with_item)
  properties.can_burn = {}
  local burner = equipment.burner_prototype
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
  if not grouped_with_item then
    properties.placeable_by = {}
    -- TODO: Add a name filter for equipment
    --- @diagnostic disable-next-line unused-fields
    for item_name, item in pairs(game.get_filtered_item_prototypes({ { filter = "placed-as-equipment-result" } })) do
      if item.place_as_equipment_result == equipment then
        properties.placeable_by[#properties.placeable_by + 1] = { type = "item", name = item_name }
      end
    end
  end
end

--- @param properties EntryProperties
--- @param entity LuaEntityPrototype
--- @param grouped_with_item LuaItemPrototype?
local function add_entity_properties(properties, entity, grouped_with_item)
  if util.crafting_machine[entity.type] then
    properties.can_craft = {}
    local filters = {}
    for category in pairs(entity.crafting_categories) do
      filters[#filters + 1] = { filter = "category", category = category }
      -- filters[#filters + 1] = { mode = "and", filter = "hidden-from-player-crafting", invert = true }
    end
    for _, recipe in pairs(game.get_filtered_recipe_prototypes(filters)) do
      local item_ingredients = 0
      for _, ingredient in pairs(recipe.ingredients) do
        if ingredient.type == "item" then
          item_ingredients = item_ingredients + 1
        end
      end
      local ingredient_count = entity.ingredient_count
      if not ingredient_count or ingredient_count >= item_ingredients then
        properties.can_craft[#properties.can_craft + 1] = { type = "recipe", name = recipe.name }
      end
    end
  elseif entity.type == "resource" then
    local required_fluid = entity.mineable_properties.required_fluid
    local resource_category = entity.resource_category
    properties.mined_by = {}
    --- @diagnostic disable-next-line unused-fields
    for _, entity in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "mining-drill" } })) do
      if entity.resource_categories[resource_category] and (not required_fluid or entity.fluidbox_prototypes[1]) then
        properties.mined_by[#properties.mined_by + 1] = { type = "entity", name = entity.name }
      end
    end
    local mineable_properties = entity.mineable_properties
    if mineable_properties and mineable_properties.minable then
      local products = mineable_properties.products or {}
      if
        not (
          #products == 1
          and grouped_with_item
          and products[1].type == "item"
          and products[1].name == grouped_with_item.name
        )
      then
        properties.crafting_time = mineable_properties.mining_time
        properties.yields = mineable_properties.products
      end
    end
  elseif entity.type == "fish" or entity.type == "tree" or entity.type == "simple-entity" then
    local mineable_properties = entity.mineable_properties
    if mineable_properties and mineable_properties.minable then
      local products = mineable_properties.products or {}
      if
        not (
          #products == 1
          and grouped_with_item
          and products[1].type == "item"
          and products[1].name == grouped_with_item.name
        )
      then
        properties.crafting_time = mineable_properties.mining_time
        properties.yields = mineable_properties.products
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
        properties.can_mine[#properties.can_mine + 1] = {
          type = "entity",
          name = resource.name,
          required_fluid = required_fluid
            and { type = "fluid", name = required_fluid, amount = mineable.fluid_amount / 10 },
        }
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
      properties.can_burn[#properties.can_burn + 1] = { type = "fluid", name = fluid_box.filter.name }
    else
      for fluid_name in
        --- @diagnostic disable-next-line unused-fields
        pairs(game.get_filtered_fluid_prototypes({ { filter = "fuel-value", comparison = ">", value = 0 } }))
      do
        properties.can_burn[#properties.can_burn + 1] = { type = "fluid", name = fluid_name }
      end
    end
  end

  -- TODO: Alternate items
  properties.placeable_by = {}
  local placeable_by = entity.items_to_place_this
  if not grouped_with_item and placeable_by then
    for _, item in pairs(placeable_by) do
      properties.placeable_by[#properties.placeable_by + 1] = { type = "item", name = item.name, amount = item.count }
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

  if entry.recipe then
    add_recipe_properties(properties, entry.recipe)
  end

  if entry.fluid then
    add_fluid_properties(properties, entry.fluid, entry.entity)
  end

  if entry.item then
    add_item_properties(properties, entry.item, entry.entity)
  end

  if entry.equipment then
    add_equipment_properties(properties, entry.equipment, entry.item)
  end

  if entry.entity then
    add_entity_properties(properties, entry.entity, entry.item)
  end

  -- Don't show product of if it just shows this recipe
  if
    entry.recipe
    and entry.item
    and #properties.product_of == 1
    and properties.product_of[1].name == entry.recipe.name
  then
    properties.product_of = nil
  end

  if properties.unlocked_by then
    local prototypes = game.technology_prototypes
    table.sort(properties.unlocked_by, function(tech_a, tech_b)
      return flib_technology.sort_predicate(prototypes[tech_a.name], prototypes[tech_b.name])
    end)
  end

  force_cache[path] = properties

  profiler.stop()
  log({ "", "[" .. path .. "] Get properties ", profiler })

  return properties
end
