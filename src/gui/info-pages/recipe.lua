-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- RECIPE GUI

-- dependencies
local event = require('lualib/event')
local gui = require('lualib/gui')

-- locals
local table_sort = table.sort

-- self object
local self = {}

-- -----------------------------------------------------------------------------
-- HANDLERS

gui.add_handlers('recipe', {
  
})

-- -----------------------------------------------------------------------------
-- GUI MANAGEMENT

function self.create(player, player_table, content_container, name)
  local gui_data = gui.create(content_container, 'recipe', player.index,
    {type='label', caption='recipe'}
  )

  return gui_data
end

function self.destroy(player, content_container)
  gui.destroy(content_container.children[1], 'recipe', player.index)
end

-- -----------------------------------------------------------------------------

return self