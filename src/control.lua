-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CONTROL SCRIPTING

-- dependencies
local event = require('__RaiLuaLib__.lualib.event')
local gui = require('__RaiLuaLib__.lualib.gui')
local mod_gui = require('mod-gui')
local translation = require('__RaiLuaLib__.lualib.translation')

-- globals
open_gui_event = event.generate_id('open_gui')
reopen_source_event = event.generate_id('reopen_source')
info_guis = {crafter=true, material=true, recipe=true}

-- constants
local INTERFACE_VERSION = 1

-- locals
local string_find = string.find
local string_lower = string.lower
local string_sub = string.sub

-- GUI templates
gui.add_templates{
  close_button = {type='sprite-button', style='close_button', sprite='utility/close_white', hovered_sprite='utility/close_black',
    clicked_sprite='utility/close_black', handlers='close_button', mouse_button_filter={'left'}},
  pushers = {
    horizontal = {type='empty-widget', style_mods={horizontally_stretchable=true}},
    vertical = {type='empty-widget', style_mods={vertically_stretchable=true}}
  },
  listbox_with_label = function(name)
    return
    {type='flow', direction='vertical', children={
      {type='label', style='rb_listbox_label', save_as=name..'_label'},
      {type='frame', style='rb_listbox_frame', save_as=name..'_frame', children={
        {type='list-box', style='rb_listbox', save_as=name..'_listbox'}
      }}
    }}
  end,
  quick_reference_scrollpane = function(name)
    return
    {type='flow', direction='vertical', children={
      {type='label', style='rb_listbox_label', save_as=name..'_label'},
      {type='frame', style='rb_icon_slot_table_frame', style_mods={maximal_height=160}, children={
        {type='scroll-pane', style='rb_icon_slot_table_scrollpane', children={
          {type='table', style='rb_icon_slot_table', style_mods={width=200}, column_count=5, save_as=name..'_table'}
        }}
      }}
    }}
  end
}

-- common GUI handlers
gui.add_handlers('common', {
  generic_open_from_listbox = function(e)
    local _,_,category,object_name = string_find(e.element.get_item(e.element.selected_index), '^%[img=(.-)/(.-)%].*$')
    event.raise(open_gui_event, {player_index=e.player_index, gui_type=category, object_name=object_name})
  end,
  open_material_from_listbox = function(e)
    local selected_item = e.element.get_item(e.element.selected_index)
    if string_sub(selected_item, 1, 1) == ' ' then
      e.element.selected_index = 0
    else
      local _,_,object_name = string_find(selected_item, '^%[img=.-/(.-)%].*$')
      event.raise(open_gui_event, {player_index=e.player_index, gui_type='material', object_name=object_name})
    end
  end,
  open_crafter_from_listbox = function(e)
    local _,_,object_name = string_find(e.element.get_item(e.element.selected_index), '^%[img=.-/(.-)%].*$')
    if object_name == 'character' then
      e.element.selected_index = 0
    else
      event.raise(open_gui_event, {player_index=e.player_index, gui_type='crafter', object_name=object_name})
    end
  end
})

-- modules
local search_gui = require('gui.search')
local recipe_quick_reference_gui = require('gui.recipe-quick-reference')
local info_gui = require('gui.info-base')

-- -----------------------------------------------------------------------------
-- RECIPE DATA

