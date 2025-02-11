local hidden_font_color = { r = 0.8, g = 0.8, b = 0.8, a = 0.8 }

local styles = data.raw["gui-style"]["default"]

styles.rb_filter_group_button_tab = {
  type = "button_style",
  parent = "filter_group_button_tab_slightly_larger",
  height = 72,
  -- The GUI style has a built-in 8 pixels of padding
  top_padding = 0,
  right_padding = 0,
  bottom_padding = 0,
  left_padding = -1,
  width = 0,
  minimal_width = 71,
  horizontally_stretchable = "on",
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
  default_font_color = gui_color.red,
}

styles.rb_subheader_caption_button = {
  type = "button_style",
  default_graphical_set = {},
  default_font_color = gui_color.caption,
  hovered_graphical_set = {},
  hovered_font_color = gui_color.caption,
  clicked_graphical_set = {},
  clicked_font_color = gui_color.caption,
  clicked_vertical_offset = 0,
  font = "default-bold",
  icon_horizontal_align = "left",
  padding = 4,
  height = 36,
  minimal_width = 0,
  draw_shadow_under_picture = true,
  left_click_sound = nil,
}

styles.rb_subheader_caption_button_hidden = {
  type = "button_style",
  parent = "rb_subheader_caption_button",
  disabled_font_color = hidden_font_color,
}

styles.rb_subheader_caption_button_unresearched = {
  type = "button_style",
  parent = "rb_subheader_caption_button",
  disabled_font_color = gui_color.red,
}

styles.rb_caption_label_hidden = {
  type = "label_style",
  parent = "caption_label",
  font_color = hidden_font_color,
}

styles.rb_caption_label_unresearched = {
  type = "label_style",
  parent = "caption_label",
  font_color = gui_color.red,
}

styles.rb_info_label = {
  type = "label_style",
  parent = "info_label",
  font = "default-semibold",
  horizontally_squashable = "off",
  single_line = true,
}

styles.rb_slot_label = {
  type = "label_style",
  parent = "count_label",
  height = 36,
  width = 35,
  vertical_align = "bottom",
  horizontal_align = "right",
  right_padding = 3,
}

styles.rb_slot_label_top = {
  type = "label_style",
  parent = "rb_slot_label",
  vertical_align = "top",
  top_padding = 3,
}

styles.rb_technology_slot_deep_frame = {
  type = "frame_style",
  parent = "deep_frame_in_shallow_frame",
  background_graphical_set = {
    position = { 282, 17 },
    corner_size = 8,
    overall_tiling_horizontal_size = 72,
    overall_tiling_vertical_size = 100,
  },
}

styles.rb_description_frame = {
  type = "frame_style",
  parent = "deep_frame_in_shallow_frame",
  padding = 8,
  horizontally_stretchable = "on",
  vertical_flow_style = {
    type = "vertical_flow_style",
    vertical_spacing = 8,
  },
}

styles.rb_description_line = {
  type = "line_style",
  parent = "tooltip_horizontal_line",
  left_margin = -8,
  right_margin = -8,
}

styles.rb_info_scroll_pane = {
  type = "scroll_pane_style",
  parent = "flib_naked_scroll_pane",
  vertical_flow_style = {
    type = "vertical_flow_style",
    vertical_spacing = 8,
  },
  horizontally_stretchable = "on",
  vertically_stretchable = "on",
}

styles.rb_description_id_button = {
  type = "button_style",
  parent = "flib_slot_button_default",
  width = 0,
  left_padding = 4,
  right_padding = 8,
  height = 28,
  default_font_color = default_font_color,
}

styles.rb_description_heading_id_button = {
  type = "button_style",
  parent = "rb_description_id_button",
  default_font_color = styles.tooltip_heading_label_category.font_color,
  font = "default-bold",
}
