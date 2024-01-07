local flib_dictionary = require("__flib__.dictionary-lite")

local db_entry = require("scripts.database.entry")
local researched = require("scripts.database.researched")
local search_tree = require("scripts.database.search-tree")
local util = require("scripts.util")

--- @class Database
--- @field entries table<string, Entry?>
--- @field search_tree SearchTree
--- @field alternatives table<SpritePath, SpritePath>
--- @field excluded_categories table<string, boolean>
--- @field group_overrides table<SpritePath, SpritePath>
local database = {}
local mt = { __index = database }
script.register_metatable("database", mt)

--- @return Database
function database.new()
  --- @type Database
  local self = setmetatable({
    entries = {},
    search_tree = search_tree.new(),

    alternatives = {},
    excluded_categories = {},
    group_overrides = {},
  }, mt)

  self:get_overrides()
  self:build()

  return self
end

--- @private
function database:build()
  log("Generating database")
  local profiler = game.create_profiler()

  flib_dictionary.new("search")

  -- Recipes determine most of what is actually attainable in the game.
  log("Recipes")
  --- @type table<string, GenericPrototype>
  local materials_to_add = {}
  for _, prototype in pairs(game.recipe_prototypes) do
    if self.excluded_categories[prototype.category] or #prototype.products == 0 then
      goto continue
    end
    self:add_prototype(prototype)
    -- Attempt to group with the main product
    local main_product = prototype.main_product or prototype.products[1]
    local main_product_prototype = util.get_prototype(main_product)
    if self:should_group(main_product_prototype, prototype) then
      self:add_prototype(main_product_prototype, prototype)
    end
    -- Mark all ingredients and products for adding in the next step
    for _, ingredient in pairs(prototype.ingredients) do
      materials_to_add[ingredient.type .. "/" .. ingredient.name] = util.get_prototype(ingredient)
    end
    for _, product in pairs(prototype.products) do
      materials_to_add[product.type .. "/" .. product.name] = util.get_prototype(product)
    end
    ::continue::
  end

  log("Materials")
  for _, prototype in pairs(materials_to_add) do
    self:add_prototype(prototype) -- If a material was grouped with a recipe, this will do nothing
    if prototype.object_name ~= "LuaItemPrototype" then
      goto continue
    end
    local place_result = prototype.place_result
    if place_result then
      self:add_prototype(place_result, prototype)
    end
    local place_as_equipment_result = prototype.place_as_equipment_result
    if place_as_equipment_result then
      self:add_prototype(place_as_equipment_result, prototype)
    end
    for _, product in pairs(prototype.rocket_launch_products) do
      self:add_prototype(util.get_prototype(product))
    end
    ::continue::
  end

  log("Resources, fish, trees & rocks")
  for _, prototype in pairs(util.get_natural_entities()) do
    local mineable = prototype.mineable_properties
    if not mineable.minable then
      goto continue
    end
    local products = mineable.products
    if not products or #products == 0 then
      goto continue
    end
    local should_add, grouped_material
    for _, product in pairs(mineable.products) do
      -- Only add resources whose products have an entry (and therefore, a recipe)
      if self:get_entry(product) then
        should_add = true
        local product_prototype = util.get_prototype(product)
        if self:should_group(prototype, product_prototype) then
          grouped_material = product_prototype
          break
        end
      end
    end
    if should_add then
      self:add_prototype(prototype, grouped_material)
    end
    ::continue::
  end

  log("Characters")
  --- @diagnostic disable-next-line unused-fields
  for _, character in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "character" } })) do
    self:add_prototype(character)
  end

  log("Technologies and research status")
  for name, technology in pairs(game.technology_prototypes) do
    local path = "technology/" .. name
    self.entries[path] = db_entry.new(technology, self)
  end
  -- TEMPORARY: Required for `researched` module
  global.database = self
  for _, force in pairs(game.forces) do
    researched.refresh(force)
  end

  log("Alternatives")
  for from, to in pairs(self.alternatives) do
    if self.entries[to] then
      self.entries[from] = self.entries[to]
    end
  end

  log("Search tree finalization")
  self.search_tree:finalize()

  profiler.stop()
  log({ "", "Database Generation ", profiler })
end

--- @private
function database:get_overrides()
  -- TODO: Smuggle from data stage
  self.alternatives = {
    ["entity-curved-rail"] = "entity/straight-rail",
  }
  self.excluded_categories = {}
  self.group_overrides = {
    ["entity/fish"] = "item/raw-fish",
    ["entity/straight-rail"] = "item/rail",
  }
end

--- @private
--- @param a GenericPrototype
--- @param b GenericPrototype
function database:should_group(a, b)
  local a_path = util.get_path(a)
  local b_path = util.get_path(b)
  if self.group_overrides[a_path] == b_path then
    return true
  end
  if
    a.object_name ~= "LuaEntityPrototype"
    and a.object_name ~= "LuaEquipmentPrototype"
    and util.is_hidden(a) ~= util.is_hidden(b)
  then
    return false
  end
  return a.name == b.name
end

--- @param obj EntryID|Ingredient|Product|ElemID
--- @return Entry?
function database:get_entry(obj)
  return self.entries[obj.type .. "/" .. obj.name]
end

--- @param path SpritePath
--- @return Entry?
function database:get(path)
  return self.entries[path]
end

--- @private
--- @param prototype GenericPrototype
--- @param group_with GenericPrototype?
function database:add_prototype(prototype, group_with)
  local path, type = util.get_path(prototype)
  local entry = self.entries[path]
  if entry then
    return
  end
  if self.alternatives[path] then
    return
  end

  if group_with then
    local parent_path = util.get_path(group_with)
    local parent_entry = self.entries[parent_path]
    if parent_entry and not parent_entry[type] and self:should_group(prototype, group_with) then
      parent_entry:add(prototype)
      self.entries[path] = parent_entry
      return
    end
  end

  local entry = db_entry.new(prototype, self)
  self.entries[path] = entry

  self.search_tree:add(entry)

  local prototype_type = util.object_name_to_type[prototype.object_name]
  local prototype_path = prototype_type .. "/" .. prototype.name
  flib_dictionary.add("search", prototype_path, { "?", prototype.localised_name, prototype_path })
end

-- Events

--- @class DatabaseModule
local M = {}

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

local function init()
  global.database = database.new()
end

M.on_init = init
M.on_configuration_changed = init

M.events = {
  [defines.events.on_research_finished] = on_research_finished,
}

return M
