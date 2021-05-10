local constants = require("constants")

local styles = data.raw["gui-style"].default

-- -----

styles.rb_list_box_item = {
  type = "button_style",
  parent = "list_box_item",
  left_padding = 4,
  right_padding = 4,
  horizontally_squashable = "on",
  horizontally_stretchable = "on",
  disabled_graphical_set = styles.list_box_item.default_graphical_set,
  disabled_font_color = styles.list_box_item.default_font_color
}

styles.rb_last_selected_list_box_item = {
  type = "button_style",
  parent = "rb_list_box_item",
  default_font_color = constants.colors.yellow.tbl,
  disabled_font_color = constants.colors.yellow.tbl
}

styles.rb_unresearched_list_box_item = {
  type = "button_style",
  parent = "rb_list_box_item",
  default_font_color = constants.colors.unresearched.tbl,
  disabled_font_color = constants.colors.unresearched.tbl
}

-- FLOW STYLES

styles.rb_main_frame_flow = {
  type = "horizontal_flow_style",
  horizontal_spacing = 12
}

styles.rb_main_info_pane_flow = {
  type = "vertical_flow_style",
  vertical_spacing = 8
}

styles.rb_quick_ref_content_flow = {
  type = "vertical_flow_style",
  bottom_padding = 12,
  left_padding = 12,
  right_padding = 0,
  top_padding = 6
}

styles.rb_search_content_flow = {
  type = "vertical_flow_style",
  padding = 12,
  top_padding = 8,
  vertical_spacing = 10
}

styles.rb_warning_flow = {
  type = "vertical_flow_style",
  padding = 12,
  horizontal_align = "center",
  vertical_align = "center",
  vertical_spacing = 8,
  horizontally_stretchable = "on"
}

-- FRAME STYLES

styles.rb_main_info_frame = {
  type = "frame_style",
  parent = "inside_shallow_frame",
  width = 450
}

styles.rb_search_results_frame = {
  type = "frame_style",
  parent = "deep_frame_in_shallow_frame",
  height = 28 * 18,
  width = 250,
  horizontally_stretchable = "on"
}

styles.rb_search_results_subheader_frame = {
  type = "frame_style",
  parent = "subheader_frame",
  height = 28,
  horizontally_stretchable = "on",
  horizontal_flow_style = {
    type = "horizontal_flow_style",
    horizontal_align = "center"
  }
}

styles.rb_quick_ref_content_frame = {
  type = "frame_style",
  parent = "inside_shallow_frame",
  width = 224
}

styles.rb_slot_table_frame = {
  type = "frame_style",
  parent = "slot_button_deep_frame",
  maximal_height = 200,
  natural_height = 40,
  width = 40 * 5
}

styles.rb_settings_category_frame = {
  type = "frame_style",
  parent = "bordered_frame",
  horizontally_stretchable = "on",
  right_padding = 8
}

styles.rb_inside_warning_frame = {
  type = "frame_style",
  parent = "inside_shallow_frame",
  graphical_set = {
    base = {
      position = {17, 0}, corner_size = 8,
      center = {position = {411, 25}, size = {1, 1}},
      draw_type = "outer"
    },
    shadow = default_inner_shadow
  }
}

-- LABEL STYLES

styles.rb_table_label = {
  type = "label_style",
  font = "default-semibold",
  horizontally_stretchable = "on"
}

styles.rb_toolbar_label = {
  type = "label_style",
  parent = "subheader_caption_label",
  left_padding = 4,
  horizontally_squashable = "on"
}

styles.rb_slot_label = {
  type = "label_style",
  parent = "count_label",
  height = 36,
  width = 35,
  vertical_align = "bottom",
  horizontal_align = "right",
  right_padding = 3
}

styles.rb_slot_label_top = {
  type = "label_style",
  parent = "rb_slot_label",
  vertical_align = "top",
  top_padding = 3
}

styles.rb_list_box_label = {
  type = "label_style",
  parent = "bold_label",
  bottom_padding = 2
}

-- SCROLL PANE STYLES

styles.rb_list_box_scroll_pane = {
  type = "scroll_pane_style",
  parent = "list_box_scroll_pane",
  graphical_set = {
    shadow = default_inner_shadow
  },
  vertical_flow_style = {
    type = "vertical_flow_style",
    vertical_spacing = 0,
    horizontally_stretchable = "on"
  }
}

styles.rb_page_scroll_pane = {
  type = "scroll_pane_style",
  parent = "flib_naked_scroll_pane_no_padding",
  vertical_flow_style = {
    type = "vertical_flow_style",
    padding = 12,
    top_padding = 8,
    vertical_spacing = 8
  }
}

-- styles.rb_search_results_scroll_pane = {
--   type = "scroll_pane_style",
--   parent = "rb_list_box_scroll_pane",
--   vertically_stretchable = "on"
-- }

-- styles.rb_settings_content_scroll_pane = {
--   type = "scroll_pane_style",
--   parent = "rb_naked_scroll_pane",
--   vertical_flow_style = {
--     type = "vertical_flow_style",
--     padding = 4
--   }
-- }

-- TABLE STYLES

styles.rb_info_table = {
  type = "table_style",
  parent = "mods_table",
  top_margin = -6, -- To hide the strange first row styling
  bottom_margin = 2,
  column_alignments = {
    {column = 1, alignment = "middle-left"},
    {column = 2, alignment = "middle-right"},
  }
}

-- TEXTFIELD STYLES

styles.rb_search_textfield = {
  type = "textbox_style",
  width = 250
}
