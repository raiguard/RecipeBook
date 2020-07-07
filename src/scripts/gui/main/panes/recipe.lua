local recipe_pane = {}

local gui = require("__flib__.gui")

function recipe_pane.update(parent, gui_data, translations)
  parent.clear()
  gui.build(parent, {
    {type="flow", style_mods={horizontally_stretchable=true, vertically_stretchable=true, horizontal_align="center", vertical_align="center"}, children={
      {type="label", style="bold_label", caption="Recipe page"}
    }}
  })
end

return recipe_pane