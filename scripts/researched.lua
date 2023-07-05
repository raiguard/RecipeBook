local util = require("__RecipeBook__/scripts/util")

--- @alias ForceIndex uint

local unlock_products

--- @param entity LuaEntityPrototype
--- @param researched Set<string>
local function unlock_mining_drill_products(entity, researched)
  --- @type string|boolean?
  local filter
  for _, fluidbox_prototype in pairs(entity.fluidbox_prototypes) do
    local production_type = fluidbox_prototype.production_type
    if production_type == "input" or production_type == "input-output" then
      filter = fluidbox_prototype.filter and fluidbox_prototype.filter.name or true
      break
    end
  end
  -- TODO: Handle if the required fluid is not unlocked
  local resource_categories = entity.resource_categories
  --- @cast resource_categories Set<string>
  for _, resource in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "resource" } })) do
    local mineable = resource.mineable_properties
    local required_fluid = mineable.required_fluid
    if
      resource_categories[resource.resource_category]
      and (not required_fluid or filter == true or filter == required_fluid)
    then
      local products = resource.mineable_properties.products
      if products then
        unlock_products(products, researched)
      end
    end
  end
end

--- @param fluid LuaFluidPrototype
--- @param researched Set<string>
local function unlock_fluid(fluid, researched)
  local key = "fluid/" .. fluid.name
  if researched[key] then
    return
  end
  researched[key] = true
end

--- @param entity LuaEntityPrototype
--- @param researched Set<string>
local function unlock_entity(entity, researched)
  local key = "entity/" .. entity.name
  if researched[key] then
    return
  end
  researched[key] = true

  if entity.type == "boiler" then
    local output_fluid = entity.fluidbox_prototypes[2].filter
    if output_fluid then
      unlock_fluid(output_fluid, researched)
    end
  elseif entity.type == "mining-drill" then
    unlock_mining_drill_products(entity, researched)
  elseif entity.type == "offshore-pump" then
    local fluid = entity.fluid --[[@as LuaFluidPrototype]]
    unlock_fluid(fluid, researched)
  end
end

--- @param item LuaItemPrototype
--- @param researched Set<string>
local function unlock_item(item, researched)
  local key = "item/" .. item.name
  if researched[key] then
    return
  end
  researched[key] = true

  -- TODO: Handle Exotic Industries' scripted rocket launch products
  for _, product in pairs(item.rocket_launch_products) do
    local product_prototype = game.item_prototypes[product.name]
    unlock_item(product_prototype, researched)
  end

  local place_result = item.place_result
  if place_result then
    unlock_entity(place_result, researched)
  end

  local burnt_result = item.burnt_result
  if burnt_result then
    unlock_item(burnt_result, researched)
  end
end

--- @param products Product[]
--- @param researched Set<string>
function unlock_products(products, researched)
  for _, product in pairs(products) do
    if product.type == "fluid" then
      unlock_fluid(game.fluid_prototypes[product.name], researched)
    else
      unlock_item(game.item_prototypes[product.name], researched)
    end
  end
end

--- @param recipe LuaRecipe
--- @param researched Set<string>
local function unlock_recipe(recipe, researched)
  local key = "recipe/" .. recipe.name
  if researched[key] then
    return
  end
  researched[key] = true

  local recipe_prototype = recipe.prototype
  if not recipe_prototype.unlock_results then
    return
  end

  unlock_products(recipe.products, researched)
end

--- @param technology LuaTechnology
--- @param researched Set<string>
local function unlock_technology(technology, researched)
  local recipes = technology.force.recipes
  researched["technology/" .. technology.name] = true
  for _, effect in pairs(technology.effects) do
    if effect.type == "unlock-recipe" then
      unlock_recipe(recipes[effect.recipe], researched)
    end
  end
  for _, player in pairs(technology.force.players) do
    util.schedule_gui_refresh(player)
  end
end

--- @param e EventData.on_research_finished
local function on_research_finished(e)
  if not global.researched_objects then
    return
  end
  local technology = e.research
  local researched = global.researched_objects[technology.force.index]
  if not researched then
    return
  end
  unlock_technology(technology, researched)
end

--- @param force LuaForce
local function refresh_force(force)
  local researched = {}
  for _, technology in pairs(force.technologies) do
    if technology.researched then
      unlock_technology(technology, researched)
    end
  end
  for _, recipe in pairs(force.recipes) do
    if recipe.enabled and not researched["recipe/" .. recipe.name] then
      unlock_recipe(recipe, researched)
    end
  end
  -- Trees and rocks
  local flora = game.get_filtered_entity_prototypes({
    { filter = "type", type = "simple-entity" },
    { filter = "type", type = "tree" },
  })
  for _, entity in pairs(flora) do
    local mineable_properties = entity.mineable_properties
    local products = mineable_properties.products
    if products and not mineable_properties.required_fluid then
      -- TODO: Character mining categories?
      unlock_products(products, researched)
    end
    -- TODO: "Gathered from" lists
  end
  global.researched_objects[force.index] = researched
end

--- @param e EventData.on_force_created
local function on_force_created(e)
  if not global.researched_objects then
    return
  end
  refresh_force(e.force)
end

local function refresh_all_forces()
  for _, force in pairs(game.forces) do
    refresh_force(force)
  end
end

local researched = {}

researched.on_init = function()
  --- @type table<ForceIndex, Set<string>>
  global.researched_objects = {}
  refresh_all_forces()
end

researched.on_configuration_changed = refresh_all_forces

researched.events = {
  [defines.events.on_force_created] = on_force_created,
  [defines.events.on_research_finished] = on_research_finished,
}

return researched
