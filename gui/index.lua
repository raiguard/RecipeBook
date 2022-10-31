local libgui = require("__flib__.gui-lite")
local libmath = require("__flib__.math")
local libtable = require("__flib__.table")
local mod_gui = require("__core__.lualib.mod-gui")

local util = require("__RecipeBook__.util")

--- @class Gui
local gui = {}
local gui_mt = { __index = gui }
script.register_metatable("RecipeBook_gui", gui_mt)

-- HANDLERS

local handlers = {}

--- @param self Gui
function handlers.close_button(_, self)
  self:hide()
end

--- @param e on_gui_checked_state_changed
function handlers.collapse_list_box(e)
  local state = e.element.state
  e.element.parent.parent.list_frame.style.height = state and 1 or 0
  -- TODO: Keep track of collapsed states
end
--- @param e on_gui_click
--- @param self Gui
function handlers.filter_group_button(e, self)
  if e.element.style.name ~= "rb_disabled_filter_group_button_tab" then
    self:select_filter_group(e.element.name)
  end
end

--- @param self Gui
function handlers.overhead_button(_, self)
  self:toggle()
end

--- @param self Gui
function handlers.pin_button(_, self)
  self:toggle_pinned()
end

--- @param e on_gui_click
--- @param self Gui
function handlers.prototype_button(e, self)
  local tags = e.element.tags
  if tags.prototype then
    self:show_page(tags.prototype --[[@as string]])
  end
end

--- @param self Gui
function handlers.search_button(_, self)
  self:toggle_search()
end

--- @param self Gui
--- @param e on_gui_text_changed
function handlers.search_textfield(e, self)
  -- TODO: Fuzzy search
  self.state.search_query = e.element.text
  self:update_filter_panel()
end

--- @param e on_gui_click
--- @param self Gui
function handlers.show_hidden_button(e, self)
  self.state.show_hidden = not self.state.show_hidden
  if self.state.show_hidden then
    e.element.style = "flib_selected_frame_action_button"
    e.element.sprite = "rb_show_hidden_black"
  else
    e.element.style = "frame_action_button"
    e.element.sprite = "rb_show_hidden_white"
  end
  self:update_filter_panel()
end

--- @param e on_gui_click
--- @param self Gui
function handlers.show_unresearched_button(e, self)
  self.state.show_unresearched = not self.state.show_unresearched
  if self.state.show_unresearched then
    e.element.style = "flib_selected_frame_action_button"
    e.element.sprite = "rb_show_unresearched_black"
  else
    e.element.style = "frame_action_button"
    e.element.sprite = "rb_show_unresearched_white"
  end
  self:update_filter_panel()
end

--- @param e on_gui_click
--- @param self Gui
function handlers.titlebar_flow(e, self)
  if e.button == defines.mouse_button_type.middle then
    self.refs.rb_main_window.force_auto_center()
  end
end

--- @param self Gui
function handlers.window_closed(_, self)
  if not self.state.pinned then
    if self.state.search_open then
      self:toggle_search()
      self.player.opened = self.refs.rb_main_window
    else
      self:hide()
    end
  end
end

libgui.add_handlers(handlers)

-- TEMPLATES

local templates = {}

local crafting_machine = {
  ["assembling-machine"] = true,
  ["furnace"] = true,
  ["rocket-silo"] = true,
}

