local handlers = {}

--- @param self Gui
function handlers.close_button(self)
  self:hide()
end

--- @param e on_gui_checked_state_changed
function handlers.collapse_list_box(_, e)
  local state = e.element.state
  e.element.parent.parent.list_frame.style.height = state and 1 or 0
end

--- @param self Gui
--- @param e on_gui_click
function handlers.filter_group_button(self, e)
  self:select_filter_group(e.element.name)
end

--- @param self Gui
--- @param e on_gui_click
function handlers.pin_button(self, e)
  self.state.pinned = not self.state.pinned
  if self.state.pinned then
    e.element.style = "flib_selected_frame_action_button"
    e.element.sprite = "rb_pin_black"
    self.refs.close_button.tooltip = { "gui.close" }
    self.refs.search_button.tooltip = { "gui.search" }
    if self.player.opened == self.refs.window then
      self.player.opened = nil
    end
  else
    e.element.style = "frame_action_button"
    e.element.sprite = "rb_pin_white"
    self.player.opened = self.refs.window
    self.refs.window.force_auto_center()
    self.refs.close_button.tooltip = { "gui.close-instruction" }
    self.refs.search_button.tooltip = { "gui.rb-search-instruction" }
  end
end

--- @param self Gui
--- @param e on_gui_click
function handlers.prototype_button(self, e)
  self:show_page(e.element.name)
end

--- @param self Gui
function handlers.search_button(self)
  self:toggle_search()
end

--- @param self Gui
--- @param e on_gui_click
function handlers.show_hidden_button(self, e)
  self.state.show_hidden = not self.state.show_hidden
  if self.state.show_hidden then
    e.element.style = "flib_selected_frame_action_button"
    e.element.sprite = "rb_show_hidden_black"
  else
    e.element.style = "frame_action_button"
    e.element.sprite = "rb_show_hidden_white"
  end
end

--- @param self Gui
--- @param e on_gui_click
function handlers.show_unresearched_button(self, e)
  self.state.show_unresearched = not self.state.show_unresearched
  if self.state.show_unresearched then
    e.element.style = "flib_selected_frame_action_button"
    e.element.sprite = "rb_show_unresearched_black"
  else
    e.element.style = "frame_action_button"
    e.element.sprite = "rb_show_unresearched_white"
  end
end

--- @param self Gui
function handlers.window_closed(self)
  if not self.state.pinned then
    if self.state.search_open then
      self:toggle_search()
      self.player.opened = self.refs.window
    else
      self:hide()
    end
  end
end

return handlers
