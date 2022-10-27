local dictionary = require("__flib__.dictionary")
local table = require("__flib__.table")

local util = require("__RecipeBook__.util")

-- DESIGN GOALS:
-- Find a balance between caching information and generating it on the fly
-- Reduce complexity as much as possible
-- Don't rely on translated strings at all
-- Type annotations!!!

-- TODO: Use data-stage properties instead of hardcoding
local excluded_categories = {
  ["ee-testing-tool"] = true,
  ["big-turbine"] = true,
  ["condenser-turbine"] = true,
  ["delivery-cannon"] = true,
  ["spaceship-antimatter-engine"] = true,
  ["spaceship-ion-engine"] = true,
  ["spaceship-rocket-engine"] = true,
}

local database = {}

--- @param a GenericPrototype
--- @param b GenericPrototype
local function compare_icons(a, b)
  if game.active_mods.base == "1.1.71" then
    return table.deep_compare(a.icons, b.icons)
  else
    -- TEMPORARY:
    return a.name == b.name
  end
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

function database.build_groups()
  log("Starting database generation")
  local profiler = game.create_profiler()

  local search_strings = dictionary.new("search")

  --- Each top-level prototype sorted into groups and subgroups for the search_interface
  --- @type table<string, table<string, GenericPrototype>>
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
  local function add_to_subgroup(prototype)
    local prototypes = search_tree[prototype.group.name][prototype.subgroup.name]
    local order = prototype.order
    -- TODO: Binary search
    for i, other in pairs(prototypes) do
      if order <= other.order then
        added = true
        table.insert(prototypes, i, prototype)
        return
      end
    end
    table.insert(prototypes, prototype)
    search_strings:add(util.sprite_path[prototype.object_name] .. "/" .. prototype.name, prototype.localised_name)
  end

  local recipes = game.recipe_prototypes
  local items = game.item_prototypes
  local fluids = game.fluid_prototypes
  local entities = game.entity_prototypes

  -- Start from recipes
  log("Phase 1: Recipes")
  for recipe_name, recipe_prototype in pairs(recipes) do
    if not excluded_categories[recipe_prototype.category] then
      add_to_subgroup(recipe_prototype)
      local path = "recipe/" .. recipe_name
      db[path] = { recipe = recipe_prototype }
      -- If there is exactly one product, and its icon is the same, then group them
      local main_product = recipe_prototype.main_product
      if not main_product then
        local products = recipe_prototype.products
        if #products == 1 then
          main_product = products[1]
        end
      end
      if main_product then
        local product_prototype
        if main_product.type == "item" then
          product_prototype = items[main_product.name]
        else
          product_prototype = fluids[main_product.name]
        end

        if
          product_prototype
          and not db[main_product.type .. "/" .. main_product.name]
          and compare_icons(recipe_prototype, product_prototype)
        then
          -- Associate this main_product with the recipe entry, and sync the two entries to the same set of prototypes
          db[path][main_product.type] = product_prototype
          db[main_product.type .. "/" .. main_product.name] = db[path]

          if main_product.type == "item" then
            local place_result = product_prototype.place_result
            if
              place_result
              and not db["entity/" .. place_result.name]
              and compare_icons(recipe_prototype, place_result)
            then
              db[path].entity = product_prototype.place_result
              db["entity/" .. place_result.name] = db[path]
            end
          end
        end
      end
    end
  end

  -- Add missing items and fluids
  log("Phase 2: Missing materials")
  for name, prototype in pairs(items) do
    -- If the item is "spawnable", then it is a utility on the shortcut bar
    if not prototype.has_flag("spawnable") then
      local path = "item/" .. name
      if not db[path] then
        add_to_subgroup(prototype)
        db[path] = { item = prototype }
      end
    end
  end
  for name, prototype in pairs(fluids) do
    -- If the item is "spawnable", then it is a utility on the shortcut bar
    local path = "fluid/" .. name
    if not db[path] then
      add_to_subgroup(prototype)
      db[path] = { fluid = prototype }
    end
  end

  -- Add missing entities
  log("Phase 3: Missing entities")
  for name, prototype in pairs(entities) do
    local path = "entity/" .. name
    if not db[path] then
      local products = prototype.mineable_properties.products
      if products then
        -- Group with entity
        if #products == 1 then
          local product = products[1]
          local product_path = product.type .. "/" .. product.name
          local product_group = db[product_path]
          if
            product_group
            and not product_group.entity
            and compare_icons(prototype, product_group[next(product_group)])
          then
            product_group.entity = prototype
            db[path] = product_group
          elseif prototype.type == "resource" then
            add_to_subgroup(prototype)
            db[path] = { entity = prototype }
          end
        end
      end
    end
  end

  log("Phase 4: Technologies and research status")
  for name in pairs(game.technology_prototypes) do
    local path = "technology/" .. name
    db[path] = {}
  end
  for _, force in pairs(game.forces) do
    database.refresh_researched(force)
  end

  -- Remove empty groups and subgroups
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
  log({ "", "Database generation finished, ", profiler })
