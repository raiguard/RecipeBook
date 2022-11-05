local gui = require("__flib__.gui-lite")
local math = require("__flib__.math")
local misc = require("__flib__.misc")
local mod_gui = require("__core__.lualib.mod-gui")
local table = require("__flib__.table")

local database = require("__RecipeBook__.database")
local util = require("__RecipeBook__.util")

--- @class Gui
local root = {}
local root_mt = { __index = root }
script.register_metatable("RecipeBook_gui", root_mt)

-- TEMPLATES

--- @param sprite string
--- @param name string
--- @param tooltip LocalisedString
--- @param handler GuiElemHandler?
local function frame_action_button(name, sprite, tooltip, handler)
  return {
    type = "sprite-button",
    name = name,
    style = "frame_action_button",
    sprite = sprite .. "_white",
    hovered_sprite = sprite .. "_black",
    clicked_sprite = sprite .. "_black",
    tooltip = tooltip,
    handler = handler,
  }
end

--- @param name string
--- @param header LocalisedString
--- @param header_remark LocalisedString
local function list_box(name, header, header_remark)
  return {
    type = "flow",
    name = name,
    direction = "vertical",
    visible = false,
    {
      type = "flow",
      style = "centering_horizontal_flow",
      {
        type = "checkbox",
        style = "rb_list_box_caption",
        caption = header,
        state = false,
        handler = root.collapse_list_box,
      },
      { type = "empty-widget", style = "flib_horizontal_pusher" },
      { type = "label", caption = header_remark },
    },
    {
      type = "frame",
      name = "list_frame",
      style = "deep_frame_in_shallow_frame",
      direction = "vertical",
    },
  }
end

-- METHODS

--- @param e on_gui_checked_state_changed
function root:collapse_list_box(e)
  local state = e.element.state
  e.element.parent.parent.list_frame.style.height = state and 1 or 0
  -- TODO: Keep track of collapsed states
end

function root:destroy()
  if self.elems.rb_main_window.valid then
    self.elems.rb_main_window.destroy()
  end
  self.player_table.gui = nil
end

function root:focus_search()
  self.elems.search_textfield.select_all()
  self.elems.search_textfield.focus()
end

function root:hide()
  self.elems.rb_main_window.visible = false
  if self.player.opened == self.elems.rb_main_window then
    self.player.opened = nil
  end
  self.player.set_shortcut_toggled("RecipeBook", false)
end

--- @param e on_gui_click
function root:on_filter_group_button_clicked(e)
  if e.element.style.name ~= "rb_disabled_filter_group_button_tab" then
    self:select_filter_group(e.element.name)
  end
end

--- @param e on_gui_click
function root:on_prototype_button_clicked(e)
  local tags = e.element.tags
  if tags.prototype then
    self:update_page(tags.prototype --[[@as string]])
  end
end

--- @param e on_gui_text_changed
function root:on_search_query_changed(e)
  -- TODO: Fuzzy search
  self.state.search_query = e.element.text
  self:update_filter_panel()
end

function root:on_window_closed()
  if not self.state.pinned then
    if self.state.search_open then
      self:toggle_search()
      self.player.opened = self.elems.rb_main_window
    else
      self:hide()
    end
  end
end

--- @param e on_gui_click?
function root:recenter(e)
  if not e or e.button == defines.mouse_button_type.middle then
    self.elems.rb_main_window.force_auto_center()
  end
end

--- @param group_name string
function root:select_filter_group(group_name)
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

function root:show()
  self.elems.rb_main_window.visible = true
  self.elems.rb_main_window.bring_to_front()
  if not self.state.pinned then
    self.player.opened = self.elems.rb_main_window
    self.elems.rb_main_window.force_auto_center()
  end
  self.player.set_shortcut_toggled("RecipeBook", true)
end

function root:toggle()
  if self.elems.rb_main_window.visible then
    self:hide()
  else
    self:show()
  end
end

function root:toggle_pinned()
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

function root:toggle_search()
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
      self:update_filter_panel()
    end
  end
end

