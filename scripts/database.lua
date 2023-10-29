local flib_dictionary = require("__flib__/dictionary-lite")
local flib_table = require("__flib__/table")

local util = require("__RecipeBook__/scripts/util")

-- DESIGN GOALS:
-- Find a balance between caching information and generating it on the fly
-- Reduce complexity as much as possible
-- Don't rely on translated strings at all
-- Type annotations!!!

-- TODO: Use data-stage properties instead of hardcoding
local excluded_categories = {
  ["big-turbine"] = true,
  ["condenser-turbine"] = true,
  ["delivery-cannon"] = true,
  ["fuel-depot"] = true,
  ["ee-testing-tool"] = true,
  ["spaceship-antimatter-engine"] = true,
  ["spaceship-ion-engine"] = true,
  ["spaceship-rocket-engine"] = true,
  ["transport-drone-request"] = true,
  ["transport-fluid-request"] = true,
  ["void-crushing"] = true,
}

--- @param a GenericPrototype
--- @param b GenericPrototype
local function compare_names(a, b)
  return flib_table.deep_compare(a.localised_name --[[@as table]], b.localised_name --[[@as table]])
end

--- @param entry PrototypeEntry
--- @param force_index uint
local function add_researched(entry, force_index)
  if entry.researched then
    entry.researched[force_index] = true
  else
    entry.researched = { [force_index] = true }
  end
end

--- @class SubgroupData
--- @field members GenericPrototype[]
--- @field parent_name string

-- This and on_entity_unlocked are codependent
local on_product_unlocked

--- @param entity LuaEntityPrototype
--- @param force_index uint
local function on_entity_unlocked(entity, force_index)
  local db = global.database
  local entry = db["entity/" .. entity.name]
  if entry then
    add_researched(entry, force_index)
  end
  if entity.type == "mining-drill" then
    -- Resources
    local categories = entity.resource_categories --[[@as table<string, _>]]
    local fluidbox = entity.fluidbox_prototypes[1]
    local fluidbox_filter = fluidbox and fluidbox.filter or nil
    for resource_name, resource in
      --- @diagnostic disable-next-line unused-fields
      pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "resource" } }))
    do
      local mineable = resource.mineable_properties
      if mineable.products and categories[resource.resource_category] then
        -- Check fluid compatibility
        local required_fluid = mineable.required_fluid
        if not required_fluid or (fluidbox and (not fluidbox_filter or fluidbox_filter == required_fluid)) then
          -- Add resource entry
          local resource_entry = db["entity/" .. resource_name]
          if resource_entry then
            add_researched(resource_entry, force_index)
          end
          for _, product in pairs(mineable.products) do
            on_product_unlocked(product, force_index)
          end
        end
      end
    end
  elseif entity.type == "offshore-pump" then
    -- Pumped fluid
    local fluid = entity.fluid
    if fluid then
      local fluid_entry = db["fluid/" .. fluid.name]
      if fluid_entry then
        add_researched(fluid_entry, force_index)
      end
    end
  elseif entity.type == "boiler" then
    -- Produced fluid
    for _, fluidbox in pairs(entity.fluidbox_prototypes) do
      if fluidbox.production_type == "output" and fluidbox.filter then
        on_product_unlocked({ type = "fluid", name = fluidbox.filter.name }, force_index)
      end
    end
  end
end

--- @param product Product
--- @param force_index uint
function on_product_unlocked(product, force_index)
  local db = global.database
  local entry = db[product.type .. "/" .. product.name]
  if not entry then
    return
  end
  add_researched(entry, force_index)
  local prototype
  if product.type == "fluid" then
    prototype = game.fluid_prototypes[product.name]
  else
    prototype = game.item_prototypes[product.name]
  end
  if product.type == "item" then
    -- Rocket launch products
    local rocket_launch_products = prototype.rocket_launch_products
    if rocket_launch_products then
      for _, product in pairs(rocket_launch_products) do
        on_product_unlocked(product, force_index)
      end
    end
    -- Burnt results
    local burnt_result = prototype.burnt_result
    if burnt_result then
      on_product_unlocked({ type = "item", name = burnt_result.name }, force_index)
    end
    -- Place result
    local place_result = prototype.place_result
    if place_result then
      on_entity_unlocked(place_result, force_index)
    end
  end
