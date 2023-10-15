local dictionary = require("__flib__/dictionary-lite")
local flib_gui = require("__flib__/gui-lite")
local math = require("__flib__/math")
local mod_gui = require("__core__/lualib/mod-gui")
local table = require("__flib__/table")

local database = require("__RecipeBook__/scripts/database")
local gui_templates = require("__RecipeBook__/scripts/gui-templates")
local gui_util = require("__RecipeBook__/scripts/gui-util")
local util = require("__RecipeBook__/scripts/util")

--- @class Gui
--- @field current_page string?
--- @field elems table<string, LuaGuiElement>,
--- @field history  {[integer]: string, __index: integer}
--- @field pinned boolean
--- @field player LuaPlayer
--- @field search_open boolean
--- @field search_query string
--- @field selected_filter_group string?
--- @field show_hidden boolean
--- @field show_unresearched boolean

--- @class GuiMod
local gui = {}

--- @class GuiElems
--- @field rb_main_window LuaGuiElement
--- @field nav_backward_button LuaGuiElement
--- @field nav_forward_button LuaGuiElement
--- @field search_textfield LuaGuiElement
--- @field search_button LuaGuiElement
--- @field show_unresearched_button LuaGuiElement
--- @field show_hidden_button LuaGuiElement
--- @field pin_button LuaGuiElement
--- @field close_button LuaGuiElement
--- @field filter_group_table LuaGuiElement
--- @field filter_scroll_pane LuaGuiElement
--- @field page_header_title LuaGuiElement
--- @field page_header_type_label LuaGuiElement
--- @field page_scroll_pane LuaGuiElement

local handlers
--- @class GuiHandlers
handlers = {
  --- @param e EventData.on_gui_checked_state_changed
  collapse_list_box = function(_, e)
    local state = e.element.state
    e.element.parent.parent.list_frame.style.height = state and 1 or 0
    -- TODO: Keep track of collapsed states
  end,

  --- @param self Gui
  on_close_button_click = function(self)
    gui.hide(self)
  end,

  --- @param self Gui
  --- @param e EventData.on_gui_click
  on_filter_group_button_click = function(self, e)
    if e.element.style.name ~= "rb_disabled_filter_group_button_tab" then
      gui.select_filter_group(self, e.element.name)
    end
  end,

  --- @param self Gui
  --- @param e EventData.on_gui_click
  on_nav_button_click = function(self, e)
    local delta = e.element.name == "nav_backward_button" and -1 or 1
    gui.nav_history(self, delta)
  end,

  --- @param self Gui
  on_overhead_button_click = function(self)
    gui.toggle(self)
  end,

  --- @param self Gui
  --- @param e EventData.on_gui_click
  on_prototype_button_click = function(self, e)
    local prototype = e.element.sprite --[[@as string?]]
    if not prototype then
      return
    end
    local type, name = string.match(prototype, "(.*)/(.*)")
    if type == "technology" then
      -- TODO: Keep-open logic
      self.player.open_technology_gui(name)
      return
    end
    gui.update_page(self, prototype)
  end,

  --- @param self Gui
  on_search_button_click = function(self)
    gui.toggle_search(self)
  end,

  --- @param self Gui
  on_pin_button_click = function(self)
    gui.toggle_pinned(self)
  end,

  --- @param self Gui
  --- @param e EventData.on_gui_text_changed
  on_search_query_changed = function(self, e)
    -- TODO: Fuzzy search
    self.search_query = e.element.text
    gui.update_filter_panel(self)
  end,

  --- @param self Gui
  on_show_hidden_button_click = function(self)
    self.show_hidden = not self.show_hidden
    gui_util.update_frame_action_button(self.elems.show_hidden_button, self.show_hidden and "selected" or "default")
    gui.update_filter_panel(self)
    gui.update_page(self)
  end,

  --- @param self Gui
  on_show_unresearched_button_click = function(self)
    self.show_unresearched = not self.show_unresearched
    gui_util.update_frame_action_button(
      self.elems.show_unresearched_button,
      self.show_unresearched and "selected" or "default"
    )
    gui.update_filter_panel(self)
    gui.update_page(self)
  end,

  --- @param self Gui
  --- @param e EventData.on_gui_click?
  on_titlebar_click = function(self, e)
    if not e or e.button == defines.mouse_button_type.middle then
      self.elems.rb_main_window.force_auto_center()
    end
  end,

  --- @param self Gui
  on_window_closed = function(self)
    if self.pinned then
      return
    end
    if self.search_open then
      gui.toggle_search(self)
      self.player.opened = self.elems.rb_main_window
      return
    end
    gui.hide(self)
  end,
}

