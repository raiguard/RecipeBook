local flib_math = require("__flib__.math")
local flib_table = require("__flib__.table")
local flib_technology = require("__flib__.technology")

local entry_id = require("scripts.database.entry-id")
local util = require("scripts.util")

--- @alias GenericPrototype LuaEquipmentPrototype|LuaEntityPrototype|LuaFluidPrototype|LuaItemPrototype|LuaRecipePrototype|LuaTechnologyPrototype

--- @class Entry
--- @field technology LuaTechnologyPrototype?
--- @field recipe LuaRecipePrototype?
--- @field item LuaItemPrototype?
--- @field fluid LuaFluidPrototype?
--- @field equipment LuaEquipmentPrototype?
--- @field entity LuaEntityPrototype?
--- @field private database Database
--- @field private base GenericPrototype
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

--- @param force_index uint
--- @return boolean
function entry:is_hidden(force_index)
  return self.database:is_hidden(self.base, force_index)
end

--- @param force_index uint
--- @return boolean
function entry:is_hidden_from_search(force_index)
  if self:is_hidden(force_index) then
    return true
  end
  if self.database.hidden_from_search[self:get_path()] then
    return true
  end
  return false
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
  if self.fluid then
    return self.fluid.group
  end
  if self.item then
    return self.item.group
  end
  return self.base.group
end

--- @return LuaGroup
function entry:get_subgroup()
  if self.base.object_name == "LuaEquipmentPrototype" then
    return game.item_subgroup_prototypes["rb-uncategorized-equipment"]
  end
  if self.fluid then
    return self.fluid.subgroup
  end
  if self.item then
    return self.item.subgroup
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

--- @return integer
function entry:get_display_order()
  return self.database.search_tree.order[self]
end

--- @return boolean
function entry:get_unlocks_results()
  local override = self.database.unlocks_results[self:get_path()]
  if override ~= nil then
    return override
  end

  if self.recipe then
    return self.recipe.unlock_results
  end

  return true
end

-- RESEARCH

--- @param force_index uint
function entry:research(force_index)
  if not self.researched then
    self.researched = {}
  end
  if self.researched[force_index] then
    return
  end
  self.researched[force_index] = true

  if not self:get_unlocks_results() then
    return
  end

  for _, recipe in pairs(self:get_unlocks_recipes() or {}) do
    recipe:get_entry():research(force_index)
  end
  for _, product in pairs(self:get_products() or {}) do
    product:get_entry():research(force_index)
  end
  for _, product in pairs(self:get_rocket_launch_products() or {}) do
    product:get_entry():research(force_index)
  end
  for _, product in pairs(self:get_yields() or {}) do
    product:get_entry():research(force_index)
  end
  for _, resource in pairs(self:get_can_mine() or {}) do
    resource:get_entry():research(force_index)
  end
  local burnt_result = self:get_burnt_result()
  if burnt_result then
    burnt_result:get_entry():research(force_index)
  end
  local pumped_fluid = self:get_pumped_fluid()
  if pumped_fluid then
    pumped_fluid:get_entry():research(force_index)
  end
  local generated_fluid = self:get_generated_fluid()
  if generated_fluid then
    generated_fluid:get_entry():research(force_index)
  end
end

local next_key = {
  recipe = "item",
  item = "fluid",
  fluid = "entity",
}

