local constants = require("constants")

local styles = data.raw["gui-style"].default

-- BUTTON STYLES

styles.rb_selected_frame_action_button = {
  type = "button_style",
  parent = "frame_action_button",
  default_graphical_set = {
    base = {position = {272, 169}, corner_size = 8},
    shadow = {position = {440, 24}, corner_size = 8, draw_type = "outer"}
  },
  hovered_graphical_set = {
    base = {position = {369, 17}, corner_size = 8},
    shadow = default_dirt
  },
  clicked_graphical_set = {
    base = {position = {352, 17}, corner_size = 8},
    shadow = default_dirt
  }
}

local btn = styles.button

styles.rb_selected_tool_button = {
  type = "button_style",
  parent = "tool_button",
  default_font_color = btn.selected_font_color,
  default_graphical_set = btn.selected_graphical_set,
  hovered_font_color = btn.selected_hovered_font_color,
  hovered_graphical_set = btn.selected_hovered_graphical_set,
  clicked_font_color = btn.selected_clicked_font_color,
  clicked_graphical_set = btn.selected_clicked_graphical_set
}

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

styles.rb_unavailable_list_box_item = {
  type = "button_style",
  parent = "rb_list_box_item",
  default_font_color = constants.colors.unavailable.tbl,
  disabled_font_color = constants.colors.unavailable.tbl
}

-- "adjusted" for the material and recipe icon glyphs, to remove the extraneous left padding
styles.rb_adjusted_list_box_item = {
  type = "button_style",
  parent = "rb_list_box_item",
  left_padding = -8
}

styles.rb_adjusted_unavailable_list_box_item = {
  type = "button_style",
  parent = "rb_unavailable_list_box_item",
  left_padding = -8
}

-- EMPTY-WIDGET STYLES

styles.rb_drag_handle = {
  type = "empty_widget_style",
  parent = "draggable_space",
  left_margin = 4,
  right_margin = 4,
  height = 24,
  horizontally_stretchable = "on"
}

--! TODO move to flib

styles.flib_horizontal_pusher = {
  type = "empty_widget_style",
  horizontally_stretchable = "on"
}

styles.flib_vertical_pusher = {
  type = "empty_widget_style",
  vertically_stretchable = "on"
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

-- FRAME STYLES

styles.rb_main_info_frame = {
  type = "frame_style",
  parent = "inside_shallow_frame",
  width = 400
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

-- LABEL STYLES

styles.rb_info_bar_label = {
  type = "label_style",
  parent = "subheader_caption_label",
  left_padding = 4
}

-- SCROLL PANE STYLES

styles.rb_main_info_scroll_pane = {
  type = "scroll_pane_style",
  extra_padding_when_activated = 0,
  padding = 0,
  horizontally_stretchable = "on",
  vertically_stretchable = "on",
  graphical_set = {
    shadow = default_inner_shadow
  },
  vertical_flow_style = {
    type = "vertical_flow_style",
    padding = 12,
    top_padding = 8
  }
}

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