local gui = require("__flib__.gui-beta")
local table = require("__flib__.table")

local constants = require("constants")

local util = require("scripts.util")

local root = {}

function root.build(player, player_table)
  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      direction = "vertical",
      ref = {"window"},
      actions = {
        on_closed = {gui = "settings", action = "close"},
      },
      {type = "flow", style = "flib_titlebar_flow", ref = {"titlebar", "flow"},
        {type = "label", style = "frame_title", caption = {"gui.rb-settings"}, ignored_by_interaction = true},
        {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
        {
          type = "textfield",
          style_mods = {
            top_margin = -3,
            right_padding = 3,
            width = 120
          },
          visible = false,
          ref = {"titlebar", "search_textfield"},
          actions = {
            on_text_changed = {gui = "settings", action = "update_search_query"}
          }
        },
        util.frame_action_button(
          "utility/search",
          {"gui.rb-search-instruction"},
          {"titlebar", "search_button"},
          {gui = "settings", action = "toggle_search"}
        ),
        util.frame_action_button(
          "utility/close",
          {"gui.close"},
          {"titlebar", "close_button"},
          {gui = "settings", action = "close"}
        ),
      },
      {type = "frame", style = "inside_deep_frame_for_tabs", direction = "vertical",
        {type = "tabbed-pane", style = "flib_tabbed_pane_with_no_padding", style_mods = {width = 500},
          {
            tab = {type = "tab", caption = {"gui.rb-general"}},
            content = {
              type = "flow",
              style_mods = {padding = 4},
              direction = "vertical",
              ref = {"general", "pane"},
            },
          },
          {
            tab = {type = "tab", caption = {"gui.rb-categories"}},
            content = {
              type = "flow",
              style_mods = {horizontal_spacing = 12, padding = {8, 12, 0, 12}},
              {
                type = "list-box",
                style = "list_box_in_shallow_frame",
                style_mods = {height = 504, width = 150},
                items = constants.category_classes,
                selected_index = 1
              },
              {type = "frame", style = "flib_shallow_frame_in_shallow_frame", style_mods = {height = 504},
                {type = "scroll-pane", style = "flib_naked_scroll_pane", style_mods = {padding = 4},
                  {
                    type = "frame",
                    style = "bordered_frame",
                    style_mods = {horizontally_stretchable = true, vertically_stretchable = true},
                    direction = "vertical",
                    ref = {"categories", "pane"},
                  },
                },
              },
            },
          },
          {
            tab = {type = "tab", caption = {"gui.rb-pages"}},
            content = {
              type = "flow",
              style_mods = {horizontal_spacing = 12, padding = {8, 12, 0, 12}},
              {
                type = "list-box",
                style = "list_box_in_shallow_frame",
                style_mods = {height = 504, width = 150},
                items = constants.classes,
                selected_index = 1
              },
              {type = "frame", style = "flib_shallow_frame_in_shallow_frame", style_mods = {height = 504},
                {type = "scroll-pane", style = "flib_naked_scroll_pane", style_mods = {padding = 4},
                  {
                    type = "table",
                    style = "bordered_table",
                    style_mods = {horizontally_stretchable = true, vertically_stretchable = true},
                    column_count = 1,
                    ref = {"pages", "pane"},
                  },
                },
              },
            },
          },
          {
            tab = {type = "tab", caption = {"gui.rb-admin"}},
            content = {
              type = "flow",
              style_mods = {padding = {8, 12, 0, 12}},
              direction = "vertical",
              {
                type = "button",
                style_mods = {horizontally_stretchable = true},
                caption = {"gui.rb-clear-memoizer-cache"}
              },
              {
                type = "button",
                style = "red_button",
                style_mods = {horizontally_stretchable = true},
                caption = {"gui.rb-reset-player-data"}
              },
            },
          }
        },
      },
    }
  })

  refs.window.force_auto_center()
  refs.titlebar.flow.drag_target = refs.window
  player.opened = refs.window

  player_table.guis.settings = {
    refs = refs,
    state = {
      search_opened = false,
      search_query = "",
    },
  }

  root.update_contents(player, player_table)
end

function root.destroy(player_table)
  player_table.guis.settings.refs.window.destroy()
  player_table.guis.settings = nil
end

function root.toggle(player, player_table)
  if player_table.guis.settings then
    root.destroy(player_table)
  else
    root.build(player, player_table)
  end
end

function root.update_contents(player, player_table)
  local gui_data = player_table.guis.settings
  local refs = gui_data.refs
  local state = gui_data.state

  local query = state.search_query

  local gui_translations = player_table.translations.gui

  -- NOTE: For simplicity's sake, since there's not _that much_ going on here, we will just destroy and recreate things
  --       instead of updating them.

  -- GENERAL

  local general_pane = refs.general.pane
  general_pane.clear()
  for category, settings in pairs(constants.general_settings) do
    local children = {}
    for setting_name, setting_ident in pairs(settings) do
      local caption = gui_translations[setting_name] or setting_name
      if string.find(string.lower(caption), query) then
        local converted_setting_name = string.gsub(setting_name, "_", "-")
        local tooltip = ""
        if setting_ident.has_tooltip then
          tooltip = {"gui.rb-"..converted_setting_name.."-description"}
          caption = caption.." [img=info]"
        end
        if setting_ident.type == "bool" then
            children[#children + 1] = {
              type = "checkbox",
              caption = caption,
              tooltip = tooltip,
              state = setting_ident.default_value,
            }
        elseif setting_ident.type == "enum" then
          children[#children + 1] = {
            type = "flow",
            style_mods = {vertical_align = "center"},
            {type = "label", caption = caption, tooltip = tooltip},
            {type = "empty-widget", style = "flib_horizontal_pusher"},
            {
              type = "drop-down",
              items = table.map(
                setting_ident.options,
                function(option_name)
                  return {"gui.rb-"..converted_setting_name.."-"..string.gsub(option_name, "_", "-")}
                end
              ),
              selected_index = table.find(setting_ident.options, setting_ident.default_value),
            },
          }
        end
      end
    end
    if #children > 0 then
      gui.build(general_pane, {
        {
          type = "frame",
          style = "bordered_frame",
          direction = "vertical",
          caption = gui_translations[category] or category,
          children = children,
        }
      })
    end
  end

  -- CATEGORIES
  -- TODO: Dynamically generate listbox contents based on search

  local categories_pane = refs.categories.pane
  categories_pane.clear()
  local dummy_category = constants.category_classes[2]
  for category_name in pairs(global.recipe_book[dummy_category]) do
    categories_pane.add{type = "checkbox", caption = category_name, state = true}
  end
  for i = 1, 15 do
    categories_pane.add{type = "checkbox", caption = i, state = true}
  end
end

return root
