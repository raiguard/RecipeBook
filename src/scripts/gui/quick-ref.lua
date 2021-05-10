local gui = require("__flib__.gui-beta")

local constants = require("constants")

local formatter = require("scripts.formatter")
local shared = require("scripts.shared")
local util = require("scripts.util")

local quick_ref_gui = {}

local function quick_ref_panel(ref)
  return
    {type = "flow", direction = "vertical", ref = {ref, "flow"},
      {type = "label", style = "rb_list_box_label", ref = {ref, "label"}},
      {type = "frame", style = "rb_slot_table_frame", ref = {ref, "frame"},
        {type = "table", style = "slot_table", column_count = 5, ref = {ref, "table"}}
      }
    }
end

local function build_tooltip(tooltip, amount_string)
  -- TODO: Add shift+click to toggle green status
  return string.gsub(tooltip, "^.-color=.-%]", "%1"..string.gsub(amount_string, "%%", "%%%%").." ")
end

function quick_ref_gui.build(player, player_table, recipe_name)
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

  quick_ref_gui.update_contents(player, player_table, recipe_name)
end

function quick_ref_gui.destroy(player_table, recipe_name)
  local gui_data = player_table.guis.quick_ref[recipe_name]
  if gui_data then
    gui_data.refs.window.destroy()
    player_table.guis.quick_ref[recipe_name] = nil
  end
end

function quick_ref_gui.destroy_all(player_table)
  for recipe_name in pairs(player_table.guis.quick_ref) do
    quick_ref_gui.destroy(player_table, recipe_name)
  end
end

function quick_ref_gui.update_contents(player, player_table, recipe_name)
  local gui_data = player_table.guis.quick_ref[recipe_name]
  local refs = gui_data.refs
  local state = gui_data.state

  local show_made_in = player_table.settings.show_made_in_in_quick_ref

  local recipe_data = global.recipe_book.recipe[recipe_name]
  local player_data = formatter.build_player_data(player, player_table)

  -- Label
  local recipe_info = formatter(recipe_data, player_data, {always_show = true, is_label = true})
  local label = refs.label
  label.caption = recipe_info.caption
  label.tooltip = recipe_info.tooltip
  -- TODO: Append tooltip to talk about alt+clicking

  -- Slot boxes
  for _, source in ipairs{"ingredients", "products", "made_in"} do
    local box = refs[source]

    if source == "made_in" and not show_made_in then
      box.flow.visible = false
      break
    else
      box.flow.visible = true
    end

    local table = box.table
    local buttons = table.children
    local i = 0
    for _, object in pairs(recipe_data[source]) do
      local object_data = global.recipe_book[object.class][object.name]
      local object_info = formatter(
        object_data,
        player_data,
        {always_show = source ~= "made_in", blueprint_recipe = source == "made_in" and recipe_name or nil}
      )
      if object_info then
        i = i + 1

        local button_style = object_info.is_researched and "flib_slot_button_default" or "flib_slot_button_red"
        local tooltip = build_tooltip(object_info.tooltip, object.amount_string)

        local button = buttons[i]

        if button then
          button.style = button_style
          button.sprite = constants.class_to_type[object.class].."/"..object.name
          button.tooltip = tooltip
          gui.update_tags(button, {obj = object, researched = object_data.is_researched})
        else
          gui.build(table, {
            {
              type = "sprite-button",
              style = button_style,
              sprite = constants.class_to_type[object.class].."/"..object.name,
              tooltip = tooltip,
              tags = {obj = object, researched = object_data.is_researched},
              actions = {
                on_click = {gui = "quick_ref", id = recipe_name, action = "handle_button_click", source = source}
              },
              {
                type = "label",
                style = "rb_slot_label",
                caption = object.quick_ref_amount_string,
                ignored_by_interaction = true
              },
              {
                type = "label",
                style = "rb_slot_label_top",
                caption = string.find(object.amount_string, "%%") and "%" or "",
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
      box.label.caption = {"gui.rb-list-box-"..string.gsub(source, "_", "-"), i}
    end
  end
end

function quick_ref_gui.update_all(player, player_table)

end

function quick_ref_gui.handle_action(msg, e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]

  local gui_data = player_table.guis.quick_ref[msg.id]
  local refs = gui_data.refs

  if msg.action == "close" then
    refs.window.destroy()
    player_table.guis.quick_ref[msg.id] = nil
    shared.update_quick_ref_button(player, player_table, msg.id)
  elseif msg.action == "view_details" then
    shared.open_page(player, player_table, {class = "recipe", name = msg.id})
  elseif msg.action == "handle_button_click" then
    if e.alt then
      local button = e.element
      local style = button.style.name
      if style == "flib_slot_button_green" then
        button.style = gui.get_tags(button).previous_style
      else
        gui.update_tags(button, {previous_style = style})
        button.style = "flib_slot_button_green"
      end
    else
      local context = util.navigate_to(msg, e)
      if context then
        shared.open_page(player, player_table, context)
      end
    end
  end
end

return quick_ref_gui
