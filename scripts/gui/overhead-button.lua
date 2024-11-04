local flib_gui = require("__flib__.gui")
local mod_gui = require("__core__.lualib.mod-gui")

local main_gui = require("scripts.gui.main")

--- @param player LuaPlayer
local function refresh_button(player)
  local button_flow = mod_gui.get_button_flow(player)
  if button_flow.rb_toggle then
    button_flow.rb_toggle.destroy()
  end
  if player.mod_settings["rb-show-overhead-button"].value then
    button_flow.add({
      type = "sprite-button",
      name = "rb_toggle",
      style = mod_gui.button_style,
      tooltip = { "", { "shortcut-name.rb-toggle" }, " (", { "gui.rb-toggle-instruction" }, ")" },
      sprite = "rb_logo",
      tags = flib_gui.format_handlers({ [defines.events.on_gui_click] = main_gui.toggle }),
    }).style.padding =
      7
  end
end

local function on_runtime_mod_setting_changed(e)
  if e.setting ~= "rb-show-overhead-button" then
    return
  end
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  refresh_button(player)
end

local overhead_button = {}

function overhead_button.on_init()
  for _, player in pairs(game.players) do
    refresh_button(player)
  end
end

function overhead_button.on_configuration_changed()
  for _, player in pairs(game.players) do
    refresh_button(player)
  end
end

overhead_button.events = {
  [defines.events.on_runtime_mod_setting_changed] = on_runtime_mod_setting_changed,
}

return overhead_button
