local flib_table = require("__flib__/table")

--- @class DatabaseRecipe
--- @field type "recipe"
--- @field name string
--- @field localised_name LocalisedString
--- @field sprite_path SpritePath
--- @field hidden boolean?
--- @field energy double
--- @field ingredients table<SpritePath, Ingredient>
--- @field products table<SpritePath, Product>
--- @field is_hand_craftable boolean?
--- @field made_in table<SpritePath, DatabaseRecipeDefinition>?
--- @field unlocked_by Set<SpritePath>?

--- @alias MaterialType "fluid"|"item"

--- @class DatabaseRecipeDefinition
--- @field type string
--- @field name string
--- @field amount double?

--- @alias UnlockedByLookup table<SpritePath, Set<SpritePath>>

--- @generic T
--- @param array T[]
--- @return table<SpritePath, T>
local function make_sprite_path_lookup(array)
  local output = {}
  for _, obj in pairs(array) do
    output[obj.type .. "/" .. obj.name] = obj
  end
  return output
end

--- @param lookup UnlockedByLookup
--- @param key string
--- @param value string
--- @return boolean already_existed
local function add_lookup(lookup, key, value)
  if not lookup[key] then
    lookup[key] = {}
  end
  if lookup[key][value] then
    return true
  end
  lookup[key][value] = true
  return false
end

local unlocked_by_products

--- @param lookup UnlockedByLookup
--- @param entity LuaEntityPrototype
--- @param technology string
local function unlocked_by_mining_drill_products(lookup, entity, technology)
  --- @type string|boolean?
  local filter
  for _, fluidbox_prototype in pairs(entity.fluidbox_prototypes) do
    local production_type = fluidbox_prototype.production_type
    if production_type == "input" or production_type == "input-output" then
      filter = fluidbox_prototype.filter and fluidbox_prototype.filter.name or true
      break
    end
  end
  local resource_categories = entity.resource_categories
  --- @cast resource_categories UnlockedByLookup
  for _, resource in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "resource" } })) do
    if not add_lookup(lookup, "entity/" .. resource.name, technology) then
      local mineable = resource.mineable_properties
      local required_fluid = mineable.required_fluid
      if
        resource_categories[resource.resource_category]
        and (not required_fluid or filter == true or filter == required_fluid)
      then
        local products = resource.mineable_properties.products
        if products then
          unlocked_by_products(lookup, products, technology)
        end
      end
    end
  end
end

--- @param lookup UnlockedByLookup
--- @param fluid LuaFluidPrototype
--- @param technology string
local function unlocked_by_fluid(lookup, fluid, technology)
  add_lookup(lookup, "fluid/" .. fluid.name, technology)
end

--- @param lookup UnlockedByLookup
--- @param entity LuaEntityPrototype
--- @param technology string
local function unlocked_by_entity(lookup, entity, technology)
  if add_lookup(lookup, "entity/" .. entity.name, technology) then
    return
  end

  if entity.type == "boiler" then
    local output_fluid = entity.fluidbox_prototypes[2].filter
    if output_fluid then
      unlocked_by_fluid(lookup, output_fluid, technology)
    end
  elseif entity.type == "mining-drill" then
    unlocked_by_mining_drill_products(lookup, entity, technology)
  elseif entity.type == "offshore-pump" then
    local fluid = entity.fluid --[[@as LuaFluidPrototype]]
    unlocked_by_fluid(lookup, fluid, technology)
  end
end

--- @param lookup UnlockedByLookup
--- @param item LuaItemPrototype
--- @param technology string
local function unlocked_by_item(lookup, item, technology)
  if add_lookup(lookup, "item/" .. item.name, technology) then
    return
  end

  for _, product in pairs(item.rocket_launch_products) do
    local product_prototype = game.item_prototypes[product.name]
    unlocked_by_item(lookup, product_prototype, technology)
  end

  local place_result = item.place_result
  if place_result then
    unlocked_by_entity(lookup, place_result, technology)
  end

  local burnt_result = item.burnt_result
  if burnt_result then
    unlocked_by_item(lookup, burnt_result, technology)
  end
end

--- @param lookup UnlockedByLookup
--- @param products Product[]
--- @param technology string
function unlocked_by_products(lookup, products, technology)
  for _, product in pairs(products) do
    if product.type == "fluid" then
      unlocked_by_fluid(lookup, game.fluid_prototypes[product.name], technology)
    else
      unlocked_by_item(lookup, game.item_prototypes[product.name], technology)
    end
  end
end

