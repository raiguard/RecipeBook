local flib_gui = require("__flib__.gui")

local researched = require("scripts.database.researched")
local util = require("scripts.util")

--- @class InfoSectionSettings
--- @field always_show boolean?
--- @field column_count integer?
--- @field remark LocalisedString?
--- @field style string?

--- @class InfoSection
local info_section = {}

--- @param parent LuaGuiElement
--- @param context MainGuiContext
--- @param title LocalisedString
--- @param ids DatabaseID[]?
--- @param settings InfoSectionSettings
--- @param callback function(id: DatabaseID, holder: LuaGuiElement): LuaGuiElement?
function info_section.build(parent, context, title, ids, settings, callback)
  if not ids or #ids == 0 then
    return
  end
  local outer = parent.add({ type = "flow", direction = "vertical" })
  local header = outer.add({ type = "flow" })
  header.style.vertical_align = "center"
  header.add({
    type = "checkbox",
    style = "rb_list_box_caption",
    caption = title,
    state = false,
    mouse_button_filter = {},
    tags = flib_gui.format_handlers({ [defines.events.on_gui_click] = info_section.on_header_clicked }),
  })
  local count_label = header.add({ type = "label", style = "rb_info_label" })
  if settings.remark then
    header.add({ type = "empty-widget", style = "flib_horizontal_pusher" })
    header.add({ type = "label", style = "count_label", caption = settings.remark })
  end

  local holder = outer
    .add({
      type = "frame",
      name = "frame",
      style = settings.style or "slot_button_deep_frame",
      direction = "vertical",
    })
    .add({ type = "table", name = "table", style = "slot_table", column_count = settings.column_count or 1 })

  local show_hidden = context.show_hidden
  local show_unresearched = context.show_unresearched
  local force_index = context.player.force.index
  local always_show = settings.always_show

  local result_count = 0
  for id_index = 1, #ids do
    local id = ids[id_index]
    local prototype = util.get_prototype(id)
    if not prototype then
      goto continue
    end

    local is_hidden = prototype.hidden_in_factoriopedia
    local is_unresearched = not researched.is(prototype, force_index)
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
    tags.id = { type = id.type, name = id.name }
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
function info_section.on_header_clicked(e)
  local frame = e.element.parent.parent.frame
  if frame then
    frame.style.height = e.element.state and 1 or 0
  end
end

flib_gui.add_handlers(info_section, nil, "info_section")

return info_section
