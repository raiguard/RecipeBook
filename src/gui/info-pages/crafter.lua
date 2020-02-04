-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CRAFTER GUI

-- dependencies
local event = require('lualib/event')
local gui = require('lualib/gui')

-- locals
local table_sort = table.sort

-- self object
local self = {}

-- -----------------------------------------------------------------------------
-- HANDLERS

gui.add_handlers('crafter', {
  generic_listbox = {
    on_gui_selection_state_changed = gui.get_handler('common.generic_open_from_listbox')
  }
})

-- -----------------------------------------------------------------------------
-- GUI MANAGEMENT

function self.create(player, player_table, content_container, name)
  local gui_data = gui.create(content_container, 'crafter', player.index,
    gui.call_template('listbox_with_label', 'recipes')
  )

  -- get data
  local crafter_data = global.recipe_book.crafter[name]
  local recipe_translations = player_table.dictionary.recipe.translations

  -- populate recipes table
  local label = gui_data.recipes_label
  local listbox = gui_data.recipes_listbox
  local recipes = crafter_data.recipes
  local recipes_len = #recipes
  local items = {}
  for i=1,recipes_len do
    local recipe = recipes[i]
    items[i] = '[img=recipe/'..recipe..']  '..(recipe_translations[recipe] or recipe)
  end
  listbox.items = items
  label.caption = {'rb-gui.craftable-recipes', recipes_len}

  -- register handler
  gui.register_handlers('crafter', 'generic_listbox', {player_index=player.index, gui_filters=listbox})

  return gui_data
end

function self.destroy(player, content_container)
  gui.destroy(content_container.children[1], 'crafter', player.index)
end

-- -----------------------------------------------------------------------------

return self