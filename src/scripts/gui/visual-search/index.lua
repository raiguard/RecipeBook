local gui = require("__flib__.gui")
local table = require("__flib__.table")

local database = require("scripts.database")
local formatter = require("scripts.formatter")
local util = require("scripts.util")

--- @class VisualSearchGuiRefs
--- @field window LuaGuiElement
--- @field titlebar_flow LuaGuiElement
--- @field group_table LuaGuiElement
--- @field objects_frame LuaGuiElement
--- @field warning_frame LuaGuiElement

--- @class VisualSearchGui
local Gui = {}
local actions = require("scripts.gui.visual-search.actions")

function Gui:dispatch(msg, e)
  if type(msg) == "string" then
    actions[msg](self, msg, e)
  else
    actions[msg.action](self, msg, e)
  end
end

function Gui:destroy()
  self.refs.window.destroy()
end

function Gui:update_contents()
  local player_data = formatter.build_player_data(self.player, self.player_table)

  -- ITEMS

  local show_fluid_temperatures = player_data.settings.general.search.show_fluid_temperatures
  local groups = {}
  local first_group

  for _, objects in pairs({ database.item, database.fluid }) do
    for name, object in pairs(objects) do
      -- Create / retrieve group and subgroup
      local group = object.group
      local group_table = groups[group.name]
      if not group_table then
        group_table = {
          button = {
            type = "sprite-button",
            name = group.name,
            style = "rb_filter_group_button_tab",
            sprite = "item-group/" .. group.name,
            tooltip = { "item-group-name." .. group.name },
            actions = {
              on_click = { gui = "visual_search", action = "change_group", group = group.name },
            },
          },
          members = 0,
          scroll_pane = {
            type = "scroll-pane",
            name = group.name,
            style = "rb_filter_scroll_pane",
            vertical_scroll_policy = "always",
            visible = false,
          },
          subgroups = {},
        }
        groups[group.name] = group_table
        if not first_group then
          first_group = group.name
        end
      end
      local subgroup = object.subgroup
      local subgroup_table = group_table.subgroups[subgroup.name]
      if not subgroup_table then
        subgroup_table = { type = "table", style = "slot_table", column_count = 10 }
        group_table.subgroups[subgroup.name] = subgroup_table
        table.insert(group_table.scroll_pane, subgroup_table)
      end

      -- Check fluid temperature
      local matched = true
      local temperature_ident = object.temperature_ident
      if temperature_ident then
        local is_range = temperature_ident.min ~= temperature_ident.max
        if is_range then
          if show_fluid_temperatures ~= "all" then
            matched = false
          end
        else
          if show_fluid_temperatures == "off" then
            matched = false
          end
        end
      end

      if matched then
        local formatted = formatter(object, player_data)
        if formatted then
          group_table.members = group_table.members + 1
          -- Create the button
          table.insert(subgroup_table, {
            type = "sprite-button",
            style = "flib_slot_button_" .. (formatted.researched and "default" or "red"),
            sprite = object.class .. "/" .. object.prototype_name,
            tooltip = formatted.tooltip,
            tags = {
              context = { class = object.class, name = name },
            },
            actions = {
              on_click = { gui = "visual_search", action = "open_object" },
            },
            temperature_ident and {
              type = "label",
              style = "rb_slot_label",
              caption = temperature_ident.short_string,
              ignored_by_interaction = true,
            } or nil,
          })
        end
      end
    end
  end

  local group_buttons = {}
  local group_scroll_panes = {}
  for _, group in pairs(groups) do
    if group.members > 0 then
      table.insert(group_buttons, group.button)
      table.insert(group_scroll_panes, group.scroll_pane)
    end
  end

  if
    #self.state.active_group == 0
    or not table.for_each(group_buttons, function(button)
      return button.name == self.state.active_group
    end)
  then
    self.state.active_group = first_group
  end

  local refs = self.refs

  refs.group_table.clear()
  gui.build(refs.group_table, group_buttons)

  refs.objects_frame.clear()
  gui.build(refs.objects_frame, group_scroll_panes)

  self:dispatch({ action = "change_group", group = self.state.active_group, ignore_last_button = true })
end

local index = {}

--- @param player LuaPlayer
--- @param player_table PlayerTable
function index.build(player, player_table)
  --- @type VisualSearchGuiRefs
  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      direction = "vertical",
      ref = { "window" },
      {
        type = "flow",
        style = "flib_titlebar_flow",
        ref = { "titlebar_flow" },
        { type = "label", style = "frame_title", caption = { "gui.rb-search-title" }, ignored_by_interaction = true },
        { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
        {
          type = "textfield",
          style_mods = {
            top_margin = -3,
            right_padding = 3,
            width = 120,
          },
          clear_and_focus_on_right_click = true,
          actions = {
            on_text_changed = { gui = "visual_search", action = "update_search_query" },
          },
        },
        util.frame_action_button("utility/close", { "gui.close-instruction" }, { "close_button" }),
      },
      {
        type = "frame",
        style = "inside_deep_frame",
        direction = "vertical",
        {
          type = "table",
          style = "filter_group_table",
          style_mods = { width = 426 },
          column_count = 6,
          ref = { "group_table" },
        },
        {
          type = "frame",
          style = "rb_filter_frame",
          {
            type = "frame",
            style = "deep_frame_in_shallow_frame",
            style_mods = { height = 40 * 15, natural_width = 40 * 10 },
            ref = { "objects_frame" },
          },
          {
            type = "frame",
            style = "rb_warning_frame_in_shallow_frame",
            style_mods = { height = 40 * 15, width = 40 * 10 },
            ref = { "warning_frame" },
            visible = false,
            {
              type = "flow",
              style = "rb_warning_flow",
              direction = "vertical",
              { type = "label", style = "bold_label", caption = { "gui.rb-no-results" } },
            },
          },
        },
      },
    },
  })

  refs.titlebar_flow.drag_target = refs.window
  refs.window.force_auto_center()

  --- @type VisualSearchGui
  local self = {
    player = player,
    player_table = player_table,
    refs = refs,
    state = {
      active_group = "",
      search_query = "",
    },
  }
  index.load(self)
  player_table.guis.visual_search = self

  self:update_contents()
end

function index.load(self)
  setmetatable(self, { __index = Gui })
end

return index
