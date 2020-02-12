-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- RECIPE GUI

-- dependencies
local event = require('lualib/event')
local gui = require('lualib/gui')

-- locals
local math_max = math.max
local math_min = math.min

-- because LUA doesn't have a math.round...
-- from http://lua-users.org/wiki/SimpleRound
local function math_round(num, numDecimalPlaces)
local mult = 10^(numDecimalPlaces or 0)
return math.floor(num * mult + 0.5) / mult
end

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
  quick_reference_button = {
    on_gui_click = function(e)
      event.raise(open_gui_event, {player_index=e.player_index, gui_type='recipe_quick_reference', object_name=global.players[e.player_index].gui.info.name})
    end
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
      }},
      {type='button', style={horizontally_stretchable=true}, caption={'rb-gui.open-quick-reference'}, mouse_button_filter={'left'},
        handlers='quick_reference_button'}
    }}
  )

  -- get data
  local recipe_book = global.recipe_book
  local recipe_data = recipe_book.recipe[name]
  local dictionary = player_table.dictionary
  local crafter_translations = dictionary.crafter.translations
  local material_translations = dictionary.material.translations
  local technology_translations = dictionary.technology.translations
  local show_hidden = player_table.settings.show_hidden
  local rows = 0

  -- populate ingredients and products
  for _,mode in ipairs{'ingredients', 'products'} do
    local label = gui_data[mode..'_label']
    local listbox = gui_data[mode..'_listbox']
    local materials_list = recipe_data[mode]
    local items = {}
    local items_index = 0
    if mode == 'ingredients' then
      items[1] = ' [img=quantity-time]  '..recipe_data.energy..' seconds'
      items_index = 1
    end
    for ri=1,#materials_list do
      local material = materials_list[ri]
      if show_hidden or not material.hidden then
        items_index = items_index + 1
        items[items_index] = '[img='..material.type..'/'..material.name..']  [font=default-semibold]'..material.amount_string..'[/font] '
          ..material_translations[material.name]
      end
    end
    listbox.items = items
    label.caption = {'rb-gui.'..mode, items_index}
    rows = math_max(rows, math_min(6, items_index))
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
    local items = {}
    local items_index = 0
    if recipe_data.hand_craftable then
      items[1] = '[img=entity/character]  [font=default-semibold]('..recipe_data.energy..'s)[/font] '..dictionary.other.translations.character
      items_index = 1
    end
    for ri=1,#crafters_list do
      local crafter = crafters_list[ri]
      if show_hidden or not crafter.hidden then
        items_index = items_index + 1
        items[items_index] = '[img=entity/'..crafter.name..']  [font=default-semibold]('..math_round(recipe_data.energy/crafter.crafting_speed,2)..'s)[/font] '
          ..crafter_translations[crafter.name]
      end
    end
    listbox.items = items
    label.caption = {'rb-gui.made-in', items_index}
    rows = math_max(rows, math_min(6, items_index))
  end

  -- populate technologies
  do
    local label = gui_data['technologies_label']
    local listbox = gui_data['technologies_listbox']
    local technologies_list = recipe_data.unlocked_by
    local items = {}
    local items_index = 0
    for ri=1,#technologies_list do
      local technology = technologies_list[ri]
      if show_hidden or not technology.hidden then
        items_index = items_index + 1
        items[items_index] = '[img=technology/'..technology.name..']  '..technology_translations[technology.name]
      end
    end
    listbox.items = items
    label.caption = {'rb-gui.unlocked-by', items_index}
    rows = math_max(rows, math_min(6, items_index))
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