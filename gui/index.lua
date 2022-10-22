local libgui = require("__flib__.gui")

-- local util = require("__RecipeBook__.util")

local handlers = require("__RecipeBook__.gui.handlers")
local page = require("__RecipeBook__.gui.page")
local templates = require("__RecipeBook__.gui.templates")

local sprite_path = {
  ["LuaEntityPrototype"] = "entity",
  ["LuaFluidPrototype"] = "fluid",
  ["LuaItemPrototype"] = "item",
  ["LuaRecipePrototype"] = "recipe",
}

--- @class Gui
local gui = {}

function gui:build_filters()
  local researched = global.researched[self.player.force.index]
  local groups = global.search_groups
  local group_prototypes = game.item_group_prototypes
  -- Create tables for each subgroup
  local group_tabs = {}
  local group_flows = {}
  local first_group = next(groups)
  for group_name, subgroups in pairs(groups) do
    -- Base flow
    local group_flow = {
      type = "flow",
      name = group_name,
      style = "rb_filter_group_flow",
      direction = "vertical",
      visible = group_name == first_group,
    }
    -- Assemble subgroups
    for subgroup_name, prototypes in pairs(subgroups) do
      local subgroup_table = { type = "table", name = subgroup_name, style = "slot_table", column_count = 10 }
      for _, prototype in pairs(prototypes) do
        local path = sprite_path[prototype.object_name] .. "/" .. prototype.name
        if not self.player.gui.is_valid_sprite_path(path) then
          path = "item/item-unknown"
        end
        table.insert(subgroup_table, {
          type = "sprite-button",
          name = path,
          style = researched[path] and "slot_button" or "flib_slot_button_red",
          sprite = path,
          tooltip = { "", prototype.localised_name, "\n", sprite_path[prototype.object_name], "/", prototype.name },
          actions = { on_click = "prototype_button" },
        })
      end
      if #subgroup_table > 0 then
        table.insert(group_flow, subgroup_table)
      end
    end
    -- Add flow and button
    if #group_flow > 0 then
      table.insert(group_flows, group_flow)
      table.insert(group_tabs, {
        type = "sprite-button",
        name = group_name,
        style = "rb_filter_group_button_tab",
        sprite = "item-group/" .. group_name,
        tooltip = group_prototypes[group_name].localised_name,
        enabled = group_name ~= first_group,
        actions = { on_click = "filter_group_button" },
      })
    end
  end

  local filter_group_table = self.refs.filter_group_table
  filter_group_table.clear()
  libgui.build(filter_group_table, group_tabs)

  local filter_scroll_pane = self.refs.filter_scroll_pane
  filter_scroll_pane.clear()
  libgui.build(filter_scroll_pane, group_flows)

  self.state.selected_filter_group = first_group
end

function gui:destroy()
  if self.refs.window.valid then
    self.refs.window.destroy()
  end
  self.player_table.gui = nil
end

--- @param e EventData
--- @param action string
function gui:dispatch(e, action)
  local handler = handlers[action]
  if handler then
    handler(self, e)
  else
    log("Attempted to call nonexistent GUI handler " .. action)
  end
end

function gui:focus_search()
  self.refs.search_textfield.select_all()
  self.refs.search_textfield.focus()
end

function gui:hide()
  self.refs.window.visible = false
  if self.player.opened == self.refs.window then
    self.player.opened = nil
  end
end

--- @param group_name string
function gui:select_filter_group(group_name)
  local tabs = self.refs.filter_group_table
  local members = self.refs.filter_scroll_pane
  local previous_group = self.state.selected_filter_group
  if previous_group then
    tabs[previous_group].enabled = true
    members[previous_group].visible = false
  end
  tabs[group_name].enabled = false
  members[group_name].visible = true
  self.state.selected_filter_group = group_name
end

function gui:show()
  self.refs.window.visible = true
  self.refs.window.bring_to_front()
  if not self.state.pinned then
    self.player.opened = self.refs.window
    self.refs.window.force_auto_center()
  end
end

--- @param object_name string
function gui:show_page(object_name)
  page.update(self, object_name)
end

function gui:toggle()
  if self.refs.window.visible then
    self:hide()
  else
    self:show()
  end
end

function gui:toggle_search()
  self.state.search_open = not self.state.search_open
  if self.state.search_open then
    self.refs.search_button.style = "flib_selected_frame_action_button"
    self.refs.search_button.sprite = "utility/search_black"
    self.refs.search_textfield.visible = true
    self.refs.search_textfield.focus()
  else
    self.state.search_query = ""

    self.refs.search_button.style = "frame_action_button"
    self.refs.search_button.sprite = "utility/search_white"
    self.refs.search_textfield.visible = false
    self.refs.search_textfield.text = ""
  end
end

--- @param player LuaPlayer
--- @param player_table PlayerTable
--- @return Gui
function gui.new(player, player_table)
  --- @type GuiRefs
  local refs = libgui.build(player.gui.screen, { templates.base() })

  refs.titlebar_flow.drag_target = refs.window
  refs.window.force_auto_center()

  --- @class Gui
  local self = {
    player = player,
    player_table = player_table,
    refs = refs,
    state = {
      --- @type string?
      current_page = nil,
      pinned = false,
      search_open = false,
      search_query = "",
      --- @type string?
      selected_filter_group = nil,
    },
  }
  gui.load(self)
  player_table.gui = self

  self:build_filters()

  return self
end

function gui.load(self)
  setmetatable(self, { __index = gui })
end

return gui
