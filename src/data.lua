-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PROTOTYPES

data:extend{
  {
    type = 'custom-input',
    name = 'rb-toggle-search',
    key_sequence = 'CONTROL + R',
    order = 'a'
  }
}

-- GUI styles
local styles = data.raw['gui-style'].default

styles.rb_titlebar_flow = {
  type = 'horizontal_flow_style',
  direction = 'horizontal',
  horizontally_stretchable = 'on',
  vertical_align = 'center',
  top_margin = -3
}

styles.rb_titlebar_draggable_space = {
  type = 'empty_widget_style',
  parent = 'draggable_space_header',
  horizontally_stretchable = 'on',
  natural_height = 24,
  minimal_width = 24,
  right_margin = 7
}