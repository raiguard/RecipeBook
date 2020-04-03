data:extend{
  {
    type = 'bool-setting',
    name = 'rb-open-item-hotkey',
    setting_type = 'runtime-per-user',
    default_value = true,
    order = 'a'
  },
  {
    type = 'bool-setting',
    name = 'rb-open-fluid-hotkey',
    setting_type = 'runtime-per-user',
    default_value = true,
    order = 'b'
  },
  {
    type = 'bool-setting',
    name = 'rb-show-hidden-objects',
    setting_type = 'runtime-per-user',
    default_value = false,
    order = 'c'
  },
  {
    type = 'bool-setting',
    name = 'rb-use-fuzzy-search',
    setting_type = 'runtime-per-user',
    default_value = false,
    order = 'd'
  },
  {
    type = 'string-setting',
    name = 'rb-default-search-category',
    setting_type = 'runtime-per-user',
    default_value = 'material',
    allowed_values = {'crafter', 'material', 'recipe'},
    order = 'e'
  }
}