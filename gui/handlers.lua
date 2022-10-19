local handlers = {}

--- @param self Gui
--- @param e on_gui_click
function handlers.select_filter_group(self, e)
  self:select_filter_group(e.element.name)
end

--- @param self Gui
--- @param e on_gui_click
function handlers.show_recipe(self, e)
  self:show_recipe(e.element.name)
end

return handlers