function templates.base()
  local group_tabs, group_flows = templates.filter_pane()

  return {
    type = "frame",
    name = "rb_main_window",
    direction = "vertical",
    visible = false,
    handler = { [defines.events.on_gui_closed] = handlers.window_closed },
    {
      type = "flow",
      name = "titlebar_flow",
      style = "flib_titlebar_flow",
      handler = "titlebar_flow",
      templates.frame_action_button("nav_backward_button", "rb_nav_backward", { "gui.rb-nav-backward-instruction" }),
      templates.frame_action_button("nav_forward_button", "rb_nav_forward", { "gui.rb-nav-forward-instruction" }),
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
        handler = { [defines.events.on_gui_text_changed] = handlers.search_textfield },
      },
      templates.frame_action_button("search_button", "utility/search", { "gui.rb-search-instruction" }),
      templates.frame_action_button(
        "show_unresearched_button",
        "rb_show_unresearched",
        { "gui.rb-show-unresearched-instruction" }
      ),
      templates.frame_action_button("show_hidden_button", "rb_show_hidden", { "gui.rb-show-hidden-instruction" }),
      {
        type = "line",
        style_mods = { top_margin = -2, bottom_margin = 2 },
        direction = "vertical",
        ignored_by_interaction = true,
      },
      templates.frame_action_button("pin_button", "rb_pin", { "gui.rb-pin-instruction" }),
      templates.frame_action_button("close_button", "utility/close", { "gui.close-instruction" }),
    },
    {
      type = "flow",
      style_mods = { horizontal_spacing = 12 },
      {
        type = "frame",
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
              vertical_scroll_policy = "always",
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
        style_mods = { width = 500 },
        direction = "vertical",
        {
          type = "frame",
          style = "subheader_frame",
          {
            type = "sprite-button",
            name = "page_header_icon",
            style = "rb_small_transparent_slot",
            visible = false,
          },
          {
            type = "label",
            name = "page_header_label",
            style = "subheader_caption_label",
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
          name = "page_scroll",
          style = "flib_naked_scroll_pane",
          style_mods = { horizontally_stretchable = true, vertically_stretchable = true },
          vertical_scroll_policy = "always",
          {
            type = "label",
            style_mods = { horizontally_stretchable = true, single_line = false },
            caption = { "gui.rb-welcome-text" },
          },
        },
      },
    },
  }
end

--- @return GuiBuildStructure[] group_tabs
--- @return GuiBuildStructure[] group_flows
function templates.filter_pane()
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
      handler = handlers.filter_group_button,
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
          tooltip = { "gui.rb-prototype-tooltip", prototype.localised_name, path, prototype.localised_description },
          handler = handlers.prototype_button,
          -- TODO: Read the sprite instead?
          tags = { prototype = path },
        })
      end
    end
  end

  return group_tabs, group_flows
end

--- @param name string
--- @param sprite string
--- @param tooltip LocalisedString
--- @param handler GuiElemHandler?
function templates.frame_action_button(name, sprite, tooltip, handler)
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

--- @param caption LocalisedString
--- @param objects GenericObject[]
--- @param right_caption LocalisedString?
function templates.list_box(caption, objects, right_caption)
  local num_objects = #objects
  local rows = {}
  local i = 0
  local database = global.database
  for _, object in pairs(objects) do
    if
      not database[object.type .. "/" .. object.name]
      or util.is_hidden(game[object.type .. "_prototypes"][object.name])
    then
      num_objects = num_objects - 1
    else
      i = i + 1
      table.insert(
        rows,
        templates.prototype_button(
          game[object.type .. "_prototypes"][object.name],
          "rb_list_box_row_" .. (i % 2 == 0 and "even" or "odd"),
          object.amount or "",
          object.remark
        )
      )
    end
  end
  if num_objects == 0 then
    return {}
  end
  return {
    type = "flow",
    style_mods = { bottom_margin = 4 },
    direction = "vertical",
    {
      type = "flow",
      style = "centering_horizontal_flow",
      {
        type = "checkbox",
        style = "rb_list_box_caption",
        caption = { "", caption, " (", num_objects, ")" },
        state = false,
        handler = { [defines.events.on_gui_checked_state_changed] = handlers.collapse_list_box },
      },
      { type = "empty-widget", style = "flib_horizontal_pusher" },
      { type = "label", caption = right_caption },
    },
    {
      type = "frame",
      name = "list_frame",
      style = "deep_frame_in_shallow_frame",
      {
        type = "flow",
        style_mods = { vertical_spacing = 0 },
        direction = "vertical",
        children = rows,
      },
    },
  }
end

