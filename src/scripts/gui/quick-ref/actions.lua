local gui = require("__flib__.gui")

local gui_util = require("scripts.gui.util")
local shared = require("scripts.shared")

local actions = {}

--- @param Gui QuickRefGui
function actions.close(Gui, _, _)
  Gui:destroy()
end

--- @param Gui QuickRefGui
--- @param e on_gui_click
function actions.reset_location(Gui, _, e)
  if e.button == defines.mouse_button_type.middle then
    Gui.refs.window.location = { x = 0, y = 0 }
  end
end

--- @param Gui QuickRefGui
--- @param e on_gui_click
function actions.handle_button_click(Gui, _, e)
  if e.alt then
    local button = e.element
    local style = button.style.name
    if style == "flib_slot_button_green" then
      button.style = gui.get_tags(button).previous_style
    else
      gui.update_tags(button, { previous_style = style })
      button.style = "flib_slot_button_green"
    end
  else
    local context = gui_util.navigate_to(e)
    if context then
      -- FIXME:
      shared.open_page(Gui.player, Gui.player_table, context)
    end
  end
end

--- @param Gui QuickRefGui
function actions.view_details(Gui, _, _)
  -- FIXME:
  shared.open_page(Gui.player, Gui.player_table, { class = "recipe", name = Gui.recipe_name })
end

return actions
