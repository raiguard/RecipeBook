local function mipped_icon(name, position, filename, size, mipmap_count, mods)
  local def = {
    type = "sprite",
    name = name,
    filename = filename,
    position = position,
    size = size or 32,
    mipmap_count = mipmap_count or 2,
    flags = {"icon"}
  }
  if mods then
    for k, v in pairs(mods) do
      def[k] = v
    end
  end
  return def
end

data:extend{
  -- custom inputs
  {
    type = "custom-input",
    name = "rb-toggle-search",
    key_sequence = "CONTROL + B",
    order = "a"
  },
  {
    type = "custom-input",
    name = "rb-results-nav-confirm",
    key_sequence = "ENTER",
    order = "b"
  },
  {
    type = "custom-input",
    name = "rb-cycle-category",
    key_sequence = "",
    linked_game_control = "confirm-message"
  },
  -- shortcut
  {
    type = "shortcut",
    -- TODO rename to rb-toggle-gui
    name = "rb-toggle-search",
    action = "lua",
    icon = mipped_icon(nil, {0,0}, "__RecipeBook__/graphics/search-shortcut.png", 32, 2),
    small_icon = mipped_icon(nil, {0,32}, "__RecipeBook__/graphics/search-shortcut.png", 24, 2),
    disabled_icon = mipped_icon(nil, {48,0}, "__RecipeBook__/graphics/search-shortcut.png", 32, 2),
    disabled_small_icon = mipped_icon(nil, {36,32}, "__RecipeBook__/graphics/search-shortcut.png", 24, 2),
    toggleable = true,
    associated_control_input = "rb-toggle-search"
  },
  -- sprites
  mipped_icon("rb_close_black", {0,0}, "__RecipeBook__/graphics/frame-action-icons.png", 40, 2),
  mipped_icon("rb_close_white", {60,0}, "__RecipeBook__/graphics/frame-action-icons.png", 40, 2),
  mipped_icon("rb_pin_black", {0,40}, "__RecipeBook__/graphics/frame-action-icons.png", 40, 2),
  mipped_icon("rb_pin_white", {60,40}, "__RecipeBook__/graphics/frame-action-icons.png", 40, 2),
  mipped_icon("rb_nav_forward_black", {0,80}, "__RecipeBook__/graphics/frame-action-icons.png", 40, 2),
  mipped_icon("rb_nav_forward_white", {60,80}, "__RecipeBook__/graphics/frame-action-icons.png", 40, 2),
  mipped_icon("rb_nav_backward_black", {0,120}, "__RecipeBook__/graphics/frame-action-icons.png", 40, 2),
  mipped_icon("rb_nav_backward_white", {60,120}, "__RecipeBook__/graphics/frame-action-icons.png", 40, 2),
}

local styles = data.raw["gui-style"].default

-- BUTTON STYLES

-- slightly smaller close button that looks WAY better ;)
styles.rb_frame_action_button = {
  type = "button_style",
  parent = "close_button",
  size = 20,
  top_margin = 2
}