--- @param gui GuiData
--- @param context Context
--- @param recipe string?
--- @return DatabaseRecipe[], integer
local function get_recipes(gui, context, recipe)
  local researched = global.researched_objects[gui.player.force_index]
  local show_hidden = gui.show_hidden
  local show_unresearched = gui.show_unresearched
  local material_key = context.type .. "/" .. context.name
  local subtable_key = context.kind == "recipes" and "products" or "ingredients"
  local output = {}
  local index = 1
  for key, obj in pairs(global.database) do
    if obj.type ~= "recipe" or not obj[subtable_key][material_key] then
      goto continue
    end
    if obj.hidden and not show_hidden then
      goto continue
    end
    if not researched[key] and not show_unresearched then
      goto continue
    end
    output[#output + 1] = obj
    if obj.name == recipe then
      index = #output
    end
    ::continue::
  end
  return output, index
end

--- @param item LuaItemPrototype
--- @param item_name string
--- @param launch_products Product[]
--- @param unlocked_by_lookup UnlockedByLookup
local function add_launch_recipe(item, item_name, launch_products, unlocked_by_lookup)
  local machines = game.get_filtered_entity_prototypes({ filter = { filter = "type", type = "rocket-silo" } })
  local made_in = {}
  for _, machine in pairs(machines) do
    made_in[#made_in + 1] = { type = "entity", name = machine.name, amount = machine.rocket_parts_required }
  end

  local name = "rb-pseudo-" .. item_name .. "-rocket-launch"
  global.database["recipe/" .. name] = {
    type = "recipe",
    name = name,
    localised_name = { "recipe-name.rb-pseudo-rocket-launch", item.localised_name },
    sprite_path = "item/" .. item_name,
    energy = 1,
    ingredients = make_sprite_path_lookup({ { type = "item", name = item_name, amount = 1 } }),
    products = make_sprite_path_lookup(launch_products),
    made_in = made_in,
    unlocked_by = unlocked_by_lookup["item/" .. item_name],
  }
end

--- @param item LuaItemPrototype
--- @param item_name string
--- @param burnt_result LuaItemPrototype
--- @param unlocked_by_lookup UnlockedByLookup
local function add_burning_recipe(item, item_name, burnt_result, unlocked_by_lookup)
  local name = "rb-pseudo-" .. item_name .. "-burning"

  local buildings = game.get_filtered_entity_prototypes({ { filter = "building" } })
  local made_in = {}
  local fuel_category = item.fuel_category
  for _, machine in pairs(buildings) do
    if machine.burner_prototype and machine.burner_prototype.fuel_categories[fuel_category] then
      made_in[#made_in + 1] = {
        type = "entity",
        name = machine.name,
        amount = item.fuel_value / (machine.max_energy_usage / machine.burner_prototype.effectivity) / 60,
      }
    end
  end

  global.database["recipe/" .. name] = {
    type = "recipe",
    name = name,
    localised_name = { "recipe-name.rb-pseudo-burning", item.localised_name },
    sprite_path = "item/" .. item_name,
    energy = 1,
    ingredients = make_sprite_path_lookup({ { type = "item", name = item_name, amount = 1 } }),
    products = make_sprite_path_lookup({ { type = "item", name = burnt_result.name, amount = 1 } }),
    made_in = made_in,
    unlocked_by = unlocked_by_lookup["item/" .. item_name],
  }
end

--- @param resource LuaEntityPrototype
--- @param resource_name string
--- @param mineable_properties LuaEntityPrototype.mineable_properties
--- @param unlocked_by_lookup UnlockedByLookup
local function add_mining_recipe(resource, resource_name, mineable_properties, unlocked_by_lookup)
  local products = mineable_properties.products
  if not products then
    return
  end

  local required_fluid
  if mineable_properties.required_fluid then
    required_fluid = {
      type = "fluid",
      name = mineable_properties.required_fluid,
      amount = mineable_properties.fluid_amount,
    }
  end

  local made_in = {}
  local unlocked_by = {}
  local resource_category = resource.resource_category
  for drill_name, drill in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "mining-drill" } })) do
    if not drill.resource_categories[resource_category] then
      goto continue
    end
    if required_fluid then
      local fluidbox = drill.fluidbox_prototypes[1]
      if not fluidbox then
        goto continue
      end
      if fluidbox.filter and fluidbox.filter.name ~= required_fluid.name then
        goto continue
      end
    end
    made_in["entity/" .. drill_name] =
      { type = "entity", name = drill_name, amount = mineable_properties.mining_time / drill.mining_speed }
    for technology in pairs(unlocked_by_lookup["entity/" .. drill_name] or {}) do
      unlocked_by[technology] = true
    end
    ::continue::
  end

  local name = "rb-pseudo-" .. resource_name .. "-mining"
  local recipe = {
    type = "recipe",
    name = name,
    localised_name = { "recipe-name.rb-pseudo-mining", resource.localised_name },
    sprite_path = "entity/" .. resource_name,
    energy = mineable_properties.mining_time,
    ingredients = make_sprite_path_lookup({ { type = "entity", name = resource_name }, required_fluid }),
    products = make_sprite_path_lookup(products),
    made_in = made_in,
    unlocked_by = unlocked_by,
  }
  global.database["recipe/" .. name] = recipe
