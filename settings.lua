data:extend({
  {
    type = "bool-setting",
    name = "rb-show-overhead-button",
    setting_type = "runtime-per-user",
    default_value = true,
  },
  {
    type = "bool-setting",
    name = "rb-auto-focus-search",
    setting_type = "runtime-per-user",
    default_value = false,
  },
  {
    type = "bool-setting",
    name = "rb-lists-everywhere",
    setting_type = "runtime-per-user",
    default_value = false,
  },
  {
    type = "string-setting",
    name = "rb-grouping-mode",
    setting_type = "runtime-per-user",
    default_value = "all",
    allowed_values = { "all", "exclude-recipes", "none" },
  },
})
