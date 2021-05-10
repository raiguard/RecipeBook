local fixed_format = require("lib.fixed-precision-format")
local gui = require("__flib__.gui-beta")

local table_comp = {}

local formatters = {
  fuel_value = function(value, _)
    return {"", fixed_format(value, 3, "2"), {"si-unit-symbol-joule"}}
  end,
  percent = function(value, _)
    return {"format-percent", value * 100}
  end,
  seconds = function(value, _)
    return {"time-symbol-seconds", value}
  end
}

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
  for _, row in ipairs(component.rows) do
    if row.type == "plain" then
      local value = object_data[row.name]
      if value then
        -- Format value
        local formatter = row.formatter
        if formatter then
          value = formatters[formatter](value, object_data)
        end

        -- Label
        i = i + 1
        local label_label = children[i]
        if not label_label then
          label_label = table.add{
            type = "label",
            style = "rb_table_label",
          }
        end
        label_label.caption = row.label or {"gui.rb-"..string.gsub(row.name, "_", "-")}

        -- Value
        i = i + 1
        local value_label = children[i]
        if not value_label then
          value_label = table.add{type = "label"}
        end
        value_label.caption = value
      end
    end
  end
end

return table_comp
