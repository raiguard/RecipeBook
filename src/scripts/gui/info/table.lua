local gui = require("__flib__.gui-beta")
local table = require("__flib__.table")

local formatter = require("scripts.formatter")

local table_comp = {}

function table_comp.build(parent, index, _)
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
  local tbl = refs.table
  local children = tbl.children

  local gui_translations = player_data.translations.gui

  local search_query = variables.search_query

  local i = 2
  for _, row in ipairs(component.rows) do
    local value = object_data[row.source]
    if value then
      local caption = gui_translations[row.label or row.source]
      if string.find(string.lower(caption), search_query) then
        -- Label
        i = i + 1
        local label_label = children[i]
        if not label_label then
          label_label = tbl.add{
            type = "label",
            style = "rb_table_label",
            index = i
          }
        end
        local tooltip = row.label_tooltip
        if tooltip then
          caption = caption.." [img=info]"
          tooltip = gui_translations[row.label_tooltip]
        else
          tooltip = ""
        end
        label_label.caption = caption
        label_label.tooltip = tooltip

        -- Value
        if row.type == "plain" then
          local fmt = row.formatter
          if fmt then
            value = formatter[fmt](value, gui_translations)
          end
          i = i + 1
          local value_label = children[i]
          if not value_label or value_label.type ~= "label" then
            if value_label then
              value_label.destroy()
            end
            value_label = tbl.add{type = "label", index = i}
          end
          value_label.caption = value
        elseif row.type == "goto" then
          i = i + 1
          local button = children[i]
          if not button or button.type ~= "button" then
            if button then
              button.destroy()
            end
            button = tbl.add{
              type = "button",
              style = "rb_table_button",
              mouse_button_filter = {"left", "middle"},
              index = i
            }
          end
          local source_data = global.recipe_book[value.class][value.name]
          local options = table.shallow_copy(row.options or {})
          options.label_only = true
          options.amount_ident = value.amount_ident
          local info = formatter(source_data, player_data, options)
          if info then
            button.caption = info.caption
            button.tooltip = info.tooltip
            gui.set_action(button, "on_click", {gui = "info", id = variables.gui_id, action = "navigate_to"})
            gui.update_tags(button, {context = {class = value.class, name = value.name}})
          else
            -- Don't actually show this row
            -- This is an ugly way to do it, but whatever
            button.destroy()
            label_label.destroy()
            i = i - 2
          end
        elseif row.type == "tech_level_selector" then
          i = i + 1
          local flow = children[i]
          if not flow or flow.type ~= "flow" then
            if flow then flow.destroy() end
            flow = gui.build(tbl, {
              {type = "flow", style_mods = {vertical_align = "center"}, index = i, ref = {"flow"},
                -- TODO: Arrow button styles
                {
                  type = "button",
                  style = "mini_button_aligned_to_text_vertically_when_centered",
                  caption = "-",
                  mouse_button_filter = {"left"},
                  actions = {
                    on_click = {gui = "info", id = variables.gui_id, action = "change_tech_level", delta = -1}
                  }
                },
                {type = "label", name = "tech_level_label"},
                {
                  type = "button",
                  style = "mini_button_aligned_to_text_vertically_when_centered",
                  caption = "+",
                  mouse_button_filter = {"left"},
                  actions = {
                    on_click = {gui = "info", id = variables.gui_id, action = "change_tech_level", delta = 1}
                  }
                }
              }
            }).flow
          end
          flow.tech_level_label.caption = formatter.number(variables.selected_tech_level)
        elseif row.type == "tech_level_research_unit_count" then
          i = i + 1
          local value_label = children[i]
          if not value_label or value_label.type ~= "label" then
            if value_label then value_label.destroy() end
            value_label = tbl.add{type = "label", index = i}
          end
          local tech_level = variables.selected_tech_level
          value_label.caption = formatter[row.formatter](
            game.evaluate_expression(value, {L = tech_level, l = tech_level})
          )
        end
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
