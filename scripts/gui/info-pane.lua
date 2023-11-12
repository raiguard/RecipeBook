local database = require("__RecipeBook__/scripts/database")
local gui_util = require("__RecipeBook__/scripts/gui/util")
local list_box = require("__RecipeBook__/scripts/gui/list-box")
local slot_table = require("__RecipeBook__/scripts/gui/slot-table")
local technology_slot_table = require("__RecipeBook__/scripts/gui/technology-slot-table")
local util = require("__RecipeBook__/scripts/util")

--- @class InfoPane
--- @field context MainGuiContext
--- @field title_label LuaGuiElement
--- @field type_label LuaGuiElement
--- @field content_pane LuaGuiElement
local info_pane = {}
local mt = { __index = info_pane }
script.register_metatable("info_pane", mt)

--- @param parent LuaGuiElement
--- @param context MainGuiContext
function info_pane.build(parent, context)
  local frame = parent.add({
    type = "frame",
    style = "inside_shallow_frame",
    direction = "vertical",
  })
  frame.style.width = (40 * 10) + 24 + 12

  local subheader = frame.add({ type = "frame", style = "subheader_frame" })
  local title_label = subheader.add({
    type = "sprite-button",
    name = "page_header_title",
    style = "rb_subheader_caption_button",
    enabled = false,
    caption = { "gui.rb-welcome-title" },
  })
  subheader.add({ type = "empty-widget", style = "flib_horizontal_pusher" })
  local type_label = subheader.add({
    type = "label",
    name = "page_header_type_label",
    style = "rb_info_label",
  })
  type_label.style.right_margin = 8

  local content_pane = frame.add({
    type = "scroll-pane",
    style = "flib_naked_scroll_pane",
    horizontal_scroll_policy = "never",
    vertical_scroll_policy = "always",
  })
  -- content_pane.style.top_padding = 8
  content_pane.style.horizontally_stretchable = true
  content_pane.style.vertically_stretchable = true

  -- Will be deleted when the first page is shown
  content_pane.add({
    type = "label",
    name = "welcome_label",
    caption = { "gui.rb-welcome-text" },
  }).style.single_line =
    false

  local self = {
    context = context,
    title_label = title_label,
    type_label = type_label,
    content_pane = content_pane,
  }
  setmetatable(self, mt)
  return self
end

--- @param path string
--- @return boolean? updated
function info_pane:show(path)
  local path = database.get_base_path(path)
  if not path then
    return
  end

  local properties = database.get_properties(path, self.context.player.force.index)
  if not properties then
    return
  end
  local entry = properties.entry

  local profiler = game.create_profiler()

  -- Subheader
  local title_label = self.title_label
  title_label.caption = { "", "            ", entry.base.localised_name }
  title_label.sprite = entry.base_path
  local style = "rb_subheader_caption_button"
  if util.is_hidden(entry.base) then
    style = "rb_subheader_caption_button_hidden"
  elseif util.is_unresearched(entry, self.context.player.force.index) then
    style = "rb_subheader_caption_button_unresearched"
  end
  title_label.style = style
  title_label.style.horizontally_squashable = true
  local type_label = self.type_label
  --- @type LocalisedString
  local type_caption = { "" }
  for _, key in pairs({ "recipe", "item", "fluid", "equipment", "entity" }) do
    local prototype = entry[key]
    if prototype then
      type_caption[#type_caption + 1] = gui_util.type_locale[prototype.object_name]
      type_caption[#type_caption + 1] = "/"
    end
  end
  type_caption[#type_caption] = nil
  type_label.caption = type_caption

  -- Contents

  local content_pane = self.content_pane
  content_pane.clear()
  content_pane.scroll_to_top()
  if content_pane.welcome_label then
    content_pane.welcome_label.destroy()
  end

  -- FIXME: Separate descriptions
  local description = { "?" }
  for _, key in pairs({ "recipe", "item", "fluid", "entity" }) do
    local prototype = entry[key]
    if prototype and prototype.localised_description then
      description[#description + 1] = prototype.localised_description
    end
  end
  description[#description + 1] = ""
  local description_frame =
    content_pane.add({ type = "frame", style = "deep_frame_in_shallow_frame", horizontal_scroll_policy = "never" })
  description_frame.style.horizontally_stretchable = true
  local description_label = description_frame.add({ type = "label", caption = description })
  description_label.style.padding = 8
  description_label.style.single_line = false

  list_box.build(
    content_pane,
    self.context,
    { "description.ingredients" },
    properties.ingredients,
    gui_util.format_crafting_time(properties.crafting_time)
  )
  list_box.build(content_pane, self.context, { "description.products" }, properties.products)
  slot_table.build(content_pane, self.context, { "description.made-in" }, properties.made_in)
  slot_table.build(content_pane, self.context, { "description.rb-ingredient-in" }, properties.ingredient_in)
  slot_table.build(content_pane, self.context, { "description.rb-product-of" }, properties.product_of)
  slot_table.build(content_pane, self.context, { "description.rb-can-craft" }, properties.can_craft)
  list_box.build(content_pane, self.context, { "description.rb-yields" }, properties.yields)
  slot_table.build(content_pane, self.context, { "description.rb-mined-by" }, properties.mined_by)
  slot_table.build(content_pane, self.context, { "description.rb-can-mine" }, properties.can_mine)
  slot_table.build(content_pane, self.context, { "description.rb-burned-in" }, properties.burned_in)
  slot_table.build(content_pane, self.context, { "description.rb-gathered-from" }, properties.gathered_from)
  slot_table.build(content_pane, self.context, { "description.rb-can-burn" }, properties.can_burn)
  slot_table.build(
    content_pane,
    self.context,
    { "description.rocket-launch-products" },
    properties.rocket_launch_products
  )
  slot_table.build(
    content_pane,
    self.context,
    { "description.rb-rocket-launch-product-of" },
    properties.rocket_launch_product_of
  )
  slot_table.build(content_pane, self.context, { "description.rb-placeable-by" }, properties.placeable_by)
  technology_slot_table.build(content_pane, self.context, { "description.rb-unlocked-by" }, properties.unlocked_by)

  profiler.stop()
  log({ "", "[", path, "] GUI update ", profiler })

  return true
end

return info_pane
