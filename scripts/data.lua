local util = require("__RecipeBookLite__/scripts/util")

-- TODO: Gatherable materials (wood, stone, hand-mineable ores)

local unlock_products

--- @param entity LuaEntityPrototype
--- @param force_index uint
local function unlock_mining_products(entity, force_index)
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
  --- @cast resource_categories Set<string>
  for _, resource in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "resource" } })) do
    local mineable = resource.mineable_properties
    local required_fluid = mineable.required_fluid
    if
      resource_categories[resource.resource_category]
      and (not required_fluid or filter == true or filter == required_fluid)
    then
      unlock_products(resource.mineable_properties.products, force_index)
    end
  end
end

--- @param entity LuaEntityPrototype
--- @param force_index uint
local function unlock_entity(entity, force_index)
  global.researched_objects[force_index]["entity/" .. entity.name] = true

  if entity.type == "mining-drill" then
    unlock_mining_products(entity, force_index)
  elseif entity.type == "offshore-pump" then
    local fluid = entity.fluid --[[@as LuaFluidPrototype]]
    global.researched_objects["fluid/" .. fluid.name] = true
  end
end

--- @param fluid LuaFluidPrototype
--- @param force_index uint
local function unlock_fluid(fluid, force_index)
  global.researched_objects[force_index]["fluid/" .. fluid.name] = true
end

--- @param item LuaItemPrototype
--- @param force_index uint
local function unlock_item(item, force_index)
  global.researched_objects[force_index]["item/" .. item.name] = true

  for _, product in pairs(item.rocket_launch_products) do
    local product_prototype = game.item_prototypes[product.name]
    unlock_item(product_prototype, force_index)
  end

  local place_result = item.place_result
  if place_result then
    unlock_entity(place_result, force_index)
  end

  local burnt_result = item.burnt_result
  if burnt_result then
    unlock_item(burnt_result, force_index)
  end
end

--- @param products Product[]
--- @param force_index uint
function unlock_products(products, force_index)
  for _, product in pairs(products) do
    if product.type == "fluid" then
      unlock_fluid(game.fluid_prototypes[product.name], force_index)
    else
      unlock_item(game.item_prototypes[product.name], force_index)
    end
  end
end

--- @param recipe LuaRecipe
--- @param force_index uint
local function unlock_recipe(recipe, force_index)
  global.researched_objects[force_index]["recipe/" .. recipe.name] = true

  local recipe_prototype = recipe.prototype
  if not recipe_prototype.unlock_results then
    return
  end

  unlock_products(recipe.products, force_index)
end

--- @param e EventData.on_research_finished
local function on_research_finished(e)
  local research = e.research
  local recipes = research.force.recipes
  local force_index = research.force.index
  for _, effect in pairs(research.effects) do
    if effect.type == "unlock-recipe" then
      local recipe = recipes[effect.recipe]
      unlock_recipe(recipe, force_index)
    end
  end
  for _, player in pairs(research.force.players) do
    util.schedule_gui_refresh(player)
  end
end

--- @param force LuaForce
local function refresh_force(force)
  local force_index = force.index
  global.researched_objects[force_index] = {}
  for _, recipe in pairs(force.recipes) do
    if recipe.enabled then
      unlock_recipe(recipe, force_index)
    end
  end
end

--- @param e EventData.on_force_created
local function on_force_created(e)
  refresh_force(e.force)
end

local function refresh_all_forces()
  for _, force in pairs(game.forces) do
    refresh_force(force)
  end
end

local data = {}

data.on_init = function()
  --- @type table<uint, Set<string>>
  global.researched_objects = {}
  refresh_all_forces()
end

data.on_configuration_changed = refresh_all_forces

data.events = {
  [defines.events.on_force_created] = on_force_created,
  [defines.events.on_research_finished] = on_research_finished,
}

return data