flib_gui.add_handlers(handlers, function(e, handler)
  local pgui = gui.get(e.player_index)
  if pgui then
    handler(pgui, e)
  end
end)

-- Methods

--- @param self Gui
function gui.focus_search(self)
  self.elems.search_textfield.select_all()
  self.elems.search_textfield.focus()
end

--- @param self Gui
function gui.hide(self)
  self.elems.rb_main_window.visible = false
  if self.player.opened == self.elems.rb_main_window then
    self.player.opened = nil
  end
  self.player.set_shortcut_toggled("rb-toggle", false)
end

--- @param self Gui
--- @param delta integer
function gui.nav_history(self, delta)
  local history = self.history
  history.__index = math.clamp(history.__index + delta, 1, #history)
  self.current_page = history[history.__index]
  gui.update_page(self)
end

--- @param self Gui
--- @param group_name string
function gui.select_filter_group(self, group_name)
  local tabs = self.elems.filter_group_table
  local members = self.elems.filter_scroll_pane
  local previous_group = self.selected_filter_group
  if previous_group then
    tabs[previous_group].enabled = true
    members[previous_group].visible = false
  end
  tabs[group_name].enabled = false
  members[group_name].visible = true
  self.selected_filter_group = group_name
end

--- @param self Gui
function gui.show(self)
  self.elems.rb_main_window.visible = true
  self.elems.rb_main_window.bring_to_front()
  if not self.pinned then
    self.player.opened = self.elems.rb_main_window
    self.elems.rb_main_window.force_auto_center()
  end
  self.player.set_shortcut_toggled("rb-toggle", true)
end

--- @param self Gui
function gui.toggle(self)
  if self.elems.rb_main_window.visible then
    gui.hide(self)
  else
    gui.show(self)
  end
end

--- @param self Gui
function gui.toggle_pinned(self)
  self.pinned = not self.pinned
  if self.pinned then
    self.elems.pin_button.style = "flib_selected_frame_action_button"
    self.elems.pin_button.sprite = "flib_pin_black"
    self.elems.close_button.tooltip = { "gui.close" }
    self.elems.search_button.tooltip = { "gui.search" }
    if self.player.opened == self.elems.rb_main_window then
      self.player.opened = nil
    end
  else
    self.elems.pin_button.style = "frame_action_button"
    self.elems.pin_button.sprite = "flib_pin_white"
    self.player.opened = self.elems.rb_main_window
    self.elems.rb_main_window.force_auto_center()
    self.elems.close_button.tooltip = { "gui.close-instruction" }
    self.elems.search_button.tooltip = { "gui.flib-search-instruction" }
  end
end

--- @param self Gui
function gui.toggle_search(self)
  self.search_open = not self.search_open
  if self.search_open then
    self.elems.search_button.style = "flib_selected_frame_action_button"
    self.elems.search_button.sprite = "utility/search_black"
    self.elems.search_textfield.visible = true
    self.elems.search_textfield.focus()
  else
    self.elems.search_button.style = "frame_action_button"
    self.elems.search_button.sprite = "utility/search_white"
    self.elems.search_textfield.visible = false
    if #self.search_query > 0 then
      self.elems.search_textfield.text = ""
      self.search_query = ""
      gui.update_filter_panel(self)
    end
  end
end

--- @param self Gui
function gui.update_filter_panel(self)
  local profiler = game.create_profiler()
  local show_hidden = self.show_hidden
  local show_unresearched = self.show_unresearched
  local search_query = string.lower(self.search_query)
  local db = global.database
  local force_index = self.player.force.index
  local tabs_table = self.elems.filter_group_table
  local groups_scroll = self.elems.filter_scroll_pane
  local first_valid
  local search_strings = dictionary.get(self.player.index, "search") or {}

  for _, group in pairs(groups_scroll.children) do
    local filtered_count = 0
    local searched_count = 0
    for _, subgroup in pairs(group.children) do
      for _, button in pairs(subgroup.children) do
        local path = button.sprite
        local entry = db[path]
        local base_prototype = entry.base
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
      group_tab.enabled = group.name ~= self.selected_filter_group
    end
    if is_visible and has_search_matches then
      first_valid = first_valid or group.name
    end
  end

  if first_valid then
    groups_scroll.visible = true
    self.elems.filter_no_results_label.visible = false
    local current_tab = tabs_table[self.selected_filter_group] --[[@as LuaGuiElement]]
    if current_tab.visible == false or current_tab.style.name == "rb_disabled_filter_group_button_tab" then
      gui.select_filter_group(self, first_valid)
    end
  else
    groups_scroll.visible = false
    self.elems.filter_no_results_label.visible = true
  end

  profiler.stop()
  log({ "", "Update Filter Panel ", profiler })
end

--- @param self Gui
--- @param prototype_path string?
--- @return boolean?
function gui.update_page(self, prototype_path)
  if prototype_path then
    prototype_path = database.get_base_path(prototype_path)
  end
  local path = prototype_path or self.current_page
  if not path then
    return
  end
  if prototype_path and path == self.current_page then
    return true
  end

  local profiler = game.create_profiler()

  local properties = database.get_properties(path, self.player.force.index)
  if not properties then
    return
  end
  local entry = properties.entry

  -- Header
  local header_title = self.elems.page_header_title
  header_title.caption = { "", "            ", entry.base.localised_name }
  header_title.sprite = entry.base_path
  local style = "rb_subheader_caption_button"
  if util.is_hidden(entry.base) then
    style = "rb_subheader_caption_button_hidden"
  elseif util.is_unresearched(entry, self.player.force.index) then
    style = "rb_subheader_caption_button_unresearched"
  end
  header_title.style = style
  local header_type = self.elems.page_header_type_label
  local type_caption = { "" }
  for _, type in pairs(properties.types) do
    table.insert(type_caption, util.type_locale[type])
    table.insert(type_caption, "/")
  end
  type_caption[#type_caption] = nil
  header_type.caption = type_caption

  -- Contents

  local scroll_pane = self.elems.page_scroll_pane
  if scroll_pane.welcome_label then
    scroll_pane.welcome_label.destroy()
  end

  --- @type LocalisedString?
  local crafting_time
  if properties.crafting_time then
    crafting_time = {
      "",
      "[img=quantity-time][font=default-bold]",
      { "time-symbol-seconds", properties.crafting_time },
      "[/font] ",
      { "description.crafting-time" },
    }
  end
  gui_util.update_list_box(self, handlers, scroll_pane.ingredients, properties.ingredients, crafting_time, true)
  gui_util.update_list_box(self, handlers, scroll_pane.products, properties.products, nil, true)
  gui_util.update_list_box(self, handlers, scroll_pane.made_in, properties.made_in)
  gui_util.update_list_box(self, handlers, scroll_pane.ingredient_in, properties.ingredient_in)
  gui_util.update_list_box(self, handlers, scroll_pane.product_of, properties.product_of)
  gui_util.update_list_box(self, handlers, scroll_pane.can_craft, properties.can_craft)
  gui_util.update_list_box(self, handlers, scroll_pane.mined_by, properties.mined_by)
  gui_util.update_list_box(self, handlers, scroll_pane.can_mine, properties.can_mine)
  gui_util.update_list_box(self, handlers, scroll_pane.burned_in, properties.burned_in)
  gui_util.update_list_box(self, handlers, scroll_pane.can_burn, properties.can_burn)
  gui_util.update_list_box(self, handlers, scroll_pane.unlocked_by, properties.unlocked_by)

  -- Update history
  local history = self.history
  if prototype_path then
    for i = history.__index + 1, #history do
      history[i] = nil
    end
    local existing = table.find(history, path)
    if existing then
      table.remove(history, existing)
    end
    history[#history + 1] = path
    history.__index = #history
  end
  self.current_page = path
  -- Update history buttons
  gui_util.update_frame_action_button(self.elems.nav_backward_button, history.__index > 1 and "default" or "disabled")
  gui_util.update_frame_action_button(
    self.elems.nav_forward_button,
    history.__index < #history and "default" or "disabled"
  )

  profiler.stop()
  log({ "", "[", path, "] ", profiler })

  return true
end

--- @param self Gui
function gui.update_translation_warning(self)
  self.elems.filter_warning_frame.visible = not dictionary.get(self.player.index, "search")
end

-- Lifecycle

--- @param player LuaPlayer
--- @return Gui
function gui.new(player)
  gui.destroy(player.index)

  local elems = gui_templates.base(player, handlers)

  -- Set initial button states
  gui_util.update_frame_action_button(elems.nav_backward_button, "disabled")
  gui_util.update_frame_action_button(elems.nav_forward_button, "disabled")
  gui_util.update_frame_action_button(elems.show_unresearched_button, "selected")

  --- @type Gui
  local self = {
    --- @type string?
    current_page = nil,
    elems = elems,
    --- @type {[integer]: string, __index: integer}
    history = { __index = 0 },
    pinned = false,
    player = player,
    search_open = false,
    search_query = "",
    --- @type string?
    selected_filter_group = next(global.search_tree),
    show_hidden = false,
    show_unresearched = true,
  }

  global.guis[player.index] = self

  gui.select_filter_group(self, self.selected_filter_group)
  gui.update_filter_panel(self)
  gui.update_translation_warning(self)

  return self
end

--- @param player_index uint
function gui.destroy(player_index)
  local self = global.guis[player_index]
  if not self then
    return
  end
  local window = self.elems.rb_main_window
  if window.valid then
    window.destroy()
  end
  global.guis[player_index] = nil
end

--- @param player LuaPlayer
function gui.refresh_overhead_button(player)
  local button_flow = mod_gui.get_button_flow(player)
  if button_flow.rb_toggle then
    button_flow.rb_toggle.destroy()
  end
  if player.mod_settings["rb-show-overhead-button"].value then
    flib_gui.add(button_flow, {
      type = "sprite-button",
      name = "rb_toggle",
      style = mod_gui.button_style,
      style_mods = { padding = 8 },
      tooltip = { "", { "shortcut-name.rb-toggle" }, " (", { "gui.rb-toggle-instruction" }, ")" },
      sprite = "rb_logo",
      handler = { [defines.events.on_gui_click] = handlers.on_overhead_button_click },
    })
  end
end

--- Get the player's GUI or create it if it does not exist
--- @param player_index uint
--- @return Gui?
function gui.get(player_index)
  local self = global.guis[player_index]
  if not self or not self.elems.rb_main_window.valid then
    local player = game.get_player(player_index)
    if not player then
      return
    end
    if self then
      player.print({ "message.rb-recreated-gui" })
    end
    self = gui.new(player)
  end
  return self
end

--- @param force LuaForce
local function update_force_guis(force)
  for _, player in pairs(force.players) do
    local player_gui = gui.get(player.index)
    if player_gui then
      gui.update_filter_panel(player_gui)
      gui.update_page(player_gui)
    end
  end
end

-- Events

--- @param e EventData.on_player_dictionaries_ready
local function on_player_dictionaries_ready(e)
  local player_gui = gui.get(e.player_index)
  if player_gui then
    gui.update_translation_warning(player_gui)
  end
end

local function on_runtime_mod_setting_changed(e)
  if e.setting ~= "rb-show-overhead-button" then
    return
  end
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  gui.refresh_overhead_button(player)
end

local function on_tick()
  for force_index in pairs(global.update_force_guis) do
    local force = game.forces[force_index]
    if force then
      update_force_guis(force)
    end
  end
  global.update_force_guis = {}
end

--- @param e EventData.CustomInputEvent
local function on_focus_search(e)
  local player_gui = gui.get(e.player_index)
  if not player_gui or player_gui.pinned or not player_gui.elems.rb_main_window.visible then
    return
  end
  if player_gui.search_open then
    gui.focus_search(player_gui)
  else
    gui.toggle_search(player_gui)
  end
end

--- @param e EventData.CustomInputEvent
local function on_open_selected(e)
  local selected_prototype = e.selected_prototype
  if not selected_prototype then
    return
  end
  local player_gui = gui.get(e.player_index)
  if not player_gui then
    return
  end
  local updated = gui.update_page(player_gui, selected_prototype.base_type .. "/" .. selected_prototype.name)
  if not updated then
    util.flying_text(player_gui.player, { "message.rb-no-info" })
    return
  end
  gui.show(player_gui)
end

--- @param e EventData.CustomInputEvent
local function on_toggle(e)
  local self = gui.get(e.player_index)
  if self then
    gui.toggle(self)
  end
end

--- @param e EventData.on_lua_shortcut
local function on_lua_shortcut(e)
  if e.prototype_name ~= "rb-toggle" then
    return
  end
  local self = gui.get(e.player_index)
  if self then
    gui.toggle(self)
  end
end

--- @param e EventData.CustomInputEvent
local function on_next(e)
  local self = gui.get(e.player_index)
  if not self then
    return
  end
  gui.nav_history(self, 1)
end

--- @param e EventData.CustomInputEvent
local function on_previous(e)
  local self = gui.get(e.player_index)
  if not self then
    return
  end
  gui.nav_history(self, -1)
end

local mod = {}

mod.on_init = function()
  --- @type table<uint, Gui>
  global.guis = {}
  --- @type table<uint, boolean>
  global.update_force_guis = {} --
end

mod.on_configuration_changed = function()
  for _, player in pairs(game.players) do
    gui.new(player)
    gui.refresh_overhead_button(player)
  end
end

mod.events = {
  [defines.events.on_lua_shortcut] = on_lua_shortcut,
  [defines.events.on_runtime_mod_setting_changed] = on_runtime_mod_setting_changed,
  [defines.events.on_tick] = on_tick,
  [dictionary.on_player_dictionaries_ready] = on_player_dictionaries_ready,
  ["rb-linked-focus-search"] = on_focus_search,
  ["rb-next"] = on_next,
  ["rb-open-selected"] = on_open_selected,
  ["rb-previous"] = on_previous,
  ["rb-toggle"] = on_toggle,
}

mod.add_remote_interface = function()
  remote.add_interface("RecipeBook", {
    --- Open the given page in Recipe Book.
    --- @param player_index uint
    --- @param class string
    --- @param name string
    --- @return boolean success
    open_page = function(player_index, class, name)
      local path = class .. "/" .. name
      local entry = global.database[path]
      if not entry or not entry.base then
        return false
      end
      local player_gui = gui.get(player_index)
      if player_gui then
        gui.update_page(player_gui, path)
        gui.show(player_gui)
      end
      return true
    end,
    --- The current interface version.
    version = function()
      return 4
    end,
  })
end

return mod
