local flib_gui = require("__flib__.gui-lite")

--- @class ContextMenu
--- @field overlay LuaGuiElement
--- @field window LuaGuiElement
local context_menu = {}
local mt = { __index = context_menu }
script.register_metatable("context_menu", mt)

--- @param player LuaPlayer
--- @param items LocalisedString[]
--- @param location GuiLocation
--- @return ContextMenu
function context_menu.new(player, items, location)
  local resolution = player.display_resolution
  local scale = player.display_scale
  local overlay_size = { resolution.width / scale, resolution.height / scale }

  local overlay = player.gui.screen.add({
    type = "frame",
    name = "rb_context_overlay",
    style = "invisible_frame",
    tags = flib_gui.format_handlers({ [defines.events.on_gui_click] = context_menu.on_overlay_clicked }),
  })
  overlay.style.size = overlay_size
  overlay.bring_to_front()

  local window = player.gui.screen.add({
    type = "frame",
    name = "rb_context_menu",
    style = "invisible_frame",
    direction = "vertical",
  })
  window.location = location
  for i = 1, #items do
    window.add({
      type = "button",
      style = "list_box_item",
      caption = items[i],
      tags = flib_gui.format_handlers({ [defines.events.on_gui_click] = context_menu.on_result_clicked }),
    })
  end
  window.bring_to_front()

  --- @type ContextMenu
  local self = {
    overlay = overlay,
    window = window,
  }
  return setmetatable(self, mt)
end

--- @param e EventData.on_gui_click
function context_menu.on_result_clicked(e)
  game.print(e.element.caption)
  context_menu.on_overlay_clicked(e)
end

--- @param e EventData.on_gui_click
function context_menu.on_overlay_clicked(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  player.gui.screen.rb_context_overlay.destroy()
  player.gui.screen.rb_context_menu.destroy()
end

flib_gui.add_handlers(context_menu, nil, "context_menu")

return context_menu
