local data_util = require("__flib__.data_util")

local frame_action_sheet = "__RecipeBook__/graphics/frame-action-icons.png"
local tool_sheet = "__RecipeBook__/graphics/tool-icons.png"

data:extend{
  data_util.build_sprite("rb_nav_backward_black", {0, 0}, frame_action_sheet, 32),
  data_util.build_sprite("rb_nav_backward_white", {32, 0}, frame_action_sheet, 32),
  data_util.build_sprite("rb_nav_forward_black", {0, 32}, frame_action_sheet, 32),
  data_util.build_sprite("rb_nav_forward_white", {32, 32}, frame_action_sheet, 32),
  data_util.build_sprite("rb_pin_black", {0, 64}, frame_action_sheet, 32),
  data_util.build_sprite("rb_pin_white", {32, 64}, frame_action_sheet, 32),
  data_util.build_sprite("rb_expand_black", {0, 96}, frame_action_sheet, 32),
  data_util.build_sprite("rb_expand_white", {32, 96}, frame_action_sheet, 32),
  data_util.build_sprite("rb_favorite_black", {0, 0}, tool_sheet, 32, 2)
}