end

--- @param boiler LuaEntityPrototype
--- @param boiler_name string
--- @param unlocked_by_lookup UnlockedByLookup
local function add_boiler_recipe(boiler, boiler_name, unlocked_by_lookup)
  local fluidbox = boiler.fluidbox_prototypes

  local input = fluidbox[1].filter
  local output = fluidbox[2].filter
  if not (input and output) then
    return
  end

  local name = "rb-pseudo-" .. input.name .. "-boiling"
  local path = "recipe/" .. name
  local existing = global.database[path]
  if existing then
    existing.made_in["entity/" .. boiler_name] = { type = "entity", name = boiler_name }
    for technology in pairs(unlocked_by_lookup["entity/" .. boiler_name] or {}) do
      existing.unlocked_by[technology] = true
    end
    return
  end

  global.database[path] = {
    type = "recipe",
    name = name,
    localised_name = { "recipe-name.rb-pseudo-boiling", input.localised_name },
    sprite_path = "fluid/" .. output.name, -- TODO: Super special icons for these?
    energy = 1, -- TODO:
    ingredients = make_sprite_path_lookup({ { type = "fluid", name = input.name } }),
    products = make_sprite_path_lookup({ { type = "fluid", name = output.name } }), -- TODO: Temperature
    made_in = make_sprite_path_lookup({ { type = "entity", name = boiler_name } }),
    unlocked_by = flib_table.shallow_copy(unlocked_by_lookup["entity/" .. boiler_name] or {}),
  }
end

--- @param recipe LuaRecipePrototype
--- @param unlocked_by_lookup table<SpritePath, Set<SpritePath>>
local function add_real_recipe(recipe, unlocked_by_lookup)
  local item_ingredients = 0
  for _, ingredient in pairs(recipe.ingredients) do
    if ingredient.type == "item" then
      item_ingredients = item_ingredients + 1
    end
  end
  local machines =
    game.get_filtered_entity_prototypes({ { filter = "crafting-category", crafting_category = recipe.category } })
  local made_in = {}
  for _, machine in pairs(machines) do
    local ingredient_count = machine.ingredient_count
    if ingredient_count == 0 or ingredient_count >= item_ingredients then
      made_in[#made_in + 1] = { type = "entity", name = machine.name, amount = recipe.energy / machine.crafting_speed }
    end
  end

  local unlocked_by = {}
  for name in pairs(game.get_filtered_technology_prototypes({ { filter = "unlocks-recipe", recipe = recipe.name } })) do
    unlocked_by["technology/" .. name] = true
    unlocked_by_products(unlocked_by_lookup, recipe.products, "technology/" .. name)
  end

  global.database["recipe/" .. recipe.name] = {
    type = "recipe",
    name = recipe.name,
    localised_name = recipe.localised_name,
    sprite_path = "recipe/" .. recipe.name,
    hidden = recipe.hidden or nil,
    energy = recipe.energy,
    ingredients = make_sprite_path_lookup(recipe.ingredients),
    products = make_sprite_path_lookup(recipe.products),
    is_hand_craftable = game.entity_prototypes["character"].crafting_categories[recipe.category] and true or nil,
    made_in = made_in,
    unlocked_by = unlocked_by,
  }
end

local function add_objects()
  --- @type table<SpritePath, DatabaseRecipe?>
  global.database = {}
  --- @type UnlockedByLookup
  local unlocked_by_lookup = {}

  for _, recipe in pairs(game.recipe_prototypes) do
    add_real_recipe(recipe, unlocked_by_lookup)
  end

  for item_name, item in pairs(game.item_prototypes) do
    local launch_products = item.rocket_launch_products
    if launch_products[1] then
      add_launch_recipe(item, item_name, launch_products, unlocked_by_lookup)
    end
    local burnt_result = item.burnt_result
    if burnt_result then
      add_burning_recipe(item, item_name, burnt_result, unlocked_by_lookup)
    end
  end

  for resource_name, resource in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "resource" } })) do
    local mineable_properties = resource.mineable_properties
    if mineable_properties then
      add_mining_recipe(resource, resource_name, mineable_properties, unlocked_by_lookup)
    end
  end

  for boiler_name, boiler in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "boiler" } })) do
    add_boiler_recipe(boiler, boiler_name, unlocked_by_lookup)
  end
end

local function refresh()
  add_objects()
end

local database = {}

database.on_init = refresh
database.on_configuration_changed = refresh

database.get_recipes = get_recipes

return database
