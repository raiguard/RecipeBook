local libgui = require("__flib__.gui")
local math = require("__flib__.math")
local table = require("__flib__.table")

-- local util = require("__RecipeBook__.util")

local handlers = require("__RecipeBook__.gui.handlers")
local templates = require("__RecipeBook__.gui.templates")

local sprite_path = {
  ["LuaEntityPrototype"] = "entity",
  ["LuaFluidPrototype"] = "fluid",
  ["LuaItemPrototype"] = "item",
  ["LuaRecipePrototype"] = "recipe",
}

local crafting_machine = {
  ["assembling-machine"] = true,
  ["furnace"] = true,
  ["rocket-silo"] = true,
}

--- @class Gui
local gui = {}

function gui:build_filters()
  -- Create tables for each subgroup
  local subgroup_tables = {}
  for subgroup_name, subgroup in pairs(global.subgroups) do
    local prototypes = subgroup.members
    if #prototypes > 0 then
      local subgroup_table = { type = "table", name = subgroup_name, style = "slot_table", column_count = 10 }
      subgroup_tables[subgroup_name] = subgroup_table
      for _, prototype in pairs(prototypes) do
        local sprite = sprite_path[prototype.object_name] .. "/" .. prototype.name
        if not self.player.gui.is_valid_sprite_path(sprite) then
          sprite = "item/item-unknown"
        end
        table.insert(subgroup_table, {
          type = "sprite-button",
          name = prototype.name,
          style = "slot_button",
          sprite = sprite,
          tooltip = { "", prototype.localised_name, "\n", sprite_path[prototype.object_name], "/", prototype.name },
          actions = { on_click = "show_page" },
        })
      end
    end
  end

  -- Assign subgroup tables in order and determine groups to show
  local group_tabs = {}
  local group_flows = {}
  local first_group
  for name, group in pairs(game.item_group_prototypes) do
    local group_flow = {
      type = "flow",
      name = name,
      style = "rb_filter_group_flow",
      direction = "vertical",
    }
    for _, subgroup in pairs(group.subgroups) do
      local subgroup_table = subgroup_tables[subgroup.name]
      if subgroup_table and #subgroup_table > 0 then
        table.insert(group_flow, subgroup_table)
      end
    end
    if #group_flow > 0 then
      if first_group then
        group_flow.visible = false
      else
        first_group = name
      end
      table.insert(group_flows, group_flow)
      table.insert(group_tabs, {
        type = "sprite-button",
        name = name,
        style = "rb_filter_group_button_tab",
        sprite = "item-group/" .. name,
        tooltip = group.localised_name,
        enabled = name ~= first_group,
        actions = { on_click = "select_filter_group" },
      })
    end
  end

  local filter_group_table = self.refs.filter_group_table
  filter_group_table.clear()
  libgui.build(filter_group_table, group_tabs)

  local filter_scroll_pane = self.refs.filter_scroll_pane
  filter_scroll_pane.clear()
  libgui.build(filter_scroll_pane, group_flows)

  self.state.selected_filter_group = first_group
end

function gui:destroy()
  self.refs.window.destroy()
  self.player_table.gui = nil
end

--- @param e EventData
--- @param action string
function gui:dispatch(e, action)
  local handler = handlers[action]
  if handler then
    handler(self, e)
  else
    log("Attempted to call nonexistent GUI handler " .. action)
  end
end

function gui:hide()
  self.refs.window.visible = false
  if self.player.opened == self.refs.window then
    self.player.opened = nil
  end
end

--- @param group_name string
function gui:select_filter_group(group_name)
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

function gui:show()
  self.refs.window.visible = true
  self.player.opened = self.refs.window
end

