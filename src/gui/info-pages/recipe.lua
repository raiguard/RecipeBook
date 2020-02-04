-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- RECIPE GUI

-- dependencies
local event = require('lualib/event')
local gui = require('lualib/gui')

-- locals
local math_max = math.max
local math_min = math.min
local table_sort = table.sort

-- self object
local self = {}

-- -----------------------------------------------------------------------------
-- HANDLERS

gui.add_handlers('recipe', {
  material_listboxes = {
    on_gui_selection_state_changed = gui.get_handler('common.open_material_from_listbox')
  }
})

-- -----------------------------------------------------------------------------
-- GUI MANAGEMENT

function self.create(player, player_table, content_container, name)
  local gui_data = gui.create(content_container, 'recipe', player.index,
    {type='flow', style={horizontal_spacing=8}, direction='horizontal', children={
      gui.call_template('listbox_with_label', 'ingredients'),
      gui.call_template('listbox_with_label', 'products')
    }}
  )

  -- get data
  local recipe_data = global.recipe_book.recipe[name]
  local dictionary = player_table.dictionary
  local crafter_translations = dictionary.crafter.translations
  local material_translations = dictionary.material.translations
  local rows = 0

  -- populate ingredients and products
  for _,mode in ipairs{'ingredients', 'products'} do
    local label = gui_data[mode..'_label']
    local listbox = gui_data[mode..'_listbox']
    local materials_list = recipe_data.prototype[mode]
    local materials_len = #materials_list
    local items = {}
    for ri=1,materials_len do
      local material = materials_list[ri]
      items[ri] = '[img='..material.type..'/'..material.name..']  '..material.amount..'x '..material_translations[material.name]
    end
    listbox.items = items
    label.caption = {'rb-gui.'..mode, materials_len}
    rows = math_max(rows, math_min(6, materials_len))
  end

  -- set listbox heights
  local height = rows * 28
  gui_data.ingredients_frame.style.height = height
  gui_data.products_frame.style.height = height

  -- register handler for materials
  gui.register_handlers('recipe', 'material_listboxes', {player_index=player.index, gui_filters={gui_data.ingredients_listbox, gui_data.products_listbox}})

  return gui_data
end

function self.destroy(player, content_container)
  gui.destroy(content_container.children[1], 'recipe', player.index)
end

-- -----------------------------------------------------------------------------

return self