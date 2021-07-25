local gui = require("__flib__.gui-beta")

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
      {type = "frame", style = "inside_shallow_frame", style_mods = {width = 500, height = 500}},
      {type = "flow", style = "dialog_buttons_horizontal_flow",
        {type = "button", style = "back_button", caption = {"gui.cancel"}},
        {type = "empty-widget", style = "flib_dialog_footer_drag_handle", ref = {"footer_drag_handle"}},
        {type = "button", style = "confirm_button", caption = {"gui.confirm"}},
      }
    }
  })

  refs.window.force_auto_center()
  player.opened = refs.window

  player_table.guis.settings = {
    refs = refs,
    settings = {
      -- TODO:
    }
  }
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
  local state = gui_data.state
  local refs = gui_data.refs

  if msg.action == "close" then
    settings_gui.destroy(player_table)
    shared.deselect_settings_button(player, player_table)
  elseif msg.action == "confirm" then
    player.play_sound{path = "utility/confirm"}
  end
end

return settings_gui