-- builds recipe data table
local function build_recipe_data()
  -- table skeletons
  local recipe_book = {
    crafter = {},
    material = {},
    recipe = {},
    technology = {}
  }
  local translation_data = {
    crafter = {},
    material = {},
    recipe = {},
    technology = {}
  }
  
  -- iterate crafters
  for name,prototype in pairs(game.get_filtered_entity_prototypes{
    {filter='type', type='assembling-machine'},
    {filter='type', type='furnace'}
  })
  do
    recipe_book.crafter[name] = {
      crafting_speed = prototype.crafting_speed,
      hidden = prototype.has_flag('hidden'),
      categories = prototype.crafting_categories,
      recipes = {},
      sprite_class = 'entity'
    }
    translation_data.crafter[#translation_data.crafter+1] = {internal=name, localised=prototype.localised_name}
  end

  -- iterate materials
  for name,prototype in pairs(util.merge{game.fluid_prototypes, game.item_prototypes}) do
    local is_fluid = prototype.object_name == 'LuaFluidPrototype' and true or false
    local hidden
    if is_fluid then
      hidden = prototype.hidden
    else
      hidden = prototype.has_flag('hidden')
    end
    recipe_book.material[name] = {
      hidden = hidden,
      ingredient_in = {},
      product_of = {},
      unlocked_by = {},
      sprite_class = is_fluid and 'fluid' or 'item'
    }
    translation_data.material[#translation_data.material+1] = {internal=name, localised=prototype.localised_name}
  end

  -- iterate recipes
  for name,prototype in pairs(game.recipe_prototypes) do
    local data = {
      energy = prototype.energy,
      hand_craftable = prototype.category == 'crafting',
      hidden = prototype.hidden,
      made_in = {},
      unlocked_by = {},
      sprite_class = 'recipe'
    }
    -- ingredients / products
    local material_book = recipe_book.material
    for _,mode in ipairs{'ingredients', 'products'} do
      local materials = prototype[mode]
      for i=1,#materials do
        local material = materials[i]
        -- build amount string, to display probability, [min/max] amount - includes the 'x'
        local amount = material.amount
        local amount_string = amount and (tostring(amount)..'x') or (material.amount_min..'-'..material.amount_max..'x')
        local probability = material.probability
        if probability and probability < 1 then
          amount_string = tostring(probability * 100)..'% '..amount_string
        end
        material.amount_string = amount_string
        -- add hidden flag to table
        material.hidden = material_book[material.name].hidden
      end
      -- add to data
      data[mode] = materials
    end
    -- made in
    local category = prototype.category
    for crafter_name,crafter_data in pairs(recipe_book.crafter) do
      if crafter_data.categories[category] then
        data.made_in[#data.made_in+1] = crafter_name
        crafter_data.recipes[#crafter_data.recipes+1] = {name=name, hidden=prototype.hidden}
      end
    end
    -- material: ingredient in
    local ingredients = prototype.ingredients
    for i=1,#ingredients do
      local ingredient = ingredients[i]
      local ingredient_data = recipe_book.material[ingredient.name]
      if ingredient_data then
        ingredient_data.ingredient_in[#ingredient_data.ingredient_in+1] = name
      end
    end
    -- material: product of
    local products = prototype.products
    for i=1,#products do
      local product = products[i]
      local product_data = recipe_book.material[product.name]
      if product_data then
        product_data.product_of[#product_data.product_of+1] = name
      end
    end
    -- insert into recipe book
    recipe_book.recipe[name] = data
    -- translation data
    translation_data.recipe[#translation_data.recipe+1] = {internal=name, localised=prototype.localised_name}
  end

  -- iterate technologies
  for name,prototype in pairs(game.technology_prototypes) do
    for _,modifier in ipairs(prototype.effects) do
      if modifier.type == 'unlock-recipe' then
        -- add to recipe data
        local recipe = recipe_book.recipe[modifier.recipe]
        recipe.unlocked_by[#recipe.unlocked_by+1] = name
      end
    end
    recipe_book.technology[name] = {hidden=prototype.hidden}
    translation_data.technology[#translation_data.technology+1] = {internal=prototype.name, localised=prototype.localised_name}
  end

  -- misc translation data
  translation_data.other = {
    {internal='character', localised={'entity-name.character'}}
  }

  -- apply to global
  global.recipe_book = recipe_book
  global.__lualib.translation.translation_data = translation_data
end

local function translate_whole(player)
  for name,data in pairs(global.__lualib.translation.translation_data) do
    translation.start(player, name, data, {include_failed_translations=true, lowercase_sorted_translations=true})
  end
end

local function translate_for_all_players()
  for _,player in ipairs(game.connected_players) do
    translate_whole(player)
  end
end

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS

local function import_player_settings(player)
  local mod_settings = player.mod_settings
  return {
    default_category = mod_settings['rb-default-search-category'].value,
    show_hidden = mod_settings['rb-show-hidden-objects'].value,
    show_mod_gui_button = mod_settings['rb-show-mod-gui-button'].value
  }
end

local function setup_player(player, index)
  local data = {
    flags = {
      can_open_gui = false
    },
    history = {
      session = {position=0},
      overall = {}
    },
    gui = {},
    settings = import_player_settings(player)
  }
  data.gui.mod_gui_button = mod_gui.get_button_flow(player).add{type='sprite-button', name='recipe_book_button', style=mod_gui.button_style,
    sprite='rb_mod_gui_icon', tooltip={'mod-name.RecipeBook'}}
  data.gui.mod_gui_button.visible = data.settings.show_mod_gui_button
  global.players[index] = data
end

-- closes all of a player's open GUIs
local function close_player_guis(player, player_table)
  local gui_data = player_table.gui
  player_table.flags.can_open_gui = false
  if gui_data.search then
    search_gui.close(player, player_table)
  end
  if gui_data.info then
    info_gui.close(player, player_table)
  end
  if gui_data.recipe_quick_reference then
    recipe_quick_reference_gui.close(player, player_table)
  end
end

-- close the player's GUIs, then start translating
local function close_guis_then_translate(e)
  local player = game.get_player(e.player_index)
  close_player_guis(player, global.players[e.player_index])
  translate_whole(game.get_player(e.player_index))
end

event.on_init(function()
  global.players = {}
  for i,p in pairs(game.players) do
    setup_player(p, i)
  end
  build_recipe_data()
  translate_for_all_players()
  event.register(translation.retranslate_all_event, close_guis_then_translate)
end)

event.on_load(function()
  event.register(translation.retranslate_all_event, close_guis_then_translate)
end)

-- player insertion and removal
event.on_player_created(function(e)
  setup_player(game.get_player(e.player_index), e.player_index)
end)
event.on_player_removed(function(e)
  global.players[e.player_index] = nil
end)

-- update player settings
event.on_runtime_mod_setting_changed(function(e)
  if string_sub(e.setting, 1, 3) == 'rb-' then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    player_table.settings = import_player_settings(player)
    -- show or hide mod GUI button
    player_table.gui.mod_gui_button.visible = player_table.settings.show_mod_gui_button
  end
end)

-- retranslate all dictionaries for a player when they re-join
event.on_player_joined_game(function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  close_player_guis(player, player_table)
  translate_whole(player)
end)

-- when a translation is finished
event.register(translation.finish_event, function(e)
  local player_table = global.players[e.player_index]
  if not player_table.dictionary then player_table.dictionary = {} end

  -- add to player table
  player_table.dictionary[e.dictionary_name] = {
    lookup = e.lookup,
    lookup_lower = e.lookup_lower,
    sorted_translations = e.sorted_translations,
    translations = e.translations
  }

  -- set flag if we're done
  if global.__lualib.translation.players[e.player_index].active_translations_count == 0 then
    player_table.flags.can_open_gui = true
    if player_table.flags.tried_to_open_gui then
      player_table.flags.tried_to_open_gui = nil
      game.get_player(e.player_index).print{'rb-message.translation-finished'}
    end
  end
end)

local open_fluid_types = {
  ['pipe'] = true,
  ['pipe-to-ground'] = true,
  ['storage-tank'] = true,
  ['pump'] = true,
  ['offshore-pump'] = true,
  ['fluid-wagon'] = true
}

-- recipe book hotkey (default CONTROL + B)
event.register('rb-toggle-search', function(e)
  -- get player's currently selected entity to check for a fluid filter
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local selected = player.selected
  if player.mod_settings['rb-open-fluid-hotkey'].value then
    if selected and selected.valid and open_fluid_types[selected.type] then
      local fluidbox = selected.fluidbox
      if fluidbox and fluidbox.valid then
        local locked_fluid = fluidbox.get_locked_fluid(1)
        if locked_fluid then
          event.raise(open_gui_event, {player_index=e.player_index, gui_type='material', object_name=locked_fluid})
          return
        end
      end
    end
  end
  search_gui.toggle(player, player_table)
end)

-- mod gui button
event.on_gui_click(function(e)
  -- read player's cursor stack to see if we should open the material GUI
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local cursor_stack = player.cursor_stack
  if cursor_stack and cursor_stack.valid and cursor_stack.valid_for_read then
    -- the player is holding something, so open to its material GUI
    event.raise(open_gui_event, {player_index=e.player_index, gui_type='material', object_name=cursor_stack.name})
  else
    event.raise(open_gui_event, {player_index=e.player_index, gui_type='search'})
  end
end, {gui_filters='recipe_book_button'})

-- reopen the search GUI when the back button is pressed
event.register(reopen_source_event, function(e)
  local source_data = e.source_data
  if source_data.mod_name == 'RecipeBook' and source_data.gui_name == 'search' then
    search_gui.toggle(game.get_player(e.player_index), global.players[e.player_index], source_data)
  end
end)

-- open the specified GUI
event.register(open_gui_event, function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local gui_type = e.gui_type
  -- protected open
  if player_table.flags.can_open_gui then
    -- check for existing GUI
    if gui_type == 'search' then
      -- don't do anything if it's already open
      if player_table.gui.search then return end
      search_gui.open(player, player_table)
    elseif info_guis[gui_type] then
      info_gui.open_or_update(player, player_table, gui_type, e.object_name, e.source_data)
    elseif gui_type == 'recipe_quick_reference' then
      recipe_quick_reference_gui.open_or_update(player, player_table, e.object_name)
    end
  else
    -- set flag and tell the player that they cannot open it
    player_table.flags.tried_to_open_gui = true
    player.print{'rb-message.translation-not-finished'}
  end
end)

-- -----------------------------------------------------------------------------
-- REMOTE

remote.add_interface('RecipeBook', {
  open_info_gui = function(player_index, category, object_name, source_data)
    -- error checking
    if not info_guis[category] then error('Invalid Recipe Book category: '..category) end
    if not object_name then error('Must provide an object name!') end
    if source_data and (not source_data.mod_name or not source_data.gui_name) then
      error('Incomplete source_data table!')
    end
    -- raise internal mod event
    event.raise(open_gui_event, {player_index=player_index, gui_type=category, object_name=object_name, source_data=source_data})
  end,
  reopen_source_event = function() return reopen_source_event end,
  version = function() return INTERFACE_VERSION end
})

-- -----------------------------------------------------------------------------
-- MIGRATIONS

-- table of migration functions
local migrations = {
  ['1.1.0'] = function(e)
    -- update active_translations_count to properly reflect the active translations
    local __translation = global.__lualib.translation
    local count = 0
    for _,t in pairs(__translation.players) do
      count = count + t.active_translations_count
    end
    __translation.active_translations_count = count
  end
}

-- returns true if v2 is newer than v1, false if otherwise
local function compare_versions(v1, v2)
  local v1_split = util.split(v1, '.')
  local v2_split = util.split(v2, '.')
  for i=1,#v1_split do
    if v1_split[i] < v2_split[i] then
      return true
    end
  end
  return false
end

-- handle migrations
event.on_configuration_changed(function(e)
  local changes = e.mod_changes[script.mod_name]
  if changes then
    local old = changes.old_version
    if old then
      -- version migrations
      local migrate = false
      for v,f in pairs(migrations) do
        if migrate or compare_versions(old, v) then
          migrate = true
          log('Applying migration: '..v)
          f(e)
        end
      end
    else
      -- our mod was just added, so all of the generic migrations were done in on_init
      return
    end
  end
  -- generic migrations
  log('Applying generic migrations')
  for _,p in ipairs(game.connected_players) do
    close_player_guis(p, global.players[p.index])
  end
  build_recipe_data()
  translate_for_all_players()
end)