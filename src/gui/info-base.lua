-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- BASE INFO GUI

-- dependencies
local gui = require('lualib/gui')

-- self object
local self = {}

-- GUI templates
gui.add_templates{
  close_button = {type='sprite-button', style='close_button', sprite='utility/close_white', hovered_sprite='utility/close_black',
    clicked_sprite='utility/close_black', handlers='close_button', mouse_button_filter={'left'}},
  pushers = {
    horizontal = {type='empty-widget', style={horizontally_stretchable=true}},
    vertical = {type='empty-widget', style={vertically_stretchable=true}}
  }
}

-- locals


-- -----------------------------------------------------------------------------
-- HANDLERS



-- -----------------------------------------------------------------------------
-- GUI MANAGEMENT

function self.open(player, player_table)

end

function self.close(player, player_table)

end

function self.update_contents(player, player_table, category, name)
  
end

function self.open_or_update(player, player_table, category, name)
  -- check for pre-existing window
  if player_table.gui.info then
    self.open(player, player_table, category, name)
  else
    self.update(player, player_table, category, name)
  end
end

-- -----------------------------------------------------------------------------

return self