--- @return fun(): GenericPrototype?
function entry:iterate()
  local current = "recipe"
  return function()
    while current and not self[current] do
      current = next_key[current]
    end
    if not current then
      return nil
    end
    local ret = self[current]
    current = next_key[current]
    return ret
  end
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
function entry:get_alternative_recipes()
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
      if entry and entry ~= self then
        local id = entry_id.new({ type = "recipe", name = recipe.name }, self.database)
        for _, product in pairs(recipe.products) do
          if product.name == self.fluid.name and product.temperature then
            id.temperature = product.temperature
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
        { filter = "has-product-item", elem_filters = { { filter = "name", name = self.item.name } } },
      }))
    do
      local entry = self.database:get_entry(recipe)
      if entry and entry ~= self then
        output[#output + 1] = entry_id.new({ type = "recipe", name = recipe.name }, self.database)
      end
    end
  end

  table.sort(output, function(a, b)
    return a:get_entry():get_display_order() < b:get_entry():get_display_order()
  end)

  return output
end

--- @return EntryID[]?
function entry:get_used_in()
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
      if entry and entry ~= self then
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
      if entry and entry ~= self then
        output[#output + 1] = entry_id.new({ type = "recipe", name = recipe.name }, self.database)
      end
    end
  end

  table.sort(output, function(a, b)
    return a:get_entry():get_display_order() < b:get_entry():get_display_order()
  end)

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
    if self.database:get_entry(recipe) then
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
  end

  table.sort(output, function(a, b)
    return a:get_entry():get_display_order() < b:get_entry():get_display_order()
  end)

  return output
end

--- @return EntryID[]?
function entry:get_mined_by()
  local entity = self.entity
  if not entity or entity.type ~= "resource" then
    return
  end

  local output = util.unique_id_array()

  local required_fluid = entity.mineable_properties.required_fluid
  local resource_category = entity.resource_category
  for _, drill in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "mining-drill" } })) do
    if
      drill.resource_categories[resource_category]
      and (not required_fluid or drill.fluidbox_prototypes[1])
      and self.database:get_entry(drill)
    then
      output[#output + 1] = entry_id.new({ type = "entity", name = drill.name }, self.database)
    end
  end

  table.sort(output, function(a, b)
    return a:get_entry():get_display_order() < b:get_entry():get_display_order()
  end)

  return output
end

--- @return EntryID[]?
function entry:get_burned_in()
  local fluid, item = self.fluid, self.item
  if not fluid and not item then
    return
  end

  local output = util.unique_id_array()

  if fluid then
    --- @diagnostic disable-next-line unused-fields
    for entity_name, entity in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "generator" } })) do
      if self.database:get_entry(entity) then
        local fluid_box = entity.fluidbox_prototypes[1]
        if
          (fluid_box.filter and fluid_box.filter.name == fluid.name) or (not fluid_box.filter and fluid.fuel_value > 0)
        then
          output[#output + 1] = entry_id.new({ type = "entity", name = entity_name }, self.database)
        end
      end
    end
    --- @diagnostic disable-next-line unused-fields
    for entity_name, entity in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "boiler" } })) do
      if self.database:get_entry(entity) then
        for _, fluidbox in pairs(entity.fluidbox_prototypes) do
          if
            (fluidbox.production_type == "input" or fluidbox.production_type == "input-output")
            and fluidbox.filter
            and fluidbox.filter.name == fluid.name
          then
            output[#output + 1] = entry_id.new({ type = "entity", name = entity_name }, self.database)
          end
        end
      end
    end
    if fluid.fuel_value then
      --- @diagnostic disable-next-line unused-fields
      for entity_name, entity in pairs(game.get_filtered_entity_prototypes({ { filter = "building" } })) do
        if self.database:get_entry(entity) and entity.fluid_energy_source_prototype then
          output[#output + 1] = entry_id.new({ type = "entity", name = entity_name }, self.database)
        end
      end
    end
  end

  if item then
    local fuel_category = item.fuel_category
    for entity_name, entity_prototype in pairs(game.entity_prototypes) do
      if self.database:get_entry(entity_prototype) then
        local burner = entity_prototype.burner_prototype
        if burner and burner.fuel_categories[fuel_category] then
          output[#output + 1] = entry_id.new({ type = "entity", name = entity_name }, self.database)
        end
      end
    end
    for equipment_name, equipment_prototype in pairs(game.equipment_prototypes) do
      if self.database:get_entry(equipment_prototype) then
        local burner = equipment_prototype.burner_prototype
        if burner and burner.fuel_categories[fuel_category] then
          output[#output + 1] = entry_id.new({ type = "equipment", name = equipment_name }, self.database)
        end
      end
    end
  end

  table.sort(output, function(a, b)
    return a:get_entry():get_display_order() < b:get_entry():get_display_order()
  end)

  return output
end

--- @return EntryID[]?
function entry:get_gathered_from()
  local item = self.item
  if not item then
    return
  end

  local output = util.unique_id_array()

  for entity_name, entity in pairs(util.get_natural_entities()) do
    if not self.entity or self.entity.name ~= entity_name then
      local mineable_properties = entity.mineable_properties
      if mineable_properties.minable then
        for _, product in pairs(mineable_properties.products or {}) do
          if product.type == "item" and product.name == item.name then
            output[#output + 1] = entry_id.new({ type = "entity", name = entity_name }, self.database)
          end
        end
      end
    end
  end

  table.sort(output, function(a, b)
    return a:get_entry():get_display_order() < b:get_entry():get_display_order()
  end)

  return output
end

--- @return EntryID[]?
function entry:get_rocket_launch_products()
  if not self.item then
    return
  end

  local products = self.item.rocket_launch_products
  if #products == 0 then
    return
  end

  return flib_table.map(products, function(product)
    return entry_id.new(product, self.database)
  end)
end

--- @return EntryID[]?
function entry:get_rocket_launch_product_of()
  if not self.item then
    return
  end

  local output = util.unique_id_array()

  --- @diagnostic disable-next-line unused-fields
  for _, other_item in pairs(game.get_filtered_item_prototypes({ { filter = "has-rocket-launch-products" } })) do
    for _, product in pairs(other_item.rocket_launch_products) do
      if product.name == self.item.name then
        output[#output + 1] = entry_id.new({ type = "item", name = other_item.name }, self.database)
        break
      end
    end
  end

  return output
end

--- @return EntryID[]?
function entry:get_can_mine()
  local entity = self.entity
  if not entity or entity.type ~= "mining-drill" then
    return
  end

  --- @type string|boolean?
  local filter
  for _, fluidbox_prototype in pairs(entity.fluidbox_prototypes) do
    local production_type = fluidbox_prototype.production_type
    if production_type == "input" or production_type == "input-output" then
      filter = fluidbox_prototype.filter and fluidbox_prototype.filter.name or true
      break
    end
  end
  local resource_categories = entity.resource_categories or {}

  local output = util.unique_id_array()

  for _, resource in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "resource" } })) do
    local mineable = resource.mineable_properties
    local required_fluid = mineable.required_fluid
    if
      resource_categories[resource.resource_category]
      and (not required_fluid or filter == true or filter == required_fluid)
      and self.database:get_entry(resource)
    then
      output[#output + 1] = entry_id.new({
        type = "entity",
        name = resource.name,
        required_fluid = required_fluid
          and { type = "fluid", name = required_fluid, amount = mineable.fluid_amount / 10 },
      }, self.database)
    end
  end

  table.sort(output, function(a, b)
    return a:get_entry():get_display_order() < b:get_entry():get_display_order()
  end)

  return output
end

--- @return EntryID[]?
function entry:get_can_burn()
  local entity = self.entity
  if not entity then
    return
  end

  local output = util.unique_id_array()

  local burner = entity.burner_prototype
  if burner then
    for category in pairs(burner.fuel_categories) do
      for item_name, item in
        --- @diagnostic disable-next-line unused-fields
        pairs(game.get_filtered_item_prototypes({ { filter = "fuel-category", ["fuel-category"] = category } }))
      do
        if self.database:get_entry(item) then
          output[#output + 1] = entry_id.new({ type = "item", name = item_name }, self.database)
        end
      end
    end
  end
  local fluid_energy_source_prototype = entity.fluid_energy_source_prototype
  if fluid_energy_source_prototype then
    local filter = fluid_energy_source_prototype.fluid_box.filter
    if filter and self.database:get_entry(filter) then
      output[#output + 1] = entry_id.new({ type = "fluid", name = filter.name }, self.database)
    else
      for fluid_name, fluid in
        --- @diagnostic disable-next-line unused-fields
        pairs(game.get_filtered_fluid_prototypes({ { filter = "fuel-value", comparison = ">", value = 0 } }))
      do
        if self.database:get_entry(fluid) then
          output[#output + 1] = entry_id.new({ type = "fluid", name = fluid_name }, self.database)
        end
      end
    end
  end
  if entity.type == "generator" then
    local fluid_box = entity.fluidbox_prototypes[1]
    if fluid_box.filter then
      output[#output + 1] = entry_id.new({ type = "fluid", name = fluid_box.filter.name }, self.database)
    else
      for fluid_name, fluid in
        --- @diagnostic disable-next-line unused-fields
        pairs(game.get_filtered_fluid_prototypes({ { filter = "fuel-value", comparison = ">", value = 0 } }))
      do
        if self.database:get_entry(fluid) then
          output[#output + 1] = entry_id.new({ type = "fluid", name = fluid_name }, self.database)
        end
      end
    end
  end

  table.sort(output, function(a, b)
    return a:get_entry():get_display_order() < b:get_entry():get_display_order()
  end)

  return output
end

local yields = {
  ["fish"] = true,
  ["resource"] = true,
  ["simple-entity"] = true,
  ["tree"] = true,
}

--- @return EntryID[]?
function entry:get_yields()
  local entity = self.entity
  if not entity then
    return
  end

  if not yields[entity.type] then
    return
  end

  local mineable_properties = entity.mineable_properties
  if not mineable_properties or not mineable_properties.minable then
    return
  end

  local products = mineable_properties.products
  if not products then
    return
  end

  if not (#products == 1 and self.item and products[1].type == "item" and products[1].name == self.item.name) then
    -- properties.crafting_time = mineable_properties.mining_time
    return flib_table.map(mineable_properties.products, function(product)
      return entry_id.new(product, self.database)
    end)
  end
end

--- @return EntryID?
function entry:get_burnt_result()
  local item = self.item
  if not item then
    return
  end

  local burnt_result = item.burnt_result
  if not burnt_result then
    return
  end

  return entry_id.new({ type = "item", name = burnt_result.name }, self.database)
end

--- @return EntryID[]?
function entry:get_generated_by()
  local fluid = self.fluid
  if not fluid then
    return
  end

  local output = util.unique_id_array()

  for _, entity in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "boiler" } })) do
    local entry = self.database:get_entry(entity)
    if not entry then
      goto continue
    end
    local generates = entry:get_generated_fluid()
    if not generates or generates.name ~= fluid.name then
      goto continue
    end
    output[#output + 1] =
      entry_id.new({ type = "entity", name = entity.name, temperature = entity.target_temperature }, self.database)
    ::continue::
  end

  return output
end

--- @return EntryID[]?
function entry:get_unlocked_by()
  return self:get_unlocked_by_internal({})
end

--- @private
--- @param visited table<Entry, boolean>
--- @return EntryID[]?
function entry:get_unlocked_by_internal(visited)
  if visited[self] then
    return
  end
  visited[self] = true

  local output = util.unique_id_array()

  local recipe = self.recipe
  if recipe and self:get_unlocks_results() and not visited[recipe.name] and not recipe.enabled then
    for technology_name, technology in
      --- @diagnostic disable-next-line unused-fields
      pairs(game.get_filtered_technology_prototypes({ { filter = "unlocks-recipe", recipe = recipe.name } }))
    do
      if self.database:get_entry(technology) then
        output[#output + 1] = entry_id.new({ type = "technology", name = technology_name }, self.database)
      end
    end
  end

  for _, id in pairs(self:get_alternative_recipes() or {}) do
    for _, tech in pairs(id:get_entry():get_unlocked_by_internal(visited) or {}) do
      output[#output + 1] = tech
    end
  end

  for _, id in pairs(self:get_rocket_launch_product_of() or {}) do
    for _, tech in pairs(id:get_entry():get_unlocked_by_internal(visited) or {}) do
      output[#output + 1] = tech
    end
  end

  local prototypes = game.technology_prototypes
  table.sort(output, function(tech_a, tech_b)
    return flib_technology.sort_predicate(prototypes[tech_a.name], prototypes[tech_b.name])
  end)

  if #output == 0 and recipe and not recipe.enabled then
    for _, crafter in pairs(self:get_made_in() or {}) do
      for _, tech in pairs(crafter:get_entry():get_unlocked_by_internal(visited) or {}) do
        output[#output + 1] = tech
      end
    end
  end

  return output
end

--- @return EntryID[]?
function entry:get_technology_ingredients()
  local technology = self.technology
  if not technology then
    return
  end

  local output = util.unique_id_array()

  for _, ingredient in pairs(technology.research_unit_ingredients) do
    output[#output + 1] = entry_id.new(ingredient, self.database)
  end

  return output
end

--- @return uint?
function entry:get_technology_ingredient_count()
  local technology = self.technology
  if not technology then
    return
  end

  return technology.research_unit_count
end

--- @return double?
function entry:get_technology_ingredient_time()
  local technology = self.technology
  if not technology then
    return
  end

  return technology.research_unit_energy
end

--- @return EntryID[]?
function entry:get_unlocks_recipes()
  local technology = self.technology
  if not technology then
    return
  end

  local output = util.unique_id_array()

  for _, effect in pairs(technology.effects) do
    if effect.type == "unlock-recipe" and self.database:get_entry(effect) then
      output[#output + 1] = entry_id.new({ type = "recipe", name = effect.recipe }, self.database)
    end
  end

  return output
end

--- @return EntryID?
function entry:get_pumped_fluid()
  local entity = self.entity
  if not entity or entity.type ~= "offshore-pump" then
    return
  end

  local fluid = entity.fluid
  if not fluid or not self.database:get_entry(fluid) then
    return
  end

  return entry_id.new({ type = "fluid", name = fluid.name }, self.database)
end

--- @return EntryID?
function entry:get_generated_fluid()
  local entity = self.entity
  if not entity or entity.type ~= "boiler" then
    return
  end

  for _, fluidbox in pairs(entity.fluidbox_prototypes) do
    if fluidbox.production_type == "output" and fluidbox.filter then
      -- TODO: Check if multiple outputs are possible
      return entry_id.new(
        { type = "fluid", name = fluidbox.filter.name, temperature = entity.target_temperature },
        self.database
      )
    end
  end
end

--- @return EntryID[]
function entry:get_accepted_modules()
  --- @type EntryID[]
  local modules = {}

  local entity = self.entity
  if entity then
    local allowed_lookup = entity.allowed_effects
    for _, module in pairs(game.get_filtered_item_prototypes({ { filter = "type", type = "module" } })) do
      if not allowed_lookup then
        modules[#modules + 1] = entry_id.new({ type = "item", name = module.name }, self.database)
        goto continue
      end
      local module_effects = module.module_effects
      if not module_effects then
        goto continue
      end
      for effect in pairs(module_effects) do
        if not allowed_lookup[effect] then
          goto continue
        end
      end
      modules[#modules + 1] = entry_id.new({ type = "item", name = module.name }, self.database)
      ::continue::
    end
    -- TODO: Somehow distinguish recipe modules vs. entity modules
    return modules
  end

  local recipe = self.recipe
  if recipe then
    for _, module in pairs(game.get_filtered_item_prototypes({ { filter = "type", type = "module" } })) do
      local limitations = module.limitations
      if not limitations or #limitations == 0 then
        modules[#modules + 1] = entry_id.new({ type = "item", name = module.name }, self.database)
        goto continue
      end
      for _, recipe_name in pairs(limitations) do
        if recipe_name == recipe.name then
          modules[#modules + 1] = entry_id.new({ type = "item", name = module.name }, self.database)
        end
      end
      ::continue::
    end
  end

  return modules
end

--- @return EntryID?
function entry:get_material_consumption()
  local entity = self.entity
  if not entity then
    return
  end

  if entity.type == "boiler" then
    local input_fluid_box = entity.fluidbox_prototypes[1]
    local input_filter = input_fluid_box.filter
    if input_filter then
      local minimum_temperature = input_fluid_box.minimum_temperature or input_filter.default_temperature
      local flow_per_tick = (entity.target_temperature - minimum_temperature) * input_filter.heat_capacity
      return entry_id.new(
        { type = "fluid", name = input_filter.name, amount = entity.max_energy_usage / flow_per_tick * 60 },
        self.database
      )
    end
  elseif entity.type == "generator" then
    local fluid_box = entity.fluidbox_prototypes[1]
    local filter = fluid_box.filter
    if filter then
      return entry_id.new({
        type = "fluid",
        name = filter.name,
        amount = entity.fluid_usage_per_tick * 60,
        maximum_temperature = entity.maximum_temperature,
      }, self.database)
    end
  end
end

function entry:get_material_production()
  local entity = self.entity
  if not entity then
    return
  end

  if entity.type == "boiler" then
    local input_fluid_box = entity.fluidbox_prototypes[1]
    local input_filter = input_fluid_box.filter
    if input_filter then
      local output_fluid_box = entity.fluidbox_prototypes[2]
      local output_filter = output_fluid_box.filter
      if output_filter then
        local minimum_temperature = input_fluid_box.minimum_temperature or input_filter.default_temperature
        local flow_per_tick = (entity.target_temperature - minimum_temperature) * input_filter.heat_capacity
        return entry_id.new({
          type = "fluid",
          name = output_filter.name,
          amount = entity.max_energy_usage / flow_per_tick * 60,
          temperature = entity.target_temperature,
        }, self.database)
      end
    end
  end
end

--- @return {min: double, max: double}?
function entry:get_power_consumption()
  local entity = self.entity
  if not entity then
    return
  end

  local electric_energy_source_prototype = entity.electric_energy_source_prototype --[[@as LuaElectricEnergySourcePrototype]]
  if not electric_energy_source_prototype then
    return
  end

  -- local added_emissions = 0
  local max_energy_usage = entity.max_energy_usage or 0
  if max_energy_usage > 0 and max_energy_usage < flib_math.max_int53 then
    local drain = electric_energy_source_prototype.drain
    if max_energy_usage ~= drain then
      max_energy_usage = max_energy_usage + drain
    end
    return { min = drain * 60, max = max_energy_usage * 60 }
  end
end

--- @return double?
function entry:get_power_production()
  local entity = self.entity
  if not entity then
    return
  end

  local output = entity.max_power_output
  if not output then
    return
  end

  return output * 60
end

return entry
