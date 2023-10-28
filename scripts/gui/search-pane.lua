local flib_dictionary = require("__flib__/dictionary-lite")
local flib_gui = require("__flib__/gui-lite")

local gui_util = require("__RecipeBook__/scripts/gui/util")
local util = require("__RecipeBook__/scripts/util")

--- @class SearchPane
--- @field textfield LuaGuiElement
--- @field groups_table LuaGuiElement
--- @field results_pane LuaGuiElement
--- @field result_buttons table<string, LuaGuiElement>
--- @field dictionary_warning LuaGuiElement
--- @field no_results_warning LuaGuiElement
--- @field context MainGuiContext
--- @field query string
--- @field selected_group string
--- @field selected_result string?
local search_pane = {}
local mt = { __index = search_pane }
script.register_metatable("search_pane", mt)

--- @type function?
search_pane.on_result_clicked = nil

--- @param parent LuaGuiElement
--- @param context MainGuiContext
function search_pane.build(parent, context)
  local outer = parent.add({
    type = "frame",
    name = "filter_outer_frame",
    style = "inside_deep_frame",
    direction = "vertical",
    index = 1,
  })

  local subheader = outer.add({ type = "frame", style = "subheader_frame" })
  subheader.style.horizontally_stretchable = true

  local textfield = subheader.add({
    type = "textfield",
    name = "search_textfield",
    lose_focus_on_confirm = true,
    clear_and_focus_on_right_click = true,
    tooltip = { "gui.flib-search-instruction" },
    tags = flib_gui.format_handlers({ [defines.events.on_gui_text_changed] = search_pane.on_query_changed }),
  })
  textfield.add({
    type = "label",
    name = "placeholder",
    caption = "Search...",
    ignored_by_interaction = true,
  }).style.font_color =
    { 0, 0, 0, 0.6 }

  local dictionary_warning = outer.add({
    type = "frame",
    name = "filter_warning_frame",
    style = "negative_subheader_frame",
    visible = false,
  })
  dictionary_warning.style.horizontally_stretchable = true
  dictionary_warning.add({
    type = "label",
    style = "bold_label",
    caption = { "gui.rb-localised-search-unavailable" },
  }).style.left_margin =
    8

  local groups_table = outer.add({ type = "table", style = "filter_group_table", column_count = 6 })

  local results_pane = outer
    .add({ type = "frame", style = "rb_filter_frame" })
    .add({ type = "frame", style = "rb_filter_deep_frame" })
    .add({ type = "scroll-pane", style = "rb_filter_scroll_pane", vertical_scroll_policy = "always" })

  local no_results_warning = results_pane.add({
    type = "frame",
    name = "filter_no_results_label",
    style = "negative_subheader_frame",
    visible = false,
  })
  no_results_warning.style.horizontally_stretchable = true
  no_results_warning.add({
    type = "label",
    style = "bold_label",
    caption = { "", "[img=warning-white] ", { "gui.nothing-found" } },
  }).style.left_margin =
    8

  local result_buttons = {}
  -- Create tables for each subgroup
  for group_name, subgroups in pairs(global.search_tree) do
    -- Tab button
    groups_table.add({
      type = "sprite-button",
      name = group_name,
      style = "rb_filter_group_button_tab",
      sprite = "item-group/" .. group_name,
      tooltip = game.item_group_prototypes[group_name].localised_name,
      tags = flib_gui.format_handlers({ [defines.events.on_gui_click] = search_pane.on_group_clicked }),
    })
    -- Base flow
    local group_flow = results_pane.add({
      type = "flow",
      name = group_name,
      style = "packed_vertical_flow",
      direction = "vertical",
      visible = false,
    })
    -- Assemble subgroups
    for subgroup_name, subgroup in pairs(subgroups) do
      local subgroup_table =
        group_flow.add({ type = "table", name = subgroup_name, style = "slot_table", column_count = 10 })
      for _, path in pairs(subgroup) do
        local type, name = string.match(path, "(.*)/(.*)")
        local button = subgroup_table.add({
          type = "choose-elem-button",
          style = "flib_slot_button_default",
          elem_type = type,
          [type] = name,
          -- sprite = path,
          -- tooltip = gui_util.build_tooltip({ type = type, name = name }),
          tags = flib_gui.format_handlers({ [defines.events.on_gui_click] = search_pane.on_result_clicked }),
        })
        button.locked = true
        if result_buttons[path] then
          error("Duplicate button ID: " .. path)
        end
        result_buttons[path] = button
      end
    end
  end

  --- @type SearchPane
  local self = {
    textfield = textfield,
    groups_table = groups_table,
    results_pane = results_pane,
    result_buttons = result_buttons,
    dictionary_warning = dictionary_warning,
    no_results_warning = no_results_warning,
    context = context,
    query = "",
    selected_group = "",
  }
  setmetatable(self, mt)
  self:update()
  return self
