local gui = require("__flib__.gui-beta")

local table_comp = {}

function table_comp.build(parent, index, component)
  return gui.build(parent, {
    {
      type = "frame",
      style = "deep_frame_in_shallow_frame",
      style_mods = {top_margin = 4},
      index = index,
      ref = {"root"},
      {type = "table", style = "rb_info_table", column_count = 2, ref = {"table"},
        -- Dummy elements so the first row doesn't get used
        {type = "empty-widget"},
        {type = "empty-widget"}
      }
    }
  })
end

function table_comp.update(component, refs, object_data, player_data, variables)
  local table = refs.table
  local children = table.children

  local i = 3
  for _, source in ipairs(component.rows) do
    -- Label
    i = i + 1
    local label = children[i]
    if not label then
      label = table.add{
        type = "label",
        style = "rb_table_label",
      }
    end
    label.caption = {"gui.rb-table-label-"..string.gsub(source.name, "_", "-")}

    -- Value
    i = i + 1
    if source.type == "plain" then
      local value = children[i]
      if not value then
        value = table.add{type = "label", style = "rb_table_value_label"}
      end
      value.caption = object_data[source.name]
    end
  end
end

return table_comp
