-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- RECIPE GUI

-- dependencies
local event = require('__RaiLuaLib__.lualib.event')
local gui = require('__RaiLuaLib__.lualib.gui')

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

gui.handlers:extend{recipe={
  material_listboxes = {
    on_gui_selection_state_changed = gui.handlers.common.open_material_from_listbox
  },
  crafters_listbox = {
    on_gui_selection_state_changed = gui.handlers.common.open_crafter_from_listbox
  },
  quick_reference_button = {
    on_gui_click = function(e)
      event.raise(OPEN_GUI_EVENT, {player_index=e.player_index, gui_type='recipe_quick_reference', object=global.players[e.player_index].gui.info.name})
    end
  },
  technologies_listbox = {
    on_gui_selection_state_changed = function(e)
      local _,_,name = e.element.get_item(e.element.selected_index):find('^.*/(.*)%].*$')
      e.element.selected_index = 0
      game.get_player(e.player_index).open_technology_gui(name)
    end
  }
}}

-- -----------------------------------------------------------------------------
-- GUI MANAGEMENT

function self.create(player, player_table, content_container, name)
  local gui_data = gui.build(content_container, {
    {type='flow', style_mods={vertical_spacing=8}, direction='vertical', children={
      {type='flow', style_mods={horizontal_spacing=8}, direction='horizontal', children={
        gui.templates.listbox_with_label('ingredients'),
        gui.templates.listbox_with_label('products')
      }},
      {type='flow', style_mods={horizontal_spacing=8}, direction='horizontal', children={
        gui.templates.listbox_with_label('crafters'),
        gui.templates.listbox_with_label('technologies')
      }},
      {type='button', style_mods={horizontally_stretchable=true}, caption={'rb-gui.open-quick-reference'}, mouse_button_filter={'left'},
        handlers='recipe.quick_reference_button'}
    }}
  }, 'recipe', player.index)

  -- get data
  local recipe_book = global.recipe_book
  local recipe_data = recipe_book.recipe[name]
  local crafters = recipe_book.crafter
  local technologies = recipe_book.technology
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
          ..material_translations[material.type..','..material.name]
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
      local crafter_name = crafters_list[ri]
      local crafter = crafters[crafter_name]
      if show_hidden or not crafter.hidden then
        items_index = items_index + 1
        items[items_index] = '[img=entity/'..crafter_name..']  [font=default-semibold]('..math_round(recipe_data.energy/crafter.crafting_speed,2)..'s)[/font] '
          ..crafter_translations[crafter_name]
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
      local technology_name = technologies_list[ri]
      local technology = technologies[technology_name]
      if show_hidden or not technology.hidden then
        items_index = items_index + 1
        items[items_index] = '[img=technology/'..technology_name..']  '..technology_translations[technology_name]
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
  event.enable_group('gui.recipe.material_listboxes', player.index, {gui_data.ingredients_listbox, gui_data.products_listbox})
  event.enable_group('gui.recipe.crafters_listbox', player.index, gui_data.crafters_listbox)
  event.enable_group('gui.recipe.technologies_listbox', player.index, gui_data.technologies_listbox)

  return gui_data
end

function self.destroy(player, content_container)
  event.disable_group('gui.recipe', player.index)
  content_container.children[1].destroy()
end

-- -----------------------------------------------------------------------------

return self