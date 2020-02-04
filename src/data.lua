-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PROTOTYPES

-- DEBUGGING TOOL
if mods['debugadapter'] then
  data:extend{
    {
    type = 'custom-input',
    name = 'DEBUG-INSPECT-GLOBAL',
    key_sequence = 'CONTROL + SHIFT + ENTER'
    }
  }
end

data:extend{
  -- CUSTOM INPUTS
  {
    type = 'custom-input',
    name = 'rb-toggle-search',
    key_sequence = 'CONTROL + R',
    order = 'a'
  },
  {
    type = 'custom-input',
    name = 'rb-results-nav-confirm',
    key_sequence = 'ENTER',
    order = 'bd'
  },
  -- SPRITES
  {
    type = 'sprite',
    name = 'rb_nav_backward',
    filename = '__RecipeBook__/graphics/gui/nav-backward.png',
    size = 32,
    mipmap_count = 2,
    flags = {'icon'}
  },
  {
    type = 'sprite',
    name = 'rb_nav_backward_dark',
    filename = '__RecipeBook__/graphics/gui/nav-backward-dark.png',
    size = 32,
    mipmap_count = 2,
    flags = {'icon'}
  },
}

local styles = data.raw['gui-style'].default

-- -----------------------------------------------------------------------------
-- EMPTY WIDGET STYLES

styles.rb_titlebar_draggable_space = {
  type = 'empty_widget_style',
  parent = 'draggable_space_header',
  horizontally_stretchable = 'on',
  natural_height = 24,
  minimal_width = 24,
  right_margin = 7
}

-- -----------------------------------------------------------------------------
-- FRAME STYLES

styles.rb_listbox_frame = {
  type = 'frame_style',
  padding = 0,
  width = 225,
  height = 168, -- six rows
  graphical_set = { -- inset from a light frame, but keep the dark background
    base = {
      position = {85,0},
      corner_size = 8,
      draw_type = 'outer',
      center = {position={42,8}, size=1}
    },
    shadow = default_inner_shadow
  },
  background_graphical_set = { -- rubber grid
    position = {282,17},
    corner_size = 8,
    overall_tiling_vertical_size = 20,
    overall_tiling_vertical_spacing = 8,
    overall_tiling_vertical_padding = 4,
    overall_tiling_horizontal_padding = 4
  },
  vertically_stretchable = 'on'
}

styles.rb_search_results_listbox_frame = {
  type = 'frame_style',
  parent = 'rb_listbox_frame',
  height = 196
}

local outer_frame_light = outer_frame_light()
outer_frame_light.base.center = {position = {42,8}, size=1}
styles.rb_icon_slot_table_pane = {
  type = 'scroll_pane_style',
  padding = 0,
  extra_padding_when_activated = 0,
  extra_right_padding_when_activated = -12,
  graphical_set = outer_frame_light,
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

styles.rb_icon_slot_table = {
  type = 'table_style',
  parent = 'slot_table',
  horizontal_spacing = 0,
  vertical_spacing = 0
}

-- -----------------------------------------------------------------------------
-- FLOW STYLES

styles.rb_search_flow = {
  type = 'horizontal_flow_style',
  margin = 8,
  vertical_align = 'center',
  horizontal_spacing = 6
}

styles.rb_titlebar_flow = {
  type = 'horizontal_flow_style',
  direction = 'horizontal',
  horizontally_stretchable = 'on',
  vertical_align = 'center',
  top_margin = -3
}

-- -----------------------------------------------------------------------------
-- LABEL STYLES

styles.rb_listbox_label = {
  type = 'label_style',
  font = 'default-semibold',
  left_padding = 2
}

-- -----------------------------------------------------------------------------
-- IMAGE STYLES

styles.rb_object_icon = {
  type = 'image_style',
  stretch_image_to_widget_size = true,
  size = 28,
  padding = 2
}

-- -----------------------------------------------------------------------------
-- LIST BOX STYLES

styles.rb_listbox_item = {
  type = 'button_style',
  parent = 'list_box_item',
  horizontally_stretchable = 'on',
  left_padding = 4,
  right_padding = 4
}

styles.rb_listbox = {
  type = 'list_box_style',
  parent = 'list_box',
  scroll_pane_style = { -- invisible scroll pane
    type = 'scroll_pane_style',
    parent = 'list_box_scroll_pane',
    graphical_set = {},
    background_graphical_set = {},
    vertically_stretchable = 'on'
  },
  item_style = {
    type = 'button_style',
    parent = 'rb_listbox_item'
  }
}

styles.rb_listbox_for_keyboard_nav = {
  type = 'list_box_style',
  parent = 'rb_listbox',
  item_style = {
    type = 'button_style',
    parent = 'rb_listbox_item',
    selected_graphical_set = {
      base = {position = {34,17}, corner_size=8},
      shadow = default_dirt
    }
  }
}