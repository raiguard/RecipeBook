local flib_table = require("__flib__.table")
local flib_technology = require("__flib__.technology")

local entry_id = require("scripts.database.entry-id")
local util = require("scripts.util")

--- @alias GenericPrototype LuaEquipmentPrototype|LuaEntityPrototype|LuaFluidPrototype|LuaItemPrototype|LuaRecipePrototype|LuaTechnologyPrototype

--- @class Entry
--- @field private database Database
--- @field private base GenericPrototype
--- @field private technology LuaTechnologyPrototype?
--- @field private recipe LuaRecipePrototype?
--- @field private item LuaItemPrototype?
--- @field private fluid LuaFluidPrototype?
--- @field private equipment LuaEquipmentPrototype?
--- @field private entity LuaEntityPrototype?
--- @field private researched table<uint, boolean>?
local entry = {}
local mt = { __index = entry }
script.register_metatable("entry", mt)

--- @param prototype GenericPrototype
--- @param database Database
function entry.new(prototype, database)
  --- @type Entry
  local self = {
    database = database,
    base = prototype,
  }
  setmetatable(self, mt)

  self:add(prototype)

  return self
end

--- @param prototype GenericPrototype
function entry:add(prototype)
  self[util.object_name_to_type[prototype.object_name]] = prototype
end

--- @return string
function entry:get_name()
  return self.base.name
end

--- @return LocalisedString
function entry:get_localised_name()
  return self.base.localised_name
end

--- @return SpritePath
function entry:get_path()
  local base = self.base
  return util.object_name_to_type[base.object_name] .. "/" .. base.name
end

--- @return boolean
function entry:is_hidden()
  return util.is_hidden(self.base)
end

--- @param force_index uint
--- @return boolean
function entry:is_researched(force_index)
  local researched = self.researched
  return researched and researched[force_index] or false
end

--- @return LuaGroup
function entry:get_group()
  if self.base.object_name == "LuaEquipmentPrototype" then
    return game.item_group_prototypes["combat"]
  end
  return self.base.group
end

--- @return LuaGroup
function entry:get_subgroup()
  if self.base.object_name == "LuaEquipmentPrototype" then
    return game.item_subgroup_prototypes["rb-uncategorized-equipment"]
  end
  return self.base.subgroup
end

--- @return string
function entry:get_order()
  return self.base.order
end

--- @return string
function entry:get_type()
  return util.object_name_to_type[self.base.object_name]
end

-- PROPERTIES
-- TODO: Memoization

--- @return double?
function entry:get_crafting_time()
  if not self.recipe then
    return
  end

  return self.recipe.energy
end

--- @return EntryID[]?
function entry:get_ingredients()
  if not self.recipe then
    return
  end

  return flib_table.map(self.recipe.ingredients, function(ingredient)
    return entry_id.new(ingredient, self.database)
  end)
end

--- @return EntryID[]?
function entry:get_products()
  if not self.recipe then
    return
  end

  return flib_table.map(self.recipe.products, function(product)
    return entry_id.new(product, self.database)
  end)
end

--- @return EntryID[]?
function entry:get_made_in()
  if not self.recipe then
    return
  end

  local output = util.unique_id_array()

  --- @diagnostic disable-next-line unused-fields
  for _, character in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "character" } })) do
    if character.crafting_categories[self.recipe.category] then
      output[#output + 1] = entry_id.new({
        type = "entity",
        name = character.name,
        amount = self.recipe.energy,
      }, self.database)
    end
  end

  local item_ingredients = flib_table.reduce(self.recipe.ingredients, function(accumulator, ingredient)
    return accumulator + (ingredient.type == "item" and 1 or 0)
  end, 0) --[[@as integer]]

  for _, crafter in
    pairs(game.get_filtered_entity_prototypes({
      --- @diagnostic disable-next-line unused-fields
      { filter = "crafting-category", crafting_category = self.recipe.category },
    }))
  do
    local ingredient_count = crafter.ingredient_count
    local crafter_entry = self.database:get_entry(crafter)
    if crafter_entry and (ingredient_count == 0 or ingredient_count >= item_ingredients) then
      output[#output + 1] = entry_id.new({
        type = "entity",
        name = crafter.name,
        amount = self.recipe.energy / crafter.crafting_speed,
      }, self.database)
    end
  end

  return output
end

