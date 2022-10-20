-- data:extend({
--   {
--     type = "custom-input",
--     name = "rb-toggle",
--     setting_type = "",
--   },
-- })

local styles = data.raw["gui-style"]["default"]

styles.rb_filter_group_button_tab = {
  type = "button_style",
  parent = "filter_group_button_tab",
  width = 0,
  horizontally_stretchable = "on",
  disabled_graphical_set = styles.button.selected_graphical_set,
}

styles.rb_disabled_filter_group_button_tab = {
  type = "button_style",
  parent = "filter_group_button_tab",
  width = 0,
  horizontally_stretchable = "on",
  draw_grayscale_picture = true,
  default_graphical_set = styles.filter_group_button_tab.disabled_graphical_set,
  hovered_graphical_set = styles.filter_group_button_tab.disabled_graphical_set,
  clicked_graphical_set = styles.filter_group_button_tab.disabled_graphical_set,
}

styles.rb_filter_frame = {
  type = "frame_style",
  parent = "filter_frame",
  horizontally_stretchable = "on",
  bottom_padding = 8,
  top_padding = 8,
  left_padding = 13,
  right_padding = 0,
  width = (40 * 10) + (13 * 2),
}

styles.rb_filter_deep_frame = {
  type = "frame_style",
  parent = "deep_frame_in_shallow_frame",
  height = 40 * 14,
  minimal_width = 40 * 10,
}

styles.rb_filter_scroll_pane = {
  type = "scroll_pane_style",
  parent = "flib_naked_scroll_pane_no_padding",
  background_graphical_set = {
    position = { 282, 17 },
    corner_size = 8,
    overall_tiling_vertical_size = 32,
    overall_tiling_vertical_spacing = 8,
    overall_tiling_vertical_padding = 4,
    overall_tiling_horizontal_size = 32,
    overall_tiling_horizontal_spacing = 8,
    overall_tiling_horizontal_padding = 4,
  },
  minimal_width = 40 * 10,
  vertically_stretchable = "on",
  vertical_flow_style = {
    type = "vertical_flow_style",
    vertical_spacing = 0,
    width = 40 * 10,
  },
}

styles.rb_filter_group_flow = {
  type = "vertical_flow_style",
  vertical_spacing = 0,
}

styles.rb_list_box_row_even = {
  type = "button_style",
  font = "default",
  height = 36,
  -- height = 40,
  bottom_padding = 4,
  top_padding = 4,
  horizontally_stretchable = "on",
  horizontal_align = "left",
  default_font_color = default_font_color,
  default_graphical_set = { position = { 472, 25 }, size = { 1, 1 } },
  hovered_graphical_set = { position = { 42, 25 }, size = { 1, 1 } },
  clicked_graphical_set = { position = { 59, 25 }, size = { 1, 1 } },
  clicked_vertical_offset = 0,
  draw_shadow_under_picture = true,
  icon_horizontal_align = "left",
}

styles.rb_list_box_row_odd = {
  type = "button_style",
  parent = "rb_list_box_row_even",
  default_graphical_set = {},
}

styles.rb_small_transparent_slot = {
  type = "button_style",
  parent = "transparent_slot",
  bottom_margin = 0,
  left_margin = 4,
  right_margin = 4,
  top_margin = 0,
  size = 28,
}
