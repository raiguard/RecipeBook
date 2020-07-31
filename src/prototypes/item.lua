local data_util = require("__flib__.data_util")

data:extend {
  {
    type = "blueprint",
    name = "rb-crafter-blueprint",
    icons = {{icon=data_util.planner_base_image, icon_size=64, icon_mipmaps=4, tint={r=0.2, g=1, b=1}}},
    stack_size = 1,
    flags = {"hidden", "only-in-cursor", "not-stackable"},
    draw_label_for_cursor_render = true,
    selection_color = {0, 1, 0},
    alt_selection_color = {0, 1, 0},
    selection_mode = {"blueprint"},
    alt_selection_mode = {"blueprint"},
    selection_cursor_box_type = "copy",
    alt_selection_cursor_box_type = "copy"
  }
}