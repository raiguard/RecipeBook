local hidden_font_color = { r = 0.8, g = 0.8, b = 0.8, a = 0.8 }

data:extend({
  {
    type = "custom-input",
    name = "rb-toggle",
    key_sequence = "CONTROL + E",
  },
  {
    type = "custom-input",
    name = "rb-open-selected",
    key_sequence = "ALT + mouse-button-1",
    include_selected_prototype = true,
  },
  {
    type = "custom-input",
    name = "rb-previous",
    key_sequence = "mouse-button-4",
  },
  {
    type = "custom-input",
    name = "rb-next",
    key_sequence = "mouse-button-5",
  },
  {
    type = "custom-input",
    name = "rb-linked-focus-search",
    key_sequence = "",
    linked_game_control = "focus-search",
  },
  {
    type = "shortcut",
    name = "rb-toggle",
    action = "lua",
    icon = { filename = "__RecipeBook__/graphics/shortcut-x32-black.png", size = 32, flags = { "gui-icon" } },
    disabled_icon = { filename = "__RecipeBook__/graphics/shortcut-x32-white.png", size = 32, flags = { "gui-icon" } },
    small_icon = { filename = "__RecipeBook__/graphics/shortcut-x24-black.png", size = 24, flags = { "gui-icon" } },
    small_disabled_icon = {
      filename = "__RecipeBook__/graphics/shortcut-x24-white.png",
      size = 24,
      flags = { "gui-icon" },
    },
    toggleable = true,
    associated_control_input = "rb-toggle",
  },
  {
    type = "sprite",
    name = "rb_logo",
    filename = "__RecipeBook__/graphics/shortcut-x32-black.png",
    size = 32,
    flags = { "gui-icon" },
  },
  {
    type = "sprite",
    name = "rb_show_hidden_black",
    filename = "__RecipeBook__/graphics/show-hidden-black.png",
    size = 32,
    flags = { "gui-icon" },
  },
  {
    type = "sprite",
    name = "rb_show_hidden_white",
    filename = "__RecipeBook__/graphics/show-hidden-white.png",
    size = 32,
    flags = { "gui-icon" },
  },
  {
    type = "sprite",
    name = "rb_show_unresearched_black",
    filename = "__RecipeBook__/graphics/show-unresearched-black.png",
    size = 32,
    flags = { "gui-icon" },
  },
  {
    type = "sprite",
    name = "rb_show_unresearched_white",
    filename = "__RecipeBook__/graphics/show-unresearched-white.png",
    size = 32,
    flags = { "gui-icon" },
  },
})

local styles = data.raw["gui-style"]["default"]

styles.rb_filter_group_button_tab = {
  type = "button_style",
  parent = "filter_group_button_tab",
  width = 0,
  horizontally_stretchable = "on",
  -- TODO:
  -- draw_grayscale_picture = true,
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

styles.rb_list_box_caption = {
  type = "checkbox_style",
  font = "default-bold",
  font_color = styles.caption_label.font_color,
  default_graphical_set = {
    filename = "__RecipeBook__/graphics/list-expanded-white.png",
    size = 16,
  },
  hovered_graphical_set = {
    filename = "__RecipeBook__/graphics/list-expanded-orange.png",
    size = 16,
  },
  clicked_graphical_set = {
    filename = "__RecipeBook__/graphics/list-expanded-orange.png",
    size = 16,
  },
  selected_graphical_set = {
    filename = "__RecipeBook__/graphics/list-collapsed-white.png",
    size = 16,
  },
  selected_hovered_graphical_set = {
    filename = "__RecipeBook__/graphics/list-collapsed-orange.png",
    size = 16,
    scale = 0.5,
  },
  selected_clicked_graphical_set = {
    filename = "__RecipeBook__/graphics/list-collapsed-orange.png",
    size = 16,
    scale = 0.5,
  },
  checkmark = {
    filename = "__core__/graphics/empty.png",
    size = 1,
    scale = 8,
    priority = "very-low",
  },
  disabled_checkmark = {
    filename = "__core__/graphics/empty.png",
    size = 1,
    scale = 8,
    priority = "very-low",
  },
  text_padding = 5,
}

styles.rb_list_box_item = {
  type = "button_style",
  parent = "list_box_item",
  height = 40,
  horizontally_stretchable = "on",
  draw_shadow_under_picture = true,
  icon_horizontal_align = "left",
}

styles.rb_list_box_item_hidden = {
  type = "button_style",
  parent = "rb_list_box_item",
  default_font_color = hidden_font_color,
}

styles.rb_list_box_item_unresearched = {
  type = "button_style",
  parent = "rb_list_box_item",
  default_font_color = red_body_text_color,
}

styles.rb_subheader_caption_button = {
  type = "button_style",
  disabled_graphical_set = {},
  disabled_font_color = bold_font_color,
  font = "default-bold",
  icon_horizontal_align = "left",
  padding = 0,
  left_margin = 4,
  height = 36,
  minimal_width = 0,
  draw_shadow_under_picture = true,
}

styles.rb_subheader_caption_button_hidden = {
  type = "button_style",
  parent = "rb_subheader_caption_button",
  disabled_font_color = hidden_font_color,
}

styles.rb_subheader_caption_button_unresearched = {
  type = "button_style",
  parent = "rb_subheader_caption_button",
  disabled_font_color = red_body_text_color,
}

styles.rb_caption_label_hidden = {
  type = "label_style",
  parent = "caption_label",
  font_color = hidden_font_color,
}

styles.rb_caption_label_unresearched = {
  type = "label_style",
  parent = "caption_label",
  font_color = red_body_text_color,
}

styles.rb_info_label = {
  type = "label_style",
  parent = "info_label",
  font = "default-semibold",
  horizontally_squashable = "off",
  single_line = true,
}
