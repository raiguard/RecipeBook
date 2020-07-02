local styles = data.raw["gui-style"].default

-- BUTTON STYLES



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

-- FRAME STYLES



-- LABEL STYLES