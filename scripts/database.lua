local flib_table = require("__flib__/table")

-- FIXME: Has issues with LuaObject inheritance
--- @alias RBRecipePrototype LuaRecipePrototype|PseudoRecipePrototype

--- @alias RBRecipePrototypeObjectName
--- | "LuaRecipePrototype"
--- | "rb-pseudo-burning"
--- | "rb-pseudo-rocket-launch"

--- @class PseudoRecipePrototype
--- @field name string
--- @field localised_name LocalisedString
--- @field energy double
--- @field ingredients Ingredient[]
--- @field products Product[]
--- @field sprite_path SpritePath
--- @field object_name RBRecipePrototypeObjectName

--- @type table<ContextKind, string>
local context_kind_filter = {
  usage = "has-ingredient-",
  recipes = "has-product-",
}

--- @param context Context
--- @param recipe string?
--- @return LuaRecipePrototype[]?, integer?
local function get_list(context, recipe)
  local recipes_array = {}
  local pseudo = context.kind == "recipes" and global.pseudo_recipes or global.pseudo_usage
  for _, pseudo_recipe in pairs(pseudo[context.type .. "/" .. context.name] or {}) do
    recipes_array[#recipes_array + 1] = pseudo_recipe
  end
  local recipes = game.get_filtered_recipe_prototypes({
    {
      filter = context_kind_filter[context.kind] .. context.type,
      elem_filters = { { filter = "name", name = context.name } },
    },
  })
  local recipe_index = 1
  for recipe_name, recipe_prototype in pairs(recipes) do
    recipes_array[#recipes_array + 1] = recipe_prototype
    if recipe_name == recipe then
      recipe_index = #recipes_array
    end
  end
  if not recipes_array[1] then
    return nil
  end
  return recipes_array, recipe_index
end

--- @alias GenericObject Ingredient|Product|RBObject

--- @class RBObject
--- @field type string
--- @field name string
--- @field amount number

--- @param recipe LuaRecipePrototype
--- @param item_ingredients integer
--- @return GenericObject[]
local function get_made_in(recipe, item_ingredients)
  if recipe.object_name == "LuaRecipePrototype" then
    local machines =
      game.get_filtered_entity_prototypes({ { filter = "crafting-category", crafting_category = recipe.category } })
    local output = {}
    for _, machine in pairs(machines) do
      local ingredient_count = machine.ingredient_count
      if ingredient_count == 0 or ingredient_count >= item_ingredients then
        output[#output + 1] = { type = "entity", name = machine.name, amount = recipe.energy / machine.crafting_speed }
      end
    end
    return output
  elseif recipe.object_name == "rb-pseudo-rocket-launch" then
    local machines = game.get_filtered_entity_prototypes({ filter = { filter = "type", type = "rocket-silo" } })
    local output = {}
    for _, machine in pairs(machines) do
      output[#output + 1] = { type = "entity", name = machine.name, amount = machine.rocket_parts_required }
    end
    return output
  elseif recipe.object_name == "rb-pseudo-burning" then
    local fuel = game.item_prototypes[recipe.ingredients[1].name]
    local buildings = game.get_filtered_entity_prototypes({ { filter = "building" } })
    local output = {}
    local fuel_category = recipe.fuel_category
    for _, machine in pairs(buildings) do
      if machine.burner_prototype and machine.burner_prototype.fuel_categories[fuel_category] then
        output[#output + 1] = {
          type = "entity",
          name = machine.name,
          amount = fuel.fuel_value / (machine.max_energy_usage / machine.burner_prototype.effectivity) / 60,
        }
      end
    end
    return output
  end
  return {}
end

--- @param item LuaItemPrototype
--- @param item_name string
--- @param launch_products Product[]
local function create_launch_recipe(item, item_name, launch_products)
  local pseudo = {
    name = "rb-pseudo-" .. item_name .. "-rocket-launch",
    localised_name = { "recipe-name.rb-pseudo-rocket-launch", item.localised_name },
    energy = 1,
    ingredients = { { type = "item", name = item_name, amount = 1 } },
    products = launch_products,
    sprite_path = "item/" .. item_name,
    object_name = "rb-pseudo-rocket-launch",
  }
  table.insert(flib_table.get_or_insert(global.pseudo_usage, "item/" .. item_name, {}), pseudo)
  for _, product in pairs(launch_products) do
    table.insert(flib_table.get_or_insert(global.pseudo_recipes, "item/" .. product.name, {}), pseudo)
  end
end

--- @param item LuaItemPrototype
--- @param item_name string
--- @param burnt_result LuaItemPrototype
local function create_burning_recipe(item, item_name, burnt_result)
  local pseudo = {
    name = "rb-pseudo-" .. item_name .. "-burning",
    localised_name = { "recipe-name.rb-pseudo-burning", item.localised_name },
    energy = 1,
    ingredients = { { type = "item", name = item_name, amount = 1 } },
    products = { { type = "item", name = burnt_result.name, amount = 1 } },
    fuel_category = item.fuel_category,
    sprite_path = "item/" .. item_name,
    object_name = "rb-pseudo-burning",
  }
  table.insert(flib_table.get_or_insert(global.pseudo_usage, "item/" .. item_name, {}), pseudo)
  table.insert(flib_table.get_or_insert(global.pseudo_recipes, "item/" .. burnt_result.name, {}), pseudo)
end

local function refresh_database()
  for item_name, item in pairs(game.item_prototypes) do
    local launch_products = item.rocket_launch_products
    if launch_products[1] then
      create_launch_recipe(item, item_name, launch_products)
    end
    local burnt_result = item.burnt_result
    if burnt_result then
      create_burning_recipe(item, item_name, burnt_result)
    end
  end
end

--- @class Database
local database = {}

function database.on_init()
  --- @type table<string, LuaRecipePrototype>
  global.pseudo_usage = {}
  --- @type table<string, LuaRecipePrototype>
  global.pseudo_recipes = {}

  refresh_database()
end

database.on_configuration_changed = refresh_database

database.get_list = get_list
database.get_made_in = get_made_in

return database
