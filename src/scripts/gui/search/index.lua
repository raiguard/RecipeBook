local gui = require("__flib__.gui-beta")

local util = require("scripts.util")

local search_gui = {}

function search_gui.build(player, player_table)
  local refs = gui.build(player.gui.screen, {
    {type = "frame", direction = "vertical", ref = {"window"},
      {type = "flow", style = "flib_titlebar_flow", ref = {"titlebar", "flow"},
        {type = "label", style = "frame_title", caption = "Recipe Book", ignored_by_interaction = true},
        {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
        util.frame_action_button(
          "rb_settings",
          nil,
          {"titlebar", "settings_button"},
          {gui = "search", action = "toggle_settings"}
        ),
        util.frame_action_button(
          "utility/close",
          {"gui.close"},
          {"titlebar", "close_button"},
          {gui = "search", action = "close"}
        )
      },
      {type = "frame", style = "inside_deep_frame_for_tabs", direction = "vertical",
        {type = "tabbed-pane", style = "tabbed_pane_with_no_side_padding", style_mods = {height = 540},
          {tab = {type = "tab", caption = "Search"}, content = (
            {type = "frame", style = "rb_inside_deep_frame_under_tabs", direction = "vertical",
              {type = "frame", style = "rb_subheader_frame", direction = "vertical",
                {type = "flow", style_mods = {vertical_align = "center"},
                  {type = "label", style = "subheader_caption_label", caption = "Class:"},
                  {type = "empty-widget", style = "flib_horizontal_pusher"},
                  {type = "drop-down", items = {"Crafter", "Fluid", "Group", "Lab", "Mining drill", "Offshore pump", "Item", "Recipe category", "Recipe", "Resource category", "Resource", "Technology"}}
                },
                {type = "line", style = "rb_dark_line"},
                {type = "textfield", style = "flib_widthless_textfield", style_mods = {horizontally_stretchable = true}},
              },
              {type = "scroll-pane", style = "rb_search_results_scroll_pane"}
            }
          )},
          {tab = {type = "tab", caption = "Favorites"}, content = (
            {type = "frame", style = "rb_inside_deep_frame_under_tabs", direction = "vertical",
              {type = "scroll-pane", style = "rb_search_results_scroll_pane"}
            }
          )},
          {tab = {type = "tab", caption = "History"}, content = (
            {type = "frame", style = "rb_inside_deep_frame_under_tabs", direction = "vertical",
              {type = "scroll-pane", style = "rb_search_results_scroll_pane"}
            }
          )}
        },
      }
    }
  })

  refs.titlebar.flow.drag_target = refs.window

  player_table.guis.search = {
    state = {},
    refs = refs
  }
  player.set_shortcut_toggled("rb-search", true)
end

function search_gui.destroy(player, player_table)
  player_table.guis.search.refs.window.destroy()
  player_table.guis.search = nil
  player.set_shortcut_toggled("rb-search", false)
end

function search_gui.toggle(player, player_table)
  if player_table.guis.search then
    search_gui.destroy(player, player_table)
  else
    search_gui.build(player, player_table)
  end
end

return search_gui
