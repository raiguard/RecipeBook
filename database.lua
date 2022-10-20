-- DESIGN GOALS:
-- Find a balance between caching information and generating it on the fly
-- Reduce complexity as much as possible
-- Don't rely on translated strings at all
-- Type annotations!!!

local database = {}

--- @param prototypes GenericPrototype[]
--- @param obj GenericPrototype
local function sorted_insert(prototypes, obj)
  local order = obj.order
  for i, prototype in pairs(prototypes) do
    if order < prototype.order then
      table.insert(prototypes, i, obj)
      return
    end
  end
  table.insert(prototypes, obj)
end

function database.build()
  local groups = {}
  local subgroup_lookup = {}

  -- Items are iterated in the correct order
  for _, members in pairs({
    game.item_prototypes,
    game.fluid_prototypes,
    game.recipe_prototypes,
    game.get_filtered_entity_prototypes({ { filter = "crafting-machine" } }),
  }) do
    for _, prototype in pairs(members) do
      local group = prototype.group
      if not groups[group.name] then
        groups[group.name] = {}
      end
      local group = groups[group.name]
      local subgroup = prototype.subgroup
      if not group[subgroup.name] then
        group[subgroup.name] = {}
      end
      -- FIXME: Subgroups are not in order
      if not subgroup_lookup[subgroup.name] then
        subgroup_lookup[subgroup.name] = {}
      end
      if subgroup_lookup[subgroup.name][prototype.name] then
        log("COMBINE " .. prototype.name)
      else
        sorted_insert(group[subgroup.name], prototype)
        subgroup_lookup[subgroup.name][prototype.name] = true
      end
    end
  end

  global.object_groups = groups
end

return database