end

--- @param recipe LuaRecipe
--- @param force_index uint
local function on_recipe_unlocked(recipe, force_index)
  local db = global.database
  local entry = db["recipe/" .. recipe.name]
  if not entry then
    return
  end
  add_researched(entry, force_index)
  if recipe.prototype.unlock_results then
    for _, product in pairs(recipe.products) do
      on_product_unlocked(product, force_index)
    end
  end
end

--- @param technology LuaTechnology
--- @param force_index uint
local function on_technology_researched(technology, force_index)
  local db = global.database
  if not db then
    return
  end
  local technology_name = technology.name
  local technology_path = "technology/" .. technology_name
  if not db[technology_path] then
    db[technology_path] = { researched = {} }
  end
  add_researched(db[technology_path], force_index)
  for _, effect in pairs(technology.effects) do
    if effect.type == "unlock-recipe" then
      local recipe = technology.force.recipes[effect.recipe]
      on_recipe_unlocked(recipe, force_index)
    end
  end
end

--- @param force LuaForce
local function refresh_researched(force)
  local force_index = force.index
  -- Gather-able items
  for _, entity in
    pairs(game.get_filtered_entity_prototypes({
      --- @diagnostic disable-next-line unused-fields
      { filter = "type", type = "simple-entity" },
      --- @diagnostic disable-next-line unused-fields
      { filter = "type", type = "tree" },
    }))
  do
    if entity.type == "tree" or entity.count_as_rock_for_filtered_deconstruction then
      local mineable = entity.mineable_properties
      if mineable.minable and mineable.products then
        for _, product in pairs(mineable.products) do
          on_product_unlocked(product, force_index)
        end
      end
    end
  end
  -- Technologies
  for _, technology in pairs(force.technologies) do
    if technology.researched then
      on_technology_researched(technology, force_index)
    end
  end
  -- Recipes (some may be enabled without technologies)
  local db = global.database
  for _, recipe in pairs(force.recipes) do
    -- Some recipes will be enabled from the start, but will only be craftable in machines
    if recipe.enabled and not (recipe.prototype.enabled and recipe.prototype.hidden_from_player_crafting) then
      local entry = db["recipe/" .. recipe.name]
      if entry and not (entry.researched or {})[force_index] then
        add_researched(entry, force_index)
        on_recipe_unlocked(recipe, force_index)
      end
    end
  end
  -- Characters
  -- TODO: Gate some characters if mods "unlock" them (Nullius)?
  --- @diagnostic disable-next-line unused-fields
  for name in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "character" } })) do
    local entry = db["entity/" .. name]
    if entry then
      add_researched(entry, force_index)
    end
  end
end

