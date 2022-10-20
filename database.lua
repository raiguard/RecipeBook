local table = require("__flib__.table")

-- DESIGN GOALS:
-- Find a balance between caching information and generating it on the fly
-- Reduce complexity as much as possible
-- Don't rely on translated strings at all
-- Type annotations!!!

local database = {}

--- @param prototypes GenericPrototype[]
--- @param prototype GenericPrototype
--- @param cmp fun(GenericPrototype): boolean
local function sorted_insert(prototypes, prototype, cmp)
  for i = 1, #prototypes do
    if cmp(prototypes[i]) then
      table.insert(prototypes, i, prototype)
      return
    end
  end
  table.insert(prototypes, prototype)
end

function database.build()
  -- Assemble arrays of groups, subgroups, and members based on prototype order
  local groups = {}
  local group_members = {}
  local subgroups = {}
  local subgroup_members = {}
  for group_name, group in pairs(game.item_group_prototypes) do
    table.insert(groups, group)
    group_members[group_name] = {}
    subgroups[group_name] = {}
    for _, subgroup in pairs(group.subgroups) do
      table.insert(subgroups[group_name], subgroup)
      subgroup_members[subgroup.name] = {}
    end
  end

  -- Assemble array of all objects in prototype order
  local objects = {}
  -- Lookup table to de-duplicate objects
  local objects_lookup = {}

  -- Items are iterated in the correct order
  for _, prototypes in pairs({
    game.get_filtered_item_prototypes({
      -- { filter = "subgroup", subgroup = "delivery-cannon-capsules", invert = true },
      { mode = "and", filter = "flag", flag = "hidden", invert = true },
    }),
    game.get_filtered_recipe_prototypes({
      { filter = "hidden", invert = true },
      -- { mode = "and", filter = "subgroup", subgroup = "delivery-cannon-capsules", invert = true },
      -- { mode = "and", filter = "category", category = "delivery-cannon", invert = true },
    }),
    game.fluid_prototypes,
    game.get_filtered_entity_prototypes({
      { filter = "flag", flag = "player-creation" },
      { mode = "and", filter = "flag", flag = "hidden", invert = true },
    }),
  }) do
    for name, prototype in pairs(prototypes) do
      -- Only insert a prototype with the given name once - they will be grouped together
      if not objects_lookup[name] then
        objects_lookup[prototype.name] = true
        local group = prototype.group
        local subgroup = prototype.subgroup
        local order = prototype.order
        -- FIXME: This is abhorrently slow
        -- Group
        sorted_insert(group_members[group.name], prototype, function(member)
          return subgroup.order < member.subgroup.order and order < member.order
        end)
        -- Subgroup
        sorted_insert(subgroup_members[subgroup.name], prototype, function(member)
          return order < member.order
        end)
        -- All
        sorted_insert(objects, prototype, function(member)
          return group.order < member.group.order and subgroup.order < member.subgroup.order and order < member.order
        end)
      end
    end
  end

  global.groups = groups
  global.group_members = group_members
  global.sorted_objects = objects
  global.subgroups = subgroups
  global.subgroup_members = subgroup_members
end

return database
