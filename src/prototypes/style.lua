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

styles.rb_list_box_item = {
  type = "button_style",
  parent = "list_box_item",
  left_padding = 4,
  right_padding = 4,
  horizontally_squashable = "on",
  horizontally_stretchable = "on"
}

styles.rb_unavailable_list_box_item = {
  type = "button_style",
  parent = "rb_list_box_item",
  default_font_color = constants.colors.unavailable.tbl
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

-- FRAME STYLES

styles.rb_main_info_frame = {
  type = "frame_style",
  parent = "inside_shallow_frame",
  width = 400,
  height = 486
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
  graphical_set = {
    shadow = default_inner_shadow
  },
  vertical_flow_style = {
    type = "vertical_flow_style",
    padding = 12,
    top_padding = 8,
    horizontally_stretchable = "on",
    vertically_stretchable = "on"
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
    vertical_spacing = 0
  }
}