local function build_database()
  log("Generating database")
  local profiler = game.create_profiler()

  flib_dictionary.new("search")

  log("Search tree")
  --- Each top-level prototype sorted into groups and subgroups for the search_interface
  --- @type table<string, table<string, SpritePath[]>>
  local search_tree = {}
  global.search_tree = search_tree
  for group_name, group_prototype in pairs(game.item_group_prototypes) do
    local subgroups = {}
    for _, subgroup_prototype in pairs(group_prototype.subgroups) do
      subgroups[subgroup_prototype.name] = {}
    end
    search_tree[group_name] = subgroups
  end
  --- Indexable table of objects
  --- @type table<string, PrototypeEntry>
  local db = {}
  global.database = db

  --- @param prototype GenericPrototype
  --- @param group_with GenericPrototype?
  --- @return PrototypeEntry?
  local function add_prototype(prototype, group_with)
    local path, type = util.get_path(prototype)
    local entry = db[path]
    if not entry then
      if group_with then
        local parent_path = util.get_path(group_with)
        local parent_entry = db[parent_path]
        if parent_entry and not parent_entry[type] and compare_names(prototype, group_with) then
          parent_entry[type] = prototype -- Add this prototype to the parent
          db[path] = parent_entry -- Associate this prototype with the group's data
          return entry
        end
      end

      -- Add to database
      --- @diagnostic disable-next-line unused-fields
      db[path] = { base = prototype, base_path = path, [type] = prototype }
      -- Add to filter panel and search dictionary
      local subgroup = search_tree[prototype.group.name][prototype.subgroup.name]
      local order = prototype.order
      -- TODO: Binary search
      for i, other_entry in pairs(subgroup) do
        if order <= db[other_entry].base.order then
          table.insert(subgroup, i, path)
          return
        end
      end
      table.insert(subgroup, path)
      local prototype_type = util.prototype_type[prototype.object_name]
      local prototype_path = prototype_type .. "/" .. prototype.name
      flib_dictionary.add("search", prototype_path, { "?", prototype.localised_name, prototype_path })

      return db[path]
    end
  end

  -- Recipes determine what is actually attainable in the game
  -- All other objects will only be added if they are related to a recipe
  log("Recipes")
  --- @type table<string, GenericPrototype>
  local materials_to_add = {}
  for _, recipe_prototype in pairs(game.recipe_prototypes) do
    if not excluded_categories[recipe_prototype.category] and #recipe_prototype.products > 0 then
      add_prototype(recipe_prototype)
      -- Group with the main product if the icons match
      local main_product = recipe_prototype.main_product
      if not main_product then
        local products = recipe_prototype.products
        if #products == 1 then
          main_product = products[1]
        end
      end
      if main_product then
        local product_prototype = util.get_prototype(main_product)
        add_prototype(product_prototype, recipe_prototype)
      end
      -- Mark all ingredients and products for adding in the next step
      for _, ingredient in pairs(recipe_prototype.ingredients) do
        materials_to_add[ingredient.type .. "/" .. ingredient.name] = util.get_prototype(ingredient)
      end
      for _, product in pairs(recipe_prototype.products) do
        materials_to_add[product.type .. "/" .. product.name] = util.get_prototype(product)
      end
    end
  end

  log("Materials")
  for _, prototype in pairs(materials_to_add) do
    add_prototype(prototype) -- If a material was grouped with a recipe, this will do nothing
    if prototype.object_name == "LuaItemPrototype" then
      local place_result = prototype.place_result
      if place_result then
        add_prototype(place_result, prototype)
      end
      for _, product in pairs(prototype.rocket_launch_products) do
        add_prototype(util.get_prototype(product))
      end
    end
  end

  log("Resources")
  --- @diagnostic disable-next-line unused-fields
  for _, prototype in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "resource" } })) do
    local mineable = prototype.mineable_properties
    if mineable.minable then
      local products = mineable.products
      if products and #products > 0 then
        local should_add, grouped_material
        for _, product in pairs(mineable.products) do
          local product_prototype = util.get_prototype(product)
          local product_path = util.get_path(product_prototype)
          -- Only add resources whose products have an entry (and therefore, a recipe)
          if db[product_path] then
            should_add = true
            if compare_names(prototype, product_prototype) then
              grouped_material = product_prototype
              break
            end
          end
        end
        if should_add then
          add_prototype(prototype, grouped_material)
        end
      end
    end
  end

  log("Characters")
  --- @diagnostic disable-next-line unused-fields
  for _, character in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "character" } })) do
    add_prototype(character)
  end

  log("Technologies and research status")
  for name, technology in pairs(game.technology_prototypes) do
    local path = "technology/" .. name
    --- @diagnostic disable-next-line unused-fields
    db[path] = { base = technology, base_path = path }
  end
  for _, force in pairs(game.forces) do
    refresh_researched(force)
  end

  log("Search tree cleanup")
  for group_name, group in pairs(search_tree) do
    local size = 0
    for subgroup_name, subgroup in pairs(group) do
      if #subgroup == 0 then
        group[subgroup_name] = nil
      else
        size = size + 1
      end
    end
    if size == 0 then
      search_tree[group_name] = nil
    end
  end

  profiler.stop()
  log({ "", "Database Generation ", profiler })
