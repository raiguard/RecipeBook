-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- RECIPE QUICK REFERENCE GUI

-- dependencies
local event = require('lualib/event')
local gui = require('lualib/gui')
local mod_gui = require('mod-gui')

-- self object
local self = {}

-- -----------------------------------------------------------------------------
-- HANDLERS

gui.add_handlers('recipe_quick_reference', {
  close_button = {},
  window = {}
})

-- -----------------------------------------------------------------------------
-- GUI MANAGEMENT

function self.open(player, player_table, recipe_name)
  -- build GUI structure
  local gui_data = gui.create(mod_gui.get_frame_flow(player), 'recipe_quick_reference', player.index,
    {type='frame', style='dialog_frame', direction='vertical', handlers='window', save_as=true, children={
      -- titlebar
      {type='flow', style='rb_titlebar_flow', direction='horizontal', children={
        {type='label', style='frame_title', caption={'rb-gui.recipe-quick-reference'}},
        {template='pushers.horizontal'},
        {template='close_button'}
      }},
      {type='frame', style='window_content_frame', direction='vertical', children={
        -- ingredients
        {type='label', style='rb_listbox_label', caption={'rb-gui.ingredients'}},
        {type='scroll-pane', style='rb_icon_slot_table_pane', children={
          {type='table', style='rb_icon_slot_table', column_count=4, save_as='ingredients_table'}
        }},
        -- products
        {type='label', style='rb_listbox_label', caption={'rb-gui.products'}},
        {type='scroll-pane', style='rb_icon_slot_table_pane', children={
          {type='table', style='rb_icon_slot_table', column_count=4, save_as='products_table'}
        }}
      }}
    }}
  )
end

function self.close()

end

-- -----------------------------------------------------------------------------

return self