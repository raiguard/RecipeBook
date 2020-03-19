-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PROTOTYPES

local function mipped_icon(name, position, filename, size, mipmap_count, mods)
  local def = {
    type = 'sprite',
    name = name,
    filename = filename,
    position = position,
    size = size or 32,
    mipmap_count = mipmap_count or 2,
    flags = {'icon'}
  }
  if mods then
    for k,v in pairs(mods) do
      def[k] = v
    end
  end
  return def
end

data:extend{
  -- CUSTOM INPUTS
  {
    type = 'custom-input',
    name = 'rb-toggle-search',
    key_sequence = 'CONTROL + B',
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
    name = 'rb_mod_gui_icon',
    layers = {
      {
        filename = '__core__/graphics/empty.png',
        size = 1,
        scale = 40,
      },
      {
        filename = '__RecipeBook__/graphics/shortcut.png',
        size = 32,
        mipmap_count = 2,
        flags = {'icon'}
      }
    }
  },
  mipped_icon('rb_nav_backward', {0,0}, '__RecipeBook__/graphics/gui-nav-icons.png', 32, 2),
  mipped_icon('rb_nav_backward_dark', {48,0}, '__RecipeBook__/graphics/gui-nav-icons.png', 32, 2),
  mipped_icon('rb_nav_forward', {0,32}, '__RecipeBook__/graphics/gui-nav-icons.png', 32, 2),
  mipped_icon('rb_nav_forward_dark', {48,32}, '__RecipeBook__/graphics/gui-nav-icons.png', 32, 2),
  mipped_icon('rb_nav_open_info', {0,64}, '__RecipeBook__/graphics/gui-nav-icons.png', 32, 2),
  mipped_icon('rb_nav_open_info_dark', {48,64}, '__RecipeBook__/graphics/gui-nav-icons.png', 32, 2),
  mipped_icon('rb_nav_search', {0,96}, '__RecipeBook__/graphics/gui-nav-icons.png', 32, 2),
  mipped_icon('rb_nav_search_dark', {48,96}, '__RecipeBook__/graphics/gui-nav-icons.png', 32, 2),
  -- SHORTCUTS
  {
    type = 'shortcut',
    name = 'rb-toggle-search',
    action = 'lua',
    icon = mipped_icon(nil, {0,0}, '__RecipeBook__/graphics/shortcut.png', 32, 2),
    small_icon = mipped_icon(nil, {0,32}, '__RecipeBook__/graphics/shortcut.png', 24, 2),
    disabled_icon = mipped_icon(nil, {48,0}, '__RecipeBook__/graphics/shortcut.png', 32, 2),
    disabled_small_icon = mipped_icon(nil, {36,32}, '__RecipeBook__/graphics/shortcut.png', 24, 2),
    toggleable = true,
    associated_control_input = 'rb-toggle-search'
  }
}

local styles = data.raw['gui-style'].default

-- -----------------------------------------------------------------------------
-- BUTTON STYLES

-- slightly smaller close button that looks WAY better ;)
styles.rb_frame_action_button = {
  type = 'button_style',
  parent = 'close_button',
  size = 20,
  top_margin = 2
}

-- -----------------------------------------------------------------------------
-- EMPTY WIDGET STYLES

styles.rb_titlebar_draggable_space = {
  type = 'empty_widget_style',
  parent = 'draggable_space_header',
  horizontally_stretchable = 'on',
  natural_height = 24,
  minimal_width = 24,
  right_margin = 6
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

styles.rb_icon_slot_table_frame = {
  type = 'frame_style',
  padding = 0,
  graphical_set = {
    base = {
      position = {85,0},
      corner_size = 8,
      draw_type = 'outer',
      center = {position={42,8}, size=1}
    },
    shadow = default_inner_shadow
  },
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
  -- top_margin = -3
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

-- -----------------------------------------------------------------------------
-- SCROLL PANE STYLES

styles.rb_icon_slot_table_scrollpane = {
  type = 'scroll_pane_style',
  parent = 'scroll_pane',
  padding = 0,
  margin = 0,
  extra_padding_when_activated = 0
}

-- -----------------------------------------------------------------------------
-- TABLE STYLES

styles.rb_icon_slot_table = {
  type = 'table_style',
  parent = 'slot_table',
  horizontal_spacing = 0,
  vertical_spacing = 0
}