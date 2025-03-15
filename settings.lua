data:extend({
  {
    type = "bool-setting",
    name = "rb-auto-focus-search",
    order = "a",
    setting_type = "runtime-per-user",
    default_value = false,
  },
  {
    type = "bool-setting",
    name = "rb-lists-everywhere",
    order = "b",
    setting_type = "runtime-per-user",
    default_value = false,
  },
  {
    type = "bool-setting",
    name = "rb-show-mod-owners",
    order = "c",
    setting_type = "runtime-per-user",
    default_value = true,
  },
  {
    type = "bool-setting",
    name = "rb-show-overhead-button",
    order = "d",
    setting_type = "runtime-per-user",
    default_value = true,
  },
  {
    type = "string-setting",
    name = "rb-grouping-mode",
    order = "e",
    setting_type = "runtime-per-user",
    default_value = "all",
    allowed_values = { "all", "exclude-recipes", "none" },
  },
})