styles.rb_active_frame_action_button = {
  type = "button_style",
  parent = "rb_frame_action_button",
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

-- EMPTY WIDGET STYLES

styles.rb_drag_handle = {
  type = "empty_widget_style",
  parent = "draggable_space",
  height = 24,
  minimal_width = 24,
  horizontally_stretchable = "on"
}

-- DROPDOWN STYLES

styles.rb_active_dropdown = {
  type = "dropdown_style",
  parent = "dropdown",
  button_style = {
    type = "button_style",
    parent = "button",
    default_graphical_set = {
      base = {position = {34, 17}, corner_size = 8},
      shadow = default_dirt,
      -- glow = default_glow(default_glow_color, 0.5) -- no glow when it's not being mouse-hovered
    }
  }
}

-- FLOW STYLES

styles.rb_content_flow = {
  type = "vertical_flow_style",
  bottom_padding = 12,
  left_padding = 12,
  right_padding = 0,
  top_padding = 12
}

styles.rb_search_content_flow = {
  type = "vertical_flow_style",
  parent = "rb_content_flow",
  top_padding = 8
}

styles.rb_toolbar_frame = {
  type = "frame_style",
  parent = "subheader_frame",
  horizontal_flow_style = {
    type = "horizontal_flow_style",
    vertical_align = "center"
  }
}

styles.rb_window_content_flow = {
  type = "horizontal_flow_style",
  horizontal_spacing = 12,
  margin = 0,
  padding = 0
}

-- FRAME STYLES

styles.rb_blurry_frame = {
  type = "frame_style",
  -- padding of the content area of the frame
  top_padding  = 8,
  right_padding = 12,
  bottom_padding = 12,
  left_padding = 12,
  graphical_set = {
    base = {
      center = {position = {336, 0}, size = {1, 1}},
      opacity = 0,
      background_blur = true
    },
    shadow = default_shadow
  }
}

styles.rb_list_box_frame = {
  type = "frame_style",
  padding = 0,
  width = 225,
  height = 168, -- six rows
  graphical_set = { -- inset from a light frame, but keep the dark background
    base = {
      position = {85,0},
      corner_size = 8,
      draw_type = "outer",
      center = {position={42,8}, size=1}
    },
    shadow = default_inner_shadow
  }
}

styles.rb_search_list_box_frame = {
  type = "frame_style",
  parent = "rb_list_box_frame",
  height = 0,
  vertically_stretchable = "on"
}

styles.rb_slot_table_frame = {
  type = "frame_style",
  padding = 0,
  graphical_set = {
    base = {
      position = {85,0},
      corner_size = 8,
      draw_type = "outer",
      center = {position={42,8}, size=1}
    },
    shadow = default_inner_shadow
  }
}

styles.rb_window_frame = {
  type = "frame_style",
  parent = "dialog_frame",
  top_padding = 6
}

-- LABEL STYLES

styles.rb_list_box_label = {
  type = "label_style",
  font = "default-semibold",
  left_padding = 2
}

styles.rb_window_title_label = {
  type = "label_style",
  parent = "frame_title",
  left_margin = 8
}

-- IMAGE STYLES

styles.rb_object_icon = {
  type = "image_style",
  stretch_image_to_widget_size = true,
  size = 28,
  padding = 2
}

-- SCROLL PANE STYLES

styles.rb_list_box_scroll_pane = {
  type = "scroll_pane_style",
  extra_padding_when_activated = 0,
  margin = 0,
  padding = 0,
  background_graphical_set = { -- rubber grid
    position = {282,17},
    corner_size = 8,
    overall_tiling_vertical_size = 20,
    overall_tiling_vertical_spacing = 8,
    overall_tiling_vertical_padding = 4,
    overall_tiling_horizontal_padding = 4
  },
  vertical_flow_style = {
    type = "vertical_flow_style",
    margin = 0,
    padding = 0,
    vertical_spacing = 0,
    vertically_stretchable = "on"
  }
}

styles.rb_slot_table_scroll_pane = {
  type = "scroll_pane_style",
  parent = "scroll_pane",
  padding = 0,
  margin = 0,
  extra_padding_when_activated = 0,
  background_graphical_set = {
    base = {
      position = {282, 17},
      corner_size = 8,
      overall_tiling_horizontal_padding = 4,
      overall_tiling_horizontal_size = 32,
      overall_tiling_horizontal_spacing = 8,
      overall_tiling_vertical_padding = 4,
      overall_tiling_vertical_size = 32,
      overall_tiling_vertical_spacing = 8
    }
  }
}

-- TABLE STYLES

styles.rb_icon_slot_table = {
  type = "table_style",
  parent = "slot_table",
  horizontal_spacing = 0,
  vertical_spacing = 0
}

-- TEXTFIELDS STYLES

styles.rb_search_textfield = {
  type = "textbox_style",
  horizontally_stretchable = "on",
  right_margin = 12,
  bottom_margin=6,
  width = 0
}