end

--- @param entity LuaEntityPrototype
--- @param force_index uint
function database.on_entity_unlocked(entity, force_index)
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
      pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "resource" } }))
    do
      local mineable = resource.mineable_properties
      if categories[resource.resource_category] then
        -- Check fluid compatibility
        local required_fluid = mineable.required_fluid
        if not required_fluid or (fluidbox and (not fluidbox_filter or fluidbox_filter == required_fluid)) then
          -- Add resource entry
          local resource_entry = db["entity/" .. resource_name]
          if resource_entry then
            add_researched(resource_entry, force_index)
          end
          for _, product in pairs(mineable.products) do
            database.on_product_unlocked(product, force_index)
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
        database.on_product_unlocked({ type = "fluid", name = fluidbox.filter.name }, force_index)
      end
    end
  end
end

--- @param product Product
--- @param force_index uint
function database.on_product_unlocked(product, force_index)
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
        database.on_product_unlocked(product, force_index)
      end
    end
    -- Burnt results
    local burnt_result = prototype.burnt_result
    if burnt_result then
      database.on_product_unlocked({ type = "item", name = burnt_result.name }, force_index)
    end
    -- Place result
    local place_result = prototype.place_result
    if place_result then
      database.on_entity_unlocked(place_result, force_index)
    end
  end
end

--- @param recipe LuaRecipe
--- @param force_index uint
function database.on_recipe_unlocked(recipe, force_index)
  local db = global.database
  local entry = db["recipe/" .. recipe.name]
  if not entry then
    return
  end
  add_researched(entry, force_index)
  if recipe.prototype.unlock_results then
    for _, product in pairs(recipe.products) do
      database.on_product_unlocked(product, force_index)
    end
  end
end

--- @param technology LuaTechnology
--- @param force_index uint
function database.on_technology_researched(technology, force_index)
  local technology_name = technology.name
  local db = global.database
  local technology_path = "technology/" .. technology_name
  if not db[technology_path] then
    db[technology_path] = { researched = {} }
  end
  add_researched(db[technology_path], force_index)
  for _, effect in pairs(technology.effects) do
    if effect.type == "unlock-recipe" then
      local recipe = technology.force.recipes[effect.recipe]
      database.on_recipe_unlocked(recipe, force_index)
    end
  end
end

--- @param force LuaForce
function database.refresh_researched(force)
  local force_index = force.index
  -- Gather-able items
  for _, entity in
    pairs(game.get_filtered_entity_prototypes({
      { filter = "type", type = "simple-entity" },
      { filter = "type", type = "tree" },
    }))
  do
    if entity.type == "tree" or entity.count_as_rock_for_filtered_deconstruction then
      local mineable = entity.mineable_properties
      if mineable.minable and mineable.products then
        for _, product in pairs(mineable.products) do
          database.on_product_unlocked(product, force_index)
        end
      end
    end
  end
  -- Technologies
  for _, technology in pairs(force.technologies) do
    if technology.researched then
      database.on_technology_researched(technology, force_index)
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
        database.on_recipe_unlocked(recipe, force_index)
      end
    end
  end
end

return database