--- @param object_name string
function gui:show_page(object_name)
  local profiler = game.create_profiler()

  local sprite, localised_name
  local components = {}

  -- This will be common across all kinds of objects
  local unlocked_by = {}

  local types = {}

  local recipe = game.recipe_prototypes[object_name]
  if recipe then
    sprite = "recipe/" .. object_name
    localised_name = recipe.localised_name
    table.insert(types, "Recipe")

    table.insert(
      components,
      templates.list_box(
        "Ingredients",
        table.map(recipe.ingredients, function(v)
          v.amount = { "", "[font=default-semibold]", v.amount, " ×[/font]  " }
          return v
        end),
        {
          "",
          "[img=quantity-time] [font=default-semibold]",
          { "time-symbol-seconds", math.round(recipe.energy, 0.1) },
          "[/font] ",
          { "description.crafting-time" },
        }
      )
    )
    table.insert(
      components,
      templates.list_box(
        "Products",
        table.map(recipe.products, function(v)
          v.amount = { "", "[font=default-semibold]", v.amount, " ×[/font]  " }
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
            { "time-symbol-seconds", math.round(recipe.energy / crafter.crafting_speed, 0.01) },
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
        if effect.type == "unlock-recipe" and effect.recipe == object_name then
          table.insert(unlocked_by, { type = "technology", name = technology.name })
        end
      end
    end
  end

  local fluid = game.fluid_prototypes[object_name]
  if fluid then
    sprite = sprite or ("fluid/" .. object_name)
    localised_name = localised_name or fluid.localised_name
    table.insert(types, "Fluid")

    local ingredient_in = {}
    for _, recipe in
      pairs(game.get_filtered_recipe_prototypes({
        { filter = "has-ingredient-fluid", elem_filters = { { filter = "name", name = object_name } } },
      }))
    do
      table.insert(ingredient_in, { type = "recipe", name = recipe.name })
    end
    table.insert(components, templates.list_box("Ingredient in", ingredient_in))

    local product_of = {}
    for _, recipe in
      pairs(game.get_filtered_recipe_prototypes({
        { filter = "has-product-fluid", elem_filters = { { filter = "name", name = object_name } } },
      }))
    do
      table.insert(product_of, { type = "recipe", name = recipe.name })
    end
    table.insert(components, templates.list_box("Product of", product_of))
  end

  local item = game.item_prototypes[object_name]
  if item then
    sprite = sprite or ("item/" .. object_name)
    localised_name = localised_name or item.localised_name
    table.insert(types, "Item")

    local ingredient_in = {}
    for _, recipe in
      pairs(game.get_filtered_recipe_prototypes({
        { filter = "has-ingredient-item", elem_filters = { { filter = "name", name = object_name } } },
      }))
    do
      table.insert(ingredient_in, { type = "recipe", name = recipe.name })
    end
    table.insert(components, templates.list_box("Ingredient in", ingredient_in))

    local product_of = {}
    for _, recipe in
      pairs(game.get_filtered_recipe_prototypes({
        { filter = "has-product-item", elem_filters = { { filter = "name", name = object_name } } },
      }))
    do
      table.insert(product_of, { type = "recipe", name = recipe.name })
    end
    if #product_of > 1 or not recipe then
      table.insert(components, templates.list_box("Product of", product_of))
    end
  end

  local entity = game.entity_prototypes[object_name]
  if entity then
    sprite = sprite or ("entity/" .. object_name)
    localised_name = localised_name or entity.localised_name
    table.insert(types, "Entity")

    if crafting_machine[entity.type] then
      local filters = {}
      for category in pairs(entity.crafting_categories) do
        table.insert(filters, { filter = "category", category = category })
        table.insert(filters, { mode = "and", filter = "hidden-from-player-crafting", invert = true })
      end
      local can_craft = {}
      for _, recipe in pairs(game.get_filtered_recipe_prototypes(filters)) do
        if entity.ingredient_count == 0 or entity.ingredient_count >= #recipe.ingredients then
          table.insert(can_craft, { type = "recipe", name = recipe.name })
        end
      end
      table.insert(components, templates.list_box("Can craft", can_craft))
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
          table.insert(mined_by, { type = "entity", name = entity.name })
        end
      end
      table.insert(components, templates.list_box("Mined by", mined_by, required_fluid_str))
    end
  end

  if #unlocked_by > 0 then
    table.insert(components, templates.list_box("Unlocked by", unlocked_by))
  end

  self.refs.page_header_icon.sprite = sprite
  self.refs.page_header_label.caption = localised_name
  self.refs.page_header_type_label.caption = table.concat(types, "/")

  local page_scroll = self.refs.page_scroll
  page_scroll.clear()
  libgui.build(page_scroll, components)

  profiler.stop()
  game.print(profiler)
end

function gui:toggle()
  if self.refs.window.visible then
    self:hide()
  else
    self:show()
  end
end

--- @param player LuaPlayer
--- @param player_table PlayerTable
--- @return Gui
function gui.new(player, player_table)
  --- @type GuiRefs
  local refs = libgui.build(player.gui.screen, { templates.base() })

  refs.titlebar_flow.drag_target = refs.window
  refs.window.force_auto_center()

  --- @class Gui
  local self = {
    player = player,
    player_table = player_table,
    refs = refs,
    state = {
      --- @type string?
      selected_filter_group = nil,
    },
  }
  gui.load(self)
  player_table.gui = self

  self:build_filters()

  return self
end

function gui.load(self)
  setmetatable(self, { __index = gui })
end

return gui
