local libgui = require("__flib__.gui")
local mod_gui = require("__core__.lualib.mod-gui")

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
  self.player.set_shortcut_toggled("RecipeBook", false)
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
  self.player.set_shortcut_toggled("RecipeBook", true)
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
    self.refs.search_button.style = "frame_action_button"
    self.refs.search_button.sprite = "utility/search_white"
    self.refs.search_textfield.visible = false
    if #self.state.search_query > 0 then
      self.refs.search_textfield.text = ""
      self.state.search_query = ""
      self:update_filter_panel()
    end
  end
end

-- Update filter panel contents based on filters and search query
function gui:update_filter_panel()
  local profiler = game.create_profiler()
  local show_hidden = self.state.show_hidden
  local show_unresearched = self.state.show_unresearched
  local search_query = string.lower(self.state.search_query)
  local db = global.database
  local force_index = self.player.force.index
  local tabs_table = self.refs.filter_group_table
  local groups_scroll = self.refs.filter_scroll_pane
  local first_valid
  local search_strings = self.player_table.search_strings or {}

  for _, group in pairs(groups_scroll.children) do
    local filtered_count = 0
    local searched_count = 0
    for _, subgroup in pairs(group.children) do
      for _, button in pairs(subgroup.children) do
        local path = button.sprite
        local entry = db[path]
        local _, base_prototype = next(entry)
        local is_hidden = util.is_hidden(base_prototype)
        local is_researched = entry.researched and entry.researched[force_index] or false
        local filters_match = (show_hidden or not is_hidden) and (show_unresearched or is_researched)
        if filters_match then
          filtered_count = filtered_count + 1
          local query_match = #search_query == 0
          if not query_match then
            local comp = search_strings[path] or string.gsub(path, "-", " ")
            query_match = string.find(string.lower(comp), search_query, 1, true) --[[@as boolean]]
          end
          button.visible = query_match
          if query_match then
            searched_count = searched_count + 1
            local style = "flib_slot_button_default"
            if is_hidden then
              style = "flib_slot_button_grey"
            elseif not is_researched then
              style = "flib_slot_button_red"
            end
            button.style = style
          end
        else
          button.visible = false
        end
      end
    end
    local is_visible = filtered_count > 0
    local has_search_matches = searched_count > 0
    local group_tab = tabs_table[group.name]
    tabs_table[group.name].visible = is_visible
    if is_visible and not has_search_matches then
      group_tab.style = "rb_disabled_filter_group_button_tab"
      group_tab.enabled = false
    else
      group_tab.style = "rb_filter_group_button_tab"
      group_tab.enabled = group.name ~= self.state.selected_filter_group
    end
    if is_visible and has_search_matches then
      first_valid = first_valid or group.name
    end
  end

  if first_valid then
    groups_scroll.visible = true
    self.refs.filter_no_results_label.visible = false
    local current_tab = tabs_table[self.state.selected_filter_group] --[[@as LuaGuiElement]]
    if current_tab.visible == false or current_tab.style.name == "rb_disabled_filter_group_button_tab" then
      self:select_filter_group(first_valid)
    end
  else
    groups_scroll.visible = false
    self.refs.filter_no_results_label.visible = true
  end
  profiler.stop()
  log({ "", "Update Filter Panel ", profiler })
end

function gui:update_translation_warning()
  self.refs.filter_warning_frame.visible = not self.player_table.search_strings
end

--- @param player LuaPlayer
--- @param player_table PlayerTable
--- @return Gui
function gui.new(player, player_table)
  --- @type GuiRefs
  local refs = libgui.build(player.gui.screen, { templates.base() })

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

  self:select_filter_group(self.state.selected_filter_group)
  self:update_filter_panel()
  self:update_translation_warning()

  return self
end

function gui.load(self)
  setmetatable(self, { __index = gui })
end

--- @param player LuaPlayer
function gui.refresh_overhead_button(player)
  local button_flow = mod_gui.get_button_flow(player)
  if button_flow.RecipeBook then
    button_flow.RecipeBook.destroy()
  end
  if player.mod_settings["rb-show-overhead-button"].value then
    libgui.add(mod_gui.get_button_flow(player), {
      type = "sprite-button",
      name = "RecipeBook",
      style = mod_gui.button_style,
      style_mods = { padding = 8 },
      tooltip = { "mod-name.RecipeBook" },
      sprite = "rb_logo",
      actions = {
        on_click = "overhead_button",
      },
    })
  end
end

return gui
