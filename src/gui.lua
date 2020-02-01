-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- GUI

-- dependencies
local event = require('lualib/event')
local gui = require('lualib/gui')

-- self object
local self = {}

-- GUI templates
gui.add_templates{
  close_button = {type='sprite-button', style='close_button', sprite='utility/close_white', hovered_sprite='utility/close_black',
  clicked_sprite='utility/close_black'},
  pushers = {
    horizontal = {type='empty-widget', style={horizontally_stretchable=true}},
    vertical = {type='empty-widget', style={vertically_stretchable=true}}
  }
}

-- -----------------------------------------------------------------------------
-- SEARCH GUI

-- -------------------------------------
-- HANDLERS



-- -------------------------------------
-- MANAGEMENT

local function open_search(player, player_table)
  local gui_data = gui.create(player.gui.screen, 'search', player.index,
    {type='frame', name='rb_search_window', style='dialog_frame', direction='vertical', save_as='window', children={
      -- titlebar
      {type='flow', style='rb_titlebar_flow', children={
        {type='label', style='frame_title', caption={'mod-name.RecipeBook'}},
        {type='empty-widget', style='rb_titlebar_draggable_space', save_as='drag_handle'},
        {template='close_button'}
      }},
      {type='frame', style='window_content_frame_packed', children={
        -- toolbar
        {type='frame', style='subheader_frame', children={
          {type='empty-widget', style={height=24, horizontally_stretchable=true}}
        }}
      }}
    }}
  )
  gui_data.drag_handle.drag_target = gui_data.window
  gui_data.window.force_auto_center()
end

local function close_search(player, player_table)

end

-- -----------------------------------------------------------------------------
-- INFO GUI



-- -----------------------------------------------------------------------------
-- PINNED RECIPE GUI



-- -----------------------------------------------------------------------------
-- GUI NAVIGATION HANDLERS



-- -----------------------------------------------------------------------------
-- OBJECT

-- toggle the search GUI
-- this will close the info GUI if it is open
function self.toggle_search(player, player_table)
  local search_window = player.gui.screen.rb_search_window
  if search_window then
    
  else
    -- check if we actually CAN open the GUI
    if player_table.flags.can_open_gui then
      open_search(player, player_table)
    else
      -- set flag and tell the player that they cannot open it
      player_table.flags.tried_to_open_gui = true
      player.print{'rb-message.translation-not-finished'}
    end
  end
end

-- close all GUIs, including the pinned recipe GUI
function self.close_all(player, player_table)

end

-- -----------------------------------------------------------------------------

return self