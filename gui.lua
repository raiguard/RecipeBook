local dictionary = require("__flib__/dictionary-lite")
local flib_gui = require("__flib__/gui-lite")
local mod_gui = require("__core__/lualib/mod-gui")
local table = require("__flib__/table")

local database = require("__RecipeBook__/database")
local gui_util = require("__RecipeBook__/gui-util")
local util = require("__RecipeBook__/util")

--- @class GuiMod
local gui = {}

--- @class GuiElems
--- @field rb_main_window LuaGuiElement
--- @field search_textfield LuaGuiElement
--- @field search_button LuaGuiElement
--- @field show_unresearched_button LuaGuiElement
--- @field show_hidden_button LuaGuiElement
--- @field pin_button LuaGuiElement
--- @field close_button LuaGuiElement
--- @field filter_group_table LuaGuiElement
--- @field filter_scroll_pane LuaGuiElement
--- @field page_header_sprite LuaGuiElement
--- @field page_header_caption LuaGuiElement
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
  on_overhead_button_click = function(self)
    gui.toggle(self)
  end,

  --- @param self Gui
  --- @param e EventData.on_gui_click
  on_prototype_button_click = function(self, e)
    local tags = e.element.tags
    if tags.prototype then
      gui.update_page(self, tags.prototype --[[@as string]])
    end
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
    self.state.search_query = e.element.text
    gui.update_filter_panel(self)
  end,

  --- @param self Gui
  on_show_hidden_button_click = function(self)
    self.state.show_hidden = not self.state.show_hidden
    local button = self.elems.show_hidden_button
    if self.state.show_hidden then
      button.style = "flib_selected_frame_action_button"
      button.sprite = "rb_show_hidden_black"
    else
      button.style = "frame_action_button"
      button.sprite = "rb_show_hidden_white"
    end
    gui.update_filter_panel(self)
    gui.update_page(self)
  end,

  --- @param self Gui
  on_show_unresearched_button_click = function(self)
    self.state.show_unresearched = not self.state.show_unresearched
    local button = self.elems.show_unresearched_button
    if self.state.show_unresearched then
      button.style = "flib_selected_frame_action_button"
      button.sprite = "rb_show_unresearched_black"
    else
      button.style = "frame_action_button"
      button.sprite = "rb_show_unresearched_white"
    end
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
    if self.state.pinned then
      return
    end
    if self.state.search_open then
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
  self.player.set_shortcut_toggled("RecipeBook", false)
end

--- @param self Gui
--- @param group_name string
function gui.select_filter_group(self, group_name)
  local tabs = self.elems.filter_group_table
  local members = self.elems.filter_scroll_pane
  local previous_group = self.state.selected_filter_group
  if previous_group then
    tabs[previous_group].enabled = true
    members[previous_group].visible = false
  end
  tabs[group_name].enabled = false
  members[group_name].visible = true
  self.state.selected_filter_group = group_name
end

--- @param self Gui
function gui.show(self)
  self.elems.rb_main_window.visible = true
  self.elems.rb_main_window.bring_to_front()
  if not self.state.pinned then
    self.player.opened = self.elems.rb_main_window
    self.elems.rb_main_window.force_auto_center()
  end
  self.player.set_shortcut_toggled("RecipeBook", true)
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
  self.state.pinned = not self.state.pinned
  if self.state.pinned then
    self.elems.pin_button.style = "flib_selected_frame_action_button"
    self.elems.pin_button.sprite = "rb_pin_black"
    self.elems.close_button.tooltip = { "gui.close" }
    self.elems.search_button.tooltip = { "gui.search" }
    if self.player.opened == self.elems.rb_main_window then
      self.player.opened = nil
    end
  else
    self.elems.pin_button.style = "frame_action_button"
    self.elems.pin_button.sprite = "rb_pin_white"
    self.player.opened = self.elems.rb_main_window
    self.elems.rb_main_window.force_auto_center()
    self.elems.close_button.tooltip = { "gui.close-instruction" }
    self.elems.search_button.tooltip = { "gui.rb-search-instruction" }
  end
end

--- @param self Gui
function gui.toggle_search(self)
  self.state.search_open = not self.state.search_open
  if self.state.search_open then
    self.elems.search_button.style = "flib_selected_frame_action_button"
    self.elems.search_button.sprite = "utility/search_black"
    self.elems.search_textfield.visible = true
    self.elems.search_textfield.focus()
  else
    self.elems.search_button.style = "frame_action_button"
    self.elems.search_button.sprite = "utility/search_white"
    self.elems.search_textfield.visible = false
    if #self.state.search_query > 0 then
      self.elems.search_textfield.text = ""
      self.state.search_query = ""
      gui.update_filter_panel(self)
    end
  end
