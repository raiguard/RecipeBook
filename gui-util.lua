local flib_gui = require("__flib__/gui-lite")
local math = require("__flib__/math")

local database = require("__RecipeBook__/database")
local util = require("__RecipeBook__/util")

--- @class GuiUtil
local gui_util = {}

--- @param player LuaPlayer
--- @param handlers GuiHandlers
--- @return GuiElems
function gui_util.build_base_gui(player, handlers)
  local elems = flib_gui.add(player.gui.screen, {
    type = "frame",
    name = "rb_main_window",
    direction = "vertical",
    visible = false,
    elem_mods = { auto_center = true },
    handler = { [defines.events.on_gui_closed] = handlers.on_window_closed },
    {
      style = "flib_titlebar_flow",
      type = "flow",
      drag_target = "rb_main_window",
      handler = { [defines.events.on_gui_click] = handlers.on_titlebar_click },
      gui_util.build_fab("nav_backward_button", "rb_nav_backward", { "gui.rb-nav-backward-instruction" }),
      gui_util.build_fab("nav_forward_button", "rb_nav_forward", { "gui.rb-nav-forward-instruction" }),
      {
        type = "label",
        style = "frame_title",
        caption = { "mod-name.RecipeBook" },
        ignored_by_interaction = true,
      },
      { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
      {
        type = "textfield",
        name = "search_textfield",
        style = "long_number_textfield",
        style_mods = { top_margin = -3 },
        lose_focus_on_confirm = true,
        clear_and_focus_on_right_click = true,
        visible = false,
        handler = { [defines.events.on_gui_text_changed] = handlers.on_search_query_changed },
      },
      gui_util.build_fab(
        "search_button",
        "utility/search",
        { "gui.rb-search-instruction" },
        handlers.on_search_button_click
      ),
      gui_util.build_fab(
        "show_unresearched_button",
        "rb_show_unresearched",
        { "gui.rb-show-unresearched-instruction" },
        handlers.on_show_unresearched_button_click
      ),
      gui_util.build_fab(
        "show_hidden_button",
        "rb_show_hidden",
        { "gui.rb-show-hidden-instruction" },
        handlers.on_show_hidden_button_click
      ),
      {
        type = "line",
        style_mods = { top_margin = -2, bottom_margin = 2 },
        direction = "vertical",
        ignored_by_interaction = true,
      },
      gui_util.build_fab("pin_button", "rb_pin", { "gui.rb-pin-instruction" }, handlers.on_pin_button_click),
      gui_util.build_fab("close_button", "utility/close", { "gui.close-instruction" }, handlers.on_close_button_click),
    },
    {
      type = "flow",
      style_mods = { horizontal_spacing = 12 },
      {
        type = "frame",
        name = "filter_outer_frame",
        style = "inside_deep_frame",
        direction = "vertical",
        {
          type = "frame",
          name = "filter_warning_frame",
          style = "negative_subheader_frame",
          style_mods = { horizontally_stretchable = true },
          visible = false,
          {
            type = "label",
            style = "bold_label",
            style_mods = { left_padding = 8 },
            caption = { "gui.rb-localised-search-unavailable" },
          },
        },
        { type = "table", name = "filter_group_table", style = "filter_group_table", column_count = 6 },
        {
          type = "frame",
          style = "rb_filter_frame",
          {
            type = "frame",
            style = "rb_filter_deep_frame",
            {
              type = "scroll-pane",
              name = "filter_scroll_pane",
              style = "rb_filter_scroll_pane",
            },
            vertical_scroll_policy = "always", -- FIXME: The scroll pane is stretching for some reason
            {
              type = "label",
              name = "filter_no_results_label",
              style_mods = {
                width = 40 * 10,
                height = 40 * 14,
                vertically_stretchable = true,
                horizontal_align = "center",
                vertical_align = "center",
              },
              caption = { "gui.nothing-found" },
              visible = false,
            },
          },
        },
      },
      {
        type = "frame",
        style = "inside_shallow_frame",
        style_mods = { width = (40 * 12) + 24 + 12 },
        direction = "vertical",
        {
          type = "frame",
          style = "subheader_frame",
          style_mods = { left_padding = 12 },
          {
            type = "sprite-button",
            name = "page_header_sprite",
            style = "transparent_slot",
            style_mods = { size = 28, right_margin = 4 },
            visible = false,
          },
          {
            type = "label",
            name = "page_header_caption",
            style = "caption_label",
            caption = { "gui.rb-welcome-title" },
          },
          { type = "empty-widget", style = "flib_horizontal_pusher" },
          {
            type = "label",
            name = "page_header_type_label",
            style = "info_label",
            style_mods = { font = "default-semibold", right_margin = 8 },
          },
        },
        {
          type = "scroll-pane",
          name = "page_scroll_pane",
          style = "flib_naked_scroll_pane",
          style_mods = { horizontally_stretchable = true, vertically_stretchable = true },
          vertical_scroll_policy = "always",
          {
            type = "label",
            name = "welcome_label",
            style_mods = { horizontally_stretchable = true, single_line = false },
            caption = { "gui.rb-welcome-text" },
          },
        },
      },
    },
  })

  -- Create tables for each subgroup
  local group_tabs = {}
  local group_flows = {}
  for group_name, subgroups in pairs(global.search_tree) do
    -- Tab button
    table.insert(group_tabs, {
      type = "sprite-button",
      name = group_name,
      style = "rb_filter_group_button_tab",
      sprite = "item-group/" .. group_name,
      tooltip = game.item_group_prototypes[group_name].localised_name,
      handler = { [defines.events.on_gui_click] = handlers.on_filter_group_button_click },
    })
    -- Base flow
    local group_flow = {
      type = "flow",
      name = group_name,
      style = "rb_filter_group_flow",
      direction = "vertical",
      visible = false,
    }
    table.insert(group_flows, group_flow)
    -- Assemble subgroups
    for subgroup_name, subgroup in pairs(subgroups) do
      local subgroup_table = { type = "table", name = subgroup_name, style = "slot_table", column_count = 10 }
      table.insert(group_flow, subgroup_table)
      for _, path in pairs(subgroup) do
        local type, name = string.match(path, "(.*)/(.*)")
        table.insert(subgroup_table, {
          type = "sprite-button",
          style = "flib_slot_button_default",
          sprite = path,
          tooltip = gui_util.build_tooltip({ type = type, name = name }),
          handler = { [defines.events.on_gui_click] = handlers.on_prototype_button_click },
          -- TODO: Read the sprite instead?
          tags = { prototype = path },
        })
      end
    end
  end
  flib_gui.add(elems.filter_group_table, group_tabs)
  flib_gui.add(elems.filter_scroll_pane, group_flows)

  -- Add components to page
  local page_scroll_pane = elems.page_scroll_pane
  gui_util.build_list_box(page_scroll_pane, handlers, "ingredients", { "description.ingredients" })
  gui_util.build_list_box(page_scroll_pane, handlers, "products", { "description.products" })
  gui_util.build_list_box(page_scroll_pane, handlers, "made_in", { "description.made-in" })
  gui_util.build_list_box(page_scroll_pane, handlers, "ingredient_in", { "description.rb-ingredient-in" })
  gui_util.build_list_box(page_scroll_pane, handlers, "product_of", { "description.rb-product-of" })
  gui_util.build_list_box(page_scroll_pane, handlers, "can_craft", { "description.rb-can-craft" })
  gui_util.build_list_box(page_scroll_pane, handlers, "mined_by", { "description.rb-mined-by" })
  gui_util.build_list_box(page_scroll_pane, handlers, "can_mine", { "description.rb-can-mine" })

  return elems
end

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

--- @param sprite string
--- @param name string
--- @param tooltip LocalisedString
--- @param handler GuiElemHandler?
--- @return GuiElemDef
function gui_util.build_fab(name, sprite, tooltip, handler)
  return {
    type = "sprite-button",
    name = name,
    style = "frame_action_button",
    sprite = sprite .. "_white",
    hovered_sprite = sprite .. "_black",
    clicked_sprite = sprite .. "_black",
    tooltip = tooltip,
    handler = { [defines.events.on_gui_click] = handler },
  }
end

--- @param parent LuaGuiElement
--- @param name string
--- @param header LocalisedString
function gui_util.build_list_box(parent, handlers, name, header)
  flib_gui.add(parent, {
    type = "flow",
    name = name,
    direction = "vertical",
    visible = false,
    {
      type = "flow",
      name = "header_flow",
      style = "centering_horizontal_flow",
      {
        type = "checkbox",
        style = "rb_list_box_caption",
        caption = header,
        state = false,
        handler = { [defines.events.on_gui_click] = handlers.collapse_list_box },
      },
      {
        type = "label",
        name = "count_label",
        style = "info_label",
        style_mods = { font = "default-semibold", horizontally_squashable = false },
      },
      { type = "empty-widget", style = "flib_horizontal_pusher" },
      { type = "label", name = "remark" },
    },
    {
      type = "frame",
      name = "list_frame",
      style = "deep_frame_in_shallow_frame",
      direction = "vertical",
    },
  })
end

--- @param handlers table<string, function>
--- @return GuiElemDef
function gui_util.build_prototype_button(handlers)
  return {
    type = "button",
    style = "rb_list_box_item",
    handler = { [defines.events.on_gui_click] = handlers.on_prototype_button_click },
    {
      type = "sprite-button",
      name = "icon",
      style = "transparent_slot",
      style_mods = { size = 28 },
      ignored_by_interaction = true,
    },
    {
      type = "label",
      name = "remark",
      style_mods = { width = 480 - 24, height = 28, horizontal_align = "right", vertical_align = "center" },
      ignored_by_interaction = true,
    },
  }
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

--- @param self Gui
--- @param handlers GuiHandlers
--- @param flow LuaGuiElement
--- @param members GenericObject[]
--- @param remark LocalisedString?
function gui_util.update_list_box(self, handlers, flow, members, remark)
  members = members or {}
  local header_flow = flow.header_flow --[[@as LuaGuiElement]]
  local list_frame = flow.list_frame --[[@as LuaGuiElement]]
  local children = list_frame.children

  -- Header remark
  local remark_label = header_flow.remark
  remark_label.caption = remark or ""

  local show_hidden = self.state.show_hidden
  local show_unresearched = self.state.show_unresearched
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
    local button = children[member_index]
    if not button then
      _, button = flib_gui.add(list_frame, gui_util.build_prototype_button(handlers))
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
    button.icon.sprite = entry.base_path
    -- Caption
    button.caption = gui_util.build_caption(member)
    -- Tooltip
    button.tooltip = gui_util.build_tooltip(member)
    -- Remark
    button.remark.caption = gui_util.build_remark(member)
    -- Tags
    local tags = button.tags
    tags.prototype = entry.base_path
    button.tags = tags
    ::continue::
  end
  for i = child_index + 1, #children do
    children[i].destroy()
  end
  flow.visible = child_index > 0

  -- Child count
  header_flow.count_label.caption = { "", "[", child_index, "]" }
end

return gui_util
