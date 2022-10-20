local templates = {}

local util = require("__RecipeBook__.util")

function templates.base()
  return
    {
      type = "frame",
      name = "rb_window",
      direction = "vertical",
      ref = { "window" },
      {
        type = "flow",
        style = "flib_titlebar_flow",
        ref = { "titlebar_flow" },
        {
          type = "sprite-button",
          style = "frame_action_button",
          -- sprite = "rb_nav_backward_white",
          -- hovered_sprite = "rb_nav_backward_black",
          -- clicked_sprite = "rb_nav_backward_black",
        },
        {
          type = "sprite-button",
          style = "frame_action_button",
          -- sprite = "rb_nav_forward_white",
          -- hovered_sprite = "rb_nav_forward_black",
          -- clicked_sprite = "rb_nav_forward_black",
        },
        { type = "label", style = "frame_title", caption = { "mod-name.RecipeBook" }, ignored_by_interaction = true },
        { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
        { type = "textfield", style_mods = { top_margin = -3, width = 200 } },
        {
          type = "line",
          direction = "vertical",
          style_mods = { top_margin = -2, bottom_margin = 2 },
          ignored_by_interaction = true,
        },
        { type = "sprite-button", style = "frame_action_button" },
        { type = "sprite-button", style = "frame_action_button" },
        { type = "sprite-button", style = "frame_action_button" },
        {
          type = "line",
          direction = "vertical",
          style_mods = { top_margin = -2, bottom_margin = 2 },
          ignored_by_interaction = true,
        },
        {
          type = "sprite-button",
          style = "frame_action_button",
        },
        {
          type = "sprite-button",
          style = "frame_action_button",
          sprite = "utility/close_white",
          hovered_sprite = "utility/close_black",
          clicked_sprite = "utility/close_black",
        },
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
            visible = false,
            ref = { "filter_warning_frame" },
            {
              type = "label",
              style = "subheader_caption_label",
              style_mods = { font_color = { 1, 1, 1 } },
              caption = { "gui.rb-localised-search-unavailable" },
            },
          },
          {
            type = "table",
            style = "filter_group_table",
            column_count = 6,
            ref = { "filter_group_table" },
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
                ref = { "filter_scroll_pane" },
              },
            },
          },
        },
        {
          type = "frame",
          style = "inside_shallow_frame",
          style_mods = { width = 450 },
          direction = "vertical",
          {
            type = "frame",
            style = "subheader_frame",
            style_mods = { horizontally_stretchable = true },
            {
              type = "sprite-button",
              style = "rb_small_transparent_slot",
              ref = { "page_header_icon" },
            },
            {
              type = "label",
              style = "caption_label",
              ref = { "page_header_label" },
            },
          },
          {
            type = "scroll-pane",
            style = "flib_naked_scroll_pane",
            style_mods = { vertically_stretchable = true },
            ref = { "page_scroll" },
          },
        },
      },
    }
end

--- @param caption LocalisedString
--- @param objects Ingredient[]
function templates.list_box(caption, objects)
  local num_objects = #objects
  local rows = {}
  for i, object in pairs(objects) do
    if util.is_hidden(game[object.type .. "_prototypes"][object.name]) then
      num_objects = num_objects - 1
    else
      local right = {}
      if object.amount then
        -- TODO: Add "remark" capability to API to eliminate this hack
        right = {
          type = "label",
          style_mods = {
            width = 426 - 16,
            height = 36 - 8,
            horizontal_align = "right",
            vertical_align = "center",
          },
          caption = object.amount,
          ignored_by_interaction = true,
        }
      end
      table.insert(rows, {
        type = "sprite-button",
        name = object.name,
        style = "rb_list_box_row_" .. (i % 2 == 0 and "even" or "odd"),
        -- TODO: Add icon_horizontal_align support to sprite-buttons
        -- sprite = object.type .. "/" .. object.name,
        -- TODO: Consistent spacing
        caption = { "", "            ", game[object.type .. "_prototypes"][object.name].localised_name },
        actions = { on_click = "show_recipe" },
        {
          type = "sprite-button",
          style = "rb_small_transparent_slot",
          sprite = object.type .. "/" .. object.name,
          ignored_by_interaction = true,
        },
        right,
      })
    end
  end
  if num_objects == 0 then
    return {}
  end
  return {
    type = "flow",
    style_mods = { bottom_margin = 4 },
    direction = "vertical",
    { type = "label", style = "bold_label", caption = { "", caption, " (", num_objects, ")" } },
    {
      type = "frame",
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

return templates
