local gui = require("__flib__.gui-beta")
local table = require("__flib__.table")

local constants = require("constants")

local formatter = require("scripts.formatter")
local shared = require("scripts.shared")
local util = require("scripts.util")

local function quick_ref_panel(ref, children)
  return {type = "flow", direction = "vertical", ref = util.append(ref, "flow"), children = {
    {type = "label", style = "bold_label", ref = util.append(ref, "label")},
    {type = "frame", style = "rb_slot_table_frame", ref = util.append(ref, "frame"), children = {
      {type = "scroll-pane", style = "rb_slot_table_scroll_pane", children = {
        {type = "table", style = "slot_table", column_count = 5, ref = util.append(ref, "table"), children = children}
      }}
    }}
  }}
end

local function build_tooltip(tooltip, amount_string)
  return string.gsub(tooltip, "^.-color=.-%]", "%1"..string.gsub(amount_string, "%%", "%%%%").." ")
end

local quick_ref_gui = {}

function quick_ref_gui.build(player, player_table, name, location)
  local recipe_data = global.recipe_book.recipe[name]

  local show_made_in = player_table.settings.show_made_in_in_quick_ref

  local refs = gui.build(player.gui.screen, {
    {type = "frame", direction = "vertical", ref = {"window"}, children = {
      {type = "flow", style = "flib_titlebar_flow", ref = {"titlebar_flow"}, children = {
        {type = "label", style = "frame_title", caption = {"rb-gui.recipe"}, ignored_by_interaction = true},
        {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
        {
          type = "sprite-button",
          style = "frame_action_button",
          sprite = "rb_expand_white",
          hovered_sprite = "rb_expand_black",
          clicked_sprite = "rb_expand_black",
          tooltip = {"rb-gui.view-details"},
          mouse_button_filter = {"left"},
          actions = {
            on_click = {gui = "main", action = "open_page", class = "recipe", name = name}
          }
        },
        {
          type = "sprite-button",
          style = "frame_action_button",
          sprite = "utility/close_white",
          hovered_sprite = "utility/close_black",
          clicked_sprite = "utility/close_black",
          mouse_button_filter = {"left"},
          actions = {
            on_click = {gui = "quick_ref", action = "close", name = name}
          }
        }
      }},
      {type = "frame", style = "rb_quick_ref_content_frame", direction = "vertical", children = {
        {type = "frame", style = "subheader_frame", children = {
          {type = "label", style = "rb_toolbar_label", ref = {"toolbar_label"}},
          {type = "empty-widget", style = "flib_horizontal_pusher"}
        }},
        {type = "flow", style = "rb_quick_ref_content_flow", direction = "vertical", children = {
          quick_ref_panel({"ingredients"}, {
            {
              type = "sprite-button",
              style = "flib_slot_button_default",
              tooltip = {"rb-gui.seconds-tooltip"},
              sprite = "quantity-time",
              number = recipe_data.energy,
              enabled = false
            }
          }),
          quick_ref_panel{"products"},
          show_made_in and quick_ref_panel{"made_in"} or nil
        }}
      }}
    }}
  })
  refs.titlebar_flow.drag_target = refs.window

  -- to pass to the formatter
  local player_data = {
    force_index = player.force.index,
    player_index = player.index,
    settings = player_table.settings,
    translations = player_table.translations
  }

  local data = formatter(recipe_data, player_data, {always_show = true, is_label = true})
  local label_caption = data.caption

  -- remove glyph from caption, since it's implied
  if player_data.settings.show_glyphs then
    label_caption = string.gsub(label_caption, "^.-nt%]  ", "")
  end

  refs.toolbar_label.caption = label_caption
  refs.toolbar_label.tooltip = data.tooltip

  -- add contents to tables
  local recipe_book = global.recipe_book
  for _, type in ipairs{"ingredients", "products", "made_in"} do
    local group = refs[type]
    if not group then break end -- if made_in doesn't exist
    local i = type == "ingredients" and 1 or 0
    for _, obj in ipairs(recipe_data[type]) do
      local obj_data = recipe_book[obj.class][obj.name]
      local formatter_data = formatter(
        obj_data,
        player_data,
        {amount_string = obj.amount_string, always_show = type ~= "made_in"}
      )
      if formatter_data then
        i = i + 1
        local button_style = formatter_data.is_researched and "flib_slot_button_default" or "flib_slot_button_red"
        local tooltip = build_tooltip(formatter_data.tooltip, obj.amount_string)

        gui.build(group.table, {
          {
            type = "sprite-button",
            style = button_style,
            sprite = constants.class_to_type[obj.class].."/"..obj_data.prototype_name,
            tooltip = tooltip,
            actions = {
              on_click = {gui = "main", action = "open_page", class = obj.class, name = obj.name}
            },
            children = {
              {
                type = "label",
                style = "rb_slot_label",
                caption = obj.quick_ref_amount_string,
                ignored_by_interaction = true
              },
              {
                type = "label",
                style = "rb_slot_label_top",
                caption = string.find(obj.amount_string, "%%") and "%" or "",
                ignored_by_interaction = true
              }
            }
          }
        })
      end
    end
    group.label.caption = {"rb-gui."..string.gsub(type, "_", "-"), i - (type == "ingredients" and 1 or 0)}

    if i == 0 then
      group.flow.visible = false
    end
  end

  -- save to global
  player_table.guis.quick_ref[name] = refs

  -- set window location
  if location then
    refs.window.location = location
  end
end

function quick_ref_gui.destroy(player_table, name)
  local guis = player_table.guis.quick_ref
  local refs = guis[name]
  refs.window.destroy()
  guis[name] = nil
end

function quick_ref_gui.destroy_all(player_table)
  for name in pairs(player_table.guis.quick_ref) do
    quick_ref_gui.destroy(player_table, name)
  end
end

function quick_ref_gui.handle_action(msg, e)
  if msg.action == "close" then
    local player_table = global.players[e.player_index]
    quick_ref_gui.destroy(player_table, msg.name)
    shared.update_quick_ref_button(player_table)
  end
end

function quick_ref_gui.refresh_all(player, player_table)
  for recipe_name, location in pairs(
    table.map(player_table.guis.quick_ref, function(refs) return refs.window.location end)
  ) do
    quick_ref_gui.destroy(player_table, recipe_name)
    quick_ref_gui.build(player, player_table, recipe_name, location)
  end
end

return quick_ref_gui
