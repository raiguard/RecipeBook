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

-- TODO: Implement search
function table_comp.update(component, refs, object_data, player_data, variables)
  local table = refs.table
  local children = table.children

  local gui_translations = player_data.translations.gui

  local i = 3
  for _, row in ipairs(component.rows) do
    -- TODO: Implement 'goto' type with an object
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
        label_label.caption = gui_translations[row.label or row.name]
        label_label.tooltip = row.label_tooltip and gui_translations[row.label_tooltip] or ""

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
  for j = i + 1, #children do
    children[j].destroy()
  end

  if i > 3 then
    refs.root.visible = true
  else
    refs.root.visible = false
  end

  return i > 3
end

return table_comp
