local gui = require("__flib__.gui")

local formatter = require("scripts.formatter")
local util = require("scripts.util")

local root = {}

function root.build(player, player_table)
  local refs = gui.build(player.gui.screen, {
    {type = "frame", direction = "vertical", visible = false, ref = {"window"},
      {type = "flow", style = "flib_titlebar_flow", ref = {"titlebar", "flow"},
        {type = "label", style = "frame_title", caption = {"mod-name.RecipeBook"}, ignored_by_interaction = true},
        {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
        util.frame_action_button(
          "rb_settings",
          {"gui.rb-settings-instruction"},
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
      {type = "frame", style = "inside_deep_frame_for_tabs", style_mods = {width = 276}, direction = "vertical",
        {
          type = "tabbed-pane",
          style = "tabbed_pane_with_no_side_padding",
          style_mods = {height = 532},
          ref = {"tabbed_pane"},
          {tab = {type = "tab", caption = {"gui.search"}}, content = (
            {
              type = "frame",
              style = "rb_inside_deep_frame_under_tabs",
              direction = "vertical",
              {type = "frame", style = "rb_subheader_frame", direction = "vertical",
                {
                  type = "textfield",
                  style = "flib_widthless_textfield",
                  style_mods = {horizontally_stretchable = true},
                  ref = {"search_textfield"},
                  actions = {
                    on_text_changed = {gui = "search", action = "update_search_query"}
                  }
                },
              },
              {type = "scroll-pane", style = "rb_search_results_scroll_pane", ref = {"search_results_pane"}}
            }
          )},
          {tab = {type = "tab", caption = {"gui.rb-favorites"}}, content = (
            {type = "frame", style = "rb_inside_deep_frame_under_tabs", direction = "vertical",
              {type = "frame", style = "subheader_frame",
                {type = "empty-widget", style = "flib_horizontal_pusher"},
                {
                  type = "sprite-button",
                  style = "tool_button_red",
                  sprite = "utility/trash",
                  tooltip = {"gui.rb-delete-favorites"},
                  ref = {"delete_favorites_button"},
                  actions = {
                    on_click = {gui = "search", action = "delete_favorites"},
                  },
                },
              },
              {type = "scroll-pane", style = "rb_search_results_scroll_pane", ref = {"favorites_pane"}}
            }
          )},
          {tab = {type = "tab", caption = {"gui.rb-history"}}, content = (
            {type = "frame", style = "rb_inside_deep_frame_under_tabs", direction = "vertical",
              {type = "frame", style = "subheader_frame",
                {type = "empty-widget", style = "flib_horizontal_pusher"},
                {
                  type = "sprite-button",
                  style = "tool_button_red",
                  sprite = "utility/trash",
                  tooltip = {"gui.rb-delete-history"},
                  ref = {"delete_history_button"},
                  actions = {
                    on_click = {gui = "search", action = "delete_history"},
                  },
                },
              },
              {type = "scroll-pane", style = "rb_search_results_scroll_pane", ref = {"history_pane"}}
            }
          )}
        },
      }
    }
  })

  refs.titlebar.flow.drag_target = refs.window

  player_table.guis.search = {
    state = {
      search_query = ""
    },
    refs = refs
  }

  -- TODO: Update favorites and history
end

function root.destroy(player, player_table)
  player_table.guis.search.refs.window.destroy()
  player_table.guis.search = nil
  player.set_shortcut_toggled("rb-search", false)
end

function root.open(player, player_table)
  local gui_data = player_table.guis.search
  local refs = gui_data.refs
  refs.window.visible = true
  refs.search_textfield.select_all()
  refs.search_textfield.focus()
  refs.tabbed_pane.selected_tab_index = 1

  player.set_shortcut_toggled("rb-search", true)
end

function root.close(player, player_table)
  player_table.guis.search.refs.window.visible = false
  player.set_shortcut_toggled("rb-search", false)
end

function root.toggle(player, player_table)
  if player_table.guis.search.refs.window.visible then
    root.close(player, player_table)
  else
    root.open(player, player_table)
  end
end

return root
