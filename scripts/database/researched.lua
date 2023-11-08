--- @class researched
local researched = {}

--- @param entry PrototypeEntry
--- @param force_index uint
local function add_researched(entry, force_index)
  if entry.researched then
    entry.researched[force_index] = true
  else
    entry.researched = { [force_index] = true }
  end
end

--- @param entity LuaEntityPrototype
--- @param force_index uint
function researched.on_entity_unlocked(entity, force_index)
  local db = global.database
  local entry = db["entity/" .. entity.name]
  if entry then
    add_researched(entry, force_index)
  end
  if entity.type == "mining-drill" then
    -- Resources
    local categories = entity.resource_categories --[[@as table<string, _>]]
    local fluidbox = entity.fluidbox_prototypes[1]
    local fluidbox_filter = fluidbox and fluidbox.filter or nil
    for resource_name, resource in
      --- @diagnostic disable-next-line unused-fields
      pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "resource" } }))
    do
      local mineable = resource.mineable_properties
      if mineable.products and categories[resource.resource_category] then
        -- Check fluid compatibility
        local required_fluid = mineable.required_fluid
        if not required_fluid or (fluidbox and (not fluidbox_filter or fluidbox_filter == required_fluid)) then
          -- Add resource entry
          local resource_entry = db["entity/" .. resource_name]
          if resource_entry then
            add_researched(resource_entry, force_index)
          end
          for _, product in pairs(mineable.products) do
            researched.on_product_unlocked(product, force_index)
          end
        end
      end
    end
  elseif entity.type == "offshore-pump" then
    -- Pumped fluid
    local fluid = entity.fluid
    if fluid then
      local fluid_entry = db["fluid/" .. fluid.name]
      if fluid_entry then
        add_researched(fluid_entry, force_index)
      end
    end
  elseif entity.type == "boiler" then
    -- Produced fluid
    for _, fluidbox in pairs(entity.fluidbox_prototypes) do
      if fluidbox.production_type == "output" and fluidbox.filter then
        researched.on_product_unlocked({ type = "fluid", name = fluidbox.filter.name }, force_index)
      end
    end
  end
end

--- @param product Product
--- @param force_index uint
function researched.on_product_unlocked(product, force_index)
  local db = global.database
  local entry = db[product.type .. "/" .. product.name]
  if not entry then
    return
  end
  add_researched(entry, force_index)
  local prototype
  if product.type == "fluid" then
    prototype = game.fluid_prototypes[product.name]
  else
    prototype = game.item_prototypes[product.name]
  end
  if product.type == "item" then
    -- Rocket launch products
    local rocket_launch_products = prototype.rocket_launch_products
    if rocket_launch_products then
      for _, product in pairs(rocket_launch_products) do
        researched.on_product_unlocked(product, force_index)
      end
    end
    -- Burnt results
    local burnt_result = prototype.burnt_result
    if burnt_result then
      researched.on_product_unlocked({ type = "item", name = burnt_result.name }, force_index)
    end
    -- Place result
    local place_result = prototype.place_result
    if place_result then
      researched.on_entity_unlocked(place_result, force_index)
    end
  end
end

--- @param recipe LuaRecipe
--- @param force_index uint
function researched.on_recipe_unlocked(recipe, force_index)
  local db = global.database
  local entry = db["recipe/" .. recipe.name]
  if not entry then
    return
  end
  add_researched(entry, force_index)
  if recipe.prototype.unlock_results then
    for _, product in pairs(recipe.products) do
      researched.on_product_unlocked(product, force_index)
    end
  end
end

--- @param technology LuaTechnology
--- @param force_index uint
function researched.on_technology_researched(technology, force_index)
  local db = global.database
  if not db then
    return
  end
  local technology_name = technology.name
  local technology_path = "technology/" .. technology_name
  if not db[technology_path] then
    db[technology_path] = { base = technology.prototype, base_path = technology_path, researched = {} }
  end
  add_researched(db[technology_path], force_index)
  for _, effect in pairs(technology.effects) do
    if effect.type == "unlock-recipe" then
      local recipe = technology.force.recipes[effect.recipe]
      researched.on_recipe_unlocked(recipe, force_index)
    end
  end
end

--- @param force LuaForce
function researched.refresh(force)
  local force_index = force.index
  -- Gather-able items
  for _, entity in
    pairs(game.get_filtered_entity_prototypes({
      --- @diagnostic disable-next-line unused-fields
      { filter = "type", type = "simple-entity" },
      --- @diagnostic disable-next-line unused-fields
      { filter = "type", type = "tree" },
    }))
  do
    if entity.type == "tree" or entity.count_as_rock_for_filtered_deconstruction then
      local mineable = entity.mineable_properties
      if mineable.minable and mineable.products then
        for _, product in pairs(mineable.products) do
          researched.on_product_unlocked(product, force_index)
        end
      end
    end
  end
  -- Technologies
  for _, technology in pairs(force.technologies) do
    if technology.researched then
      researched.on_technology_researched(technology, force_index)
    end
  end
  -- Recipes (some may be enabled without technologies)
  local db = global.database
  for _, recipe in pairs(force.recipes) do
    -- Some recipes will be enabled from the start, but will only be craftable in machines
    if recipe.enabled and not (recipe.prototype.enabled and recipe.prototype.hidden_from_player_crafting) then
      local entry = db["recipe/" .. recipe.name]
      if entry and not (entry.researched or {})[force_index] then
        add_researched(entry, force_index)
        researched.on_recipe_unlocked(recipe, force_index)
      end
    end
  end
  -- Characters
  -- TODO: Gate some characters if mods "unlock" them (Nullius)?
  --- @diagnostic disable-next-line unused-fields
  for name in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "character" } })) do
    local entry = db["entity/" .. name]
    if entry then
      add_researched(entry, force_index)
    end
  end
end

return researched