function root:toggle_show_hidden()
  self.state.show_hidden = not self.state.show_hidden
  local button = self.elems.show_hidden_button
  if self.state.show_hidden then
    button.style = "flib_selected_frame_action_button"
    button.sprite = "rb_show_hidden_black"
  else
    button.style = "frame_action_button"
    button.sprite = "rb_show_hidden_white"
  end
  self:update_filter_panel()
  self:update_page()
end

function root:toggle_show_unresearched()
  self.state.show_unresearched = not self.state.show_unresearched
  local button = self.elems.show_unresearched_button
  if self.state.show_unresearched then
    button.style = "flib_selected_frame_action_button"
    button.sprite = "rb_show_unresearched_black"
  else
    button.style = "frame_action_button"
    button.sprite = "rb_show_unresearched_white"
  end
  self:update_filter_panel()
  self:update_page()
end

-- Update filter panel contents based on filters and search query
function root:update_filter_panel()
  local profiler = game.create_profiler()
  local show_hidden = self.state.show_hidden
  local show_unresearched = self.state.show_unresearched
  local search_query = string.lower(self.state.search_query)
  local db = global.database
  local force_index = self.player.force.index
  local tabs_table = self.elems.filter_group_table
  local groups_scroll = self.elems.filter_scroll_pane
  local first_valid
  local search_strings = self.player_table.search_strings or {}

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
      self:select_filter_group(first_valid)
    end
  else
    groups_scroll.visible = false
    self.elems.filter_no_results_label.visible = true
  end
  profiler.stop()
  log({ "", "Update Filter Panel ", profiler })
end

