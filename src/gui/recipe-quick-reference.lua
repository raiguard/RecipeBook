-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- RECIPE QUICK REFERENCE GUI

-- dependencies
local event = require('__RaiLuaLib__.lualib.event')
local gui = require('__RaiLuaLib__.lualib.gui')
local mod_gui = require('mod-gui')

-- locals
local string_find = string.find

-- self object
local self = {}

-- -----------------------------------------------------------------------------
-- HANDLERS

gui.handlers:extend{recipe_quick_reference={
  close_button = {
    on_gui_click = function(e)
      self.close(game.get_player(e.player_index), global.players[e.player_index])
    end
  },
  material_button = {
    on_gui_click = function(e)
      local _,_,object_name = string_find(e.element.sprite, '^.*/(.*)$')
      event.raise(open_gui_event, {player_index=e.player_index, gui_type='material', object_name=object_name})
    end
  },
  open_info_button = {
    on_gui_click = function(e)
      event.raise(open_gui_event, {player_index=e.player_index, gui_type='recipe',
        object_name=global.players[e.player_index].gui.recipe_quick_reference.recipe_name})
    end
  }
}}

-- -----------------------------------------------------------------------------
-- GUI MANAGEMENT

function self.open(player, player_table, recipe_name)
  -- build GUI structure
  local gui_data = gui.build(mod_gui.get_frame_flow(player), {
    {type='frame', style='dialog_frame', direction='vertical', save_as='window', children={
      -- titlebar
      {type='flow', style='rb_titlebar_flow', direction='horizontal', children={
        {type='label', style='frame_title', caption={'rb-gui.recipe-upper'}},
        {template='pushers.horizontal'},
        {type='sprite-button', style='close_button', sprite='rb_nav_open_info', hovered_sprite='rb_nav_open_info_dark', clicked_sprite='rb_nav_open_info_dark',
          handlers='recipe_quick_reference.open_info_button', tooltip={'rb-gui.view-recipe-details'}, mouse_button_filter={'left'}},
        {template='close_button', handlers='recipe_quick_reference.close_button'}
      }},
      {type='frame', style='window_content_frame_packed', direction='vertical', children={
        {type='frame', style='subheader_frame', direction='horizontal', children={
          {type='label', style='subheader_caption_label', style_mods={width=207}, caption=player_table.dictionary.recipe.translations[recipe_name]}
        }},
        -- materials
        {type='flow', style_mods={padding=8}, direction='vertical', children={
          gui.templates.quick_reference_scrollpane('ingredients'),
          gui.templates.quick_reference_scrollpane('products')
        }}
      }}
    }}
  })

  -- get data
  local recipe_data = global.recipe_book.recipe[recipe_name]
  local material_translations = player_table.dictionary.material.translations
  local show_hidden = player_table.settings.show_hidden

  local material_button_ids = {}

  -- populate ingredients and products
  for _,mode in ipairs{'ingredients', 'products'} do
    local label = gui_data[mode..'_label']
    local table = gui_data[mode..'_table']
    local table_add = table.add
    local materials_list = recipe_data[mode]
    local delta = 0
    if mode == 'ingredients' then
      table_add{type='sprite-button', style='quick_bar_slot_button', sprite='quantity-time', number=recipe_data.energy}
      delta = 1
    end
    for ri=1,#materials_list do
      local material = materials_list[ri]
      if show_hidden or not material.hidden then
        material_button_ids[#material_button_ids+1] = table_add{type='sprite-button', style='quick_bar_slot_button', sprite=material.type..'/'..material.name,
          number=material.amount, tooltip=material_translations[material.name], mouse_button_filter={'left'}}.index
      end
    end
    label.caption = {'rb-gui.'..mode, #table.children-delta}
  end

  -- register handler for material buttons
  event.enable_group('gui.recipe_quick_reference.material_button', player.index, material_button_ids)

  -- save to global
  gui_data.recipe_name = recipe_name
  player_table.gui.recipe_quick_reference = gui_data
end

function self.close(player, player_table)
  event.disable_group('gui.recipe_quick_reference', player.index)
  player_table.gui.recipe_quick_reference.window.destroy()
  player_table.gui.recipe_quick_reference = nil
end

function self.open_or_update(player, player_table, recipe_name)
  -- check for pre-existing window
  if player_table.gui.recipe_quick_reference then
    self.close(player, player_table)
  end
  self.open(player, player_table, recipe_name)
end

-- -----------------------------------------------------------------------------

return self