--- @param prototype GenericPrototype
--- @param style string
--- @param amount_caption LocalisedString?
--- @param remark_caption LocalisedString?
function templates.prototype_button(prototype, style, amount_caption, remark_caption)
  -- TODO: We actually need to get the group so we can show all the tooltips
  local path = util.get_path(prototype)
  local remark = {}
  if remark_caption then
    -- TODO: Add "remark" capability to API to eliminate this hack
    remark = {
      type = "label",
      style_mods = {
        width = 464 - 16,
        height = 36 - 8,
        horizontal_align = "right",
        vertical_align = "center",
      },
      caption = remark_caption,
      ignored_by_interaction = true,
    }
  end
  return {
    type = "sprite-button",
    style = style,
    -- TODO: Add icon_horizontal_align support to sprite-buttons
    -- sprite = object.type .. "/" .. object.name,
    caption = { "", "            ", amount_caption or "", prototype.localised_name },
    tooltip = { "gui.rb-prototype-tooltip", prototype.localised_name, path, prototype.localised_description },
    handler = handlers.prototype_button,
    tags = { prototype = path },
    {
      type = "sprite-button",
      style = "rb_small_transparent_slot",
      sprite = path,
      ignored_by_interaction = true,
    },
    remark,
  }
end

-- METHODS

--- @param self Gui
function gui.destroy(self)
  if self.refs.rb_main_window.valid then
    self.refs.rb_main_window.destroy()
  end
  self.player_table.gui = nil
end

--- @param self Gui
function gui.focus_search(self)
  self.refs.search_textfield.select_all()
  self.refs.search_textfield.focus()
end

--- @param self Gui
function gui.hide(self)
  self.refs.rb_main_window.visible = false
  if self.player.opened == self.refs.rb_main_window then
    self.player.opened = nil
  end
  self.player.set_shortcut_toggled("RecipeBook", false)
end

--- @param self Gui
--- @param group_name string
function gui.select_filter_group(self, group_name)
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

--- @param self Gui
function gui.show(self)
  self.refs.rb_main_window.visible = true
  self.refs.rb_main_window.bring_to_front()
  if not self.state.pinned then
    self.player.opened = self.refs.rb_main_window
    self.refs.rb_main_window.force_auto_center()
  end
  self.player.set_shortcut_toggled("RecipeBook", true)
end

