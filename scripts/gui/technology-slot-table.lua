local flib_gui = require("__flib__.gui-lite")
local flib_gui_templates = require("__flib__.gui-templates")
local flib_technology = require("__flib__.technology")

--- @class technology_slot_table
local technology_slot_table = {}

--- @type function?
technology_slot_table.on_result_clicked = nil

--- @param parent LuaGuiElement
--- @param context MainGuiContext
--- @param title LocalisedString
--- @param ids EntryID[]?
--- @param remark LocalisedString?
function technology_slot_table.build(parent, context, title, ids, remark)
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
    tags = flib_gui.format_handlers({ [defines.events.on_gui_click] = technology_slot_table.toggle_collapsed }),
  })
  local count_label = header.add({ type = "label", style = "rb_info_label" })
  if remark then
    header.add({ type = "empty-widget", style = "flib_horizontal_pusher" })
    header.add({ type = "label", caption = remark })
  end

  local frame = outer.add({ type = "frame", name = "frame", style = "rb_technology_slot_deep_frame" })
  local tbl = frame.add({ type = "table", name = "table", style = "slot_table", column_count = 5 })

  local show_hidden = context.show_hidden
  local force_index = context.player.force.index

  local result_count = 0
  for id_index = 1, #ids do
    local id = ids[id_index]
    local entry = id:get_entry()
    -- Validate visibility
    -- local is_hidden = util.is_hidden(entry.base)
    -- local is_unresearched = util.is_unresearched(entry, force_index)
    if entry:is_hidden(force_index) and not show_hidden then
      goto continue
    end
    local research_state
    if not entry:is_researched(force_index) then
      research_state = flib_technology.research_state.not_available
    else
      research_state = flib_technology.research_state.researched
    end
    local technology = context.player.force.technologies[id.name]
    local slot = flib_gui_templates.technology_slot(
      tbl,
      technology,
      technology.level,
      research_state,
      technology_slot_table.on_result_clicked
    )
    local tags = slot.tags
    tags.path = id:get_path()
    slot.tags = tags
    slot.tooltip = { "", { "gui.rb-control-hint" }, "\n", { "gui.rb-technology-control-hint" } }
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
function technology_slot_table.toggle_collapsed(_, e)
  local frame = e.element.parent.parent.frame
  if frame then
    frame.style.height = e.element.state and 1 or 0
  end
end

flib_gui.add_handlers(technology_slot_table, function(e, handler)
  local main = global.guis[e.player_index]
  if not main or not main.window.valid then
    return
  end
  handler(main, e)
end, "technology_slot_table")

return technology_slot_table
