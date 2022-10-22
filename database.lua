-- DESIGN GOALS:
-- Find a balance between caching information and generating it on the fly
-- Reduce complexity as much as possible
-- Don't rely on translated strings at all
-- Type annotations!!!

local database = {}

--- @class SubgroupData
--- @field members GenericPrototype[]
--- @field parent_name string

function database.build()
  log("Starting database generation")

  -- Assemble arrays of groups, subgroups, and members based on prototype order
  --- @type table<string, SubgroupData>
  local subgroups = {}
  for group_name, group in pairs(game.item_group_prototypes) do
    for _, subgroup in pairs(group.subgroups) do
      subgroups[subgroup.name] = { parent_name = group_name, members = {} }
    end
  end

  -- Keep track of added prototypes for de-duplication
  local added = {}

  -- Items are iterated in the correct order
  for type, prototypes in pairs({
    recipe = game.get_filtered_recipe_prototypes({
      { filter = "hidden", invert = true },
      { mode = "and", filter = "hidden-from-player-crafting", invert = true },
      { mode = "and", filter = "has-ingredients" },
    }),
    item = game.get_filtered_item_prototypes({
      { filter = "flag", flag = "hidden", invert = true },
      { mode = "and", filter = "flag", flag = "spawnable", invert = true },
    }),
    fluid = game.get_filtered_fluid_prototypes({ { filter = "hidden", invert = true } }),
    -- fluid = game.fluid_prototypes,
    entity = game.get_filtered_entity_prototypes({
      { filter = "crafting-machine" },
      { mode = "and", filter = "flag", flag = "player-creation" },
      { mode = "and", filter = "flag", flag = "hidden", invert = true },
    }),
  }) do
    log("Compiling " .. type .. " list")
    for name, prototype in pairs(prototypes) do
      -- Only insert a prototype with the given name once - they will be grouped together
      -- TODO: Group by icon instead of by name
      if not added[name] then
        added[prototype.name] = true
        local subgroup = subgroups[prototype.subgroup.name]
        local order = prototype.order
        -- TODO: Binary search
        local added
        for i, member in pairs(subgroup.members) do
          if order <= member.order then
            added = true
            table.insert(subgroup.members, i, prototype)
            break
          end
        end
        if not added then
          table.insert(subgroup.members, prototype)
        end
      end
    end
  end

  global.subgroups = subgroups

  log("Database generation finished")

  database.refresh_researched()
end

--- @param technology LuaTechnology
function database.on_technology_researched(technology)
  local force = technology.force
  local researched = global.researched[force.index]
  local technology_name = technology.name
  researched["technology/" .. technology_name] = true
  for _, effect in pairs(technology.effects) do
    if effect.type == "unlock-recipe" then
      local recipe_name = effect.recipe
      researched["recipe/" .. recipe_name] = true
      local recipe = force.recipes[recipe_name]
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
            -- TODO: Group these
            -- Entity
            local entity = item.place_result
            if entity then
              researched["entity/" .. entity.name] = true
            end
            -- Equipment
            local equipment = item.place_as_equipment_result
            if equipment then
              researched["equipment/" .. equipment.name] = true
            end
            -- Tile
            local tile = item.place_as_tile_result
            if tile then
              researched["tile/" .. tile.result.name] = true
            end
          end
        end
      end
    end
  end
end

function database.refresh_researched()
  --- @type table<uint, table<string, boolean>>
  global.researched = {}

  log("Refreshing researched prototypes")

  for _, force in pairs(game.forces) do
    global.researched[force.index] = {}
    local researched = global.researched[force.index]
    for _, recipe in pairs(force.recipes) do
      if recipe.enabled then
        researched["recipe/" .. recipe.name] = true
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