end

--- @class Database
local database = {}

--- @param path string
--- @return string? base_path
function database.get_base_path(path)
  local entry = global.database[path]
  if entry then
    local base_path = util.get_path(entry.base)
    return base_path
  end
end

--- @param obj GenericObject
--- @return boolean
function database.is_researched(obj, force_index)
  local entry = global.database[obj.type .. "/" .. obj.name]
  if entry and entry.researched and entry.researched[force_index] then
    return true
  end
  return false
end

--- @param obj GenericObject
--- @return boolean
function database.is_hidden(obj)
  local entry = global.database[obj.type .. "/" .. obj.name]
  if entry and util.is_hidden(entry.base) then
    return true
  end
  return false
end

--- @param obj GenericObject
--- @return PrototypeEntry?
function database.get_entry(obj)
  return global.database[obj.type .. "/" .. obj.name]
end

--- @param prototype GenericPrototype
-- @return PrototypeEntry?
function database.get_entry_proto(prototype)
  local type = util.prototype_type[prototype.object_name]
  if type then
    return global.database[type .. "/" .. prototype.name]
  end
end

-- Entry properties

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
        duration = recipe.energy,
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
    if database.get_entry_proto(crafter) and (ingredient_count == 0 or ingredient_count >= item_ingredients) then
      table.insert(properties.made_in, {
        type = "entity",
        name = crafter.name,
        duration = recipe.energy / crafter.crafting_speed,
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
    if database.get_entry_proto(recipe) then
      table.insert(properties.ingredient_in, { type = "recipe", name = recipe.name })
    end
  end
  properties.product_of = {}
  local product_of_recipes = game.get_filtered_recipe_prototypes({
    --- @diagnostic disable-next-line unused-fields
    { filter = "has-product-fluid", elem_filters = { { filter = "name", name = fluid.name } } },
  })
  for _, recipe in pairs(product_of_recipes) do
    if database.get_entry_proto(recipe) then
      table.insert(properties.product_of, { type = "recipe", name = recipe.name })
    end
  end

  -- TODO: Fluid energy sources, boilers
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
    if database.get_entry_proto(recipe) then
      table.insert(properties.ingredient_in, { type = "recipe", name = recipe.name })
    end
  end
  properties.product_of = properties.product_of or {}
  local product_of_recipes = game.get_filtered_recipe_prototypes({
    --- @diagnostic disable-next-line unused-fields
    { filter = "has-product-item", elem_filters = { { filter = "name", name = item.name } } },
  })
  for _, recipe in pairs(product_of_recipes) do
    if database.get_entry_proto(recipe) then
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
local function add_entity_properties(properties, entity)
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
end

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
--- @field unlocked_by GenericObject[]?

--- @type table<uint, table<string, EntryProperties>>
local cache = {}

--- @param path string
--- @return EntryProperties?
function database.get_properties(path, force_index)
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
    add_entity_properties(properties, entity)
  end

  -- Don't show product of if it just shows this recipe
  if recipe and item and #properties.product_of == 1 and properties.product_of[1].name == recipe.name then
    properties.product_of = nil
  end

  force_cache[path] = properties

  return properties
end

-- Events

--- @param e EventData.on_research_finished
local function on_research_finished(e)
  local profiler = game.create_profiler()
  local technology = e.research
  on_technology_researched(technology, technology.force.index)
  profiler.stop()
  log({ "", "Unlock Tech ", profiler })
  if global.update_force_guis then
    -- Update on the next tick in case multiple researches are done at once
    global.update_force_guis[technology.force.index] = true
  end
end

database.on_init = build_database
database.on_configuration_changed = build_database

database.events = {
  [defines.events.on_research_finished] = on_research_finished,
}

return database
