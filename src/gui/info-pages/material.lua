-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- INGREDIENT GUI

-- dependencies
local event = require('__RaiLuaLib__.lualib.event')
local gui = require('__RaiLuaLib__.lualib.gui')

-- locals
local math_max = math.max
local math_min = math.min
local string_gsub = string.gsub

-- self object
local self = {}

-- -----------------------------------------------------------------------------
-- HANDLERS

gui.handlers:extend{material={
  generic_listbox = {
    on_gui_selection_state_changed = gui.handlers.common.generic_open_from_listbox
  }
}}

-- -----------------------------------------------------------------------------
-- GUI MANAGEMENT

function self.create(player, player_table, content_container, name)
  local gui_data = gui.build(content_container, {
    {type='flow', style_mods={horizontal_spacing=8}, direction='horizontal', children={
      gui.templates.listbox_with_label('ingredient_in'),
      gui.templates.listbox_with_label('product_of')
    }}
  }, 'material', player.index)

  -- set up data
  local material_data = global.recipe_book.material[name]
  local recipe_translations = player_table.dictionary.recipe.translations
  local show_hidden = player_table.settings.show_hidden
  local recipes = global.recipe_book.recipe
  local rows = 0

  -- populate tables
  for _,mode in ipairs{'ingredient_in', 'product_of'} do
    local label = gui_data[mode..'_label']
    local listbox = gui_data[mode..'_listbox']
    local recipe_list = material_data[mode]
    local items = {}
    local items_index = 0
    for ri=1,#recipe_list do
      local recipe_name = recipe_list[ri]
      local recipe = recipes[recipe_name]
      if show_hidden or not recipe.hidden then
        items_index = items_index + 1
        items[items_index] = '[img=recipe/'..recipe_name..']  '..(recipe_translations[recipe_name])
      end
    end
    listbox.items = items
    label.caption = {'rb-gui.'..string_gsub(mode, '_', '-'), items_index}
    rows = math_max(rows, math_min(6, items_index))
  end

  -- set table heights
  local height = rows * 28
  gui_data.ingredient_in_frame.style.height = height
  gui_data.product_of_frame.style.height = height

  event.enable_group('gui.material.generic_listbox', player.index, {gui_data.ingredient_in_listbox.index, gui_data.product_of_listbox.index})

  return gui_data
end

function self.destroy(player, content_container)
  event.disable_group('gui.material', player.index)
  content_container.children[1].destroy()
end

-- -----------------------------------------------------------------------------

return self