end

function search_pane:update()
  local profiler = game.create_profiler()
  local show_hidden = self.context.show_hidden
  local show_unresearched = self.context.show_unresearched
  local query = string.lower(self.query)
  local force_index = self.context.player.force.index
  local groups_table = self.groups_table
  local result_buttons = self.result_buttons
  local first_valid
  local search_strings = flib_dictionary.get(self.context.player.index, "search") or {}
  local db = global.database

  self.textfield.placeholder.visible = #query == 0

  for group_name, group in pairs(global.search_tree) do
    local filtered_count = 0
    local searched_count = 0
    for _, subgroup in pairs(group) do
      for _, path in pairs(subgroup) do
        local entry = db[path]
        local base_prototype = entry.base
        local is_hidden = util.is_hidden(base_prototype)
        local is_researched = entry.researched and entry.researched[force_index] or false
        local filters_match = (show_hidden or not is_hidden) and (show_unresearched or is_researched)
        local button = result_buttons[path]
        if filters_match then
          filtered_count = filtered_count + 1
          local query_match = #query == 0
          if not query_match then
            local comp = search_strings[path] or string.gsub(path, "-", " ")
            query_match = string.find(string.lower(comp), query, 1, true) --[[@as boolean]]
          end
          button.visible = query_match
          if query_match then
            searched_count = searched_count + 1
            if is_hidden then
              button.style = "yellow_slot_button"
            elseif not is_researched then
              button.style = "red_slot_button"
            else
              button.style = "slot_button"
            end
          end
        else
          button.visible = false
        end
      end
    end
    local is_visible = filtered_count > 0
    local has_search_matches = searched_count > 0
    local group_tab = groups_table[group_name] --[[@as LuaGuiElement]]
    groups_table[group_name].visible = is_visible
    if is_visible and not has_search_matches then
      group_tab.enabled = false
      group_tab.style.draw_grayscale_picture = true
      group_tab.toggled = false
    else
      group_tab.enabled = true
      group_tab.style.draw_grayscale_picture = false
      group_tab.toggled = group_name == self.selected_group
    end
    if is_visible and has_search_matches then
      first_valid = first_valid or group_name
    end
  end

  if first_valid then
    self.no_results_warning.visible = false
    if self.selected_group ~= "" then
      local group_button = groups_table[self.selected_group] --[[@as LuaGuiElement]]
      if not group_button.visible or not group_button.enabled then
        self:select_group(first_valid)
      end
    else
      self:select_group(first_valid)
    end
  else
    self.no_results_warning.visible = true
  end

  profiler.stop()
  log({ "", "Update Filter Panel ", profiler })
end

--- @param group_name string
function search_pane:select_group(group_name)
  local groups_table = self.groups_table
  local results_pane = self.results_pane
  local previous_group = self.selected_group
  if previous_group ~= "" then
    groups_table[previous_group].toggled = false
    results_pane[previous_group].visible = false
  end
  groups_table[group_name].toggled = true
  results_pane[group_name].visible = true
  self.selected_group = group_name
end

--- @param result_path string?
function search_pane:select_result(result_path)
  local previous_result = self.selected_result
  if previous_result then
    local previous_button = self.result_buttons[previous_result]
    if previous_button then
      previous_button.enabled = true
    end
  end
  self.selected_result = result_path
  if not result_path then
    return
  end
  local new_button = self.result_buttons[result_path]
  if new_button then
    new_button.enabled = false
    self:select_group(global.database[result_path].base.group.name)
    self.results_pane.scroll_to_element(new_button)
  end
end

function search_pane:focus_search()
  self.textfield.select_all()
  self.textfield.focus()
end

--- @private
--- @param e EventData.on_gui_text_changed
function search_pane:on_query_changed(e)
  self.query = e.text
  self:update()
end

--- @private
--- @param e EventData.on_gui_text_changed
function search_pane:on_group_clicked(e)
  self:select_group(e.element.name)
end

flib_gui.add_handlers(search_pane, function(e, handler)
  local main = global.guis[e.player_index]
  if not main or not main.window.valid then
    return
  end
  handler(main.search_pane, e)
end, "search_pane")

return search_pane
