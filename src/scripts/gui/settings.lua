local gui = require("__flib__.gui-beta")
local on_tick_n = require("__flib__.on-tick-n")
local table = require("__flib__.table")

local constants = require("constants")

local shared = require("scripts.shared")
local util = require("scripts.util")

local settings_gui = {}

function settings_gui.build(player, player_table)
  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      direction = "vertical",
      caption = {"gui.rb-settings"},
      ref = {"window"},
      actions = {
        on_closed = {gui = "settings", action = "close"},
      },
      {type = "frame", style = "inside_deep_frame", direction = "vertical",
        {type = "frame", style = "subheader_frame", style_mods = {left_padding = 12},
          -- {
          --   type = "checkbox",
          --   caption = "Keep open",
          --   state = false,
          --   action = {
          --     on_click = {gui = "settings", action = "toggle_keep_open"},
          --   },
          -- },
          {type = "empty-widget", style = "flib_horizontal_pusher"},
          {
            type = "textfield",
            style_mods = {width = 200},
            visible = false,
            ref = {"toolbar", "search_textfield"},
            actions = {
              on_text_changed = {gui = "settings", action = "update_search_query"}
            }
          },
          {
            type = "sprite-button",
            style = "tool_button",
            sprite = "utility/search_icon",
            tooltip = {"gui.rb-search-instruction"},
            ref = {"toolbar", "search_button"},
            actions = {
              on_click = {gui = "settings", action = "toggle_search"},
            },
          },
          {
            type = "sprite-button",
            style = "tool_button_red",
            sprite = "utility/reset",
            tooltip = {"reset-to-defaults-disabled"},
            enabled = false,
            ref = {"toolbar", "reset_button"},
            actions = {
              on_click = {gui = "settings", action = "reset_to_defaults"},
            },
          },
        },
        {type = "tabbed-pane", style = "flib_tabbed_pane_with_no_padding", style_mods = {top_padding = 12, width = 500},
          {
            tab = {type = "tab", caption = {"gui.rb-general"}},
            -- TODO: Does this need to be a scroll pane?
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
      {type = "flow", style = "dialog_buttons_horizontal_flow",
        {
          type = "button",
          style = "back_button",
          caption = {"gui.cancel"},
          actions = {
            on_click = {gui = "settings", action = "close"}
          }
        },
        {type = "empty-widget", style = "flib_dialog_footer_drag_handle", ref = {"footer_drag_handle"}},
        {
          type = "button",
          style = "confirm_button",
          caption = {"gui.confirm"},
          enabled = false,
          actions = {
            on_click = {gui = "settings", action = "confirm"},
          },
        },
      }
    }
  })

  refs.window.force_auto_center()
  player.opened = refs.window

  player_table.guis.settings = {
    refs = refs,
    state = {
      -- keep_open = false,
      search_opened = false,
      search_query = "",
    },
  }

  -- GENERAL

  local general_pane = refs.general.pane
  for category, settings in pairs(constants.general_settings) do
    local category_frame = general_pane.add{type = "frame", style = "bordered_frame", direction = "vertical", caption = category}
    -- local spacer = category_frame.add{type = "empty-widget"}
    -- spacer.style.size = {100, 100}
    for setting_name, setting_ident in pairs(settings) do
      if setting_ident.type == "bool" then
        local checkbox = category_frame.add{type = "checkbox", caption = setting_name, state = setting_ident.default_value}
      elseif setting_ident.type == "enum" then
        local flow = category_frame.add{type = "flow"}
        flow.style.vertical_align = "center"
        flow.add{type = "label", caption = setting_name}
        flow.add{type = "empty-widget", style = "flib_horizontal_pusher"}
        flow.add{type = "drop-down", items = setting_ident.options, selected_index = table.find(setting_ident.options, setting_ident.default_value)}
      end
    end
  end

  -- CATEGOREIS

  local categories_pane = refs.categories.pane
  local dummy_category = constants.category_classes[2]
  for category_name in pairs(global.recipe_book[dummy_category]) do
    categories_pane.add{type = "checkbox", caption = category_name, state = true}
  end
  for i = 1, 15 do
    categories_pane.add{type = "checkbox", caption = i, state = true}
  end
end

function settings_gui.destroy(player_table)
  player_table.guis.settings.refs.window.destroy()
  player_table.guis.settings = nil
end

function settings_gui.toggle(player, player_table)
  if player_table.guis.settings then
    settings_gui.destroy(player_table)
  else
    settings_gui.build(player, player_table)
  end
end

function settings_gui.handle_action(msg, e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]

  local gui_data = player_table.guis.settings
  if not gui_data then return end
  local state = gui_data.state
  local refs = gui_data.refs

  local action = msg.action

  if action == "close" then
    settings_gui.destroy(player_table)
    shared.deselect_settings_button(player, player_table)
  elseif action == "confirm" then
    if e.name == defines.events.on_gui_click then
      settings_gui.destroy(player_table)
      shared.deselect_settings_button(player, player_table)
    else
      player.play_sound{path = "utility/confirm"}
    end
  -- elseif action == "toggle_keep_open" then
  --   state.keep_open = not state.keep_open
  --   refs.toolbar.keep_open_checkbox.state = state.keep_open
  elseif action == "toggle_search" then
    local opened = state.search_opened
    state.search_opened = not opened

    local search_button = refs.toolbar.search_button
    local search_textfield = refs.toolbar.search_textfield
    if opened then
      search_button.style = "tool_button"
      search_textfield.visible = false

      if state.search_query ~= "" then
        -- Reset query
        search_textfield.text = ""
        state.search_query = ""
        -- Refresh page
        -- TODO:
        -- info_gui.update_contents(player, player_table, msg.id)
      end
    else
      -- Show search textfield
      search_button.style = "flib_selected_tool_button"
      search_textfield.visible = true
      search_textfield.focus()
    end
  elseif action == "update_search_query" then
    local query = string.lower(e.element.text)
    -- Fuzzy search
    if player_table.settings.use_fuzzy_search then
      query = string.gsub(query, ".", "%1.*")
    end
    -- Input sanitization
    for pattern, replacement in pairs(constants.input_sanitizers) do
      query = string.gsub(query, pattern, replacement)
    end
    -- Save query
    state.search_query = query

    -- Remove scheduled update if one exists
    if state.update_results_ident then
      on_tick_n.remove(state.update_results_ident)
      state.update_results_ident = nil
    end

    if query == "" then
      -- Update now
      -- TODO:
      -- info_gui.update_contents(player, player_table, msg.id, {refresh = true})
    else
      -- Update in a while
      state.update_results_ident = on_tick_n.add(
        game.tick + constants.search_timeout,
        {gui = "settings", action = "update_search_results", player_index = e.player_index}
      )
    end
  end
end

return settings_gui
