data:extend({
  {
    type = "custom-input",
    name = "rb-toggle-gui",
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
    name = "rb-go-back",
    key_sequence = "mouse-button-4",
  },
  {
    type = "custom-input",
    name = "rb-go-forward",
    key_sequence = "mouse-button-5",
  },
  {
    type = "shortcut",
    name = "rb-toggle-gui",
    order = "p[panels]-r[recipe-book]",
    icon = "__RecipeBook__/graphics/shortcut-x32-black.png",
    icon_size = 32,
    small_icon = "__RecipeBook__/graphics/shortcut-x24-black.png",
    small_icon_size = 24,
    associated_control_input = "rb-toggle-gui",
    toggleable = true,
    action = "lua",
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
  {
    type = "sprite",
    name = "rb_mod_gui_icon",
    filename = "__RecipeBook__/graphics/shortcut-x32-black.png",
    size = 32,
    mipmap_count = 2,
    flags = { "gui-icon" },
  },
})

local styles = data.raw["gui-style"]["default"]

styles.rb_subheader_caption_button = {
  type = "button_style",
  disabled_graphical_set = {},
  disabled_font_color = bold_font_color,
  font = "default-bold",
  icon_horizontal_align = "left",
  padding = 0,
  top_padding = -4,
  bottom_padding = -4,
  left_margin = 4,
  height = 28,
  minimal_width = 0,
  draw_shadow_under_picture = true,
}

local hidden_font_color = { r = 1, g = 1, b = 1, a = 0.6 }

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

styles.rb_list_box_item = {
  type = "button_style",
  parent = "list_box_item",
  height = 36,
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

styles.rb_search_scroll_pane = {
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
