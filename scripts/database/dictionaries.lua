-- TODO: Make custom dictionary module that allows me to build the dictionaries in the root scope

local flib_dictionary = require("__flib__.dictionary")

local search_tree = require("scripts.database.search-tree")
local util = require("scripts.util")

local function rebuild()
  flib_dictionary.new("search")
  for _, group in pairs(search_tree.plain.groups) do
    for _, subgroup in pairs(group) do
      for _, prototype in pairs(subgroup) do
        local prototype_path = util.get_path(prototype)
        flib_dictionary.add("search", prototype_path, { "?", prototype.localised_name, prototype_path }) --- @diagnostic disable-line:assign-type-mismatch
      end
    end
  end

  flib_dictionary.new("description")
  for _, entity in pairs(prototypes.entity) do
    local path = util.get_path(entity)
    flib_dictionary.add("description", path, { "?", entity.factoriopedia_description, entity.localised_description }) --- @diagnostic disable-line:assign-type-mismatch
  end
  for _, equipment in pairs(prototypes.equipment) do
    local path = util.get_path(equipment)
    flib_dictionary.add(
      "description",
      path,
      { "?", equipment.factoriopedia_description, equipment.localised_description } --- @diagnostic disable-line:assign-type-mismatch
    )
  end
  for _, fluid in pairs(prototypes.fluid) do
    local path = util.get_path(fluid)
    flib_dictionary.add("description", path, { "?", fluid.factoriopedia_description, fluid.localised_description }) --- @diagnostic disable-line:assign-type-mismatch
  end
  for _, item in pairs(prototypes.item) do
    local path = util.get_path(item)
    flib_dictionary.add("description", path, { "?", item.factoriopedia_description, item.localised_description }) --- @diagnostic disable-line:assign-type-mismatch
  end
  for _, recipe in pairs(prototypes.recipe) do
    local path = util.get_path(recipe)
    flib_dictionary.add("description", path, { "?", recipe.factoriopedia_description, recipe.localised_description }) --- @diagnostic disable-line:assign-type-mismatch
  end
  for _, tile in pairs(prototypes.tile) do
    local path = util.get_path(tile)
    flib_dictionary.add("description", path, { "?", tile.factoriopedia_description, tile.localised_description }) --- @diagnostic disable-line:assign-type-mismatch
  end
end

local M = {}

M.on_init = rebuild
M.on_configuration_changed = rebuild

return M