--- @param prototype_path string?
--- @return boolean?
function root:update_page(prototype_path)
  local entry
  if prototype_path then
    entry = global.database[prototype_path]
  elseif self.state.current_page then
    entry = global.database[self.state.current_page]
  end
  if not entry then
    if prototype_path then
      util.flying_text(self.player, { "message.rb-no-info" })
    end
    return
  end
  local base_path = entry.base_path
  if not prototype_path or (base_path ~= self.state.current_page) then
    local properties = database.get_properties(entry, self.player.force.index)

    -- Header
    local page_header_caption = self.elems.page_header_caption
    page_header_caption.sprite = base_path
    page_header_caption.caption = { "", "             ", entry.base.localised_name }
    if properties.hidden then
      page_header_caption.style = "rb_subheader_caption_button_hidden"
    elseif not properties.researched then
      page_header_caption.style = "rb_subheader_caption_button_unresearched"
    else
      page_header_caption.style = "rb_subheader_caption_button"
    end
    local caption = { "" }
    if entry.recipe then
      table.insert(caption, { "description.recipe" })
      table.insert(caption, "/")
    end
    if entry.item then
      table.insert(caption, { "description.rb-item" })
      table.insert(caption, "/")
    end
    if entry.fluid then
      table.insert(caption, { "gui-train.fluid" })
      table.insert(caption, "/")
    end
    if entry.entity then
      table.insert(caption, { "description.rb-entity" })
      table.insert(caption, "/")
    end
    caption[#caption] = nil
    self.elems.page_header_type_label.caption = caption
    -- TODO: Tooltip

    -- Content
    local page_scroll_pane = self.elems.page_scroll_pane
    if page_scroll_pane.welcome_label then
      page_scroll_pane.welcome_label.destroy()
    end
    local show_hidden = self.state.show_hidden
    local show_unresearched = self.state.show_unresearched
    local force_index = self.player.force.index
    for _, component_name in pairs(page_scroll_pane.children_names) do
      local component = page_scroll_pane[component_name]
      if component then
        local objects = properties[component_name]
        local should_show = false
        if objects then
          local children = component.list_frame.children
          local i = 0
          for _, obj in pairs(objects) do
            local obj_entry = database.get_entry(obj)
            if obj_entry then
              local is_researched = database.is_researched(obj, force_index)
              local is_hidden = util.is_hidden(obj_entry.base)
              if (show_unresearched or is_researched) and (show_hidden or not is_hidden) then
                i = i + 1
                should_show = true
                local obj_path = obj.type .. "/" .. obj.name
                local button = children[i]
                if not button then
                  gui.add(component.list_frame, {
                    {
                      type = "sprite-button",
                      handler = root.on_prototype_button_clicked,
                      sprite = obj_path,
                      {
                        type = "label",
                        name = "remark",
                        style_mods = {
                          horizontal_align = "right",
                          height = 36 - 8,
                          width = (40 * 12) - 24,
                          vertical_align = "center",
                        },
                        ignored_by_interaction = true,
                      },
                    },
                  })
                  button = component.list_frame.children[i]
                end
                local style = "rb_list_box_item"
                if is_hidden then
                  style = "rb_list_box_item_hidden"
                elseif not is_researched then
                  style = "rb_list_box_item_unresearched"
                end
                button.style = style
                -- Caption
                local caption = { "", "            " }
                if obj.probability and obj.probability < 1 then
                  table.insert(caption, {
                    "",
                    "[font=default-semibold]",
                    { "format-percent", math.round(obj.probability * 100, 0.01) },
                    "[/font] ",
                  })
                end
                if obj.amount then
                  table.insert(caption, {
                    "",
                    "[font=default-semibold]",
                    misc.delineate_number(math.round(obj.amount, 0.01)),
                    " ×[/font]  ",
                  })
                elseif obj.amount_min and obj.amount_max then
                  table.insert(caption, {
                    "",
                    "[font=default-semibold]",
                    misc.delineate_number(math.round(obj.amount_min, 0.01)),
                    " - ",
                    misc.delineate_number(math.round(obj.amount_max, 0.01)),
                    " ×[/font]  ",
                  })
                end
                table.insert(caption, obj_entry.base.localised_name)
                button.caption = caption
                -- Remark
                local remark = { "" }
                if obj.duration then
                  table.insert(
                    remark,
                    { "", "[img=quantity-time] ", { "time-symbol-seconds", math.round(obj.duration, 0.01) } }
                  )
                end
                if obj.temperature then
                  table.insert(remark, { "", "  ", { "format-degrees-c-compact", math.round(obj.temperature, 0.01) } })
                elseif obj.minimum_temperature and obj.maximum_temperature then
                  local temperature_min = obj.minimum_temperature --[[@as number]]
                  local temperature_max = obj.maximum_temperature --[[@as number]]
                  local temperature_string
                  if temperature_min == math.min_double then
                    temperature_string = "≤ " .. math.round(temperature_max, 0.01)
                  elseif temperature_max == math.max_double then
                    temperature_string = "≥ " .. math.round(temperature_min, 0.01)
                  else
                    temperature_string = ""
                      .. math.round(temperature_min, 0.01)
                      .. " - "
                      .. math.round(temperature_max, 0.01)
                  end
                  table.insert(remark, { "", "  ", { "format-degrees-c-compact", temperature_string } })
                end
                button.remark.caption = remark

                -- Icon and action
                button.sprite = obj_path
                local tags = button.tags
                tags.prototype = obj_path
                button.tags = tags
              end
            end
          end
          for j = i + 1, #children do
            children[j].destroy()
          end
        end
        component.visible = should_show
      end
    end

    self.state.current_page = base_path
  end
  if not self.elems.rb_main_window.visible then
    self:show()
  end
end

function root:update_translation_warning()
  self.elems.filter_warning_frame.visible = not self.player_table.search_strings
end

-- BOOTSTRAP

--- @param player LuaPlayer
--- @param player_table PlayerTable
--- @return Gui
function root.new(player, player_table)
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
      handler = root.on_filter_group_button_clicked,
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
            {
              "gui.rb-prototype-tooltip",
              prototype.localised_name,
              path,
              prototype.localised_description,
            },
            "\n",
            "foo bar",
          },
          handler = root.on_prototype_button_clicked,
          -- TODO: Read the sprite instead?
          tags = { prototype = path },
        })
      end
    end
  end

  -- Build GUI
  local elems = gui.add(player.gui.screen, {
    {
      type = "frame",
      name = "rb_main_window",
      direction = "vertical",
      visible = false,
      handler = { [defines.events.on_gui_closed] = root.on_window_closed },
      {
        type = "flow",
        name = "titlebar_flow",
        style = "flib_titlebar_flow",
        handler = root.recenter,
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
          handler = { [defines.events.on_gui_text_changed] = root.on_search_query_changed },
        },
        frame_action_button("search_button", "utility/search", { "gui.rb-search-instruction" }, root.toggle_search),
        frame_action_button(
          "show_unresearched_button",
          "rb_show_unresearched",
          { "gui.rb-show-unresearched-instruction" },
          root.toggle_show_unresearched
        ),
        frame_action_button(
          "show_hidden_button",
          "rb_show_hidden",
          { "gui.rb-show-hidden-instruction" },
          root.toggle_show_hidden
        ),
        {
          type = "line",
          style_mods = { top_margin = -2, bottom_margin = 2 },
          direction = "vertical",
          ignored_by_interaction = true,
        },
        frame_action_button("pin_button", "rb_pin", { "gui.rb-pin-instruction" }, root.toggle_pinned),
        frame_action_button("close_button", "utility/close", { "gui.close-instruction" }, root.hide),
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
                name = "filter_scroll_pane",
                style = "rb_filter_scroll_pane",
                vertical_scroll_policy = "always", -- FIXME: The scroll pane is stretching for some reason
                children = group_flows,
              },
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
            {
              type = "sprite-button",
              name = "page_header_caption",
              style = "rb_subheader_caption_button",
              caption = { "gui.rb-welcome-title" },
              enabled = false,
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
    },
  })

  -- Add components to page
  local page_scroll_pane = elems.page_scroll_pane
  gui.add(page_scroll_pane, { list_box("ingredients", { "description.ingredients" }) })
  gui.add(page_scroll_pane, { list_box("products", { "description.products" }) })
  gui.add(page_scroll_pane, { list_box("made_in", { "description.made-in" }) })
  gui.add(page_scroll_pane, { list_box("ingredient_in", { "description.rb-ingredient-in" }) })
  gui.add(page_scroll_pane, { list_box("product_of", { "description.rb-product-of" }) })
  gui.add(page_scroll_pane, { list_box("can_craft", { "description.rb-can-craft" }) })

  -- Ingredients

  -- Dragging and centering
  elems.titlebar_flow.drag_target = elems.rb_main_window
  elems.rb_main_window.force_auto_center()

  -- Set initial state of show unresearched button
  elems.show_unresearched_button.sprite = "rb_show_unresearched_black"
  elems.show_unresearched_button.style = "flib_selected_frame_action_button"

  --- @class Gui
  local self = {
    elems = elems,
    player = player,
    player_table = player_table,
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
  setmetatable(self, root_mt)
  player_table.gui = self

  self:select_filter_group(self.state.selected_filter_group)
  self:update_filter_panel()
  self:update_translation_warning()

  return self
end

--- @param player LuaPlayer
function root.refresh_overhead_button(player)
  local button_flow = mod_gui.get_button_flow(player)
  if button_flow.RecipeBook then
    button_flow.RecipeBook.destroy()
  end
  if player.mod_settings["rb-show-overhead-button"].value then
    gui.add(button_flow, {
      {
        type = "sprite-button",
        name = "RecipeBook",
        style = mod_gui.button_style,
        style_mods = { padding = 8 },
        tooltip = { "mod-name.RecipeBook" },
        sprite = "rb_logo",
        handler = root.toggle,
      },
    })
  end
end

--- Get the player's GUI or create it if it does not exist
--- @return Gui?
function root.get(player)
  local player_table = global.players[player.index]
  if player_table then
    local pgui = player_table.gui
    if pgui and pgui.elems.rb_main_window.valid then
      return pgui
    else
      if pgui then
        pgui:destroy()
        player.print({ "message.rb-recreated-gui" })
      end
      pgui = root.new(player, player_table)
      return pgui
    end
  end
end

--- @param e GuiEventData
gui.dispatch_wrapper = function(e, handler)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  local pgui = root.get(player)
  if pgui then
    handler(pgui, e)
  end
end
gui.add_handlers(root)

root.handle_events = gui.handle_events

return root

-- -- TODO: This currently redraws a page if you click a grouped item, then its recipe, etc
-- -- Proper grouping of prototypes will fix this
-- if self.state.current_page == prototype_path then
--   return true
-- end

-- log("Updating page to " .. prototype_path)
-- local group = global.database[prototype_path]
-- if not group then
--   log("Page was not found")
--   return
-- end

-- local profiler = game.create_profiler()

-- local sprite, localised_name
-- -- TODO: Assemble info, THEN build the GUI
-- local components = {}

-- -- This will be common across all kinds of objects
-- local unlocked_by = {}

-- local types = {}

-- local recipe = group.recipe
-- if recipe then
--   sprite = "recipe/" .. recipe.name
--   localised_name = recipe.localised_name
--   table.insert(types, "Recipe")

--   table.insert(
--     components,
--     list_box(
--       "Ingredients",
--       -- TODO: Handle amount ranges and probabilities
--       table.map(recipe.ingredients, function(v)
--         if v.amount then
--           v.amount = { "", "[font=default-semibold]", v.amount, " ×[/font]  " }
--         end
--         return v
--       end),
--       {
--         "",
--         "[img=quantity-time] [font=default-semibold]",
--         { "time-symbol-seconds", math.round(recipe.energy, 0.1) },
--         "[/font] ",
--         { "description.crafting-time" },
--       }
--     )
--   )
--   table.insert(
--     components,
--     list_box(
--       "Products",
--       table.map(recipe.products, function(v)
--         if v.amount then
--           v.amount = { "", "[font=default-semibold]", v.amount, " ×[/font]  " }
--         end
--         return v
--       end)
--     )
--   )

--   local made_in = {}
--   for _, crafter in
--     pairs(game.get_filtered_entity_prototypes({
--       { filter = "crafting-category", crafting_category = recipe.category },
--     }))
--   do
--     if crafter.ingredient_count == 0 or crafter.ingredient_count >= #recipe.ingredients then
--       table.insert(made_in, {
--         type = "entity",
--         name = crafter.name,
--         remark = {
--           "",
--           "[img=quantity-time] ",
--           { "time-symbol-seconds", math.round(recipe.energy / crafter.crafting_speed, 0.01) },
--           " ",
--         },
--       })
--     end
--   end
--   table.insert(components, list_box("Made in", made_in))

--   for _, technology in
--     pairs(game.get_filtered_technology_prototypes({ { filter = "enabled" }, { filter = "has-effects" } }))
--   do
--     for _, effect in pairs(technology.effects) do
--       if effect.type == "unlock-recipe" and effect.recipe == recipe.name then
--         table.insert(unlocked_by, { type = "technology", name = technology.name })
--       end
--     end
--   end
-- end

-- local fluid = group.fluid
-- if fluid then
--   sprite = sprite or ("fluid/" .. fluid.name)
--   localised_name = localised_name or fluid.localised_name
--   table.insert(types, "Fluid")

--   local ingredient_in = {}
--   for _, recipe in
--     pairs(game.get_filtered_recipe_prototypes({
--       { filter = "has-ingredient-fluid", elem_filters = { { filter = "name", name = fluid.name } } },
--     }))
--   do
--     table.insert(ingredient_in, { type = "recipe", name = recipe.name })
--   end
--   table.insert(components, list_box("Ingredient in", ingredient_in))

--   local product_of = {}
--   for _, recipe in
--     pairs(game.get_filtered_recipe_prototypes({
--       { filter = "has-product-fluid", elem_filters = { { filter = "name", name = fluid.name } } },
--     }))
--   do
--     table.insert(product_of, { type = "recipe", name = recipe.name })
--   end
--   table.insert(components, list_box("Product of", product_of))
-- end

-- local item = group.item
-- if item then
--   sprite = sprite or ("item/" .. item.name)
--   localised_name = localised_name or item.localised_name
--   table.insert(types, "Item")

--   local ingredient_in = {}
--   for _, recipe in
--     pairs(game.get_filtered_recipe_prototypes({
--       { filter = "has-ingredient-item", elem_filters = { { filter = "name", name = item.name } } },
--     }))
--   do
--     table.insert(ingredient_in, { type = "recipe", name = recipe.name })
--   end
--   table.insert(components, list_box("Ingredient in", ingredient_in))

--   local product_of = {}
--   for _, recipe in
--     pairs(game.get_filtered_recipe_prototypes({
--       { filter = "has-product-item", elem_filters = { { filter = "name", name = item.name } } },
--     }))
--   do
--     table.insert(product_of, { type = "recipe", name = recipe.name })
--   end
--   if #product_of > 1 or not recipe then
--     table.insert(components, list_box("Product of", product_of))
--   end
-- end

-- local entity = group.entity
-- if entity then
--   sprite = sprite or ("entity/" .. entity.name)
--   localised_name = localised_name or entity.localised_name
--   table.insert(types, "Entity")

--   if util.crafting_machine[entity.type] then
--     local filters = {}
--     for category in pairs(entity.crafting_categories) do
--       table.insert(filters, { filter = "category", category = category })
--       table.insert(filters, { mode = "and", filter = "hidden-from-player-crafting", invert = true })
--     end
--     local can_craft = {}
--     for _, recipe in pairs(game.get_filtered_recipe_prototypes(filters)) do
--       if entity.ingredient_count == 0 or entity.ingredient_count >= #recipe.ingredients then
--         table.insert(can_craft, { type = "recipe", name = recipe.name })
--       end
--     end
--     table.insert(components, list_box("Can craft", can_craft))
--   elseif entity.type == "resource" then
--     local required_fluid_str
--     local required_fluid = entity.mineable_properties.required_fluid
--     if required_fluid then
--       required_fluid_str = {
--         "",
--         "Requires:  ",
--         "[img=fluid/" .. required_fluid .. "] ",
--         game.fluid_prototypes[required_fluid].localised_name,
--       }
--     end
--     local resource_category = entity.resource_category
--     local mined_by = {}
--     for _, entity in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "mining-drill" } })) do
--       if entity.resource_categories[resource_category] and (not required_fluid or entity.fluidbox_prototypes[1]) then
--         table.insert(mined_by, { type = "entity", name = entity.name })
--       end
--     end
--     table.insert(components, list_box("Mined by", mined_by, required_fluid_str))

