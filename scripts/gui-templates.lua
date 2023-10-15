local flib_gui = require("__flib__/gui-lite")

local database = require("__RecipeBook__/scripts/database")
local util = require("__RecipeBook__/scripts/util")

--- @class GuiTemplates
local gui_templates = {}

--- @param player LuaPlayer
--- @param handlers GuiHandlers
--- @return GuiElems
function gui_templates.base(player, handlers)
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
        style = "flib_titlebar_search_textfield",
        lose_focus_on_confirm = true,
        clear_and_focus_on_right_click = true,
        visible = false,
        handler = { [defines.events.on_gui_text_changed] = handlers.on_search_query_changed },
      },
      gui_templates.frame_action_button(
        "search_button",
        "utility/search",
        { "gui.flib-search-instruction" },
        handlers.on_search_button_click,
        true
      ),
      gui_templates.frame_action_button(
        "show_unresearched_button",
        "rb_show_unresearched",
        { "gui.rb-show-unresearched-instruction" },
        handlers.on_show_unresearched_button_click,
        true
      ),
      gui_templates.frame_action_button(
        "show_hidden_button",
        "rb_show_hidden",
        { "gui.rb-show-hidden-instruction" },
        handlers.on_show_hidden_button_click,
        true
      ),
      {
        type = "flow",
        style = "packed_horizontal_flow",
        gui_templates.frame_action_button(
          "nav_backward_button",
          "flib_nav_backward",
          { "gui.rb-nav-backward-instruction" },
          handlers.on_nav_button_click,
          false
        ),
        gui_templates.frame_action_button(
          "nav_forward_button",
          "flib_nav_forward",
          { "gui.rb-nav-forward-instruction" },
          handlers.on_nav_button_click,
          false
        ),
      },
      gui_templates.frame_action_button(
        "pin_button",
        "flib_pin",
        { "gui.rb-pin-instruction" },
        handlers.on_pin_button_click,
        true
      ),
      gui_templates.frame_action_button(
        "close_button",
        "utility/close",
        { "gui.close-instruction" },
        handlers.on_close_button_click,
        false
      ),
    },
    {
      type = "flow",
      style = "inset_frame_container_horizontal_flow",
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
        style_mods = { width = (40 * 10) + 24 + 12 },
        direction = "vertical",
        {
          type = "frame",
          style = "subheader_frame",
          {
            type = "sprite-button",
            name = "page_header_title",
            style = "rb_subheader_caption_button",
            enabled = false,
            caption = { "gui.rb-welcome-title" },
          },
          { type = "empty-widget", style = "flib_horizontal_pusher" },
          {
            type = "label",
            name = "page_header_type_label",
            style = "info_label",
            style_mods = {
              font = "default-semibold",
              right_margin = 8,
              single_line = true,
              horizontally_squashable = false,
            },
          },
        },
        {
          type = "scroll-pane",
          name = "page_scroll_pane",
          style = "flib_naked_scroll_pane",
          style_mods = {
            -- width = (40 * 10) + 24 + 12,
            top_padding = 8,
            horizontally_stretchable = true,
            vertically_stretchable = true,
          },
          horizontal_scroll_policy = "never",
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
      style = "packed_vertical_flow",
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
          tooltip = gui_templates.tooltip({ type = type, name = name }),
          handler = { [defines.events.on_gui_click] = handlers.on_prototype_button_click },
        })
      end
    end
  end
  flib_gui.add(elems.filter_group_table, group_tabs)
  flib_gui.add(elems.filter_scroll_pane, group_flows)

  -- Add components to page
  local page_scroll_pane = elems.page_scroll_pane
  gui_templates.list_box(page_scroll_pane, handlers, "ingredients", { "description.ingredients" })
  gui_templates.list_box(page_scroll_pane, handlers, "products", { "description.products" })
  gui_templates.list_box(page_scroll_pane, handlers, "made_in", { "description.made-in" })
  gui_templates.list_box(page_scroll_pane, handlers, "ingredient_in", { "description.rb-ingredient-in" })
  gui_templates.list_box(page_scroll_pane, handlers, "product_of", { "description.rb-product-of" })
  gui_templates.list_box(page_scroll_pane, handlers, "can_craft", { "description.rb-can-craft" })
  gui_templates.list_box(page_scroll_pane, handlers, "mined_by", { "description.rb-mined-by" })
  gui_templates.list_box(page_scroll_pane, handlers, "can_mine", { "description.rb-can-mine" })
  gui_templates.list_box(page_scroll_pane, handlers, "burned_in", { "description.rb-burned-in" })
  gui_templates.list_box(page_scroll_pane, handlers, "can_burn", { "description.rb-can-burn" })
  gui_templates.list_box(page_scroll_pane, handlers, "unlocked_by", { "description.rb-unlocked-by" })

  return elems
end

--- @param sprite string
--- @param name string
--- @param tooltip LocalisedString
--- @param handler GuiElemHandler
--- @param auto_toggle boolean
--- @return GuiElemDef
function gui_templates.frame_action_button(name, sprite, tooltip, handler, auto_toggle)
  return {
    type = "sprite-button",
    name = name,
    style = "frame_action_button",
    sprite = sprite .. "_white",
    hovered_sprite = sprite .. "_black",
    clicked_sprite = sprite .. "_black",
    tooltip = tooltip,
    handler = { [defines.events.on_gui_click] = handler },
    auto_toggle = auto_toggle,
  }
end

--- @param parent LuaGuiElement
--- @param name string
--- @param header LocalisedString
function gui_templates.list_box(parent, handlers, name, header)
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
        name = "checkbox",
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
function gui_templates.list_box_item(handlers)
  return {
    type = "sprite-button",
    style = "rb_list_box_item",
    handler = { [defines.events.on_gui_click] = handlers.on_prototype_button_click },
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
function gui_templates.tooltip(obj)
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

return gui_templates
