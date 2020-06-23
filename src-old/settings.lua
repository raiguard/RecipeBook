data:extend{
  {
    type = "bool-setting",
    name = "rb-open-item-hotkey",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "a"
  },
  {
    type = "bool-setting",
    name = "rb-open-fluid-hotkey",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "b"
  },
  {
    type = "bool-setting",
    name = "rb-show-hidden-objects",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "c"
  },
  {
    type = "bool-setting",
    name = "rb-show-unavailable-objects",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "d"
  },
  {
    type = "bool-setting",
    name = "rb-use-fuzzy-search",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "e"
  },
  {
    type = "string-setting",
    name = "rb-default-search-category",
    setting_type = "runtime-per-user",
    default_value = "material",
    allowed_values = {"material", "recipe"},
    order = "f"
  }
}