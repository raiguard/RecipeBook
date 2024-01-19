local flib_gui = require("__flib__.gui-lite")

--- @class InfoSectionSettings
--- @field always_show boolean?
--- @field frame_style string?
--- @field remark LocalisedString?
--- @field use_table boolean?

--- @class InfoSection
local info_section = {}

--- @param parent LuaGuiElement
--- @param context MainGuiContext
--- @param title LocalisedString
--- @param ids EntryID[]?
--- @param settings InfoSectionSettings
--- @param callback function(id: EntryID, holder: LuaGuiElement): LuaGuiElement?
function info_section.build(parent, context, title, ids, settings, callback)
  if not ids or #ids == 0 then
    return
  end
  local outer = parent.add({ type = "flow", direction = "vertical" })
  local header = outer.add({ type = "flow", style = "centering_horizontal_flow" })
  header.add({
    type = "checkbox",
    style = "rb_list_box_caption",
    caption = title,
    state = false,
    tags = flib_gui.format_handlers({ [defines.events.on_gui_click] = info_section.toggle_collapsed }),
  })
  local count_label = header.add({ type = "label", style = "rb_info_label" })
  if settings.remark then
    header.add({ type = "empty-widget", style = "flib_horizontal_pusher" })
    header.add({ type = "label", style = "count_label", caption = settings.remark })
  end

  local holder = outer.add({
    type = "frame",
    name = "frame",
    style = settings.frame_style or "slot_button_deep_frame",
    direction = "vertical",
  })
  if settings.use_table then
    holder = holder.add({ type = "table", name = "table", style = "slot_table", column_count = 10 })
  end

  local show_hidden = context.show_hidden
  local show_unresearched = context.show_unresearched
  local force_index = context.player.force.index
  local always_show = settings.always_show

  local result_count = 0
  for id_index = 1, #ids do
    local id = ids[id_index]
    local entry = id:get_entry()
    if not entry then
      goto continue
    end

    local is_hidden = entry:is_hidden(force_index)
    local is_unresearched = not entry:is_researched(force_index)
    if not always_show then
      if is_hidden and not show_hidden then
        goto continue
      elseif is_unresearched and not show_unresearched then
        goto continue
      end
    end
    local button = callback(id, holder)
    if not button then
      goto continue
    end

    local tags = button.tags
    tags.path = id:get_path()
    button.tags = tags

    result_count = result_count + 1
    ::continue::
  end

  if result_count == 0 then
    outer.destroy()
    return
  end

  count_label.caption = { "", "[", result_count, "]" }
end

--- @param e EventData.on_gui_click
function info_section.toggle_collapsed(e)
  local frame = e.element.parent.parent.frame
  if frame then
    frame.style.height = e.element.state and 1 or 0
  end
end

flib_gui.add_handlers(info_section, nil, "info_section")

return info_section
