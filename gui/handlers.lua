local handlers = {}

--- @param self Gui
function handlers.close(self)
  self:hide()
end

--- @param self Gui
--- @param e on_gui_click
function handlers.select_filter_group(self, e)
  self:select_filter_group(e.element.name)
end

--- @param self Gui
--- @param e on_gui_click
function handlers.show_page(self, e)
  self:show_page(e.element.name)
end

return handlers
