local flib_gui = require("__flib__/gui-lite")

local database = require("__RecipeBook__/scripts/database")
local gui_util = require("__RecipeBook__/scripts/gui/util")
local util = require("__RecipeBook__/scripts/util")

--- @class ListBox
local list_box = {}

--- @type function?
list_box.on_result_clicked = nil
--- @type function?
list_box.on_result_hovered = nil

--- @param parent LuaGuiElement
--- @param context MainGuiContext
--- @param title LocalisedString
--- @param members GenericObject[]?
--- @param remark LocalisedString?
function list_box.build(parent, context, title, members, remark)
  if not members or #members == 0 then
    return
  end
  local outer = parent.add({ type = "flow", direction = "vertical" })
  local header = outer.add({ type = "flow", style = "centering_horizontal_flow" })
  -- header.add({ type = "label", style = "caption_label", caption = title })
  header.add({
    type = "checkbox",
    style = "rb_list_box_caption",
    caption = title,
    state = false,
    tags = flib_gui.format_handlers({ [defines.events.on_gui_click] = list_box.toggle_collapsed }),
  })
  local count_label = header.add({ type = "label", style = "rb_info_label" })
  if remark then
    header.add({ type = "empty-widget", style = "flib_horizontal_pusher" })
    header.add({ type = "label", caption = remark })
  end

  local frame = outer.add({
    type = "frame",
    name = "frame",
    style = "deep_frame_in_shallow_frame",
    direction = "vertical",
  })

  local show_hidden = context.show_hidden
  local show_unresearched = context.show_unresearched
  local force_index = context.player.force.index

  local _ -- To avoid creating a global
  local result_count = 0
  for member_index = 1, #members do
    local member = members[member_index]
    local entry = database.get_entry(member)
    if not entry then
      goto continue
    end
    -- Validate visibility
    local is_hidden = util.is_hidden(entry.base)
    local is_unresearched = util.is_unresearched(entry, force_index)
    if is_hidden and not show_hidden then
      goto continue
    elseif is_unresearched and not show_unresearched then
      goto continue
    end
    -- Style
    local style = "rb_list_box_item"
    if is_hidden then
      style = "rb_list_box_item_hidden"
    elseif is_unresearched then
      style = "rb_list_box_item_unresearched"
    end
    frame.add({
      type = "sprite-button",
      style = style,
      sprite = entry.base_path,
      caption = gui_util.build_caption(member),
      tags = flib_gui.format_handlers({
        [defines.events.on_gui_click] = list_box.on_result_clicked,
        [defines.events.on_gui_hover] = list_box.on_result_hovered,
      }),
      raise_hover_events = true,
    })
    -- button.remark.caption = gui_util.build_remark(member)
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
function list_box.toggle_collapsed(e)
  local frame = e.element.parent.parent.frame
  if frame then
    frame.style.height = e.element.state and 1 or 0
  end
end

flib_gui.add_handlers(list_box, nil, "list_box")

return list_box
