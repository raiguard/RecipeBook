local flib_gui = require("__flib__/gui-lite")
local math = require("__flib__/math")

local database = require("__RecipeBook__/database")
local gui_templates = require("__RecipeBook__/gui-templates")
local util = require("__RecipeBook__/util")

--- @class GuiUtil
local gui_util = {}

--- @param obj GenericObject
--- @param include_icon boolean?
--- @return LocalisedString
function gui_util.build_caption(obj, include_icon)
  --- @type LocalisedString
  local caption = { "", "            " }
  if include_icon then
    caption[#caption + 1] = "[img=" .. obj.type .. "/" .. obj.name .. "]  "
  end
  if obj.probability and obj.probability < 1 then
    caption[#caption + 1] = {
      "",
      "[font=default-semibold]",
      { "format-percent", math.round(obj.probability * 100, 0.01) },
      "[/font] ",
    }
  end
  if obj.amount then
    caption[#caption + 1] = {
      "",
      "[font=default-semibold]",
      util.format_number(obj.amount),
      " ×[/font]  ",
    }
  elseif obj.amount_min and obj.amount_max then
    caption[#caption + 1] = {
      "",
      "[font=default-semibold]",
      util.format_number(obj.amount_min),
      " - ",
      util.format_number(obj.amount_max),
      " ×[/font]  ",
    }
  end
  -- TODO: Optimize this
  caption[#caption + 1] = game[obj.type .. "_prototypes"][obj.name].localised_name

  return caption
end

--- @param obj GenericObject
--- @return LocalisedString
function gui_util.build_remark(obj)
  --- @type LocalisedString
  local remark = { "" }
  if obj.required_fluid then
    remark[#remark + 1] = { "", gui_util.build_caption(obj.required_fluid, true) }
  end
  if obj.duration then
    remark[#remark + 1] = { "", "  [img=quantity-time] ", { "time-symbol-seconds", math.round(obj.duration, 0.01) } }
  end
  if obj.temperature then
    remark[#remark + 1] = { "", "  ", { "format-degrees-c-compact", math.round(obj.temperature, 0.01) } }
  elseif obj.minimum_temperature and obj.maximum_temperature then
    local temperature_min = obj.minimum_temperature --[[@as number]]
    local temperature_max = obj.maximum_temperature --[[@as number]]
    local temperature_string
    if temperature_min == math.min_double then
      temperature_string = "≤ " .. math.round(temperature_max, 0.01)
    elseif temperature_max == math.max_double then
      temperature_string = "≥ " .. math.round(temperature_min, 0.01)
    else
      temperature_string = "" .. math.round(temperature_min, 0.01) .. " - " .. math.round(temperature_max, 0.01)
    end
    remark[#remark + 1] = { "", "  ", { "format-degrees-c-compact", temperature_string } }
  end
  return remark
end

--- @param obj GenericObject
--- @return LocalisedString
function gui_util.build_tooltip(obj)
  local entry = database.get_entry(obj)
  if not entry then
    return ""
  end
  local base = entry.base
  --- @type LocalisedString
  local tooltip = {
    "",
    { "gui.rb-tooltip-title", { "", base.localised_name, " (", util.type_locale[obj.type], ")" } },
  }
  --- @type LocalisedString
  local description = { "?" }
  for _, key in pairs({ "recipe", "item", "fluid", "entity" }) do
    local prototype = entry[key]
    if prototype then
      description[#description + 1] = { "", "\n", prototype.localised_description }
    end
  end
  description[#description + 1] = ""
  tooltip[#tooltip + 1] = description

  return tooltip
end

--- @alias FabState
--- | "default"
--- | "selected"
--- | "disabled"

--- @param button LuaGuiElement
--- @param state FabState
function gui_util.update_frame_action_button(button, state)
  local sprite_base = string.match(button.sprite, "(.*)_[a-z]")
  if state == "default" then
    button.enabled = true
    button.style = "frame_action_button"
    button.sprite = sprite_base .. "_white"
  elseif state == "selected" then
    button.enabled = true
    button.style = "flib_selected_frame_action_button"
    button.sprite = sprite_base .. "_black"
  elseif state == "disabled" then
    button.enabled = false
    button.style = "frame_action_button"
    button.sprite = sprite_base .. "_disabled"
  end
end

--- @param self Gui
--- @param handlers GuiHandlers
--- @param flow LuaGuiElement
--- @param members GenericObject[]
--- @param remark LocalisedString?
--- @param no_collapse boolean?
function gui_util.update_list_box(self, handlers, flow, members, remark, no_collapse)
  members = members or {}
  local header_flow = flow.header_flow --[[@as LuaGuiElement]]
  local list_frame = flow.list_frame --[[@as LuaGuiElement]]
  local children = list_frame.children

  -- Header remark
  local remark_label = header_flow.remark
  remark_label.caption = remark or ""

  local show_hidden = self.show_hidden
  local show_unresearched = self.show_unresearched
  local force_index = self.player.force.index

  local _ -- To avoid creating a global
  local child_index = 0
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
    -- Get button
    child_index = child_index + 1
    local button = children[child_index]
    if not button then
      _, button = flib_gui.add(list_frame, gui_templates.list_box_item(handlers))
    end
    -- Style
    local style = "rb_list_box_item"
    if is_hidden then
      style = "rb_list_box_item_hidden"
    elseif is_unresearched then
      style = "rb_list_box_item_unresearched"
    end
    button.style = style
    -- Sprite
    button.sprite = entry.base_path
    -- Caption
    button.caption = gui_util.build_caption(member)
    -- Tooltip
    button.tooltip = gui_util.build_tooltip(member)
    -- Remark
    button.remark.caption = gui_util.build_remark(member)
    ::continue::
  end
  for i = child_index + 1, #children do
    children[i].destroy()
  end

  flow.visible = child_index > 0

  local collapsed = child_index > 15 and not no_collapse
  list_frame.style.height = collapsed and 1 or 0
  header_flow.checkbox.state = collapsed

  -- Child count
  header_flow.count_label.caption = { "", "[", child_index, "]" }
end

return gui_util
