local bigpack = require("__big-data-string__.pack")
local data_util = require("prototypes.util")
local flib_table = require("__flib__.table")

data:extend({
  bigpack("rb_alternatives", serpent.line(flib_table.map(recipe_book.alternatives, data_util.get_sprite_path))),
  bigpack("rb_exclude", serpent.line(recipe_book.exclude)),
  bigpack("rb_group_with", serpent.line(flib_table.map(recipe_book.group_with, data_util.get_sprite_path))),
  bigpack("rb_hidden", serpent.line(recipe_book.hidden)),
  bigpack("rb_hidden_from_search", serpent.line(recipe_book.hidden_from_search)),
  bigpack("rb_unlocks_results", serpent.line(recipe_book.unlocks_results)),
})
