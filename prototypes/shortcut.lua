data:extend({
  {
    type = "shortcut",
    name = "rb-toggle",
    action = "lua",
    icon = { filename = "__RecipeBook__/graphics/shortcut-x32-black.png", size = 32, flags = { "gui-icon" } },
    disabled_icon = { filename = "__RecipeBook__/graphics/shortcut-x32-white.png", size = 32, flags = { "gui-icon" } },
    small_icon = { filename = "__RecipeBook__/graphics/shortcut-x24-black.png", size = 24, flags = { "gui-icon" } },
    small_disabled_icon = {
      filename = "__RecipeBook__/graphics/shortcut-x24-white.png",
      size = 24,
      flags = { "gui-icon" },
    },
    toggleable = true,
    associated_control_input = "rb-toggle",
  },
})
