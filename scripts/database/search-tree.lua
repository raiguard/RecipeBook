local grouped = require("scripts.database.grouped")
local util = require("scripts.util")

--- Each top-level prototype sorted into groups and subgroups for the search panel.
--- @class SearchTree
--- @field groups table<string, table<string, GenericPrototype[]>> Group name -> subgroup name -> members
--- @field order table<SpritePath, integer>

--- @alias GenericPrototype LuaEntityPrototype|LuaEquipmentPrototype|LuaFluidPrototype|LuaItemPrototype|LuaRecipePrototype|LuaTechnologyPrototype|LuaTilePrototype

--- @param grouping GroupingMode
--- @return SearchTree
local function build_tree(grouping)
  --- @type SearchTree
  local self = {
    groups = {},
    order = {},
  }

  --- @param prototype GenericPrototype
  local function add(prototype)
    local subgroup = self.groups[util.get_group(prototype).name][util.get_subgroup(prototype).name]
    assert(subgroup, "Subgroup was nil.")
    if prototype.parameter and prototype.object_name ~= "LuaEntityPrototype" then
      return
    end
    if prototype.factoriopedia_alternative then
      return
    end
    subgroup[#subgroup + 1] = prototype
  end

  for group_name, group_prototype in pairs(prototypes.item_group) do
    local subgroups = {}
    for _, subgroup_prototype in pairs(group_prototype.subgroups) do
      subgroups[subgroup_prototype.name] = {}
    end
    self.groups[group_name] = subgroups
  end

  for _, item in pairs(prototypes.item) do
    add(item)
  end
  for _, fluid in pairs(prototypes.fluid) do
    add(fluid)
  end
  for _, entity in pairs(prototypes.entity) do
    if grouping == "none" or not grouped.material[util.get_path(entity)] then
      add(entity)
    end
  end
  for _, recipe in pairs(prototypes.recipe) do
    if grouping ~= "all" or not grouped.material[util.get_path(recipe)] then
      add(recipe)
    end
  end
  for _, tile in pairs(prototypes.tile) do
    if grouping == "none" or not grouped.material[util.get_path(tile)] then
      add(tile)
    end
  end
  -- Space location
  -- Asteroid chunk
  -- Ammo
  -- Space Connection
  -- Virtual signal
  -- Surface

  local order = 0
  for group_name, group in pairs(self.groups) do
    for subgroup_name, subgroup in pairs(group) do
      if not next(subgroup) then
        group[subgroup_name] = nil
        goto continue
      end

      -- TODO: This doesn't match up with Factoriopedia
      table.sort(subgroup, function(a, b)
        local a_order, b_order = a.order, b.order
        if a_order == b_order then
          return a.name < b.name
        end
        return a_order < b_order
      end)

      for i = 1, #subgroup do
        order = order + 1
        self.order[util.get_path(subgroup[i])] = order
      end

      ::continue::
    end
    if not next(group) then
      self.groups[group_name] = nil
    end
  end

  return self
end

--- @class SearchTreeMod
local search_tree = {}

search_tree.all = build_tree("all")
search_tree.separate_recipes = build_tree("exclude-recipes")
search_tree.plain = build_tree("none")

return search_tree
