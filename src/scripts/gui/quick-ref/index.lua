local gui = require("__flib__.gui")

local constants = require("constants")

local formatter = require("scripts.formatter")
local recipe_book = require("scripts.recipe-book")
local shared = require("scripts.shared")
local util = require("scripts.util")

local function quick_ref_panel(ref)
  return {
    type = "flow",
    direction = "vertical",
    ref = { ref, "flow" },
    { type = "label", style = "rb_list_box_label", ref = { ref, "label" } },
    {
      type = "frame",
      style = "rb_slot_table_frame",
      ref = { ref, "frame" },
      { type = "table", style = "slot_table", column_count = 5, ref = { ref, "table" } },
    },
  }
end

--- @class QuickRefGuiRefs
--- @field window LuaGuiElement
--- @field titlebar_flow LuaGuiElement
--- @field label LuaGuiElement

--- @class QuickRefGui
local Gui = {}

local actions = require("actions")

function Gui:dispatch(msg, e)
  if type(msg) == "string" then
    actions[msg](self, msg, e)
  else
    actions[msg.action](self, msg, e)
  end
end

function Gui:destroy()
  self.refs.window.destroy()
  self.player_table.guis.quick_ref[self.recipe_name] = nil
  -- FIXME: Remove this
  shared.update_header_button(
    self.player,
    self.player_table,
    { class = "recipe", name = self.recipe_name },
    "quick_ref_button",
    false
  )
end

function Gui:update_contents()
  local refs = self.refs

  local show_made_in = self.player_table.settings.general.content.show_made_in_in_quick_ref

  local recipe_data = recipe_book.recipe[self.recipe_name]
  local player_data = formatter.build_player_data(self.player, self.player_table)

  -- Label
  local recipe_info = formatter(recipe_data, player_data, { always_show = true, is_label = true })
  local label = refs.label
  label.caption = recipe_info.caption
  label.tooltip = recipe_info.tooltip
  label.style = recipe_info.researched and "rb_toolbar_label" or "rb_unresearched_toolbar_label"

  -- Slot boxes
  for _, source in ipairs({ "ingredients", "products", "made_in" }) do
    local box = refs[source]

    if source == "made_in" and not show_made_in then
      box.flow.visible = false
      break
    else
      box.flow.visible = true
    end

    local blueprint_recipe = source == "made_in" and self.recipe_name or nil

    local table = box.table
    local buttons = table.children
    local i = 0
    for _, object in pairs(recipe_data[source]) do
      local object_data = recipe_book[object.class][object.name]
      local object_info = formatter(object_data, player_data, {
        amount_ident = object.amount_ident,
        amount_only = true,
        always_show = source ~= "made_in",
        blueprint_recipe = blueprint_recipe,
      })
      if object_info then
        i = i + 1

        local button_style = object_info.researched and "flib_slot_button_default" or "flib_slot_button_red"

        local button = buttons[i]

        if button and button.valid then
          button.style = button_style
          button.sprite = constants.class_to_type[object.class] .. "/" .. object_data.prototype_name
          button.tooltip = object_info.tooltip
          gui.update_tags(button, {
            blueprint_recipe = blueprint_recipe,
            context = object,
            researched = object_data.researched,
          })
        else
          local probability = object.amount_ident.probability
          if probability == 1 then
            probability = false
          end
          gui.build(table, {
            {
              type = "sprite-button",
              style = button_style,
              sprite = constants.class_to_type[object.class] .. "/" .. object_data.prototype_name,
              tooltip = object_info.tooltip,
              tags = {
                blueprint_recipe = blueprint_recipe,
                context = object,
                researched = object_data.researched,
              },
              actions = {
                on_click = {
                  gui = "quick_ref",
                  id = self.recipe_name,
                  action = "handle_button_click",
                  source = source,
                },
              },
              {
                type = "label",
                style = "rb_slot_label",
                caption = object_info.caption,
                ignored_by_interaction = true,
              },
              {
                type = "label",
                style = "rb_slot_label_top",
                caption = probability and "%" or "",
                ignored_by_interaction = true,
              },
            },
          })
        end
      end
      for j = i + 1, #buttons do
        buttons[j].destroy()
      end

      -- Label
      box.label.caption = { "gui.rb-list-box-label", { "gui.rb-" .. string.gsub(source, "_", "-") }, i }
    end
  end
end

local index = {}

function index.build(player, player_table, recipe_name, window_location)
  --- @type QuickRefGuiRefs
  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      direction = "vertical",
      ref = { "window" },
      {
        type = "flow",
        style = "flib_titlebar_flow",
        ref = { "titlebar_flow" },
        actions = {
          on_click = { gui = "quick_ref", id = recipe_name, action = "reset_location" },
        },
        { type = "label", style = "frame_title", caption = { "gui.rb-recipe" }, ignored_by_interaction = true },
        { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
        util.frame_action_button(
          "rb_expand",
          { "gui.rb-view-details" },
          nil,
          { gui = "quick_ref", id = recipe_name, action = "view_details" }
        ),
        util.frame_action_button(
          "utility/close",
          { "gui.close" },
          nil,
          { gui = "quick_ref", id = recipe_name, action = "close" }
        ),
      },
      {
        type = "frame",
        style = "rb_quick_ref_content_frame",
        direction = "vertical",
        {
          type = "frame",
          style = "subheader_frame",
          { type = "label", style = "rb_toolbar_label", ref = { "label" } },
          { type = "empty-widget", style = "flib_horizontal_pusher" },
        },
        {
          type = "flow",
          style = "rb_quick_ref_content_flow",
          direction = "vertical",
          quick_ref_panel("ingredients"),
          quick_ref_panel("products"),
          quick_ref_panel("made_in"),
        },
      },
    },
  })

  if window_location then
    refs.window.location = window_location
  end

  refs.titlebar_flow.drag_target = refs.window

  --- @type QuickRefGui
  local self = {
    player = player,
    player_table = player_table,
    recipe_name = recipe_name,
    refs = refs,
  }
  index.load(self)
  player_table.guis.quick_ref[recipe_name] = self

  self:update_contents()
end

function index.load(self)
  setmetatable(self, { __index = Gui })
end

return index
