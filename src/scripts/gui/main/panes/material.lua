local material_pane = {}

local gui = require("__flib__.gui")

function material_pane.update(parent, gui_data, translations)
  parent.clear()
  gui.build(parent, {
    {type="flow", style_mods={horizontally_stretchable=true, vertically_stretchable=true, horizontal_align="center", vertical_align="center"}, children={
      {type="label", style="bold_label", caption="Material page"}
    }}
  })
end

return material_pane