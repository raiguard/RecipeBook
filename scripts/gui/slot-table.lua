local flib_gui = require("__flib__.gui-lite")

local database = require("scripts.database")
local gui_util = require("scripts.gui.util")
local util = require("scripts.util")

--- @class SlotTable
local slot_table = {}

--- @type function?
slot_table.on_result_clicked = nil

--- @param parent LuaGuiElement
--- @param context MainGuiContext
--- @param title LocalisedString
--- @param members GenericObject[]?
--- @param remark LocalisedString?
--- @param parent_fluid string?
function slot_table.build(parent, context, title, members, remark, parent_fluid)
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
    tags = flib_gui.format_handlers({ [defines.events.on_gui_click] = slot_table.toggle_collapsed }),
  })
  local count_label = header.add({ type = "label", style = "rb_info_label" })
  if remark then
    header.add({ type = "empty-widget", style = "flib_horizontal_pusher" })
    header.add({ type = "label", caption = remark })
  end

  local frame = outer.add({ type = "frame", name = "frame", style = "slot_button_deep_frame" })
  -- frame.style.horizontally_stretchable = true
  local tbl = frame.add({ type = "table", name = "table", style = "slot_table", column_count = 10 })

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
    local style = "flib_slot_button_default"
    if is_hidden then
      style = "flib_slot_button_grey"
    elseif is_unresearched then
      style = "flib_slot_button_red"
    end
    local button = tbl.add({
      type = "sprite-button",
      style = style,
      sprite = entry.base_path,
      elem_tooltip = member,
      tooltip = { "gui.rb-control-hint" },
      -- TODO: Probabilities, ranges, fluid temperatures
      number = member.amount,
      tags = flib_gui.format_handlers({
        [defines.events.on_gui_click] = slot_table.on_result_clicked,
      }),
    })
    -- TODO: Custom tooltip titles with all the info?
    if not member.amount and (member.temperature or member.minimum_temperature) then
      local bottom, top = gui_util.build_temperature_strings(member)
      if bottom then
        button.add({ type = "label", style = "rb_slot_label", caption = bottom, ignored_by_interaction = true })
      end
      if top then
        button.add({ type = "label", style = "rb_slot_label_top", caption = top, ignored_by_interaction = true })
      end
    end
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
function slot_table.toggle_collapsed(e)
  local frame = e.element.parent.parent.frame
  if frame then
    frame.style.height = e.element.state and 1 or 0
  end
end

flib_gui.add_handlers(slot_table, nil, "slot_table")

return slot_table