--- @return EntryID[]?
function entry:get_ingredient_in()
  if not self.fluid and not self.item then
    return
  end

  local output = util.unique_id_array()
  if self.fluid then
    for _, recipe in
      pairs(game.get_filtered_recipe_prototypes({
        --- @diagnostic disable-next-line unused-fields
        { filter = "has-ingredient-fluid", elem_filters = { { filter = "name", name = self.fluid.name } } },
      }))
    do
      local entry = self.database:get_entry(recipe)
      if entry then
        local id = entry_id.new({ type = "recipe", name = recipe.name }, self.database)
        for _, ingredient in pairs(recipe.ingredients) do
          -- minimum_temperature and maximum_temperature are mutually inclusive.
          if ingredient.name == self.fluid.name and ingredient.minimum_temperature then
            id.minimum_temperature = ingredient.minimum_temperature
            id.maximum_temperature = ingredient.maximum_temperature
            break
          end
        end
        output[#output + 1] = id
      end
    end
  end
  if self.item then
    for _, recipe in
      pairs(game.get_filtered_recipe_prototypes({
        --- @diagnostic disable-next-line unused-fields
        { filter = "has-ingredient-item", elem_filters = { { filter = "name", name = self.item.name } } },
      }))
    do
      local entry = self.database:get_entry(recipe)
      if entry then
        output[#output + 1] = entry_id.new({ type = "recipe", name = recipe.name }, self.database)
      end
    end
  end

  return output
end

--- @return EntryID[]?
function entry:get_product_of()
  if not self.fluid and not self.item then
    return
  end

  local output = util.unique_id_array()
  if self.fluid then
    for _, recipe in
      pairs(game.get_filtered_recipe_prototypes({
        --- @diagnostic disable-next-line unused-fields
        { filter = "has-product-fluid", elem_filters = { { filter = "name", name = self.fluid.name } } },
      }))
    do
      local entry = self.database:get_entry(recipe)
      if entry then
        output[#output + 1] = entry_id.new({ type = "recipe", name = recipe.name }, self.database)
      end
    end
  end
  if self.item then
    for _, recipe in
      pairs(game.get_filtered_recipe_prototypes({
        --- @diagnostic disable-next-line unused-fields
        { filter = "has-product-item", elem_filters = { { filter = "name", name = self.item.name } } },
      }))
    do
      local entry = self.database:get_entry(recipe)
      if entry then
        output[#output + 1] = entry_id.new({ type = "recipe", name = recipe.name }, self.database)
      end
    end
  end
  return output
end

local crafting_entities = {
  ["assembling-machine"] = true,
  ["furnace"] = true,
  ["rocket-silo"] = true,
  ["character"] = true,
}

--- @return EntryID[]?
function entry:get_can_craft()
  if not self.entity or not crafting_entities[self.entity.type] then
    return
  end

  local output = util.unique_id_array()

  local filters = {}
  for category in pairs(self.entity.crafting_categories) do
    filters[#filters + 1] = { filter = "category", category = category }
  end
  for _, recipe in pairs(game.get_filtered_recipe_prototypes(filters)) do
    local item_ingredients = 0
    for _, ingredient in pairs(recipe.ingredients) do
      if ingredient.type == "item" then
        item_ingredients = item_ingredients + 1
      end
    end
    local ingredient_count = self.entity.ingredient_count
    if not ingredient_count or ingredient_count >= item_ingredients then
      output[#output + 1] = entry_id.new({ type = "recipe", name = recipe.name }, self.database)
    end
  end

  return output
end

--- @return EntryID[]?
function entry:get_unlocked_by()
  local output = util.unique_id_array()

  -- TODO: Rocket launch products, unlock with crafting machines if no techs

  for _, id in pairs(self:get_product_of() or {}) do
    local recipe = id:get_entry().recipe
    assert(recipe, "Product of recipe was nil.")
    if recipe.unlock_results then
      for technology_name in
        --- @diagnostic disable-next-line unused-fields
        pairs(game.get_filtered_technology_prototypes({ { filter = "unlocks-recipe", recipe = recipe.name } }))
      do
        output[#output + 1] = entry_id.new({ type = "technology", name = technology_name }, self.database)
      end
    end
  end

  local prototypes = game.technology_prototypes
  table.sort(output, function(tech_a, tech_b)
    return flib_technology.sort_predicate(prototypes[tech_a.name], prototypes[tech_b.name])
  end)

  return output
end

return entry
