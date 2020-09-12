local data_util = require("__flib__.data-util")

local frame_action_icons = "__RecipeBook__/graphics/frame-action-icons.png"
local tool_icons = "__RecipeBook__/graphics/tool-icons.png"

data:extend{
  -- frame action icons
  data_util.build_sprite("rb_nav_backward_black", {0, 0}, frame_action_icons, 32),
  data_util.build_sprite("rb_nav_backward_white", {32, 0}, frame_action_icons, 32),
  data_util.build_sprite("rb_nav_backward_disabled", {64, 0}, frame_action_icons, 32),
  data_util.build_sprite("rb_nav_forward_black", {0, 32}, frame_action_icons, 32),
  data_util.build_sprite("rb_nav_forward_white", {32, 32}, frame_action_icons, 32),
  data_util.build_sprite("rb_nav_forward_disabled", {64, 32}, frame_action_icons, 32),
  data_util.build_sprite("rb_pin_black", {0, 64}, frame_action_icons, 32),
  data_util.build_sprite("rb_pin_white", {32, 64}, frame_action_icons, 32),
  data_util.build_sprite("rb_settings_black", {0, 96}, frame_action_icons, 32),
  data_util.build_sprite("rb_settings_white", {32, 96}, frame_action_icons, 32),
  data_util.build_sprite("rb_expand_black", {0, 128}, frame_action_icons, 32),
  data_util.build_sprite("rb_expand_white", {32, 128}, frame_action_icons, 32),
  -- tool icons
  data_util.build_sprite("rb_favorite_black", {0, 0}, tool_icons, 32, 2),
  data_util.build_sprite("rb_clipboard_black", {0, 32}, tool_icons, 32, 2)
}