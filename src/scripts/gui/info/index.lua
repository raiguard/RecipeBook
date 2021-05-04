local gui = require("__flib__.gui-beta")

local formatter = require("scripts.formatter")

local info_gui = {}

local function frame_action_button(sprite, tooltip, action, ref)
  return {
    type = "sprite-button",
    style = "frame_action_button",
    sprite = sprite.."_white",
    hovered_sprite = sprite.."_black",
    clicked_sprite = sprite.."_black",
    tooltip = tooltip,
    mouse_button_filter = {"left"},
    ref = ref,
    actions = {
      on_click = action
    }
  }
end

function info_gui.build(player, player_table, context)
  local id = player_table.guis.info._next_id
  player_table.guis.info._next_id = id + 1
  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      direction = "vertical",
      ref = {"window", "frame"},
      actions = {
        on_closed = {gui = "info", id = id, action = "close"}
      },
      {type = "flow", style = "flib_titlebar_flow", ref = {"titlebar", "flow"},
        frame_action_button(
          "rb_nav_backward",
          nil,
          {gui = "info", id = id, action = "navigate_backward"},
          {"titlebar", "nav_backward_button"}
        ),
        frame_action_button(
          "rb_nav_forward",
          nil,
          {gui = "info", id = id, action = "navigate_forward"},
          {"titlebar", "nav_forward_button"}
        ),
        {
          type = "label",
          style = "frame_title",
          style_mods = {left_margin = 4},
          -- TODO: Dynamic title?
          caption = {"mod-name.RecipeBook"},
          ignored_by_interaction = true
        },
        {
          type = "empty-widget",
          style = "flib_titlebar_drag_handle",
          ignored_by_interaction = true,
          ref = {"titlebar", "drag_handle"}
        },
        {
          type = "textfield",
          style_mods = {
            top_margin = -3,
            right_padding = 3,
          },
          visible = false,
          ref = {"titlebar", "search_textfield"},
          actions = {
            on_text_changed = {gui = "info", id = id, action = "update_search"}
          }
        },
        frame_action_button(
          "utility/search",
          {"gui.rb-search-instruction"},
          {gui = "info", id = id, action = "toggle_search"},
          {"titlebar", "search_button"}
        ),
        -- frame_action_button(
        --   "rb_pin",
        --   {"gui.rb-pin-instruction"},
        --   {gui = "info", id = id, action = "toggle_pinned"},
        --   {"titlebar", "pin_button"}
        -- ),
        -- frame_action_button(
        --   "rb_settings",
        --   {"gui.rb-settings-instruction"},
        --   {gui = "info", id = id, action = "toggle_settings"},
        --   {"titlebar", "settings_button"}
        -- ),
        frame_action_button(
          "utility/close",
          {"gui.close-instruction"},
          {gui = "info", id = id, action = "close"},
          {"titlebar", "close_button"}
        )
      },
      {type = "frame", style = "inside_shallow_frame", style_mods = {width = 500, height = 400},
        {type = "frame", style = "subheader_frame",
          {
            type = "label",
            style = "rb_toolbar_label",
            ref = {"info_bar", "label"}
          },
          {type = "empty-widget", style = "flib_horizontal_pusher"}
        }
      }
    }
  })

  refs.titlebar.flow.drag_target = refs.window.frame
  refs.window.frame.force_auto_center()

  -- TEMPORARY: Populate info bar label to distinguish GUIs
  local obj_data = global.recipe_book[context.class][context.name]
  local player_data = {
    favorites = player_table.favorites,
    force_index = player.force.index,
    history = player_table.history.global,
    -- TODO: Rename to `context`
    open_page_data = context,
    player_index = player.index,
    settings = player_table.settings,
    translations = player_table.translations
  }
  local info = formatter(obj_data, player_data, {always_show = true, is_label = true})
  local label = refs.info_bar.label
  label.caption = info.caption
  label.tooltip = info.tooltip

  player_table.guis.info[id] = {
    refs = refs,
    state = {
      history = {},
      opened_context = context,
      search_opened = false,
      search_query = ""
    }
  }
end

function info_gui.destroy(player_table, id)
  local gui_data = player_table.guis.info[id]
  if gui_data then
    gui_data.refs.window.frame.destroy()
    player_table.guis.info[id] = nil
  end
end

function info_gui.destroy_all(player_table)
  for id in pairs(player_table.guis.info) do
    if id ~= "_next_id" then
      info_gui.destroy(player_table, id)
    end
  end
end

function info_gui.find_open_context(player_table, context)
  for id, gui_data in pairs(player_table.guis.info) do
    if id ~= "_next_id" then
      local opened_context = gui_data.state.opened_context
      if opened_context.class == context.class and opened_context.name == context.name then
        return id
      end
    end
  end
end

function info_gui.handle_action(msg, e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]

  local gui_data = player_table.guis.info[msg.id]
  local state = gui_data.state
  local refs = gui_data.refs

  if msg.action == "close" then
    info_gui.destroy(player_table, msg.id)
  elseif msg.action == "bring_to_front" then
    refs.window.frame.bring_to_front()
  elseif msg.action == "toggle_search" then
    local opened = state.search_opened
    state.search_opened = not opened

    local search_button = refs.titlebar.search_button
    local search_textfield = refs.titlebar.search_textfield
    if opened then
      search_button.sprite = "utility/search_white"
      search_button.style = "frame_action_button"
      search_textfield.text = ""
      state.search_query = ""
      search_textfield.visible = false
    else
      search_button.sprite = "utility/search_black"
      search_button.style = "flib_selected_frame_action_button"
      search_textfield.visible = true
      search_textfield.focus()
    end
  end
end

return info_gui
