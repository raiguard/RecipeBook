local flib_gui = require("__flib__.gui")
local flib_gui_templates = require("__flib__.gui-templates")
local flib_technology = require("__flib__.technology")

local gui_util = require("scripts.gui.util")
local info_description = require("scripts.gui.info-description")
local info_section = require("scripts.gui.info-section")

local collectors = require("scripts.database.collectors")
local grouped = require("scripts.database.grouped")
local researched = require("scripts.database.researched")
local util = require("scripts.util")

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

--- @param prototype GenericPrototype
--- @return boolean? updated
function info_pane:show(prototype)
  local profiler = game.create_profiler()

  -- Subheader
  do
    local title_label = self.title_label
    title_label.caption = { "", "      ", prototype.localised_name } --- @diagnostic disable-line:assign-type-mismatch
    title_label.sprite = util.get_path(prototype)
    local style = "rb_subheader_caption_button"
    -- TODO: Technology runtime enable/disable
    if prototype.hidden_in_factoriopedia then
      style = "rb_subheader_caption_button_hidden"
    elseif not researched.is(prototype, self.context.player.force_index) then
      style = "rb_subheader_caption_button_unresearched"
    end
    title_label.style = style
    title_label.style.horizontally_squashable = true
  end

  local prototype_path = util.get_path(prototype)

  do
    --- @type LocalisedString
    local type_caption = { "" }
    --- @param sub_prototype GenericPrototype
    local function add_type_locale(sub_prototype)
      type_caption[#type_caption + 1] = gui_util.type_locale[sub_prototype.object_name] --- @diagnostic disable-line:assign-type-mismatch
      type_caption[#type_caption + 1] = "/"
    end

    if self.context.use_groups then
      local grouped_recipe = grouped.recipe[prototype_path]
      if grouped_recipe then
        add_type_locale(grouped_recipe)
      end
    end
    add_type_locale(prototype)
    if self.context.use_groups then
      local grouped_entity = grouped.entity[prototype_path]
      if grouped_entity then
        add_type_locale(grouped_entity)
      end
      local grouped_equipment = grouped.equipment[prototype_path]
      if grouped_equipment then
        add_type_locale(grouped_equipment)
      end
      local grouped_tile = grouped.tile[prototype_path]
      if grouped_tile then
        add_type_locale(grouped_tile)
      end
    end
    type_caption[#type_caption] = nil
    self.type_label.caption = type_caption
  end

  -- Contents

  local force_index = self.context.player.force_index

  --- @param id DatabaseID
  --- @param holder LuaGuiElement
  local function make_list_box_item(id, holder)
    local prototype = util.get_prototype(id)
    local style = "rb_list_box_item"
    if prototype.hidden_in_factoriopedia then
      style = "rb_list_box_item_hidden"
    elseif not researched.is(prototype, force_index) then
      style = "rb_list_box_item_unresearched"
    end

    return holder.add({
      type = "sprite-button",
      style = style,
      sprite = id.type .. "/" .. id.name,
      caption = { "", "      ", gui_util.format_caption(id) },
      tooltip = { "gui.rb-control-hint" },
      elem_tooltip = { type = id.type, name = id.name },
      tags = flib_gui.format_handlers({ [defines.events.on_gui_click] = info_pane.on_result_clicked }),
    })
  end

  --- @param id DatabaseID
  --- @param holder LuaGuiElement
  local function make_slot_button(id, holder)
    local prototype = util.get_prototype(id)
    local style = "flib_slot_button_default"
    if prototype.hidden_in_factoriopedia then
      style = "flib_slot_button_grey"
    elseif not researched.is(prototype, force_index) then
      style = "flib_slot_button_red"
    end

    local button = holder.add({
      type = "sprite-button",
      style = style,
      sprite = id.type .. "/" .. id.name,
      number = id.amount,
      tooltip = { "gui.rb-control-hint" },
      elem_tooltip = { type = id.type, name = id.name },
      tags = flib_gui.format_handlers({ [defines.events.on_gui_click] = info_pane.on_result_clicked }),
    })

    if not id.amount and (id.temperature or id.minimum_temperature) then
      local bottom, top = gui_util.get_temperature_strings(id)
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

  -- local general_desc = info_description.new(content_pane, self.context, info_pane.on_result_clicked)
  -- general_desc:add_history_and_description(prototype)
  -- general_desc:add_recipe_properties(prototype)
  -- general_desc:add_item_properties(prototype)
  -- general_desc:add_fluid_properties(prototype)
  -- general_desc:add_entity_properties(prototype)
  -- general_desc:finalize()

  -- local entity = prototype.entity
  -- if entity then
  --   local consumption_desc = info_description.new(content_pane, self.context, info_pane.on_result_clicked)
  --   local consumption_id = collectors.material_consumption()
  --   if consumption_id then
  --     consumption_desc:add_consumption(consumption_id)
  --   end
  --   consumption_desc:finalize()

  --   local power_consumption_desc = info_description.new(content_pane, self.context, info_pane.on_result_clicked)
  --   local power_consumption = collectors.power_consumption()
  --   if power_consumption then
  --     power_consumption_desc:add_category_header(
  --       "tooltip-category-electricity",
  --       { "", { "tooltip-category.consumes" }, " ", { "tooltip-category.electricity" } }
  --     )
  --     if power_consumption.min == power_consumption.max then
  --       power_consumption_desc:add_generic_row(
  --         { "description.energy-consumption" },
  --         gui_util.format_power(power_consumption.max)
  --       )
  --     else
  --       power_consumption_desc:add_generic_row(
  --         { "description.max-energy-consumption" },
  --         gui_util.format_power(power_consumption.max)
  --       )
  --       power_consumption_desc:add_generic_row(
  --         { "description.min-energy-consumption" },
  --         gui_util.format_power(power_consumption.min)
  --       )
  --     end
  --   end
  --   power_consumption_desc:finalize()

  --   local power_production_desc = info_description.new(content_pane, self.context, info_pane.on_result_clicked)
  --   local power_production = collectors.power_production()
  --   if power_production then
  --     power_production_desc:add_category_header(
  --       "tooltip-category-electricity",
  --       { "", { "tooltip-category.generates" }, " ", { "tooltip-category.electricity" } }
  --     )
  --     power_production_desc:add_generic_row(
  --       { "description.maximum-power-output" },
  --       gui_util.format_power(power_production)
  --     )
  --   end
  --   power_production_desc:finalize()

  --   local production_desc = info_description.new(content_pane, self.context, info_pane.on_result_clicked)
  --   local production_id = collectors.material_production()
  --   if production_id then
  --     production_desc:add_production(production_id)
  --   end
  --   production_desc:finalize()

  --   local vehicle_desc = info_description.new(content_pane, self.context, info_pane.on_result_clicked)
  --   vehicle_desc:add_vehicle_properties(prototype)
  --   vehicle_desc:finalize()
  -- end

  local lists_everywhere = self.context.player.mod_settings["rb-lists-everywhere"].value --[[@as boolean]]
  local grid_builder = lists_everywhere and make_list_box_item or make_slot_button
  local grid_column_count = lists_everywhere and 1 or 10

  local recipe = prototype.object_name == "LuaRecipePrototype" and prototype --[[@as LuaRecipePrototype]]
    or (self.context.use_groups and grouped.recipe[prototype_path] or nil)
  if recipe then
    info_section.build(
      content_pane,
      self.context,
      { "factoriopedia.ingredients" },
      collectors.ingredients(recipe),
      { always_show = true, remark = gui_util.format_crafting_time(recipe.energy) },
      make_list_box_item
    )
    info_section.build(
      content_pane,
      self.context,
      { "factoriopedia.products" },
      collectors.products(recipe),
      { always_show = true },
      make_list_box_item
    )
    info_section.build(
      content_pane,
      self.context,
      { "factoriopedia.made-in" },
      collectors.made_in(recipe),
      { column_count = grid_column_count },
      grid_builder
    )
  end

  if prototype.object_name == "LuaFluidPrototype" or prototype.object_name == "LuaItemPrototype" then
    info_section.build(
      content_pane,
      self.context,
      { "factoriopedia.gathered-from" },
      collectors.gathered_from(prototype),
      { column_count = grid_column_count },
      grid_builder
    )
    local grouped_recipe = grouped.recipe[prototype_path]
    info_section.build(
      content_pane,
      self.context,
      grouped_recipe and { "description.rb-alternative-recipes" } or { "description.rb-recipes" },
      collectors.alternative_recipes(prototype, grouped_recipe),
      { column_count = grid_column_count },
      grid_builder
    )
    info_section.build(
      content_pane,
      self.context,
      { "description.rb-used-in" },
      collectors.used_in(prototype, grouped_recipe),
      { column_count = grid_column_count },
      grid_builder
    )
  end

  if prototype.object_name == "LuaItemPrototype" then
    info_section.build(
      content_pane,
      self.context,
      { "description.rocket-launch-products" },
      collectors.rocket_launch_products(prototype),
      { column_count = grid_column_count },
      grid_builder
    )
    info_section.build(
      content_pane,
      self.context,
      { "description.rb-rocket-launch-product-of" },
      collectors.rocket_launch_product_of(prototype),
      { column_count = grid_column_count },
      grid_builder
    )
  end

  if prototype.object_name == "LuaFluidPrototype" then
    info_section.build(
      content_pane,
      self.context,
      { "factoriopedia.generated-by" },
      collectors.generated_by(prototype),
      { column_count = grid_column_count },
      grid_builder
    )
  end

  local entity = prototype.object_name == "LuaEntityPrototype" and prototype --[[@as LuaEntityPrototype]]
    or (self.context.use_groups and grouped.entity[prototype_path] or nil)
  if entity then
    info_section.build(
      content_pane,
      self.context,
      { "description.mined-by" },
      collectors.mined_by(entity),
      { column_count = grid_column_count },
      grid_builder
    )
  end

  if prototype.object_name == "LuaFluidPrototype" or prototype.object_name == "LuaItemPrototype" then
    info_section.build(
      content_pane,
      self.context,
      { "factoriopedia.burned-in" },
      collectors.burned_in(prototype),
      { column_count = grid_column_count },
      grid_builder
    )
  end

  -- info_section.build(
  --   content_pane,
  --   self.context,
  --   { "description.rb-can-mine" },
  --   collectors.can_mine(),
  --   { column_count = grid_column_count },
  --   grid_builder
  -- )
  -- info_section.build(
  --   content_pane,
  --   self.context,
  --   { "description.rb-can-burn" },
  --   collectors.can_burn(),
  --   { column_count = grid_column_count },
  --   grid_builder
  -- )
  -- info_section.build(
  --   content_pane,
  --   self.context,
  --   { "description.rb-yields" },
  --   collectors.yields(),
  --   {},
  --   make_list_box_item
  -- )

  -- info_section.build(
  --   content_pane,
  --   self.context,
  --   { "description.rb-unlocked-by" },
  --   collectors.unlocked_by(),
  --   { style = "rb_technology_slot_deep_frame", column_count = 5, always_show = true },
  --   --- @param id EntryID
  --   --- @param holder LuaGuiElement
  --   function(id, holder)
  --     local entry = id:get_entry()
  --     if not entry then
  --       return
  --     end

  --     if entry:is_hidden(force_index) and not self.context.show_hidden then
  --       return
  --     end
  --     local research_state
  --     if not entry:is_researched(force_index) then
  --       research_state = flib_technology.research_state.not_available
  --     else
  --       research_state = flib_technology.research_state.researched
  --     end
  --     local technology = self.context.player.force.technologies[id.name]
  --     local button = flib_gui_templates.technology_slot(
  --       holder,
  --       technology,
  --       technology.level,
  --       research_state,
  --       info_pane.on_result_clicked
  --     )
  --     button.tooltip = { "", { "gui.rb-control-hint" }, "\n", { "gui.rb-technology-control-hint" } }

  --     return button
  --   end
  -- )

  -- info_section.build(
  --   content_pane,
  --   self.context,
  --   { "description.rb-can-craft" },
  --   collectors.can_craft(),
  --   { column_count = grid_column_count },
  --   grid_builder
  -- )

  -- info_section.build(
  --   content_pane,
  --   self.context,
  --   { "description.rb-accepted-modules" },
  --   collectors.accepted_modules(),
  --   { column_count = grid_column_count },
  --   grid_builder
  -- )

  -- info_section.build(
  --   content_pane,
  --   self.context,
  --   { "factoriopedia.can-extract-from" },
  --   collectors.can_extract_from(),
  --   { column_count = grid_column_count },
  --   grid_builder
  -- )

  -- info_section.build(
  --   content_pane,
  --   self.context,
  --   { "gui-technology-preview.unit-ingredients" },
  --   collectors.technology_ingredients(),
  --   {
  --     remark = gui_util.format_technology_count_and_time(
  --       collectors.technology_ingredient_count(),
  --       collectors.technology_ingredient_time()
  --     ),
  --     column_count = grid_column_count,
  --   },
  --   grid_builder
  -- )

  -- info_section.build(
  --   content_pane,
  --   self.context,
  --   { "description.rb-unlocks-recipes" },
  --   collectors.unlocks_recipes(),
  --   { column_count = grid_column_count },
  --   grid_builder
  -- )

  -- info_section.build(
  --   content_pane,
  --   self.context,
  --   { "factoriopedia.source-of" },
  --   collectors.source_of(),
  --   { column_count = grid_column_count },
  --   grid_builder
  -- )

  -- info_section.build(
  --   content_pane,
  --   self.context,
  --   { "description.rb-extracted-by" },
  --   collectors.extracted_by(),
  --   { column_count = grid_column_count },
  --   grid_builder
  -- )

  profiler.stop()
  log({ "", "[", util.get_path(prototype), "] ", profiler })

  return true
end

return info_pane
