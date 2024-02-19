local flib_dictionary = require("__flib__.dictionary-lite")
local flib_gui = require("__flib__.gui-lite")
local flib_gui_templates = require("__flib__.gui-templates")
local flib_technology = require("__flib__.technology")

local gui_util = require("scripts.gui.util")
local info_description = require("scripts.gui.info-description")
local info_section = require("scripts.gui.info-section")

--- @class InfoPane
--- @field context MainGuiContext
--- @field title_label LuaGuiElement
--- @field type_label LuaGuiElement
--- @field content_pane LuaGuiElement
local info_pane = {}
local mt = { __index = info_pane }
script.register_metatable("info_pane", mt)

--- @type function?
info_pane.on_result_clicked = nil

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
    style = "rb_info_scroll_pane",
    horizontal_scroll_policy = "never",
    vertical_scroll_policy = "always",
  })

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

--- @param entry Entry
--- @return boolean? updated
function info_pane:show(entry)
  local profiler = game.create_profiler()

  -- Subheader
  local title_label = self.title_label
  title_label.caption = { "", "            ", entry:get_localised_name() }
  title_label.sprite = entry:get_path()
  local style = "rb_subheader_caption_button"
  if entry:is_hidden(self.context.player.force_index) then
    style = "rb_subheader_caption_button_hidden"
  elseif not entry:is_researched(self.context.player.force_index) then
    style = "rb_subheader_caption_button_unresearched"
  end
  title_label.style = style
  title_label.style.horizontally_squashable = true
  local type_label = self.type_label
  --- @type LocalisedString
  local type_caption = { "" }
  for _, key in pairs({ "technology", "recipe", "item", "fluid", "equipment", "entity" }) do
    local prototype = entry[key]
    if prototype then
      type_caption[#type_caption + 1] = gui_util.type_locale[prototype.object_name]
      type_caption[#type_caption + 1] = "/"
    end
  end
  type_caption[#type_caption] = nil
  type_label.caption = type_caption

  -- Contents

  local force_index = self.context.player.force_index

  --- @param id EntryID
  --- @param holder LuaGuiElement
  local function make_list_box_item(id, holder)
    local entry = id:get_entry()
    if not entry then
      return
    end

    local style = "rb_list_box_item"
    if entry:is_hidden(force_index) then
      style = "rb_list_box_item_hidden"
    elseif not entry:is_researched(force_index) then
      style = "rb_list_box_item_unresearched"
    end

    return holder.add({
      type = "sprite-button",
      style = style,
      sprite = id:get_path(),
      caption = { "", "              ", id:get_caption() },
      tooltip = { "gui.rb-control-hint" },
      elem_tooltip = id:strip(),
      tags = flib_gui.format_handlers({ [defines.events.on_gui_click] = info_pane.on_result_clicked }),
    })
  end

  --- @param id EntryID
  --- @param holder LuaGuiElement
  local function make_slot_button(id, holder)
    local entry = id:get_entry()
    if not entry then
      return
    end

    local style = "flib_slot_button_default"
    if entry:is_hidden(force_index) then
      style = "flib_slot_button_grey"
    elseif not entry:is_researched(force_index) then
      style = "flib_slot_button_red"
    end

    local button = holder.add({
      type = "sprite-button",
      style = style,
      sprite = id:get_path(),
      number = id.amount,
      tooltip = { "gui.rb-control-hint" },
      elem_tooltip = id:strip(),
      tags = flib_gui.format_handlers({ [defines.events.on_gui_click] = info_pane.on_result_clicked }),
    })

    -- TODO: Custom tooltip titles with all the info?
    if not id.amount and (id.temperature or id.minimum_temperature) then
      local bottom, top = id:get_temperature_strings()
      if bottom then
        button.add({ type = "label", style = "rb_slot_label", caption = bottom, ignored_by_interaction = true })
      end
      if top then
        button.add({ type = "label", style = "rb_slot_label_top", caption = top, ignored_by_interaction = true })
      end
    end

    return button
  end

  local content_pane = self.content_pane
  content_pane.clear()
  content_pane.scroll_to_top()
  if content_pane.welcome_label then
    content_pane.welcome_label.destroy()
  end

  -- Recipe

  local recipe_description = info_description.new(content_pane, self.context)
  recipe_description:add_common(entry.recipe)
  recipe_description:finalize()

  local material_description = info_description.new(content_pane, self.context)
  material_description:add_common(entry.item or entry.fluid)
  material_description:add_item(entry)
  material_description:add_fluid(entry)
  material_description:add_entity(entry)
  material_description:finalize()

  info_section.build(
    content_pane,
    self.context,
    { "description.ingredients" },
    entry:get_ingredients(),
    { always_show = true, remark = gui_util.format_crafting_time(entry:get_crafting_time()) },
    make_list_box_item
  )
  info_section.build(
    content_pane,
    self.context,
    { "description.products" },
    entry:get_products(),
    { always_show = true },
    make_list_box_item
  )
  info_section.build(
    content_pane,
    self.context,
    { "description.made-in" },
    entry:get_made_in(),
    { column_count = 10 },
    make_slot_button
  )

  -- Material

  info_section.build(
    content_pane,
    self.context,
    { "description.rb-used-in" },
    entry:get_used_in(),
    { column_count = 10 },
    make_slot_button
  )
  info_section.build(
    content_pane,
    self.context,
    { "description.rb-alternative-recipes" },
    entry:get_alternative_recipes(),
    { column_count = 10 },
    make_slot_button
  )
  info_section.build(
    content_pane,
    self.context,
    { "description.rb-generated-by" },
    entry:get_generated_by(),
    { column_count = 10 },
    make_slot_button
  )
  info_section.build(
    content_pane,
    self.context,
    { "description.rb-mined-by" },
    entry:get_mined_by(),
    { column_count = 10 },
    make_slot_button
  )
  info_section.build(
    content_pane,
    self.context,
    { "description.rb-burned-in" },
    entry:get_burned_in(),
    { column_count = 10 },
    make_slot_button
  )
  info_section.build(
    content_pane,
    self.context,
    { "description.rb-gathered-from" },
    entry:get_gathered_from(),
    { column_count = 10 },
    make_slot_button
  )
  info_section.build(
    content_pane,
    self.context,
    { "description.rocket-launch-products" },
    entry:get_rocket_launch_products(),
    { column_count = 10 },
    make_slot_button
  )
  info_section.build(
    content_pane,
    self.context,
    { "description.rb-rocket-launch-product-of" },
    entry:get_rocket_launch_product_of(),
    { column_count = 10 },
    make_slot_button
  )
  info_section.build(
    content_pane,
    self.context,
    { "description.rb-can-mine" },
    entry:get_can_mine(),
    { column_count = 10 },
    make_slot_button
  )
  info_section.build(
    content_pane,
    self.context,
    { "description.rb-can-burn" },
    entry:get_can_burn(),
    { column_count = 10 },
    make_slot_button
  )
  info_section.build(
    content_pane,
    self.context,
    { "description.rb-yields" },
    entry:get_yields(),
    {},
    make_list_box_item
  )

  info_section.build(
    content_pane,
    self.context,
    { "description.rb-unlocked-by" },
    entry:get_unlocked_by(),
    { style = "rb_technology_slot_deep_frame", column_count = 5 },
    --- @param id EntryID
    --- @param holder LuaGuiElement
    function(id, holder)
      local entry = id:get_entry()
      if not entry then
        return
      end

      if entry:is_hidden(force_index) and not self.context.show_hidden then
        return
      end
      local research_state
      if not entry:is_researched(force_index) then
        research_state = flib_technology.research_state.not_available
      else
        research_state = flib_technology.research_state.researched
      end
      local technology = self.context.player.force.technologies[id.name]
      local button = flib_gui_templates.technology_slot(
        holder,
        technology,
        technology.level,
        research_state,
        info_pane.on_result_clicked
      )
      button.tooltip = { "", { "gui.rb-control-hint" }, "\n", { "gui.rb-technology-control-hint" } }

      return button
    end
  )

  info_section.build(
    content_pane,
    self.context,
    { "description.rb-can-craft" },
    entry:get_can_craft(),
    { column_count = 10 },
    make_slot_button
  )

  -- Technology
  info_section.build(
    content_pane,
    self.context,
    { "gui-technology-preview.unit-ingredients" },
    entry:get_technology_ingredients(),
    {
      remark = gui_util.format_technology_count_and_time(
        entry:get_technology_ingredient_count(),
        entry:get_technology_ingredient_time()
      ),
      column_count = 10,
    },
    make_slot_button
  )
  info_section.build(
    content_pane,
    self.context,
    { "description.rb-unlocks-recipes" },
    entry:get_unlocks_recipes(),
    { column_count = 10 },
    make_slot_button
  )

  profiler.stop()
  log({ "", "[", entry:get_path(), "] ", profiler })

  return true
end

return info_pane
