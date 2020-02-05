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
  },
  crafters_listbox = {
    on_gui_selection_state_changed = gui.get_handler('common.open_crafter_from_listbox')
  },
  technologies_listbox = {
    on_gui_selection_state_changed = function(e)
      local _,_,name = e.element.get_item(e.element.selected_index):find('^.*/(.*)%].*$')
      e.element.selected_index = 0
      game.get_player(e.player_index).open_technology_gui(name)
    end
  }
})

-- -----------------------------------------------------------------------------
-- GUI MANAGEMENT

function self.create(player, player_table, content_container, name)
  local gui_data = gui.create(content_container, 'recipe', player.index,
    {type='flow', style={vertical_spacing=8}, direction='vertical', children={
      {type='flow', style={horizontal_spacing=8}, direction='horizontal', children={
        gui.call_template('listbox_with_label', 'ingredients'),
        gui.call_template('listbox_with_label', 'products')
      }},
      {type='flow', style={horizontal_spacing=8}, direction='horizontal', children={
        gui.call_template('listbox_with_label', 'crafters'),
        gui.call_template('listbox_with_label', 'technologies')
      }}
    }}
  )

  -- get data
  local recipe_data = global.recipe_book.recipe[name]
  local dictionary = player_table.dictionary
  local crafter_translations = dictionary.crafter.translations
  local material_translations = dictionary.material.translations
  local technology_translations = dictionary.technology.translations
  local rows = 0

  -- populate ingredients and products
  for _,mode in ipairs{'ingredients', 'products'} do
    local label = gui_data[mode..'_label']
    local listbox = gui_data[mode..'_listbox']
    local materials_list = recipe_data.prototype[mode]
    local materials_len = #materials_list
    local items = {}
    local delta = 0
    if mode == 'ingredients' then
      items[1] = '[img=quantity-time]  '..recipe_data.prototype.energy..' seconds'
      delta = 1
    end
    for ri=1,materials_len do
      local material = materials_list[ri]
      items[ri+delta] = '[img='..material.type..'/'..material.name..']  '..material.amount..'x '..material_translations[material.name]
    end
    listbox.items = items
    label.caption = {'rb-gui.'..mode, materials_len}
    rows = math_max(rows, math_min(6, materials_len+delta))
  end

  -- set material listbox heights
  local height = rows * 28
  gui_data.ingredients_frame.style.height = height
  gui_data.products_frame.style.height = height

  -- populate crafters
  rows = 0
  do
    local label = gui_data['crafters_label']
    local listbox = gui_data['crafters_listbox']
    local crafters_list = recipe_data.made_in
    local crafters_len = #crafters_list
    local items = {}
    for ri=1,crafters_len do
      local crafter = crafters_list[ri]
      items[ri] = '[img=entity/'..crafter.name..']  ('..crafter.crafting_speed..'x) '..crafter_translations[crafter.name]
    end
    listbox.items = items
    label.caption = {'rb-gui.made-in', crafters_len}
    rows = math_max(rows, math_min(6, crafters_len))
  end

  -- populate technologies
  do
    local label = gui_data['technologies_label']
    local listbox = gui_data['technologies_listbox']
    local technologies_list = recipe_data.unlocked_by
    local technologies_len = #technologies_list
    local items = {}
    for ri=1,technologies_len do
      local technology = technologies_list[ri]
      items[ri] = '[img=technology/'..technology..']  '..technology_translations[technology]
    end
    listbox.items = items
    label.caption = {'rb-gui.unlocked-by', technologies_len}
    rows = math_max(rows, math_min(6, technologies_len))
  end

  -- set listbox heights
  height = rows * 28
  gui_data.crafters_frame.style.height = height
  gui_data.technologies_frame.style.height = height

  -- register handlers for listboxes
  gui.register_handlers('recipe', 'material_listboxes', {player_index=player.index, gui_filters={gui_data.ingredients_listbox, gui_data.products_listbox}})
  gui.register_handlers('recipe', 'crafters_listbox', {player_index=player.index, gui_filters=gui_data.crafters_listbox})
  gui.register_handlers('recipe', 'technologies_listbox', {player_index=player.index, gui_filters=gui_data.technologies_listbox})

  return gui_data
end

function self.destroy(player, content_container)
  gui.destroy(content_container.children[1], 'recipe', player.index)
end

-- -----------------------------------------------------------------------------

return self