--- @param self Gui
--- @param prototype_path string
--- @return boolean?
function gui.show_page(self, prototype_path)
  -- TODO: This currently redraws a page if you click a grouped item, then its recipe, etc
  -- Proper grouping of prototypes will fix this
  if self.state.current_page == prototype_path then
    return true
  end

  log("Updating page to " .. prototype_path)
  local group = global.database[prototype_path]
  if not group then
    log("Page was not found")
    return
  end

  local profiler = game.create_profiler()

  local sprite, localised_name
  -- TODO: Assemble info, THEN build the GUI
  local components = {}

  -- This will be common across all kinds of objects
  local unlocked_by = {}

  local types = {}

  local recipe = group.recipe
  if recipe then
    sprite = "recipe/" .. recipe.name
    localised_name = recipe.localised_name
    table.insert(types, "Recipe")

    table.insert(
      components,
      templates.list_box(
        "Ingredients",
        -- TODO: Handle amount ranges and probabilities
        libtable.map(recipe.ingredients, function(v)
          if v.amount then
            v.amount = { "", "[font=default-semibold]", v.amount, " ×[/font]  " }
          end
          return v
        end),
        {
          "",
          "[img=quantity-time] [font=default-semibold]",
          { "time-symbol-seconds", libmath.round(recipe.energy, 0.1) },
          "[/font] ",
          { "description.crafting-time" },
        }
      )
    )
    table.insert(
      components,
      templates.list_box(
        "Products",
        libtable.map(recipe.products, function(v)
          if v.amount then
            v.amount = { "", "[font=default-semibold]", v.amount, " ×[/font]  " }
          end
          return v
        end)
      )
    )

    local made_in = {}
    for _, crafter in
      pairs(game.get_filtered_entity_prototypes({
        { filter = "crafting-category", crafting_category = recipe.category },
      }))
    do
      if crafter.ingredient_count == 0 or crafter.ingredient_count >= #recipe.ingredients then
        table.insert(made_in, {
          type = "entity",
          name = crafter.name,
          remark = {
            "",
            "[img=quantity-time] ",
            { "time-symbol-seconds", libmath.round(recipe.energy / crafter.crafting_speed, 0.01) },
            " ",
          },
        })
      end
    end
    table.insert(components, templates.list_box("Made in", made_in))

    for _, technology in
      pairs(game.get_filtered_technology_prototypes({ { filter = "enabled" }, { filter = "has-effects" } }))
    do
      for _, effect in pairs(technology.effects) do
        if effect.type == "unlock-recipe" and effect.recipe == recipe.name then
          table.insert(unlocked_by, { type = "technology", name = technology.name })
        end
      end
    end
  end

  local fluid = group.fluid
  if fluid then
    sprite = sprite or ("fluid/" .. fluid.name)
    localised_name = localised_name or fluid.localised_name
    libtable.insert(types, "Fluid")

    local ingredient_in = {}
    for _, recipe in
      pairs(game.get_filtered_recipe_prototypes({
        { filter = "has-ingredient-fluid", elem_filters = { { filter = "name", name = fluid.name } } },
      }))
    do
      libtable.insert(ingredient_in, { type = "recipe", name = recipe.name })
    end
    libtable.insert(components, templates.list_box("Ingredient in", ingredient_in))

    local product_of = {}
    for _, recipe in
      pairs(game.get_filtered_recipe_prototypes({
        { filter = "has-product-fluid", elem_filters = { { filter = "name", name = fluid.name } } },
      }))
    do
      libtable.insert(product_of, { type = "recipe", name = recipe.name })
    end
    libtable.insert(components, templates.list_box("Product of", product_of))
  end

  local item = group.item
  if item then
    sprite = sprite or ("item/" .. item.name)
    localised_name = localised_name or item.localised_name
    libtable.insert(types, "Item")

    local ingredient_in = {}
    for _, recipe in
      pairs(game.get_filtered_recipe_prototypes({
        { filter = "has-ingredient-item", elem_filters = { { filter = "name", name = item.name } } },
      }))
    do
      libtable.insert(ingredient_in, { type = "recipe", name = recipe.name })
    end
    libtable.insert(components, templates.list_box("Ingredient in", ingredient_in))

    local product_of = {}
    for _, recipe in
      pairs(game.get_filtered_recipe_prototypes({
        { filter = "has-product-item", elem_filters = { { filter = "name", name = item.name } } },
      }))
    do
      libtable.insert(product_of, { type = "recipe", name = recipe.name })
    end
    if #product_of > 1 or not recipe then
      libtable.insert(components, templates.list_box("Product of", product_of))
    end
  end

  local entity = group.entity
  if entity then
    sprite = sprite or ("entity/" .. entity.name)
    localised_name = localised_name or entity.localised_name
    libtable.insert(types, "Entity")

    if crafting_machine[entity.type] then
      local filters = {}
      for category in pairs(entity.crafting_categories) do
        libtable.insert(filters, { filter = "category", category = category })
        libtable.insert(filters, { mode = "and", filter = "hidden-from-player-crafting", invert = true })
      end
      local can_craft = {}
      for _, recipe in pairs(game.get_filtered_recipe_prototypes(filters)) do
        if entity.ingredient_count == 0 or entity.ingredient_count >= #recipe.ingredients then
          libtable.insert(can_craft, { type = "recipe", name = recipe.name })
        end
      end
      libtable.insert(components, templates.list_box("Can craft", can_craft))
    elseif entity.type == "resource" then
      local required_fluid_str
      local required_fluid = entity.mineable_properties.required_fluid
      if required_fluid then
        required_fluid_str = {
          "",
          "Requires:  ",
          "[img=fluid/" .. required_fluid .. "] ",
          game.fluid_prototypes[required_fluid].localised_name,
        }
      end
      local resource_category = entity.resource_category
      local mined_by = {}
      for _, entity in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "mining-drill" } })) do
        if entity.resource_categories[resource_category] and (not required_fluid or entity.fluidbox_prototypes[1]) then
          libtable.insert(mined_by, { type = "entity", name = entity.name })
        end
      end
      libtable.insert(components, templates.list_box("Mined by", mined_by, required_fluid_str))

      local mineable = entity.mineable_properties
      if mineable.minable and #mineable.products > 0 then
        libtable.insert(components, templates.list_box("Mining products", mineable.products))
      end
    elseif entity.type == "mining-drill" then
      local categories = entity.resource_categories --[[@as table<string, _>]]
      -- TODO: Fluid filters?
      local supports_fluid = entity.fluidbox_prototypes[1] and true or false
      local can_mine = {}
      for _, resource in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "resource" } })) do
        if
          categories[resource.resource_category] and (supports_fluid or not resource.mineable_properties.required_fluid)
        then
          table.insert(can_mine, { type = "entity", name = resource.name })
        end
      end
      table.insert(components, templates.list_box("Can mine", can_mine))
    end
  end

  if #unlocked_by > 0 then
    libtable.insert(components, templates.list_box("Unlocked by", unlocked_by))
  end

  profiler.stop()
  log({ "", "Build Info ", profiler })
  profiler.reset()

  self.refs.page_header_icon.sprite = sprite
  self.refs.page_header_icon.visible = true
  self.refs.page_header_label.caption = localised_name
  self.refs.page_header_type_label.caption = libtable.concat(types, "/")

  local page_scroll = self.refs.page_scroll
  page_scroll.clear()
  libgui.add(page_scroll, components)

  profiler.stop()
  log({ "", "Build GUI ", profiler })

  self.state.current_page = prototype_path

  self.refs.page_scroll.scroll_to_top()
  if not self.refs.rb_main_window.visible then
    self:show()
  end
  return true
