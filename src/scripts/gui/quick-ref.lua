local quick_ref_gui = {}

local event = require("__flib__.event")
local gui = require("__flib__.gui")

local constants = require("constants")
local formatter = require("scripts.formatter")

gui.add_templates{
  quick_ref_panel = function(name, children)
    return {type="flow", direction="vertical", children={
      {type="label", style="bold_label", save_as=name..".label"},
      {type="frame", style="rb_slot_table_frame", save_as=name..".frame", children={
        {type="scroll-pane", style="rb_slot_table_scroll_pane", save_as=name..".scroll_pane", children={
          {type="table", style="slot_table", column_count=5, save_as=name..".table", children=children}
        }}
      }}
    }}
  end
}

gui.add_handlers{
  quick_ref = {
    close_button = {
      on_gui_click = function(e)
        local _, _, name = string.find(e.element.name, "rb_quick_ref_close_button__(.*)")
        quick_ref_gui.destroy(game.get_player(e.player_index), global.players[e.player_index], name)
        event.raise(constants.events.update_quick_ref_button, {player_index=e.player_index})
      end
    },
    open_info_button = {
      on_gui_click = function(e)
        local _, _, name = string.find(e.element.name, "rb_quick_ref_expand_button__(.*)")
        event.raise(constants.events.open_page, {player_index=e.player_index, obj_class="recipe", obj_name=name})
      end
    },
    material_button = {
      on_gui_click = function(e)
        local _, _, class, name = string.find(e.element.sprite, "^(.-)/(.-)$")
        event.raise(constants.events.open_page, {player_index=e.player_index, obj_class=class, obj_name=name})
      end
    }
  }
}

function quick_ref_gui.create(player, player_table, name)
  local recipe_data = global.recipe_book.recipe[name]

  local gui_data, filters = gui.build(player.gui.screen, {
    {type="frame", direction="vertical", save_as="window", children={
      {type="flow", save_as="titlebar.flow", children={
        {type="label", style="frame_title", caption={"rb-gui.recipe"}, elem_mods={ignored_by_interaction=true}},
        {type="empty-widget", style="rb_titlebar_drag_handle", elem_mods={ignored_by_interaction=true}},
        {template="frame_action_button", name="rb_quick_ref_expand_button__"..name, tooltip={"rb-gui.view-details"}, sprite="rb_expand_white",
          hovered_sprite="rb_expand_black", clicked_sprite="rb_expand_black", handlers="quick_ref.open_info_button"},
        {template="frame_action_button", name="rb_quick_ref_close_button__"..name, sprite="utility/close_white", hovered_sprite="utility/close_black",
          clicked_sprite="utility/close_black", handlers="quick_ref.close_button"}
      }},
      {type="frame", style="rb_quick_ref_content_frame", direction="vertical", children={
        {type="frame", style="subheader_frame", children={
          {type="label", style="rb_toolbar_label", save_as="toolbar_label"},
          {template="pushers.horizontal"}
        }},
        {type="flow", style="rb_quick_ref_content_flow", direction="vertical", children={
          gui.templates.quick_ref_panel("ingredients", {
            {type="sprite-button", style="flib_slot_button_default", tooltip={"rb-gui.seconds-tooltip"}, sprite="quantity-time", number=recipe_data.energy,
              enabled=false}
          }),
          gui.templates.quick_ref_panel("products")
        }}
      }}
    }}
  })
  gui_data.titlebar.flow.drag_target = gui_data.window

  gui.update_filters("quick_ref.material_button", player.index, {"rb_quick_ref_material_button"}, "add")

  -- to pass to the formatter
  local player_data = {
    force_index = player.force.index,
    player_index = player.index,
    settings = player_table.settings,
    translations = player_table.translations
  }

  local _, _, label_caption, label_tooltip = formatter(recipe_data, player_data, nil, true, true)

  -- remove glyph from caption, since it's implied
  if player_data.settings.show_glyphs then
    label_caption = string.gsub(label_caption, "^.-nt%]  ", "")
  end

  gui_data.toolbar_label.caption = label_caption
  gui_data.toolbar_label.tooltip = label_tooltip

  -- add contents to tables
  local material_data = global.recipe_book.material
  for _, type in ipairs{"ingredients", "products"} do
    local group = gui_data[type]
    local table_add = group.table.add
    local i = type == "ingredients" and 1 or 0
    for _, obj in ipairs(recipe_data[type]) do
      local obj_data = material_data[obj.type.."."..obj.name]
      local _, style, _, tooltip = formatter(obj_data, player_data, obj.amount_string, true)
      i = i + 1

      local button_style = string.find(style, "unresearched") and "flib_slot_button_red" or "flib_slot_button_default"
      tooltip = string.gsub(tooltip, "^.-color=.-%]", "%1"..string.gsub(obj.amount_string, "%%", "%%%%").." ")
      local shown_string = obj.avg_amount_string and "~"..obj.avg_amount_string or string.gsub(obj.amount_string, "^.-(%d+)x$", "%1")

      local button = table_add{
        type = "sprite-button",
        name = "rb_quick_ref_material_button__"..i,
        style = button_style,
        sprite = obj.type.."/"..obj.name,
        tooltip = tooltip,
      }
      button.add{
        type = "label",
        style = "rb_slot_label",
        caption = shown_string,
        ignored_by_interaction = true
      }
      button.add{
        type = "label",
        style = "rb_slot_label_top",
        caption = string.find(obj.amount_string, "%%") and "%" or "",
        ignored_by_interaction = true
      }
      group.label.caption = {"rb-gui."..type, i - (type == "ingredients" and 1 or 0)}
    end
  end

  -- save to global
  gui_data.filters = filters
  player_table.gui.quick_ref[name] = gui_data
end

function quick_ref_gui.destroy(player, player_table, name)
  local guis = player_table.gui.quick_ref
  local gui_data = guis[name]
  -- only remove filters for this GUI
  for handler_name, filters in pairs(gui_data.filters) do
    gui.update_filters(handler_name, player.index, filters, "remove")
  end
  gui_data.window.destroy()
  guis[name] = nil
end

function quick_ref_gui.destroy_all(player, player_table)
  for name in pairs(player_table.gui.quick_ref) do
    quick_ref_gui.destroy(player, player_table, name)
  end
end

return quick_ref_gui