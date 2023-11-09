local flib_dictionary = require("__flib__/dictionary-lite")
local flib_table = require("__flib__/table")

local researched = require("__RecipeBook__/scripts/database/researched")
local util = require("__RecipeBook__/scripts/util")

--- @class CustomObject
--- @field type string
--- @field name string
--- @field count double
--- @field required_fluid Ingredient?

--- @alias GenericObject Ingredient|Product|CustomObject
--- @alias GenericPrototype LuaEntityPrototype|LuaFluidPrototype|LuaItemPrototype|LuaRecipePrototype|LuaTechnologyPrototype

--- @class PrototypeEntry
--- @field base GenericPrototype
--- @field base_path string
--- @field recipe LuaRecipePrototype?
--- @field item LuaItemPrototype?
--- @field fluid LuaFluidPrototype?
--- @field entity LuaEntityPrototype?
--- @field researched table<uint, boolean>?

-- TODO: Remote interface
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
  ["scrapping"] = true,
  ["barreling"] = true,
  ["unbarreling"] = true,
}

-- TODO: Remote interface
local group_overrides = {
  ["entity/coal"] = "item/coal",
  ["entity/copper-ore"] = "item/copper-ore",
  ["entity/iron-ore"] = "item/iron-ore",
  ["entity/stone"] = "item/stone",
  ["entity/uranium-ore"] = "item/uranium-ore",
  ["entity/straight-rail"] = "item/rail",
}

--- @param a GenericPrototype
--- @param b GenericPrototype
local function should_group(a, b)
  local a_path = util.get_path(a)
  local b_path = util.get_path(b)
  if group_overrides[a_path] == b_path then
    return true
  end
  return flib_table.deep_compare(a.localised_name --[[@as table]], b.localised_name --[[@as table]])
end

--- @param obj GenericObject
--- @return PrototypeEntry?
local function get_entry(obj)
  return global.database[obj.type .. "/" .. obj.name]
end

--- @param prototype GenericPrototype
--- @param group_with GenericPrototype?
--- @return PrototypeEntry?
local function add_prototype(prototype, group_with)
  local path, type = util.get_path(prototype)
  local entry = global.database[path]
  if not entry then
    if group_with then
      local parent_path = util.get_path(group_with)
      local parent_entry = global.database[parent_path]
      if parent_entry and not parent_entry[type] and should_group(prototype, group_with) then
        parent_entry[type] = prototype -- Add this prototype to the parent
        global.database[path] = parent_entry -- Associate this prototype with the group's data
        return entry
      end
    end

    -- Add to database
    global.database[path] = { base = prototype, base_path = path, [type] = prototype }
    -- Add to filter panel and search dictionary
    local subgroup = global.search_tree[prototype.group.name][prototype.subgroup.name]
    local order = prototype.order
    -- TODO: Binary search
    for i, other_entry in pairs(subgroup) do
      if order <= global.database[other_entry].base.order then
        table.insert(subgroup, i, path)
        return
      end
    end
    table.insert(subgroup, path)
    local prototype_type = util.prototype_type[prototype.object_name]
    local prototype_path = prototype_type .. "/" .. prototype.name
    flib_dictionary.add("search", prototype_path, { "?", prototype.localised_name, prototype_path })

    return global.database[path]
  end
end

local function build_database()
  log("Generating database")
  local profiler = game.create_profiler()

  flib_dictionary.new("search")

  log("Search tree")
  --- Each top-level prototype sorted into groups and subgroups for the search panel
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

  -- Recipes determine what is actually attainable in the game
  -- All other objects will only be added if they are related to a recipe
  log("Recipes")
  --- @type table<string, GenericPrototype>
  local materials_to_add = {}
  for _, prototype in pairs(game.recipe_prototypes) do
    if not excluded_categories[prototype.category] and #prototype.products > 0 then
      add_prototype(prototype)
      -- Attempt to group with the main product
      local main_product = prototype.main_product
      if not main_product then
        local products = prototype.products
        if #products == 1 then
          main_product = products[1]
        end
      end
      if main_product then
        local product_prototype = util.get_prototype(main_product)
        add_prototype(product_prototype, prototype)
      end
      -- Mark all ingredients and products for adding in the next step
      for _, ingredient in pairs(prototype.ingredients) do
        materials_to_add[ingredient.type .. "/" .. ingredient.name] = util.get_prototype(ingredient)
      end
      for _, product in pairs(prototype.products) do
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
          -- Only add resources whose products have an entry (and therefore, a recipe)
          if get_entry(product) then
            should_add = true
            local product_prototype = util.get_prototype(product)
            if should_group(prototype, product_prototype) then
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
    db[path] = { base = technology, base_path = path }
  end
  for _, force in pairs(game.forces) do
    researched.refresh(force)
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

database.get_entry = get_entry
database.get_properties = require("__RecipeBook__/scripts/database/properties")

-- Events

--- @param e EventData.on_research_finished
local function on_research_finished(e)
  local profiler = game.create_profiler()
  local technology = e.research
  researched.on_technology_researched(technology, technology.force.index)
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
