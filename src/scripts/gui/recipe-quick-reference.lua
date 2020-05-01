local recipe_quick_reference_gui = {}

local event = require("__flib__.control.event")
local gui = require("__flib__.control.gui")

local constants = require("scripts.constants")

local string_find = string.find
local string_gsub = string.gsub

gui.add_handlers{recipe_quick_reference={
  close_button = {
    on_gui_click = function(e)
      recipe_quick_reference_gui.close(game.get_player(e.player_index), global.players[e.player_index], string_gsub(e.element.name, "rb_close_button_", ""))
    end
  },
  material_button = {
    on_gui_click = function(e)
      local _,_,object_class,object_name = string_find(e.element.sprite, "^(.-)/(.-)$")
      event.raise(constants.open_gui_event, {player_index=e.player_index, gui_type="material", object={object_class, object_name}})
    end
  },
  open_info_button = {
    on_gui_click = function(e)
      event.raise(constants.open_gui_event, {player_index=e.player_index, gui_type="recipe", object=string_gsub(e.element.name, "rb_open_info_button_", "")})
    end
  }
}}

function recipe_quick_reference_gui.open(player, player_table, recipe_name)
  -- build GUI structure
  local data, filters = gui.build(player.gui.screen, {
    {type="frame", style="dialog_frame", direction="vertical", save_as="window", children={
      -- titlebar
      {type="flow", style="rb_titlebar_flow", direction="horizontal", children={
        {type="label", style="frame_title", caption={"rb-gui.recipe-upper"}},
        {type="empty-widget", style="rb_titlebar_draggable_space", save_as="drag_handle"},
        {type="sprite-button", name="rb_open_info_button_"..recipe_name, style="rb_frame_action_button", sprite="rb_nav_open_info",
          hovered_sprite="rb_nav_open_info_dark", clicked_sprite="rb_nav_open_info_dark", handlers="recipe_quick_reference.open_info_button",
          tooltip={"rb-gui.view-recipe-details"}, mouse_button_filter={"left"}},
        {template="close_button", name="rb_close_button_"..recipe_name, handlers="recipe_quick_reference.close_button"}
      }},
      {type="frame", style="window_content_frame_packed", direction="vertical", children={
        {type="frame", style="subheader_frame", direction="horizontal", children={
          {type="label", style="subheader_caption_label", style_mods={width=207}, caption=player_table.dictionary.recipe.translations[recipe_name]}
        }},
        -- materials
        {type="flow", style_mods={padding=8}, direction="vertical", children={
          gui.templates.quick_reference_scrollpane("ingredients"),
          gui.templates.quick_reference_scrollpane("products")
        }}
      }}
    }}
  })
  -- screen data
  data.drag_handle.drag_target = data.window

  -- get data
  local recipe_data = global.recipe_book.recipe[recipe_name]
  local material_translations = player_table.dictionary.material.translations
  local show_hidden = player_table.settings.show_hidden

  local material_button_ids = {}

  -- populate ingredients and products
  for _,mode in ipairs{"ingredients", "products"} do
    local label = data[mode.."_label"]
    local table = data[mode.."_table"]
    local table_add = table.add
    local materials_list = recipe_data[mode]
    local delta = 0
    if mode == "ingredients" then
      table_add{type="sprite-button", style="quick_bar_slot_button", sprite="quantity-time", number=recipe_data.energy}
      delta = 1
    end
    for ri=1,#materials_list do
      local material = materials_list[ri]
      if show_hidden or not material.hidden then
        local index = table_add{type="sprite-button", style="quick_bar_slot_button", sprite=material.type.."/"..material.name, number=material.amount,
          tooltip=material_translations[material.name], mouse_button_filter={"left"}}.index
        material_button_ids[#material_button_ids+1] = index
      end
    end
    label.caption = {"rb-gui."..mode, #table.children-delta}
  end

  -- register handler for material buttons
  gui.update_filters("recipe_quick_reference.material_button.on_gui_click", player.index, material_button_ids, "add")
  filters["recipe_quick_reference.material_button.on_gui_click"] = material_button_ids

  -- save to global
  data.filters = filters
  data.recipe_name = recipe_name
  player_table.gui.recipe_quick_reference[recipe_name] = data
end

function recipe_quick_reference_gui.close(player, player_table, recipe_name)
  local guis = player_table.gui.recipe_quick_reference
  local gui_data = guis[recipe_name]
  -- only remove filters for this GUI
  local profiler = game.create_profiler()
  for handler_name, filters in pairs(gui_data.filters) do
    gui.update_filters(handler_name, player.index, filters, "remove")
  end
  profiler.stop()
  game.print(profiler)
  gui_data.window.destroy()
  guis[recipe_name] = nil
end

function recipe_quick_reference_gui.close_all(player, player_table)
  for name,_ in pairs(player_table.gui.recipe_quick_reference) do
    recipe_quick_reference_gui.close(player, player_table, name)
  end
end

return recipe_quick_reference_gui