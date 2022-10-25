local libgui = require("__flib__.gui")

local handlers = require("__RecipeBook__.gui.handlers")
local page = require("__RecipeBook__.gui.page")
local templates = require("__RecipeBook__.gui.templates")
local util = require("__RecipeBook__.util")

--- @class Gui
local gui = {}

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

-- Update the filter panel based on the current search query
function gui:update_filter_search() end

-- Update filter panel contents based on active visibility settings
function gui:update_filter_visibility()
  local show_hidden = self.state.show_hidden
  local show_unresearched = self.state.show_unresearched
  local db = global.database
  local force_index = self.player.force.index
  local tabs_table = self.refs.filter_group_table
  local groups_scroll = self.refs.filter_scroll_pane
  local first_visible

  for _, group in pairs(groups_scroll.children) do
    local i = 0
    for _, subgroup in pairs(group.children) do
      for _, button in pairs(subgroup.children) do
        local entry = db[button.sprite]
        local _, base_prototype = next(entry)
        local is_hidden = util.is_hidden(base_prototype, true)
        local is_researched = entry.researched and entry.researched[force_index] or false
        local is_visible = (show_hidden or not is_hidden) and (show_unresearched or is_researched)
        button.visible = is_visible
        if is_visible then
          i = i + 1
        end
      end
    end
    local is_visible = i > 0
    tabs_table[group.name].visible = is_visible
    -- group.visible = is_visible
    if is_visible then
      first_visible = first_visible or group.name
    end
  end

  if first_visible and groups_scroll[self.state.selected_filter_group].visible == false then
    self:select_filter_group(first_visible)
  else
    -- TODO:
  end
end

--- @param player LuaPlayer
--- @param player_table PlayerTable
--- @return Gui
function gui.new(player, player_table)
  --- @type GuiRefs
  local refs = libgui.build(player.gui.screen, {
    templates.base(player.force --[[@as LuaForce]]),
  })

  refs.titlebar_flow.drag_target = refs.window
  refs.window.force_auto_center()

  -- TODO:
  refs.show_unresearched_button.sprite = "rb_show_unresearched_black"
  refs.show_unresearched_button.style = "flib_selected_frame_action_button"

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
      selected_filter_group = next(global.search_tree),
      show_hidden = false,
      show_unresearched = true,
    },
  }
  gui.load(self)
  player_table.gui = self

  self:update_filter_visibility()

  return self
end

function gui.load(self)
  setmetatable(self, { __index = gui })
end

return gui
