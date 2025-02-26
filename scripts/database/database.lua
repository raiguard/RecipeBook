local flib_dictionary = require("__flib__.dictionary")

local db_entry = require("scripts.database.entry")
local search_tree = require("scripts.database.search-tree")
local util = require("scripts.util")

local bigunpack = require("__big-data-string2__.unpack")

--- @generic T
--- @param key string
--- @return T
local function unpack(key)
  local success, value = serpent.load(bigunpack(key))
  assert(success, "Deserialising overrides failed for " .. key)
  return value
end

--- @class Database
--- @field entries table<SpritePath, Entry?>
--- @field search_tree SearchTree
--- @field alternatives table<SpritePath, SpritePath>
--- @field exclude table<SpritePath, boolean>
--- @field group_with table<SpritePath, SpritePath>
--- @field hidden table<SpritePath, boolean>
--- @field hidden_from_search table<SpritePath, boolean>
--- @field unlocks_results table<SpritePath, boolean>
--- @field tooltip_category_sprites table<SpritePath, boolean>
local database = {}
local mt = { __index = database }
script.register_metatable("database", mt)

--- @return Database
function database.new()
  --- @type Database
  local self = {
    entries = {},
    search_tree = search_tree.new(),
    alternatives = unpack("rb_alternatives"),
    exclude = unpack("rb_exclude"),
    group_with = unpack("rb_group_with"),
    hidden = unpack("rb_hidden"),
    hidden_from_search = unpack("rb_hidden_from_search"),
    unlocks_results = unpack("rb_unlocks_results"),
    tooltip_category_sprites = unpack("rb_tooltip_category_sprites"),
  }
  setmetatable(self, mt)

  log("Generating database")
  local profiler = game.create_profiler()

  flib_dictionary.new("search")
  flib_dictionary.new("description")

  -- Recipes determine most of what is actually attainable in the game.
  log("Recipes")
  --- @type table<string, GenericPrototype>
  local materials_to_add = {}
  for _, prototype in pairs(prototypes.recipe) do
    if self.exclude["recipe-category/" .. prototype.category] or #prototype.products == 0 then
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

  log("Tiles")
  for _, tile in pairs(prototypes.tile) do
    local products = tile.mineable_properties.products
    local first_product = products and products[1]
    if not first_product then
      self:add_prototype(tile)
      goto continue
    end
    local product_entry = self:get_entry(first_product)
    if not product_entry or not product_entry.tile then
      self:add_prototype(tile, util.get_prototype(first_product), true)
    elseif product_entry then
      self.entries[util.get_path(tile)] = product_entry
    end
    ::continue::
  end

  log("Characters")
  --- @diagnostic disable-next-line unused-fields
  for _, character in pairs(prototypes.get_entity_filtered({ { filter = "type", type = "character" } })) do
    self:add_prototype(character)
  end

  log("Search tree")
  --- @type table<Entry, boolean>
  local added = {}
  for _, entry in pairs(self.entries) do
    if not added[entry] then
      added[entry] = true
      self.search_tree:add(entry)
    end
  end
  self.search_tree:finalize()

  log("Alternatives")
  for from, to in pairs(self.alternatives) do
    if self.entries[to] then
      self.entries[from] = self.entries[to]
    end
  end

  log("Technologies")
  for _, technology in pairs(prototypes.technology) do
    self:add_prototype(technology)
  end

  profiler.stop()
  log({ "", "Database Generation ", profiler })

  return self
end

--- @private
--- @param a GenericPrototype
--- @param b GenericPrototype
function database:should_group(a, b)
  local a_path = util.get_path(a)
  local b_path = util.get_path(b)
  if self.group_with[a_path] == b_path then
    return true
  end
  -- if
  --   a.object_name ~= "LuaEntityPrototype"
  --   and a.object_name ~= "LuaEquipmentPrototype"
  --   and self:is_hidden(a) ~= self:is_hidden(b)
  -- then
  --   return false
  -- end
  return a.name == b.name
end

--- @param obj EntryID|GenericPrototype|Ingredient|Product|SpritePath|LuaTechnology|LuaRecipe|LuaEntity|TechnologyModifier
--- @return Entry?
function database:get_entry(obj)
  -- LuaLS can't narrow object_name and the Factorio plugin's output doesn't work here
  --- @diagnostic disable
  if type(obj) == "string" then
    return self.entries[obj]
  elseif obj.object_name then
    return self.entries[util.object_name_to_type[obj.object_name] .. "/" .. obj.name]
  elseif obj.type == "unlock-recipe" then
    return self.entries["recipe/" .. obj.recipe]
  else
    return self.entries[obj.type .. "/" .. obj.name]
  end
  --- @diagnostic enable
end

--- @private
--- @param prototype GenericPrototype
--- @param group_with GenericPrototype?
--- @param force_group boolean?
--- @return Entry?
function database:add_prototype(prototype, group_with, force_group)
  local path, type = util.get_path(prototype)
  local entry = self.entries[path]
  if entry then
    return
  end
  if self.alternatives[path] then
    return
  end
  if self.exclude[path] then
    return
  end

  -- FIXME: Add factoriopedia_description read
  flib_dictionary.add("description", path, prototype.localised_description)

  if group_with then
    local parent_path = util.get_path(group_with)
    local parent_entry = self.entries[parent_path]
    if parent_entry and not parent_entry[type] and (force_group or self:should_group(prototype, group_with)) then
      parent_entry:add(prototype)
      self.entries[path] = parent_entry
      return
    end
  end

  local entry = db_entry.new(prototype, self)
  self.entries[path] = entry

  local prototype_type = util.object_name_to_type[prototype.object_name]
  local prototype_path = prototype_type .. "/" .. prototype.name
  flib_dictionary.add("search", prototype_path, { "?", prototype.localised_name, prototype_path })

  return entry
end

--- @param prototype GenericPrototype
--- @param force_index uint?
--- @return boolean
function database:is_hidden(prototype, force_index)
  local override = self.hidden[util.get_path(prototype)]
  if override ~= nil then
    return override
  end
  if force_index and prototype.object_name == "LuaTechnologyPrototype" then
    local tech = game.forces[force_index].technologies[prototype.name]
    return not tech.enabled and not tech.visible_when_disabled
  end
  return prototype.hidden
end

--- @param prototype GenericPrototype
--- @param fallback string
function database:get_tooltip_category_sprite(prototype, fallback)
  local by_name = "tooltip-category-" .. prototype.name
  if self.tooltip_category_sprites[by_name] then
    return by_name
  end
  return "tooltip-category-" .. fallback
end

-- Events

--- @class DatabaseModule
local M = {}

local function init()
  storage.database = database.new()
end

M.on_init = init
M.on_configuration_changed = init

return M
