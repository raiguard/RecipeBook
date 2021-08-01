local gui = require("__flib__.gui-beta")

local constants = require("constants")

local formatter = require("scripts.formatter")
local recipe_book = require("scripts.recipe-book")
local shared = require("scripts.shared")
local util = require("scripts.util")

local root = {}

local function quick_ref_panel(ref)
  return
    {type = "flow", direction = "vertical", ref = {ref, "flow"},
      {type = "label", style = "rb_list_box_label", ref = {ref, "label"}},
      {type = "frame", style = "rb_slot_table_frame", ref = {ref, "frame"},
        {type = "table", style = "slot_table", column_count = 5, ref = {ref, "table"}}
      }
    }
end

function root.build(player, player_table, recipe_name)
  local refs = gui.build(player.gui.screen, {
    {type = "frame", direction = "vertical", ref = {"window"},
      {type = "flow", style = "flib_titlebar_flow", ref = {"titlebar", "flow"},
        {type = "label", style = "frame_title", caption = {"gui.rb-recipe"}, ignored_by_interaction = true},
        {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
        util.frame_action_button(
          "rb_expand",
          {"gui.rb-view-details"},
          nil,
          {gui = "quick_ref", id = recipe_name, action = "view_details"}
        ),
        util.frame_action_button(
          "utility/close",
          {"gui.close"},
          nil,
          {gui = "quick_ref", id = recipe_name, action = "close"}
        )
      },
      {type = "frame", style = "rb_quick_ref_content_frame", direction = "vertical",
        {type = "frame", style = "subheader_frame",
          {type = "label", style = "rb_toolbar_label", ref = {"label"}},
          {type = "empty-widget", style = "flib_horizontal_pusher"}
        },
        {type = "flow", style = "rb_quick_ref_content_flow", direction = "vertical",
          quick_ref_panel("ingredients"),
          quick_ref_panel("products"),
          quick_ref_panel("made_in")
        }
      }
    }
  })

  refs.titlebar.flow.drag_target = refs.window

  player_table.guis.quick_ref[recipe_name] = {refs = refs}

  root.update_contents(player, player_table, recipe_name)
end

function root.destroy(player, player_table, recipe_name)
  local gui_data = player_table.guis.quick_ref[recipe_name]
  if gui_data then
    gui_data.refs.window.destroy()
    player_table.guis.quick_ref[recipe_name] = nil
    -- TODO: Shared can go away!
    shared.update_header_button(
      player,
      player_table,
      {class = "recipe", name = recipe_name},
      "quick_ref_button",
      false
    )
  end
end

function root.toggle(player, player_table, recipe_name)
  if player_table.guis.quick_ref[recipe_name] then
    root.destroy(player, player_table, recipe_name)
    -- TODO: Doesn't need to be shared anymore!
    shared.update_header_button(player, player_table, {class = "recipe", name = recipe_name}, "quick_ref_button", false)
  else
    root.build(player, player_table, recipe_name)
    shared.update_header_button(player, player_table, {class = "recipe", name = recipe_name}, "quick_ref_button", true)
  end
end

function root.destroy_all(player, player_table)
  for recipe_name in pairs(player_table.guis.quick_ref) do
    root.destroy(player, player_table, recipe_name)
  end
end

function root.update_all(player, player_table)
  for recipe_name in pairs(player_table.guis.quick_ref) do
    root.update_contents(player, player_table, recipe_name)
  end
end

function root.update_contents(player, player_table, recipe_name)
  local gui_data = player_table.guis.quick_ref[recipe_name]
  local refs = gui_data.refs

  local show_made_in = player_table.settings.show_made_in_in_quick_ref

  local recipe_data = recipe_book.recipe[recipe_name]
  local player_data = formatter.build_player_data(player, player_table)

  -- Label
  local recipe_info = formatter(recipe_data, player_data, {always_show = true, is_label = true})
  local label = refs.label
  label.caption = recipe_info.caption
  label.tooltip = recipe_info.tooltip

  -- Slot boxes
  for _, source in ipairs{"ingredients", "products", "made_in"} do
    local box = refs[source]

    if source == "made_in" and not show_made_in then
      box.flow.visible = false
      break
    else
      box.flow.visible = true
    end

    local blueprint_recipe = source == "made_in" and recipe_name or nil

    local table = box.table
    local buttons = table.children
    local i = 0
    for _, object in pairs(recipe_data[source]) do
      local object_data = recipe_book[object.class][object.name]
      local object_info = formatter(
        object_data,
        player_data,
        {
          amount_ident = object.amount_ident,
          amount_only = true,
          always_show = source ~= "made_in",
          blueprint_recipe = blueprint_recipe
        }
      )
      if object_info then
        i = i + 1

        local button_style = object_info.researched and "flib_slot_button_default" or "flib_slot_button_red"

        local button = buttons[i]

        if button then
          button.style = button_style
          button.sprite = constants.class_to_type[object.class].."/"..object_data.prototype_name
          button.tooltip = object_info.tooltip
          gui.update_tags(button, {
            blueprint_recipe = blueprint_recipe,
            context = object,
            researched = object_data.researched
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
              sprite = constants.class_to_type[object.class].."/"..object_data.prototype_name,
              tooltip = object_info.tooltip,
              tags = {
                blueprint_recipe = blueprint_recipe,
                context = object,
                researched = object_data.researched
              },
              actions = {
                on_click = {gui = "quick_ref", id = recipe_name, action = "handle_button_click", source = source}
              },
              {
                type = "label",
                style = "rb_slot_label",
                caption = object_info.caption,
                ignored_by_interaction = true
              },
              {
                type = "label",
                style = "rb_slot_label_top",
                caption = probability and "%" or "",
                ignored_by_interaction = true
              }
            }
          })
        end
      end
      for j = i + 1, #buttons do
        buttons[j].destroy()
      end

      -- Label
      box.label.caption = {"gui.rb-list-box-label", {"gui.rb-"..string.gsub(source, "_", "-")}, i}
    end
  end
end

return root
