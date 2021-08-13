local gui = require("__flib__.gui")
local table = require("__flib__.table")

local constants = require("constants")

local recipe_book = require("scripts.recipe-book")
local util = require("scripts.util")

local root = {}

function root.build(player, player_table)
  local gui_translations = player_table.translations.gui

  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      name = "rb_settings_window",
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
          clear_and_focus_on_right_click = true,
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
        {type = "tabbed-pane", style = "flib_tabbed_pane_with_no_padding",
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
            tab = {
              type = "tab",
              style_mods = {padding = {7, 10, 8, 10}},
              caption = {"", {"gui.rb-categories"}, " [img=info]"},
              tooltip = {"gui.rb-categories-description"},
            },
            content = {
              type = "flow",
              style_mods = {horizontal_spacing = 12, padding = {8, 12, 12, 12}},
              {
                type = "list-box",
                style = "list_box_in_shallow_frame",
                style_mods = {height = 504, width = 150},
                items = table.map(constants.category_classes, function(class)
                  return gui_translations[class] or class
                end),
                selected_index = 1,
                actions = {
                  on_selection_state_changed = {gui = "settings", action = "change_category"},
                },
              },
              {type = "frame", style = "flib_shallow_frame_in_shallow_frame", style_mods = {height = 504},
                {type = "scroll-pane", style = "flib_naked_scroll_pane", style_mods = {padding = 4},
                  {
                    type = "frame",
                    style = "bordered_frame",
                    style_mods = {minimal_width = 300, horizontally_stretchable = true, vertically_stretchable = true},
                    direction = "vertical",
                    ref = {"categories", "frame"},
                  },
                },
              },
            },
          },
        },
      },
    },
  })

  refs.window.force_auto_center()
  refs.titlebar.flow.drag_target = refs.window
  player.opened = refs.window

  player_table.guis.settings = {
    refs = refs,
    state = {
      search_opened = false,
      search_query = "",
      selected_category = 1,
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

function root.update_contents(player, player_table, tab)
  local gui_data = player_table.guis.settings
  local refs = gui_data.refs
  local state = gui_data.state

  local query = state.search_query

  local translations = player_table.translations
  local gui_translations = translations.gui
  local actual_settings = player_table.settings

  -- NOTE: For simplicity's sake, since there's not _that much_ going on here, we will just destroy and recreate things
  --       instead of updating them.

  -- GENERAL

  if not tab or tab == "general" then
    local general_pane = refs.general.pane
    general_pane.clear()
    for category, settings in pairs(constants.general_settings) do
      local actual_category_settings = actual_settings.general[category]
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
          local enabled = true
          if setting_ident.dependencies then
            for _, dependency in pairs(setting_ident.dependencies) do
              if actual_settings.general[dependency.category][dependency.name] ~= dependency.value then
                enabled = false
                break
              end
            end
          end
          if setting_ident.type == "bool" then
              children[#children + 1] = {
                type = "checkbox",
                caption = caption,
                tooltip = tooltip,
                state = actual_category_settings[setting_name],
                enabled = enabled,
                actions = enabled and {
                  on_click = {
                    gui = "settings",
                    action = "change_general_setting",
                    type = setting_ident.type,
                    category = category,
                    name = setting_name,
                  }
                } or nil,
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
                selected_index = table.find(setting_ident.options, actual_category_settings[setting_name]),
                enabled = enabled,
                actions = enabled and {
                  on_selection_state_changed = {
                    gui = "settings",
                    action = "change_general_setting",
                    type = setting_ident.type,
                    category = category,
                    name = setting_name,
                  }
                } or nil,
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
  end

  -- CATEGORIES

  if not tab or tab == "categories" then
    local categories_frame = refs.categories.frame
    categories_frame.clear()
    local selected_class = constants.category_classes[state.selected_category]
    local class_settings = actual_settings.categories[selected_class]
    local class_translations = translations[selected_class]
    local children = {}
    for category_name in pairs(recipe_book[selected_class]) do
      local category_translation = class_translations[category_name] or category_name
      if string.find(string.lower(category_translation), query) then
        local img_type = constants.class_to_type[selected_class]
        if img_type then
          category_translation = "[img="..img_type.."/"..category_name.."]  "..category_translation
        end
        children[#children + 1] = {
          type = "checkbox",
          caption = category_translation,
          state = class_settings[category_name],
          actions = {
            on_checked_state_changed = {
              gui = "settings",
              action = "change_category_setting",
              class = selected_class,
              name = category_name,
            },
          },
        }
      end
    end

    if #children > 0 then
      gui.build(categories_frame, children)
    end
  end
end

return root
