data:extend({
  {
    type = "custom-input",
    name = "rbl-toggle-gui",
    key_sequence = "CONTROL + B",
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
    name = "rbl_nav_backward_black",
    filename = "__RecipeBookLite__/graphics/nav-backward-black.png",
    size = 32,
    flags = { "gui-icon" },
  },
  {
    type = "sprite",
    name = "rbl_nav_backward_disabled",
    filename = "__RecipeBookLite__/graphics/nav-backward-disabled.png",
    size = 32,
    flags = { "gui-icon" },
  },
  {
    type = "sprite",
    name = "rbl_nav_backward_white",
    filename = "__RecipeBookLite__/graphics/nav-backward-white.png",
    size = 32,
    flags = { "gui-icon" },
  },
  {
    type = "sprite",
    name = "rbl_nav_forward_black",
    filename = "__RecipeBookLite__/graphics/nav-forward-black.png",
    size = 32,
    flags = { "gui-icon" },
  },
  {
    type = "sprite",
    name = "rbl_nav_forward_disabled",
    filename = "__RecipeBookLite__/graphics/nav-forward-disabled.png",
    size = 32,
    flags = { "gui-icon" },
  },
  {
    type = "sprite",
    name = "rbl_nav_forward_white",
    filename = "__RecipeBookLite__/graphics/nav-forward-white.png",
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
