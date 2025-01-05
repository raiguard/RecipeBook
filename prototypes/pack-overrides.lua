local bigpack = require("__big-data-string2__.pack")
local data_util = require("prototypes.util")
local flib_table = require("__flib__.table")

local flib_prototypes = require("__flib__.prototypes")

-- TODO: Add factoriopedia_alternative read to runtime API
local alternatives = {}
for _, prototypes in pairs(data.raw) do
  for _, prototype in pairs(prototypes) do
    local alternative = prototype.factoriopedia_alternative
    if alternative then
      local base_type = data_util.get_prototype_base_type(prototype)
      local alternative_prototype = flib_prototypes.get(base_type, alternative)
      -- This will throw a prototype error later but we don't want to be blamed.
      if alternative_prototype then
        --- @cast alternative_prototype data.PrototypeBase
        alternatives[data_util.get_sprite_path(prototype)] = data_util.get_sprite_path(alternative_prototype)
      end
    end
  end
end

data:extend({
  bigpack("rb_alternatives", serpent.line(alternatives)),
  bigpack("rb_exclude", serpent.line(recipe_book.exclude)),
  bigpack("rb_group_with", serpent.line(flib_table.map(recipe_book.group_with, data_util.get_sprite_path))),
  bigpack("rb_hidden", serpent.line(recipe_book.hidden)),
  bigpack("rb_hidden_from_search", serpent.line(recipe_book.hidden_from_search)),
  bigpack("rb_unlocks_results", serpent.line(recipe_book.unlocks_results)),
})
