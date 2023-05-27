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

--- @param gui GuiData
--- @param context Context
--- @param recipe string?
--- @return LuaRecipePrototype[]?, integer?
local function get_list(gui, context, recipe)
  local recipes_array = {}
  local pseudo = context.kind == "recipes" and global.pseudo_recipes or global.pseudo_usage
  for _, pseudo_recipe in pairs(pseudo[context.type .. "/" .. context.name] or {}) do
    recipes_array[#recipes_array + 1] = pseudo_recipe
  end
  local filters = {
    {
      filter = context_kind_filter[context.kind] .. context.type,
      elem_filters = { { filter = "name", name = context.name } },
    },
  }
  if not gui.show_hidden then
    filters[#filters + 1] = { mode = "and", filter = "hidden", invert = true }
  end
  local recipes = game.get_filtered_recipe_prototypes(filters)
  local recipe_index = 1
  local force_recipes = gui.player.force.recipes
  for recipe_name, recipe_prototype in pairs(recipes) do
    if not gui.show_unresearched and not force_recipes[recipe_name].enabled then
      goto continue
    end
    recipes_array[#recipes_array + 1] = recipe_prototype
    if recipe_name == recipe then
      recipe_index = #recipes_array
    end
    ::continue::
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
    local fuel_category = recipe.category
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
  elseif recipe.object_name == "rb-pseudo-mining" then
    local output = {}
    local resource_category = recipe.category
    for drill_name, drill in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "mining-drill" } })) do
      if not drill.resource_categories[resource_category] then
        goto continue
      end
      local required_fluid = recipe.ingredients[2]
      if required_fluid then
        local fluidbox = drill.fluidbox_prototypes[1]
        if not fluidbox then
          goto continue
        end
        if fluidbox.filter and fluidbox.filter.name ~= required_fluid.name then
          goto continue
        end
      end
      output[#output + 1] = { type = "entity", name = drill_name, amount = recipe.energy / drill.mining_speed }
      ::continue::
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
    category = item.fuel_category,
    sprite_path = "item/" .. item_name,
    object_name = "rb-pseudo-burning",
  }
  table.insert(flib_table.get_or_insert(global.pseudo_usage, "item/" .. item_name, {}), pseudo)
  table.insert(flib_table.get_or_insert(global.pseudo_recipes, "item/" .. burnt_result.name, {}), pseudo)
end

--- @param resource LuaEntityPrototype
--- @param resource_name string
--- @param mineable_properties LuaEntityPrototype.mineable_properties
local function create_mining_recipe(resource, resource_name, mineable_properties)
  local products = mineable_properties.products
  if not products then
    return
  end

  local pseudo = {
    name = "rb-pseudo-" .. resource_name .. "-mining",
    localised_name = { "recipe-name.rb-pseudo-mining", resource.localised_name },
    energy = mineable_properties.mining_time,
    ingredients = { { type = "entity", name = resource_name } },
    products = products,
    category = resource.resource_category,
    sprite_path = "entity/" .. resource_name,
    object_name = "rb-pseudo-mining",
  }
  if mineable_properties.required_fluid then
    table.insert(
      pseudo.ingredients,
      { type = "fluid", name = mineable_properties.required_fluid, amount = mineable_properties.fluid_amount }
    )
  end
  for _, product in pairs(products) do
    table.insert(flib_table.get_or_insert(global.pseudo_recipes, product.type .. "/" .. product.name, {}), pseudo)
  end
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
  for resource_name, resource in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "resource" } })) do
    local mineable_properties = resource.mineable_properties
    if mineable_properties then
      create_mining_recipe(resource, resource_name, mineable_properties)
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