--     local mineable = entity.mineable_properties
--     if mineable.minable and #mineable.products > 0 then
--       table.insert(components, list_box("Mining products", mineable.products))
--     end
--   elseif entity.type == "mining-drill" then
--     local categories = entity.resource_categories --[[@as table<string, _>]]
--     -- TODO: Fluid filters?
--     local supports_fluid = entity.fluidbox_prototypes[1] and true or false
--     local can_mine = {}
--     for _, resource in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "resource" } })) do
--       if
--         categories[resource.resource_category] and (supports_fluid or not resource.mineable_properties.required_fluid)
--       then
--         table.insert(can_mine, { type = "entity", name = resource.name })
--       end
--     end
--     table.insert(components, list_box("Can mine", can_mine))
--   end
-- end

-- if #unlocked_by > 0 then
--   table.insert(components, list_box("Unlocked by", unlocked_by))
-- end

-- profiler.stop()
-- log({ "", "Build Info ", profiler })
-- profiler.reset()

-- self.elems.page_header_icon.sprite = sprite
-- self.elems.page_header_icon.visible = true
-- self.elems.page_header_label.caption = localised_name
-- self.elems.page_header_type_label.caption = table.concat(types, "/")

-- local page_scroll = self.elems.page_scroll
-- page_scroll.clear()
-- gui.add(page_scroll, components)

-- profiler.stop()
-- log({ "", "Build GUI ", profiler })

-- self.state.current_page = prototype_path

-- self.elems.page_scroll.scroll_to_top()
-- if not self.elems.rb_main_window.visible then
--   self:show()
-- end
-- return true
