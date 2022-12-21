local dictionary = require("__flib__/dictionary-lite")
local flib_gui = require("__flib__/gui-lite")
local math = require("__flib__/math")
local mod_gui = require("__core__/lualib/mod-gui")
local table = require("__flib__/table")

local database = require("__RecipeBook__/database")
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

--- @class GuiHandlers
local handlers
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

--- @param obj GenericObject
--- @param localised_name LocalisedString
--- @return LocalisedString
local function build_caption(obj, localised_name)
  --- @type LocalisedString
  local caption = { "", "            " }
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
  caption[#caption + 1] = localised_name

  return caption
end

--- @param obj GenericObject
--- @return LocalisedString
local function build_remark(obj)
  --- @type LocalisedString
  local remark = { "" }
  if obj.duration then
    remark[#remark + 1] = { "", "[img=quantity-time] ", { "time-symbol-seconds", math.round(obj.duration, 0.01) } }
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

local function technology_button()
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

--- @param self Gui
--- @param flow LuaGuiElement
--- @param members GenericObject[]
--- @param remark any?
local function update_list_box(self, flow, members, remark)
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
      _, button = flib_gui.add(list_frame, technology_button())
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
    button.caption = build_caption(member, entry.base.localised_name)
    -- Remark
    button.remark.caption = build_remark(member)
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

--- @param self Gui
--- @param prototype_path string?
--- @return boolean?
function gui.update_page(self, prototype_path)
  local prototype_path = prototype_path or self.state.current_page
  if not prototype_path then
    return
  end
  self.state.current_page = prototype_path
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
  -- TODO: This is ugly
  local header_type = self.elems.page_header_type_label
  local type_caption = { "" }
  if entry.recipe then
    table.insert(type_caption, { "description.recipe" })
    table.insert(type_caption, "/")
  end
  if entry.item then
    table.insert(type_caption, { "description.rb-item" })
    table.insert(type_caption, "/")
  end
  if entry.fluid then
    table.insert(type_caption, { "gui-train.fluid" })
    table.insert(type_caption, "/")
  end
  if entry.entity then
    table.insert(type_caption, { "description.rb-entity" })
    table.insert(type_caption, "/")
  end
  type_caption[#type_caption] = nil
  header_type.caption = type_caption

  -- Contents
  local scroll_pane = self.elems.page_scroll_pane
  if scroll_pane.welcome_label then
    scroll_pane.welcome_label.destroy()
  end

  update_list_box(self, scroll_pane.ingredients, properties.ingredients)
  update_list_box(self, scroll_pane.products, properties.products)
  update_list_box(self, scroll_pane.made_in, properties.made_in)
  update_list_box(self, scroll_pane.ingredient_in, properties.ingredient_in)
  update_list_box(self, scroll_pane.product_of, properties.product_of)
  update_list_box(self, scroll_pane.can_craft, properties.can_craft)
  update_list_box(self, scroll_pane.mined_by, properties.mined_by)
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
  local elems = gui.build_window(player)

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

-- Templates

--- @param sprite string
--- @param name string
--- @param tooltip LocalisedString
--- @param handler GuiElemHandler?
--- @return GuiElemDef
local function frame_action_button(name, sprite, tooltip, handler)
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

--- @param name string
--- @param header LocalisedString
--- @return GuiElemDef
local function list_box(name, header)
  return {
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
  }
end

--- @param player LuaPlayer
--- @return GuiElems
function gui.build_window(player)
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
      frame_action_button("nav_backward_button", "rb_nav_backward", { "gui.rb-nav-backward-instruction" }),
      frame_action_button("nav_forward_button", "rb_nav_forward", { "gui.rb-nav-forward-instruction" }),
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
      frame_action_button(
        "search_button",
        "utility/search",
        { "gui.rb-search-instruction" },
        handlers.on_search_button_click
      ),
      frame_action_button(
        "show_unresearched_button",
        "rb_show_unresearched",
        { "gui.rb-show-unresearched-instruction" },
        handlers.on_show_unresearched_button_click
      ),
      frame_action_button(
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
      frame_action_button("pin_button", "rb_pin", { "gui.rb-pin-instruction" }, handlers.on_pin_button_click),
      frame_action_button("close_button", "utility/close", { "gui.close-instruction" }, handlers.on_close_button_click),
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
        {
          type = "table",
          name = "filter_group_table",
          style = "filter_group_table",
          column_count = 6,
        },
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
        local prototype = global.database[path].base
        table.insert(subgroup_table, {
          type = "sprite-button",
          style = "flib_slot_button_default",
          sprite = path,
          tooltip = {
            "",
            { "", "[font=default-bold]", { "?", prototype.localised_name, path }, "[/font]" },
            "\n",
            { "?", { "", prototype.localised_description, "\n" }, "" },
            path,
          },
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
  flib_gui.add(page_scroll_pane, list_box("ingredients", { "description.ingredients" }))
  flib_gui.add(page_scroll_pane, list_box("products", { "description.products" }))
  flib_gui.add(page_scroll_pane, list_box("made_in", { "description.made-in" }))
  flib_gui.add(page_scroll_pane, list_box("ingredient_in", { "description.rb-ingredient-in" }))
  flib_gui.add(page_scroll_pane, list_box("product_of", { "description.rb-product-of" }))
  flib_gui.add(page_scroll_pane, list_box("can_craft", { "description.rb-can-craft" }))
  flib_gui.add(page_scroll_pane, list_box("mined_by", { "description.rb-mined-by" }))

  return elems
end

return gui
