local templates = {}

local util = require("__RecipeBook__.util")

function templates.base()
  local group_tabs, group_flows = templates.filter_pane()

  return {
    type = "frame",
    name = "RecipeBook",
    direction = "vertical",
    visible = false,
    ref = { "window" },
    actions = { on_closed = "window_closed" },
    {
      type = "flow",
      style = "flib_titlebar_flow",
      ref = { "titlebar_flow" },
      actions = {
        on_click = "titlebar_flow",
      },
      templates.frame_action_button("rb_nav_backward", { "gui.rb-nav-backward-instruction" }, "nav_backward_button"),
      templates.frame_action_button("rb_nav_forward", { "gui.rb-nav-forward-instruction" }, "nav_forward_button"),
      {
        type = "label",
        style = "frame_title",
        caption = { "mod-name.RecipeBook" },
        ignored_by_interaction = true,
      },
      { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
      {
        type = "textfield",
        style = "long_number_textfield",
        style_mods = { top_margin = -3 },
        lose_focus_on_confirm = true,
        clear_and_focus_on_right_click = true,
        visible = false,
        ref = { "search_textfield" },
        actions = {
          on_text_changed = "search_textfield",
        },
      },
      templates.frame_action_button("utility/search", { "gui.rb-search-instruction" }, "search_button"),
      templates.frame_action_button(
        "rb_show_unresearched",
        { "gui.rb-show-unresearched-instruction" },
        "show_unresearched_button"
      ),
      templates.frame_action_button("rb_show_hidden", { "gui.rb-show-hidden-instruction" }, "show_hidden_button"),
      {
        type = "line",
        style_mods = { top_margin = -2, bottom_margin = 2 },
        direction = "vertical",
        ignored_by_interaction = true,
      },
      templates.frame_action_button("rb_pin", { "gui.rb-pin-instruction" }, "pin_button"),
      templates.frame_action_button("utility/close", { "gui.close-instruction" }, "close_button"),
    },
    {
      type = "flow",
      style_mods = { horizontal_spacing = 12 },
      {
        type = "frame",
        style = "inside_deep_frame",
        direction = "vertical",
        {
          type = "frame",
          style = "negative_subheader_frame",
          style_mods = { horizontally_stretchable = true },
          ref = { "filter_warning_frame" },
          visible = false,
          {
            type = "label",
            style = "bold_label",
            style_mods = { left_padding = 8 },
            caption = { "gui.rb-localised-search-unavailable" },
          },
        },
        {
          type = "table",
          style = "filter_group_table",
          column_count = 6,
          ref = { "filter_group_table" },
          children = group_tabs,
        },
        {
          type = "frame",
          style = "rb_filter_frame",
          {
            type = "frame",
            style = "rb_filter_deep_frame",
            {
              type = "scroll-pane",
              style = "rb_filter_scroll_pane",
              vertical_scroll_policy = "always",
              ref = { "filter_scroll_pane" },
              children = group_flows,
            },
            {
              type = "label",
              style_mods = {
                width = 40 * 10,
                height = 40 * 14,
                vertically_stretchable = true,
                horizontal_align = "center",
                vertical_align = "center",
              },
              caption = { "gui.nothing-found" },
              ref = { "filter_no_results_label" },
              visible = false,
            },
          },
        },
      },
      {
        type = "frame",
        style = "inside_shallow_frame",
        style_mods = { width = 500 },
        direction = "vertical",
        {
          type = "frame",
          style = "subheader_frame",
          {
            type = "sprite-button",
            style = "rb_small_transparent_slot",
            ref = { "page_header_icon" },
            visible = false,
          },
          {
            type = "label",
            style = "subheader_caption_label",
            caption = { "gui.rb-welcome-title" },
            ref = { "page_header_label" },
          },
          { type = "empty-widget", style = "flib_horizontal_pusher" },
          {
            type = "label",
            style = "info_label",
            style_mods = { font = "default-semibold", right_margin = 8 },
            ref = { "page_header_type_label" },
          },
        },
        {
          type = "scroll-pane",
          style = "flib_naked_scroll_pane",
          style_mods = { horizontally_stretchable = true, vertically_stretchable = true },
          vertical_scroll_policy = "always",
          ref = { "page_scroll" },
          {
            type = "label",
            style_mods = { horizontally_stretchable = true, single_line = false },
            caption = { "gui.rb-welcome-text" },
          },
        },
      },
    },
  }
end

--- @return GuiBuildStructure[] group_tabs
--- @return GuiBuildStructure[] group_flows
function templates.filter_pane()
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
      actions = { on_click = "filter_group_button" },
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
    for subgroup_name, prototypes in pairs(subgroups) do
      local subgroup_table = { type = "table", name = subgroup_name, style = "slot_table", column_count = 10 }
      table.insert(group_flow, subgroup_table)
      for _, prototype in pairs(prototypes) do
        --- @cast prototype GenericPrototype
        local path = util.sprite_path[prototype.object_name] .. "/" .. prototype.name
        table.insert(subgroup_table, {
          type = "sprite-button",
          style = "flib_slot_button_default",
          sprite = path,
          tooltip = { "gui.rb-prototype-tooltip", prototype.localised_name, path, prototype.localised_description },
          actions = { on_click = "prototype_button" },
          tags = { prototype = path },
        })
      end
    end
  end

  return group_tabs, group_flows
end

function templates.frame_action_button(sprite, tooltip, action)
  return {
    type = "sprite-button",
    style = "frame_action_button",
    sprite = sprite .. "_white",
    hovered_sprite = sprite .. "_black",
    clicked_sprite = sprite .. "_black",
    tooltip = tooltip,
    ref = { action },
    actions = {
      on_click = action,
    },
  }
end

--- @param caption LocalisedString
--- @param objects GenericObject[]
--- @param right_caption LocalisedString?
function templates.list_box(caption, objects, right_caption)
  local num_objects = #objects
  local rows = {}
  local i = 0
  local database = global.database
  for _, object in pairs(objects) do
    if
      not database[object.type .. "/" .. object.name]
      or util.is_hidden(game[object.type .. "_prototypes"][object.name])
    then
      num_objects = num_objects - 1
    else
      i = i + 1
      table.insert(
        rows,
        templates.prototype_button(
          game[object.type .. "_prototypes"][object.name],
          "rb_list_box_row_" .. (i % 2 == 0 and "even" or "odd"),
          object.amount or "",
          object.remark
        )
      )
    end
  end
  if num_objects == 0 then
    return {}
  end
  return {
    type = "flow",
    style_mods = { bottom_margin = 4 },
    direction = "vertical",
    {
      type = "flow",
      style = "centering_horizontal_flow",
      {
        type = "checkbox",
        style = "rb_list_box_caption",
        caption = { "", caption, " (", num_objects, ")" },
        state = false,
        actions = {
          on_checked_state_changed = "collapse_list_box",
        },
      },
      { type = "empty-widget", style = "flib_horizontal_pusher" },
      { type = "label", caption = right_caption },
    },
    {
      type = "frame",
      name = "list_frame",
      style = "deep_frame_in_shallow_frame",
      {
        type = "flow",
        style_mods = { vertical_spacing = 0 },
        direction = "vertical",
        children = rows,
      },
    },
  }
end

--- @param prototype GenericPrototype
--- @param style string
--- @param amount_caption LocalisedString?
--- @param remark_caption LocalisedString?
function templates.prototype_button(prototype, style, amount_caption, remark_caption)
  -- TODO: We actually need to get the group so we can show all the tooltips
  local path = util.sprite_path[prototype.object_name] .. "/" .. prototype.name
  local remark = {}
  if remark_caption then
    -- TODO: Add "remark" capability to API to eliminate this hack
    remark = {
      type = "label",
      style_mods = {
        width = 464 - 16,
        height = 36 - 8,
        horizontal_align = "right",
        vertical_align = "center",
      },
      caption = remark_caption,
      ignored_by_interaction = true,
    }
  end
  return {
    type = "sprite-button",
    style = style,
    -- TODO: Add icon_horizontal_align support to sprite-buttons
    -- sprite = object.type .. "/" .. object.name,
    caption = { "", "            ", amount_caption or "", prototype.localised_name },
    tooltip = { "gui.rb-prototype-tooltip", prototype.localised_name, path, prototype.localised_description },
    actions = { on_click = "prototype_button" },
    tags = { prototype = path },
    {
      type = "sprite-button",
      style = "rb_small_transparent_slot",
      sprite = path,
      ignored_by_interaction = true,
    },
    remark,
  }
end

return templates
