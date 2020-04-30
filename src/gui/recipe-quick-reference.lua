-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- RECIPE QUICK REFERENCE GUI

-- dependencies
local event = require("__flib__.control.event")
local gui = require("__flib__.control.gui")

-- locals
local string_find = string.find
local string_gsub = string.gsub

-- self object
local self = {}

-- -----------------------------------------------------------------------------
-- HANDLERS

gui.handlers:extend{recipe_quick_reference={
  close_button = {
    on_gui_click = function(e)
      self.close(game.get_player(e.player_index), global.players[e.player_index], string_gsub(e.element.name, "rb_close_button_", ""))
    end
  },
  material_button = {
    on_gui_click = function(e)
      local _,_,object_class,object_name = string_find(e.element.sprite, "^(.-)/(.-)$")
      event.raise(OPEN_GUI_EVENT, {player_index=e.player_index, gui_type="material", object={object_class, object_name}})
    end
  },
  open_info_button = {
    on_gui_click = function(e)
      event.raise(OPEN_GUI_EVENT, {player_index=e.player_index, gui_type="recipe", object=string_gsub(e.element.name, "rb_open_info_button_", "")})
    end
  }
}}

-- -----------------------------------------------------------------------------
-- GUI MANAGEMENT

function self.open(player, player_table, recipe_name)
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
        material_button_ids[index] = index
      end
    end
    label.caption = {"rb-gui."..mode, #table.children-delta}
  end

  -- register handler for material buttons
  if event.is_enabled("gui.recipe_quick_reference.material_button.on_gui_click", player.index) then
    event.update_gui_filters("gui.recipe_quick_reference.material_button.on_gui_click", player.index, material_button_ids, "add")
  else
    event.enable_group("gui.recipe_quick_reference.material_button", player.index, material_button_ids)
  end
  filters["gui.recipe_quick_reference.material_button"] = material_button_ids

  -- save to global
  data.filters = filters
  data.recipe_name = recipe_name
  player_table.gui.recipe_quick_reference[recipe_name] = data
end

function self.close(player, player_table, recipe_name)
  local guis = player_table.gui.recipe_quick_reference
  local gui_data = guis[recipe_name]
  for group_name,t in pairs(gui_data.filters) do
    for _,name in pairs(event.conditional_event_groups[group_name]) do
      event.update_gui_filters(name, player.index, t, "remove")
    end
  end
  gui_data.window.destroy()
  guis[recipe_name] = nil

  -- disable events if needed
  if table_size(guis) == 0 then
    event.disable_group("gui.recipe_quick_reference", player.index)
  end
end

function self.close_all(player, player_table)
  for name,_ in pairs(player_table.gui.recipe_quick_reference) do
    self.close(player, player_table, name)
  end
end

-- -----------------------------------------------------------------------------

return self