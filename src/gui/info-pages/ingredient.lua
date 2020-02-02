-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- INGREDIENT GUI

-- dependencies
local event = require('lualib/event')
local gui = require('lualib/gui')

-- locals
local table_sort = table.sort

-- self object
local self = {}

-- -----------------------------------------------------------------------------
-- HANDLERS

gui.add_handlers('ingredient', {

})

-- -----------------------------------------------------------------------------
-- GUI MANAGEMENT

function self.create(player, player_table, content_container, name)
  local gui_data = gui.create(content_container, 'ingredient', player.index,
    {type='label', caption='ingredient'}
  )

  return gui_data
end

function self.destroy(player, content_container)
  gui.destroy(content_container.children[1], 'ingredient', player.index)
end

-- -----------------------------------------------------------------------------

return self