local grouped = require("scripts.database.grouped")
local util = require("scripts.util")

local bigunpack = require("__big-data-string2__.unpack")
--- @generic T
--- @param key string
--- @return T
local function unpack(key)
  local success, value = serpent.load(bigunpack(key))
  assert(success, "Deserialising overrides failed for " .. key)
  return value
end

--- Each top-level prototype sorted into groups and subgroups for the search panel.
--- @class SearchTree
--- @field groups table<string, table<string, GenericPrototype[]>> Group name -> subgroup name -> members
--- @field order table<GenericPrototype, integer>
--
local alternatives = unpack("rb_alternatives")

--- @param use_grouping boolean
--- @return SearchTree
local function build_tree(use_grouping)
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
    if alternatives[util.get_path(prototype)] then
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
    if not use_grouping or not grouped.material[util.get_path(entity)] then
      add(entity)
    end
  end
  for _, recipe in pairs(prototypes.recipe) do
    if not use_grouping or not grouped.material[util.get_path(recipe)] then
      add(recipe)
    end
  end
  for _, tile in pairs(prototypes.tile) do
    if not use_grouping or not grouped.material[util.get_path(tile)] then
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
        self.order[subgroup[i]] = order
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

search_tree.grouped = build_tree(true)
search_tree.plain = build_tree(false)

return search_tree
