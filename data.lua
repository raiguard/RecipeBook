data:extend({
  {
    type = "custom-input",
    name = "rbl-toggle-gui",
    key_sequence = "CONTROL + B",
  },
  {
    type = "custom-input",
    name = "rbl-open-selected",
    key_sequence = "ALT + mouse-button-1",
    include_selected_prototype = true,
  },
  {
    type = "shortcut",
    name = "rbl-toggle-gui",
    icon = {
      filename = "__RecipeBookLite__/graphics/shortcut-x32-black.png",
      size = 32,
      flags = { "gui-icon" },
    },
    small_icon = {
      filename = "__RecipeBookLite__/graphics/shortcut-x24-black.png",
      size = 24,
      flags = { "gui-icon" },
    },
    associated_control_input = "rbl-toggle-gui",
    toggleable = true,
    action = "lua",
  },
  {
    type = "sprite",
    name = "rbl_show_hidden_black",
    filename = "__RecipeBookLite__/graphics/show-hidden-black.png",
    size = 32,
    flags = { "gui-icon" },
  },
  {
    type = "sprite",
    name = "rbl_show_hidden_white",
    filename = "__RecipeBookLite__/graphics/show-hidden-white.png",
    size = 32,
    flags = { "gui-icon" },
  },
  {
    type = "sprite",
    name = "rbl_show_unresearched_black",
    filename = "__RecipeBookLite__/graphics/show-unresearched-black.png",
    size = 32,
    flags = { "gui-icon" },
  },
})

local styles = data.raw["gui-style"]["default"]

styles.rbl_subheader_caption_button = {
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

styles.rbl_subheader_caption_button_hidden = {
  type = "button_style",
  parent = "rbl_subheader_caption_button",
  disabled_font_color = hidden_font_color,
}

styles.rbl_subheader_caption_button_unresearched = {
  type = "button_style",
  parent = "rbl_subheader_caption_button",
  disabled_font_color = red_body_text_color,
}

styles.rbl_list_box_item = {
  type = "button_style",
  parent = "list_box_item",
  height = 36,
  horizontally_stretchable = "on",
  draw_shadow_under_picture = true,
  icon_horizontal_align = "left",
}

styles.rbl_list_box_item_hidden = {
  type = "button_style",
  parent = "rbl_list_box_item",
  default_font_color = hidden_font_color,
}

styles.rbl_list_box_item_unresearched = {
  type = "button_style",
  parent = "rbl_list_box_item",
  default_font_color = red_body_text_color,
}

styles.rbl_search_scroll_pane = {
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
  vertical_flow_style = {
    type = "vertical_flow_style",
    vertical_spacing = 0,
  },
}