end

--- @param self Gui
function gui.update_filter_panel(self)
  local profiler = game.create_profiler()
  local show_hidden = self.state.show_hidden
  local show_unresearched = self.state.show_unresearched
  local search_query = string.lower(self.state.search_query)
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
      group_tab.enabled = group.name ~= self.state.selected_filter_group
    end
    if is_visible and has_search_matches then
      first_valid = first_valid or group.name
    end
  end

  if first_valid then
    groups_scroll.visible = true
    self.elems.filter_no_results_label.visible = false
    local current_tab = tabs_table[self.state.selected_filter_group] --[[@as LuaGuiElement]]
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
  local prototype_path = prototype_path or self.state.current_page
  if not prototype_path then
    return
  end

  self.state.current_page = prototype_path

  local profiler = game.create_profiler()

  local properties = database.get_properties(prototype_path, self.player.force.index)
  if not properties then
    return
  end
  local entry = properties.entry

  -- Header
  local header_sprite = self.elems.page_header_sprite
  header_sprite.visible = true
  header_sprite.sprite = prototype_path
  local header_caption = self.elems.page_header_caption
  header_caption.caption = entry.base.localised_name
  local style = "caption_label"
  if util.is_hidden(entry.base) then
    style = "rb_caption_label_hidden"
  elseif util.is_unresearched(entry, self.player.force.index) then
    style = "rb_caption_label_unresearched"
  end
  header_caption.style = style
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

  gui_util.update_list_box(
    self,
    handlers,
    scroll_pane.ingredients,
    properties.ingredients,
    properties.crafting_time
      and {
        "",
        "[img=quantity-time][font=default-bold]",
        { "time-symbol-seconds", properties.crafting_time },
        "[/font] ",
        { "description.crafting-time" },
      }
  )
  gui_util.update_list_box(self, handlers, scroll_pane.products, properties.products)
  gui_util.update_list_box(self, handlers, scroll_pane.made_in, properties.made_in)
  gui_util.update_list_box(self, handlers, scroll_pane.ingredient_in, properties.ingredient_in)
  gui_util.update_list_box(self, handlers, scroll_pane.product_of, properties.product_of)
  gui_util.update_list_box(self, handlers, scroll_pane.can_craft, properties.can_craft)
  gui_util.update_list_box(self, handlers, scroll_pane.mined_by, properties.mined_by)
  gui_util.update_list_box(self, handlers, scroll_pane.can_mine, properties.can_mine)

  profiler.stop()
  log({ "", "[", prototype_path, "] ", profiler })
end

--- @param self Gui
function gui.update_translation_warning(self)
  self.elems.filter_warning_frame.visible = not dictionary.get(self.player.index, "search")
end

-- Lifecycle

function gui.init()
  --- @type table<uint, Gui>
  global.guis = {}
end

--- @param player LuaPlayer
--- @return Gui
function gui.new(player)
  local elems = gui_util.build_base_gui(player, handlers)

  -- Set initial state of show unresearched button
  elems.show_unresearched_button.sprite = "rb_show_unresearched_black"
  elems.show_unresearched_button.style = "flib_selected_frame_action_button"

  --- @class Gui
  local self = {
    elems = elems,
    player = player,
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

  global.guis[player.index] = self

  gui.select_filter_group(self, self.state.selected_filter_group)
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
  if button_flow.RecipeBook then
    button_flow.RecipeBook.destroy()
  end
  if player.mod_settings["rb-show-overhead-button"].value then
    flib_gui.add(button_flow, {
      {
        type = "sprite-button",
        name = "RecipeBook",
        style = mod_gui.button_style,
        style_mods = { padding = 8 },
        tooltip = { "mod-name.RecipeBook" },
        sprite = "rb_logo",
        handler = { [defines.events.on_gui_click] = handlers.on_overhead_button_click },
      },
    })
  end
end

--- Get the player's GUI or create it if it does not exist
--- @param player_index uint
--- @return Gui?
function gui.get(player_index)
  local self = global.guis[player_index]
  if not self or not self.elems.rb_main_window.valid then
    if self then
      self.player.print({ "message.rb-recreated-gui" })
    end
    self = gui.new(self.player)
  end
  return self
end

--- @param force LuaForce
function gui.update_force(force)
  for _, player in pairs(force.players) do
    local player_gui = gui.get(player.index)
    if player_gui then
      gui.update_filter_panel(player_gui)
    end
  end
end

gui.handle_events = flib_gui.handle_events

return gui
