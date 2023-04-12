local flib_dictionary = require("__flib__/dictionary-lite")
local flib_gui = require("__flib__/gui-lite")

local util = require("__RecipeBookLite__/util")

local search_columns = 13
local main_panel_width = 40 * search_columns + 12
local materials_column_width = (main_panel_width - (12 * 3)) / 2

--- @alias ContextType
--- | "ingredient"
--- | "product"

-- These are needed in update_info_page
local on_prototype_button_clicked
local on_prototype_button_hovered

--- @param self GuiData
local function update_search_results(self)
  local query = self.search_query
  local show_hidden = self.show_hidden
  local dictionary = flib_dictionary.get(self.player.index, "search") or {}
  for _, button in pairs(self.elems.search_table.children) do
    if show_hidden or not button.tags.is_hidden then
      local search_key = dictionary[button.sprite] or button.name
      button.visible = not not string.find(string.lower(search_key), query, nil, true)
    else
      button.visible = false
    end
  end
end

--- @param self GuiData
local function update_info_page(self)
  local recipe = self.recipes[self.index]

  self.elems.info_recipe_count_label.caption = "[" .. self.index .. "/" .. #self.recipes .. "]"
  self.elems.info_context_label.sprite = self.context
  self.elems.info_context_label.caption =
    { "", "            ", self.context_type == "product" and { "gui.rbl-product-of" } or { "gui.rbl-ingredient-in" } }
  self.elems.info_context_label.tooltip = ""
  self.elems.info_recipe_name_label.sprite = "recipe/" .. recipe.name
  self.elems.info_recipe_name_label.caption = { "", "            ", recipe.localised_name }
  self.elems.info_recipe_name_label.tooltip = ""

  local ingredients_frame = self.elems.info_ingredients_frame
  ingredients_frame.clear()
  local item_ingredients = 0
  for _, ingredient in pairs(recipe.ingredients) do
    if ingredient.type == "item" then
      item_ingredients = item_ingredients + 1
    end
    flib_gui.add(ingredients_frame, {
      type = "sprite-button",
      style = "rbl_list_box_item",
      sprite = ingredient.type .. "/" .. ingredient.name,
      caption = util.build_caption(ingredient),
      raise_hover_events = true,
      handler = {
        [defines.events.on_gui_click] = on_prototype_button_clicked,
        [defines.events.on_gui_hover] = on_prototype_button_hovered,
      },
    })
  end
  self.elems.info_ingredients_count_label.caption = "[" .. #recipe.ingredients .. "]"
  self.elems.info_ingredients_energy_label.caption = "[img=quantity-time] " .. util.format_number(recipe.energy) .. " s"

  local products_frame = self.elems.info_products_frame
  products_frame.clear()
  for _, product in pairs(recipe.products) do
    flib_gui.add(products_frame, {
      type = "sprite-button",
      style = "rbl_list_box_item",
      sprite = product.type .. "/" .. product.name,
      caption = util.build_caption(product),
      raise_hover_events = true,
      handler = {
        [defines.events.on_gui_click] = on_prototype_button_clicked,
        [defines.events.on_gui_hover] = on_prototype_button_hovered,
      },
    })
  end
  self.elems.info_products_count_label.caption = "[" .. #recipe.products .. "]"

  local made_in_frame = self.elems.info_made_in_frame
  made_in_frame.clear()
  if util.is_hand_craftable(recipe) then
    flib_gui.add(made_in_frame, {
      type = "sprite-button",
      style = "slot_button",
      sprite = "utility/hand",
      hovered_sprite = "utility/hand_black",
      clicked_sprite = "utility/hand_black",
      number = recipe.energy,
      tooltip = { "gui.rbl-handcraft" },
    })
  end
  for _, machine in
    pairs(game.get_filtered_entity_prototypes({
      { filter = "crafting-category", crafting_category = recipe.category },
    }))
  do
    local ingredient_count = machine.ingredient_count
    if ingredient_count == 0 or ingredient_count >= item_ingredients then
      flib_gui.add(made_in_frame, {
        type = "sprite-button",
        style = "slot_button",
        sprite = "entity/" .. machine.name,
        number = recipe.energy / machine.crafting_speed,
        raise_hover_events = true,
        handler = {
          [defines.events.on_gui_click] = on_prototype_button_clicked,
          [defines.events.on_gui_hover] = on_prototype_button_hovered,
        },
      })
    end
  end

  local unlocked_by_frame = self.elems.info_unlocked_by_frame
  unlocked_by_frame.clear()
  for _, technology in
    pairs(game.get_filtered_technology_prototypes({ { filter = "unlocks-recipe", recipe = recipe.name } }))
  do
    flib_gui.add(unlocked_by_frame, {
      type = "sprite-button",
      style = "slot_button",
      sprite = "technology/" .. technology.name,
      raise_hover_events = true,
      handler = {
        [defines.events.on_gui_click] = on_prototype_button_clicked,
        [defines.events.on_gui_hover] = on_prototype_button_hovered,
      },
    })
  end
  self.elems.info_unlocked_by_flow.visible = #unlocked_by_frame.children > 0
