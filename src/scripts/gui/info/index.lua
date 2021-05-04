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
  local id = player_table.guis.info._nextid
  player_table.guis.info._nextid = id + 1
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
        {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
        {
          type = "textfield",
          style = "flib_widthless_textfield",
          style_mods = {
            horizontally_stretchable = true,
            top_margin = -3
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
        frame_action_button(
          "rb_pin",
          {"gui.rb-pin-instruction"},
          {gui = "info", id = id, action = "toggle_pinned"},
          {"titlebar", "pin_button"}
        ),
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
  local info = formatter(obj_data, player_data, {always_show = true})
  local label = refs.info_bar.label
  label.caption = info.caption
  label.tooltip = info.tooltip

  player_table.guis.info[id] = {
    refs = refs,
    state = {
      history = {},
      opened_context = context
    }
  }
end

function info_gui.destroy(player_table, id)

end

function info_gui.destroy_all(player_table)

end

function info_gui.handle_action(msg, e)

end

return info_gui
