local recipe_book = require("scripts.recipe-book")

local actions = {}

--- @param Gui VisualSearchGui
--- @param msg table
function actions.change_group(Gui, msg)
  local last_group = Gui.state.active_group

  Gui.refs.group_table[last_group].style = "rb_filter_group_button_tab"
  Gui.refs.group_table[last_group].enabled = true
  Gui.refs.items_frame[last_group].visible = false

  local new_group = msg.group
  Gui.refs.group_table[new_group].style = "rb_selected_filter_group_button_tab"
  Gui.refs.group_table[new_group].enabled = false
  Gui.refs.items_frame[new_group].visible = true

  Gui.state.active_group = msg.group
end

--- @param Gui VisualSearchGui
--- @param msg table
--- @param e on_gui_click
function actions.open_object(Gui, msg, e)
  local context = msg.context

  local list_name
  if e.button == defines.mouse_button_type.left then
    list_name = "product_of"
  elseif e.button == defines.mouse_button_type.right then
    list_name = "ingredient_in"
  end

  local list = recipe_book[context.class][context.name][list_name]
  if list and #list > 0 then
    local first_obj = list[1]
    OPEN_PAGE(Gui.player, Gui.player_table, {
      class = first_obj.class,
      name = first_obj.name,
      list = {
        context = context,
        index = 1,
        source = list_name,
      },
    })
  end
end

return actions
