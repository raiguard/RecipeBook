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

  --- @param recipe LuaRecipePrototype
  --- @return GenericPrototype?
  local function get_simple_product(recipe)
    local main_product = recipe.main_product
    if main_product and main_product.name == recipe.name then
      return prototypes[main_product.type][main_product.name]
    end
    local products = recipe.products
    if #products ~= 1 then
      return
    end
    local first_product = products[1]
    if first_product.name ~= recipe.name or first_product.type == "research-progress" then
      return
    end
    return prototypes[first_product.type][first_product.name]
  end

  --- @param prototype GenericPrototype
  --- @return boolean
  local function get_hidden(prototype)
    return prototype.hidden or prototype.hidden_in_factoriopedia
  end

  --- @param prototype LuaEntityPrototype|LuaTilePrototype
  --- @return LuaItemPrototype?
  local function get_simple_item_to_place_this(prototype)
    local items_to_place_this = prototype.items_to_place_this
    if not items_to_place_this then
      return
    end
    local first_item = items_to_place_this[1]
    if not first_item then
      return
    end
    if first_item.name ~= prototype.name then
      return
    end
    return prototypes.item[first_item.name]
  end

  for _, item in pairs(prototypes.item) do
    add(item)
  end
  for _, fluid in pairs(prototypes.fluid) do
    add(fluid)
  end
  for _, entity in pairs(prototypes.entity) do
    local item = get_simple_item_to_place_this(entity)
    if not use_grouping or not item or get_hidden(item) ~= get_hidden(entity) then
      add(entity)
    end
  end
  for _, recipe in pairs(prototypes.recipe) do
    local material = get_simple_product(recipe)
    if not use_grouping or not material or get_hidden(material) ~= get_hidden(recipe) then
      add(recipe)
    end
  end
  for _, tile in pairs(prototypes.tile) do
    local material = get_simple_item_to_place_this(tile)
    if not use_grouping or not material or get_hidden(material) ~= get_hidden(tile) then
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