end

--- @param self Gui
function gui.toggle(self)
  if self.refs.rb_main_window.visible then
    self:hide()
  else
    self:show()
  end
end

--- @param self Gui
function gui.toggle_pinned(self)
  self.state.pinned = not self.state.pinned
  if self.state.pinned then
    self.refs.pin_button.style = "flib_selected_frame_action_button"
    self.refs.pin_button.sprite = "rb_pin_black"
    self.refs.close_button.tooltip = { "gui.close" }
    self.refs.search_button.tooltip = { "gui.search" }
    if self.player.opened == self.refs.rb_main_window then
      self.player.opened = nil
    end
  else
    self.refs.pin_button.style = "frame_action_button"
    self.refs.pin_button.sprite = "rb_pin_white"
    self.player.opened = self.refs.rb_main_window
    self.refs.rb_main_window.force_auto_center()
    self.refs.close_button.tooltip = { "gui.close-instruction" }
    self.refs.search_button.tooltip = { "gui.rb-search-instruction" }
  end
end

--- @param self Gui
function gui.toggle_search(self)
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
-- --- @param self Gui
function gui.update_filter_panel(self)
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

--- @param self Gui
function gui.update_translation_warning(self)
  self.refs.filter_warning_frame.visible = not self.player_table.search_strings
end

-- BOOTSTRAP

--- @param player LuaPlayer
--- @param player_table PlayerTable
--- @return Gui
function gui.new(player, player_table)
  local refs = libgui.add(player.gui.screen, { templates.base() })

  refs.titlebar_flow.drag_target = refs.rb_main_window
  refs.rb_main_window.force_auto_center()

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
  setmetatable(self, gui_mt)
  player_table.gui = self

  self:select_filter_group(self.state.selected_filter_group)
  self:update_filter_panel()
  self:update_translation_warning()

  return self
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

--- Get the player's GUI or create it if it does not exist
function gui.get(player)
  local player_table = global.players[player.index]
  if player_table then
    local pgui = player_table.gui
    if pgui and pgui.refs.rb_main_window.valid then
      return pgui
    else
      if pgui then
        pgui:destroy()
        player.print({ "message.rb-recreated-gui" })
      end
      pgui = gui.new(player, player_table)
      return pgui
    end
  end
end

--- @param e GuiEventData
libgui.dispatch_wrapper = function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  return gui.get(player)
end

gui.handle_events = libgui.handle_events

return gui