end

--- @param e EventData.on_gui_text_changed
local function on_search_textfield_changed(e)
  local self = global.gui[e.player_index]
  self.search_query = string.lower(e.text)
  update_search_results(self)
end

--- @param e EventData.on_gui_click
on_prototype_button_clicked = function(e)
  local result = e.element.sprite
  local result_type, result_name = string.match(result, "(.-)/(.*)")
  if result_type == "entity" then
    result_name = util.get_item_to_place(result_name)
    result_type = "item"
  end
  if not result_name then
    return
  end
  local self = global.gui[e.player_index]
  if result_type == "technology" then
    self.player.open_technology_gui(result_name)
    return
  end
  self.context_type = e.button == defines.mouse_button_type.left and "product" or "ingredient"

  local recipes = game.get_filtered_recipe_prototypes({
    {
      filter = "has-" .. self.context_type .. "-" .. result_type,
      elem_filters = {
        { filter = "name", name = result_name },
      },
    },
  })
  local recipes_array = {}
  for _, recipe in pairs(recipes) do
    recipes_array[#recipes_array + 1] = recipe
  end
  if not next(recipes_array) then
    self.player.create_local_flying_text({ text = "No recipes to display", create_at_cursor = true })
    self.player.play_sound({ path = "utility/cannot_build" })
    return
  end

  self.recipes = recipes_array
  self.index = 1

  self.elems.search_pane.visible = false
  self.elems.info_pane.visible = true
  self.elems.nav_backward_button.visible = true
  self.context = result

  update_info_page(self)
end

on_prototype_button_hovered = function(e)
  local elem = e.element
  if elem.tooltip ~= "" then
    return
  end
  --- @type string, string
  local type, name = string.match(elem.sprite, "(.-)/(.*)")
  elem.tooltip = util.build_tooltip(global.gui[e.player_index].player, type, name)
end

--- @param self GuiData
local function return_to_search(self)
  self.elems.nav_backward_button.visible = false
  self.elems.info_pane.visible = false
  self.elems.search_pane.visible = true
  if self.player.mod_settings["rbl-auto-focus-search-box"].value then
    self.elems.search_textfield.focus()
    self.elems.search_textfield.select_all()
  end
end

--- @param self GuiData
local function show_gui(self)
  self.player.set_shortcut_toggled("rbl-toggle-gui", true)
  local window = self.elems.rbl_main_window
  window.visible = true
  if not self.pinned then
    self.player.opened = window
  end
  if self.player.mod_settings["rbl-always-open-search"].value then
    return_to_search(self)
  end
end

--- @param self GuiData
local function hide_gui(self)
  self.player.set_shortcut_toggled("rbl-toggle-gui", false)
  local window = self.elems.rbl_main_window
  window.visible = false
  if self.player.opened == window then
    self.player.opened = nil
  end
  self.player.set_shortcut_toggled("rbl-toggle-gui", false)
end

--- @param e EventData.on_gui_closed
local function on_main_window_closed(e)
  local self = global.gui[e.player_index]
  if self.pinned then
    return
  end
  hide_gui(self)
end

--- @param e EventData.on_gui_click
local function on_close_button_clicked(e)
  local self = global.gui[e.player_index]
  hide_gui(self)
end

--- @param e EventData.on_gui_click
local function on_pin_button_clicked(e)
  local self = global.gui[e.player_index]
  self.pinned = not self.pinned
  if self.pinned then
    self.player.opened = nil
    e.element.style = "flib_selected_frame_action_button"
    e.element.sprite = "flib_pin_black"
    self.elems.close_button.tooltip = { "gui.close" }
  else
    self.player.opened = self.elems.rbl_main_window
    self.elems.rbl_main_window.force_auto_center()
    e.element.style = "frame_action_button"
    e.element.sprite = "flib_pin_white"
    self.elems.close_button.tooltip = { "gui.close-instruction" }
  end
end

--- @param e EventData.on_gui_click
local function on_show_hidden_clicked(e)
  local self = global.gui[e.player_index]
  self.show_hidden = not self.show_hidden
  e.element.style = self.show_hidden and "flib_selected_frame_action_button" or "frame_action_button"
  e.element.sprite = self.show_hidden and "rbl_show_hidden_black" or "rbl_show_hidden_white"
  update_search_results(self)
  -- TODO: Update context list
end

--- @param e EventData.on_gui_click
local function on_nav_backward_clicked(e)
  local self = global.gui[e.player_index]
  return_to_search(self)
end

--- @param e EventData.on_gui_click
local function on_recipe_nav_clicked(e)
  local self = global.gui[e.player_index]
  self.index = self.index + e.element.tags.nav_offset
  if self.index == 0 then
    self.index = #self.recipes --[[@as uint]]
  elseif self.index > #self.recipes then
    self.index = 1
  end
  update_info_page(self)
end

--- @param player LuaPlayer
--- @return GuiData
local function create_gui(player)
  local buttons = {}
  for _, item in pairs(game.item_prototypes) do
    local is_hidden = item.has_flag("hidden")
    table.insert(buttons, {
      type = "sprite-button",
      style = is_hidden and "flib_slot_button_grey" or "slot_button",
      sprite = "item/" .. item.name,
      visible = not is_hidden,
      tags = { is_hidden = is_hidden },
      raise_hover_events = true,
      handler = {
        [defines.events.on_gui_click] = on_prototype_button_clicked,
        [defines.events.on_gui_hover] = on_prototype_button_hovered,
      },
    })
  end
  for _, fluid in pairs(game.fluid_prototypes) do
    local is_hidden = fluid.hidden
    table.insert(buttons, {
      type = "sprite-button",
      style = is_hidden and "flib_slot_button_grey" or "slot_button",
      sprite = "fluid/" .. fluid.name,
      visible = not is_hidden,
      tags = { is_hidden = is_hidden },
      raise_hover_events = true,
      handler = {
        [defines.events.on_gui_click] = on_prototype_button_clicked,
        [defines.events.on_gui_hover] = on_prototype_button_hovered,
      },
    })
  end
  local elems = flib_gui.add(player.gui.screen, {
    type = "frame",
    name = "rbl_main_window",
    direction = "vertical",
    elem_mods = { auto_center = true },
    visible = false,
    handler = { [defines.events.on_gui_closed] = on_main_window_closed },
    {
      type = "flow",
      style = "flib_titlebar_flow",
      drag_target = "rbl_main_window",
      {
        type = "label",
        style = "frame_title",
        caption = { "mod-name.RecipeBookLite" },
        ignored_by_interaction = true,
      },
      { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
      {
        type = "sprite-button",
        name = "nav_backward_button",
        style = "frame_action_button",
        sprite = "rbl_nav_backward_white",
        hovered_sprite = "rbl_nav_backward_black",
        clicked_sprite = "rbl_nav_backward_black",
        tooltip = { "gui.rbl-go-back" },
        visible = false,
        handler = on_nav_backward_clicked,
      },
      {
        type = "sprite-button",
        name = "show_hidden_button",
        style = "frame_action_button",
        sprite = "rbl_show_hidden_white",
        hovered_sprite = "rbl_show_hidden_black",
        clicked_sprite = "rbl_show_hidden_black",
        tooltip = { "gui.rbl-show-hidden" },
        handler = on_show_hidden_clicked,
      },
      {
        type = "sprite-button",
        name = "pin_button",
        style = "frame_action_button",
        sprite = "flib_pin_white",
        hovered_sprite = "flib_pin_black",
        clicked_sprite = "flib_pin_black",
        tooltip = { "gui.flib-keep-open" },
        handler = on_pin_button_clicked,
      },
      {
        type = "sprite-button",
        name = "close_button",
        style = "frame_action_button",
        sprite = "utility/close_white",
        hovered_sprite = "utility/close_black",
        clicked_sprite = "utility/close_black",
        tooltip = { "gui.close-instruction" },
        handler = on_close_button_clicked,
      },
    },
    {
      type = "frame",
      name = "search_pane",
      style = "inside_deep_frame",
      direction = "vertical",
      {
        type = "frame",
        style = "subheader_frame",
        style_mods = { horizontally_stretchable = true },
        { type = "label", style = "subheader_caption_label", caption = { "gui.rbl-search" } },
        { type = "empty-widget", style = "flib_horizontal_pusher" },
        {
          type = "textfield",
          name = "search_textfield",
          lose_focus_on_confirm = true,
          clear_and_focus_on_right_click = true,
          handler = { [defines.events.on_gui_text_changed] = on_search_textfield_changed },
        },
      },
      {
        type = "scroll-pane",
        style = "flib_naked_scroll_pane_no_padding",
        style_mods = { maximal_height = main_panel_width, width = main_panel_width },
        {
          type = "table",
          name = "search_table",
          style = "slot_table",
          column_count = search_columns,
          children = buttons,
        },
      },
    },
    {
      type = "frame",
      name = "info_pane",
      style = "inside_shallow_frame",
      style_mods = { width = main_panel_width },
      direction = "vertical",
      visible = false,
      {
        type = "frame",
        style = "subheader_frame",
        style_mods = { horizontally_stretchable = true },
        {
          type = "sprite-button",
          name = "info_recipe_name_label",
          style = "rbl_subheader_caption_button",
          style_mods = { horizontally_squashable = true },
          enabled = false,
          raise_hover_events = true,
          handler = { [defines.events.on_gui_hover] = on_prototype_button_hovered },
        },
        { type = "empty-widget", style = "flib_horizontal_pusher" },
        {
          type = "sprite-button",
          name = "info_context_label",
          style = "rbl_subheader_caption_button",
          enabled = false,
          raise_hover_events = true,
          handler = { [defines.events.on_gui_hover] = on_prototype_button_hovered },
        },
        {
          type = "label",
          name = "info_recipe_count_label",
          style = "info_label",
          style_mods = {
            font = "default-semibold",
            right_margin = 4,
            single_line = true,
            horizontally_squashable = false,
          },
        },
        {
          type = "sprite-button",
          style = "tool_button",
          style_mods = { padding = 0, size = 24, top_margin = 1 },
          sprite = "rbl_nav_backward_black",
          tooltip = "Previous recipe",
          tags = { nav_offset = -1 },
          handler = on_recipe_nav_clicked,
        },
        {
          type = "sprite-button",
          style = "tool_button",
          style_mods = { padding = 0, size = 24, top_margin = 1, right_margin = 4 },
          sprite = "rbl_nav_forward_black",
          tooltip = "Next recipe",
          tags = { nav_offset = 1 },
          handler = on_recipe_nav_clicked,
        },
      },
      {
        type = "flow",
        style_mods = { padding = 12, top_padding = 8, vertical_spacing = 12 },
        direction = "vertical",
        {
          type = "flow",
          style_mods = { horizontal_spacing = 12 },
          {
            type = "flow",
            style_mods = { width = materials_column_width },
            direction = "vertical",
            {
              type = "flow",
              { type = "label", style = "caption_label", caption = { "gui.rbl-ingredients" } },
              {
                type = "label",
                name = "info_ingredients_count_label",
                style = "info_label",
                style_mods = { font = "default-semibold" },
              },
              { type = "empty-widget", style = "flib_horizontal_pusher" },
              { type = "label", name = "info_ingredients_energy_label", style_mods = { font = "default-semibold" } },
            },
            {
              type = "frame",
              name = "info_ingredients_frame",
              style = "deep_frame_in_shallow_frame",
              style_mods = { width = materials_column_width, minimal_height = 1 },
              direction = "vertical",
            },
          },
          {
            type = "flow",
            style_mods = { width = materials_column_width },
            direction = "vertical",
            {
              type = "flow",
              { type = "label", style = "caption_label", caption = { "gui.rbl-products" } },
              {
                type = "label",
                name = "info_products_count_label",
                style = "info_label",
                style_mods = { font = "default-semibold" },
              },
            },
            {
              type = "frame",
              name = "info_products_frame",
              style = "deep_frame_in_shallow_frame",
              style_mods = { width = materials_column_width, minimal_height = 1 },
              direction = "vertical",
            },
          },
        },
        {
          type = "flow",
          style_mods = { vertical_align = "center", horizontal_spacing = 12 },
          { type = "label", style = "caption_label", caption = { "gui.rbl-made-in" } },
          {
            type = "frame",
            style = "slot_button_deep_frame",
            { type = "table", name = "info_made_in_frame", style = "slot_table", column_count = 11 },
          },
        },
        {
          type = "flow",
          name = "info_unlocked_by_flow",
          style_mods = { vertical_align = "center", horizontal_spacing = 12 },
          { type = "label", style = "caption_label", caption = { "gui.rbl-unlocked-by" } },
          {
            type = "frame",
            style = "slot_button_deep_frame",
            { type = "table", name = "info_unlocked_by_frame", style = "slot_table", column_count = 11 },
          },
        },
      },
    },
  })

  --- @class GuiData
  local self = {
    --- @type string?
    context = nil,
    --- @type ContextType
    context_type = "product",
    elems = elems,
    --- @type uint
    index = 1,
    pinned = false,
    player = player,
    --- @type LuaRecipePrototype[]?
    recipes = nil,
    search_query = "",
    show_hidden = false,
  }
  global.gui[player.index] = self
  return self
end

--- @param e EventData.on_player_created
local function on_player_created(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  create_gui(player)
end

--- @param e EventData.CustomInputEvent|EventData.on_lua_shortcut
local function on_gui_toggle(e)
  if e.prototype_name and e.prototype_name ~= "rbl-toggle-gui" then
    return
  end
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  local self = global.gui[e.player_index]
  if not self then
    self = create_gui(player)
  end
  if self.elems.rbl_main_window.visible then
    hide_gui(self)
  else
    show_gui(self)
  end
end

local gui = {}

gui.on_init = function()
  --- @type table<uint, GuiData>
  global.gui = {}
  util.build_dictionaries()
end
gui.on_configuration_changed = util.build_dictionaries

gui.events = {
  [defines.events.on_lua_shortcut] = on_gui_toggle,
  [defines.events.on_player_created] = on_player_created,
  ["rbl-toggle-gui"] = on_gui_toggle,
}

flib_gui.add_handlers({
  on_close_button_clicked = on_close_button_clicked,
  on_main_window_closed = on_main_window_closed,
  on_nav_backward_clicked = on_nav_backward_clicked,
  on_pin_button_clicked = on_pin_button_clicked,
  on_prototype_button_clicked = on_prototype_button_clicked,
  on_prototype_button_hovered = on_prototype_button_hovered,
  on_recipe_nav_clicked = on_recipe_nav_clicked,
  on_search_textfield_changed = on_search_textfield_changed,
  on_show_hidden_clicked = on_show_hidden_clicked,
})

return gui
