local gui = require("__flib__.gui")

local gui_util = require("scripts.gui.util")
local shared = require("scripts.shared")

local root = require("scripts.gui.quick-ref.root")

local actions = {}

function actions.bring_all_to_front(player_table)
  for _, gui_data in pairs(player_table.guis.quick_ref) do
    gui_data.refs.window.bring_to_front()
  end
end

function actions.close(data)
  root.destroy(data.player, data.player_table, data.msg.id)
end

function actions.reset_location(data)
  data.refs.window.location = {x = 0, y = 0}
end

function actions.handle_button_click(data)
  local e = data.e

  if e.alt then
    local button = e.element
    local style = button.style.name
    if style == "flib_slot_button_green" then
      button.style = gui.get_tags(button).previous_style
    else
      gui.update_tags(button, {previous_style = style})
      button.style = "flib_slot_button_green"
    end
  else
    local context = gui_util.navigate_to(e)
    if context then
      shared.open_page(data.player, data.player_table, context)
    end
  end
end

function actions.view_details(data)
  shared.open_page(data.player, data.player_table, {class = "recipe", name = data.msg.id})
end

return actions
