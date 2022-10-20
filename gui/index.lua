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

--- @class Gui
local gui = {}

function gui:build_filters()
  local first_group
  local group_tabs = {}
  local member_flows = {}
  for group_name, group_members in pairs(global.group_members) do
    if #group_members > 0 then
      first_group = first_group or group_name
      table.insert(group_tabs, {
        type = "sprite-button",
        name = group_name,
        style = "rb_filter_group_button_tab",
        sprite = "item-group/" .. group_name,
        tooltip = game.item_group_prototypes[group_name].localised_name,
        enabled = group_name ~= first_group,
        actions = { on_click = "select_filter_group" },
      })
      local group = {
        type = "flow",
        name = group_name,
        style = "rb_filter_group_flow",
        direction = "vertical",
        visible = group_name == first_group,
      }
      table.insert(member_flows, group)
      for _, subgroup in pairs(global.subgroups[group_name]) do
        local subgroup_members = global.subgroup_members[subgroup.name]
        if #subgroup_members > 0 then
          local subgroup = { type = "table", name = subgroup.name, style = "slot_table", column_count = 10 }
          table.insert(group, subgroup)
          for _, prototype in pairs(subgroup_members) do
            local sprite = sprite_path[prototype.object_name] .. "/" .. prototype.name
            if not self.player.gui.is_valid_sprite_path(sprite) then
              sprite = "item/item-unknown"
            end
            table.insert(subgroup, {
              type = "sprite-button",
              name = prototype.name,
              style = "slot_button",
              sprite = sprite,
              tooltip = { "", prototype.localised_name, "\n", sprite_path[prototype.object_name], "/", prototype.name },
              actions = { on_click = "show_recipe" },
            })
          end
        end
      end
    end
  end

  -- for _, prototype in pairs(global.sorted_objects) do
  --   -- Group
  --   local group = prototype.group
  --   first_group = first_group or group
  --   if group.name ~= current_group then
  --     current_group = group.name
  --     table.insert(group_tabs, {
  --       type = "sprite-button",
  --       name = group.name,
  --       style = "rb_filter_group_button_tab",
  --       sprite = "item-group/" .. group.name,
  --       tooltip = game.item_group_prototypes[group.name].localised_name,
  --       enabled = group.name ~= first_group,
  --       actions = { on_click = "select_filter_group" },
  --     })
  --     group_flow = {
  --       type = "flow",
  --       name = group.name,
  --       style = "rb_filter_group_flow",
  --       direction = "vertical",
  --       visible = group.name == first_group,
  --     }
  --     table.insert(member_flows, group_flow)
  --   end
  --   -- Subgroup
  --   local subgroup = prototype.subgroup
  --   if subgroup.name ~= current_subgroup then
  --     current_subgroup = subgroup.name
  --     subgroup_table = { type = "table", name = subgroup.name, style = "slot_table", column_count = 10 }
  --     table.insert(group_flow, subgroup_table)
  --   end
  --   -- Button
  --   local sprite = sprite_path[prototype.object_name] .. "/" .. prototype.name
  --   if not self.player.gui.is_valid_sprite_path(sprite) then
  --     sprite = "item/item-unknown"
  --   end
  --   table.insert(subgroup, {
  --     type = "sprite-button",
  --     name = prototype.name,
  --     style = "slot_button",
  --     sprite = sprite,
  --     tooltip = { "", prototype.localised_name, "\n", sprite_path[prototype.object_name], "/", prototype.name },
  --     actions = { on_click = "show_recipe" },
  --   })
  -- end

  local group_table = self.refs.filter_group_table
  group_table.clear()
  libgui.build(group_table, group_tabs)

  local scroll = self.refs.filter_scroll_pane
  scroll.clear()
  libgui.build(scroll, member_flows)

  self.state.selected_filter_group = first_group
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

--- @param recipe_name string
function gui:show_recipe(recipe_name)
  local profiler = game.create_profiler()
  local recipe = game.recipe_prototypes[recipe_name]
  if not recipe then
    return
  end

  local made_in = {}
  for _, crafter in
    pairs(game.get_filtered_entity_prototypes({
      -- { filter = "crafting-machine" },
      { mode = "and", filter = "crafting-category", crafting_category = recipe.category },
    }))
  do
    if crafter.ingredient_count == 0 or crafter.ingredient_count >= #recipe.ingredients then
      table.insert(made_in, {
        type = "entity",
        name = crafter.name,
        amount = {
          "",
          "[img=quantity-time] ",
          { "time-symbol-seconds", math.round(recipe.energy / crafter.crafting_speed, 0.01) },
        },
      })
    end
  end

  local unlocked_by = {}
  for _, technology in
    pairs(game.get_filtered_technology_prototypes({ { filter = "enabled" }, { filter = "has-effects" } }))
  do
    for _, effect in pairs(technology.effects) do
      if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
        table.insert(unlocked_by, { type = "technology", name = technology.name })
      end
    end
  end

  self.refs.page_header_icon.sprite = "recipe/" .. recipe_name
  self.refs.page_header_label.caption = recipe.localised_name

  local page_scroll = self.refs.page_scroll
  page_scroll.clear()
  libgui.build(page_scroll, {
    templates.list_box(
      "Ingredients",
      table.map(recipe.ingredients, function(v)
        v.amount = { "", "× ", v.amount }
        return v
      end),
      {
        "",
        "[img=quantity-time] [font=default-semibold]",
        { "time-symbol-seconds", math.round(recipe.energy, 0.1) },
        "[/font] ",
        { "description.crafting-time" },
      }
    ),
    templates.list_box(
      "Products",
      table.map(recipe.products, function(v)
        v.amount = { "", "× ", v.amount }
        return v
      end)
    ),
    templates.list_box("Made in", made_in),
    templates.list_box("Unlocked by", unlocked_by),
  })

  profiler.stop()
  game.print(profiler)
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
