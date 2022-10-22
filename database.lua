-- DESIGN GOALS:
-- Find a balance between caching information and generating it on the fly
-- Reduce complexity as much as possible
-- Don't rely on translated strings at all
-- Type annotations!!!

local database = {}

--- @param a GenericPrototype
--- @param b GenericPrototype
local function compare_icons(a, b)
  -- TODO:
  return true
end

--- @class SubgroupData
--- @field members GenericPrototype[]
--- @field parent_name string

function database.build()
  log("Starting database generation")
  local profiler = game.create_profiler()

  --- Each prototype separated by group and subgroup, sorted
  --- @type table<string, table<string, GenericPrototype>>
  local groups = {}
  for group_name, group_prototype in pairs(game.item_group_prototypes) do
    local subgroups = {}
    for _, subgroup_prototype in pairs(group_prototype.subgroups) do
      subgroups[subgroup_prototype.name] = {}
    end
    groups[group_name] = subgroups
  end
  --- Indexable table of objects
  --- @type table<string, PrototypeGroup>
  local lookup = {}

  --- @param prototype GenericPrototype
  local function add_to_subgroup(prototype)
    local prototypes = groups[prototype.group.name][prototype.subgroup.name]
    local order = prototype.order
    -- TODO: Binary search
    for i, other in pairs(prototypes) do
      if order <= other.order then
        added = true
        table.insert(prototypes, i, prototype)
        return
      end
    end
    table.insert(prototypes, prototype)
  end

  local recipes = game.recipe_prototypes
  local items = game.item_prototypes
  local fluids = game.fluid_prototypes
  local entities = game.entity_prototypes

  -- Start from recipes
  log("Phase 1: Recipes")
  for recipe_name, recipe_prototype in pairs(recipes) do
    add_to_subgroup(recipe_prototype)
    local path = "recipe/" .. recipe_name
    lookup[path] = { recipe = recipe_prototype }
    -- If there is exactly one product, and its icon is the same, then group them
    local main_product = recipe_prototype.main_product
    if not main_product then
      local products = recipe_prototype.products
      if #products == 1 then
        main_product = products[1]
      end
    end
    if main_product then
      local product_prototype
      if main_product.type == "item" then
        product_prototype = items[main_product.name]
      else
        product_prototype = fluids[main_product.name]
      end

      if
        product_prototype
        and not lookup[main_product.type .. "/" .. main_product.name]
        and compare_icons(recipe_prototype, product_prototype)
      then
        -- Associate this main_product with the recipe entry, and sync the two entries to the same set of prototypes
        lookup[path][main_product.type] = product_prototype
        lookup[main_product.type .. "/" .. main_product.name] = lookup[path]

        if main_product.type == "item" then
          local place_result = product_prototype.place_result
          if
            place_result
            and not lookup["entity/" .. place_result.name]
            and compare_icons(recipe_prototype, place_result)
          then
            lookup[path].entity = product_prototype.place_result
            lookup["entity/" .. place_result.name] = lookup[path]
          end
        end
      end
    end
  end

  -- Add missing items and fluids
  log("Phase 2: Missing materials")
  for type, prototypes in pairs({ item = items, fluid = fluids }) do
    for name, prototype in pairs(prototypes) do
      local path = type .. "/" .. name
      if not lookup[path] then
        add_to_subgroup(prototype)
        lookup[path] = { [type] = prototype }
      end
    end
  end

  -- -- Add missing entities
  -- log("Phase 3: Missing entities")
  -- for name, prototype in pairs(entities) do
  --   local path = "entity/" .. name
  --   if not lookup[path] then
  --     local products = prototype.mineable_properties.products
  --     if products then
  --       -- local added = false
  --       -- Group with entity
  --       if #products == 1 then
  --         local product = products[1]
  --         local product_path = product.type .. "/" .. product.name
  --         local product_group = lookup[product_path]
  --         if product_group and not product_group.entity then
  --           product_group.entity = prototype
  --           lookup[path] = product_group
  --           -- added = true
  --         end
  --       end
  --       -- TODO: This isn't very great
  --       -- -- Trees and rocks
  --       -- if not added and (prototype.type == "tree" or prototype.count_as_rock_for_filtered_deconstruction) then
  --       --   -- Only add if all of the results are valid in the database
  --       --   for _, product in pairs(products) do
  --       --     local product_path = product.type .. "/" .. product.name
  --       --     local product_group = lookup[product_path]
  --       --     if not product_group then
  --       --       added = true
  --       --       break
  --       --     end
  --       --   end
  --       --   if not added then
  --       --     add_to_subgroup(prototype)
  --       --     lookup[path] = { entity = prototype }
  --       --   end
  --       -- end
  --     end
  --   end
  -- end

  -- Remove empty groups and subgroups
  for group_name, group in pairs(groups) do
    local size = 0
    for subgroup_name, subgroup in pairs(group) do
      if #subgroup == 0 then
        group[subgroup_name] = nil
      else
        size = size + 1
      end
    end
    if size == 0 then
      groups[group_name] = nil
    end
  end

  global.database = lookup
  global.search_groups = groups

  profiler.stop()
  log({ "", "Database generation finished, ", profiler })

  database.refresh_researched()
end

--- @param recipe LuaRecipe
function database.on_recipe_unlocked(recipe)
  local researched = global.researched[recipe.force.index]
  researched["recipe/" .. recipe.name] = true
  -- TODO: Exclude barreling recipes
  if recipe.prototype.unlock_results then
    for _, product in pairs(recipe.products) do
      researched[product.type .. "/" .. product.name] = true
      if product.type == "item" then
        local item = game.item_prototypes[product.name]
        -- Rocket launch products
        local rocket_launch_products = item.rocket_launch_products
        if rocket_launch_products then
          for _, product in pairs(rocket_launch_products) do
            researched["item/" .. product.name] = true
          end
        end
        -- Resources
        local place_result = item.place_result
        if place_result and place_result.type == "mining-drill" then
          local categories = place_result.resource_categories --[[@as table<string, _>]]
          -- TODO: Fluid filters?
          local supports_fluid = place_result.fluidbox_prototypes[1] and true or false
          for _, resource in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "resource" } })) do
            if
              categories[resource.resource_category]
              and (supports_fluid or not resource.mineable_properties.required_fluid)
            then
              researched["item/" .. place_result.name] = true
            end
          end
        end
      end
    end
  end
end

--- @param technology LuaTechnology
function database.on_technology_researched(technology)
  local force = technology.force
  local researched = global.researched[force.index]
  if not researched then
    return
  end
  local technology_name = technology.name
  -- TODO: Do we really need this? Let's just use the prototype
  researched["technology/" .. technology_name] = true
  for _, effect in pairs(technology.effects) do
    if effect.type == "unlock-recipe" then
      local recipe = force.recipes[effect.recipe]
      database.on_recipe_unlocked(recipe)
    end
  end
end

function database.refresh_researched()
  -- TODO: Merge this into `global.database` so groups are unlocked properly
  --- @type table<uint, table<string, boolean>>
  global.researched = {}

  log("Refreshing researched prototypes")

  for _, force in pairs(game.forces) do
    global.researched[force.index] = {}
    local researched = global.researched[force.index]
    for _, recipe in pairs(force.recipes) do
      if recipe.enabled then
        researched["recipe/" .. recipe.name] = true
        database.on_recipe_unlocked(recipe)
      end
    end
    for _, technology in pairs(force.technologies) do
      if technology.researched then
        database.on_technology_researched(technology)
      end
    end
  end

  log("Finished refreshing researched prototypes")
end

return database
