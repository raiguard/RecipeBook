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
  local show_hidden = player_table.settings.show_hidden

  -- populate recipes table
  local label = gui_data.recipes_label
  local listbox = gui_data.recipes_listbox
  local recipes = crafter_data.recipes
  local items = {}
  local items_index = 0
  for i=1,#recipes do
    local recipe = recipes[i]
    if show_hidden or not recipe.hidden then
      local recipe_name = recipe.name
      items_index = items_index + 1
      items[items_index] = '[img=recipe/'..recipe_name..']  '..(recipe_translations[recipe_name])
    end
  end
  listbox.items = items
  label.caption = {'rb-gui.craftable-recipes', items_index}

  -- register handler
  gui.register_handlers('crafter', 'generic_listbox', {player_index=player.index, gui_filters=listbox})

  return gui_data
end

function self.destroy(player, content_container)
  gui.destroy(content_container.children[1], 'crafter', player.index)
end

-- -----------------------------------------------------------------------------

return self