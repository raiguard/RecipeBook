-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CONTROL SCRIPTING

-- dependencies
local event = require('__RaiLuaLib__.lualib.event')
local gui = require('__RaiLuaLib__.lualib.gui')
local migration = require('__RaiLuaLib__.lualib.migration')
local translation = require('__RaiLuaLib__.lualib.translation')

-- globals
INFO_GUIS = {crafter=true, material=true, recipe=true}
OPEN_GUI_EVENT = event.get_id('open_gui')
REOPEN_SOURCE_EVENT = event.get_id('reopen_source')

-- locals
local string_find = string.find
local string_sub = string.sub
local table_remove = table.remove

-- GUI templates
gui.templates:extend{
  close_button = {type='sprite-button', style='rb_frame_action_button', sprite='utility/close_white', hovered_sprite='utility/close_black',
    clicked_sprite='utility/close_black', mouse_button_filter={'left'}},
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
gui.handlers:extend{common={
  generic_open_from_listbox = function(e)
    local _,_,category,object_name = string_find(e.element.get_item(e.element.selected_index), '^%[img=(.-)/(.-)%].*$')
    event.raise(OPEN_GUI_EVENT, {player_index=e.player_index, gui_type=category, object=object_name})
  end,
  open_material_from_listbox = function(e)
    local selected_item = e.element.get_item(e.element.selected_index)
    if string_sub(selected_item, 1, 1) == ' ' then
      e.element.selected_index = 0
    else
      local _,_,object_class,object_name = string_find(selected_item, '^%[img=(.-)/(.-)%].*$')
      event.raise(OPEN_GUI_EVENT, {player_index=e.player_index, gui_type='material', object={object_class, object_name}})
    end
  end,
  open_crafter_from_listbox = function(e)
    local _,_,object_name = string_find(e.element.get_item(e.element.selected_index), '^%[img=.-/(.-)%].*$')
    if object_name == 'character' then
      e.element.selected_index = 0
    else
      event.raise(OPEN_GUI_EVENT, {player_index=e.player_index, gui_type='crafter', object=object_name})
    end
  end
}}

-- modules
local search_gui = require('gui.search')
local recipe_quick_reference_gui = require('gui.recipe-quick-reference')
local info_gui = require('gui.info-base')
local recipe_data = require('scripts.recipe-data')

-- -----------------------------------------------------------------------------
-- BOOTSTRAP / PLAYER DATA

local function setup_player(player, index)
  local data = {
    flags = {
      can_open_gui = false
    },
    history = {
      session = {position=0},
      overall = {}
    },
    gui = {
      recipe_quick_reference = {}
    }
  }
  global.players[index] = data
end

local function run_translations(player)
  for name,data in pairs(global.__lualib.translation.translation_data) do
    translation.start(player, name, data, {include_failed_translations=true, lowercase_sorted_translations=true})
  end
end

local function import_player_settings(player, player_table)
  local mod_settings = player.mod_settings
  player_table.settings = {
    default_category = mod_settings['rb-default-search-category'].value,
    show_hidden = mod_settings['rb-show-hidden-objects'].value,
    use_fuzzy_search = mod_settings['rb-use-fuzzy-search'].value
  }
end

-- destroys all of a player's open GUIs
local function destroy_player_guis(player, player_table)
  local gui_data = player_table.gui
  player_table.flags.can_open_gui = false
  player.set_shortcut_available('rb-toggle-search', false)
  if gui_data.search then
    search_gui.close(player, player_table)
  end
  if gui_data.info then
    info_gui.close(player, player_table)
  end
  recipe_quick_reference_gui.close_all(player, player_table)
end

-- close the player's GUIs, then start translating
local function refresh_player_data(player, player_table)
  destroy_player_guis(player, player_table)
  import_player_settings(player, player_table)
  run_translations(player)
end

event.on_init(function()
  global.dictionaries = {}
  global.players = {}
  for i,p in pairs(game.players) do
    setup_player(p, i)
    refresh_player_data(p, global.players[i])
  end
  recipe_data.build()
end)

-- player insertion and removal
event.on_player_created(function(e)
  local player = game.get_player(e.player_index)
  setup_player(player, e.player_index)
  refresh_player_data(player, global.players[e.player_index])
end)

event.on_player_removed(function(e)
  global.players[e.player_index] = nil
end)

-- update player settings
event.on_runtime_mod_setting_changed(function(e)
  if string_sub(e.setting, 1, 3) == 'rb-' then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    import_player_settings(player, player_table)
  end
end)

-- when a translation is finished
event.register(translation.finish_event, function(e)
  local player_table = global.players[e.player_index]
  if not player_table.dictionary then player_table.dictionary = {} end

  -- add to player table
  player_table.dictionary[e.dictionary_name] = {
    lookup = e.lookup,
    sorted_translations = e.sorted_translations,
    translations = e.translations
  }

  -- set flag if we're done
  if global.__lualib.translation.players[e.player_index].active_translations_count == 0 then
    local player = game.get_player(e.player_index)
    player.set_shortcut_available('rb-toggle-search', true)
    player_table.flags.can_open_gui = true
    if player_table.flags.tried_to_open_gui then
      player_table.flags.tried_to_open_gui = nil
      player.print{'rb-message.translation-finished'}
    end
  end
end)

-- retranslate_all_event doesn't exist in the root scope, so register the handler in bootstrap
event.register{"on_init", "on_load", function()
  event.register(translation.retranslate_all_event, function(e)
    refresh_player_data(game.get_player(e.player_index), global.players[e.player_index])
  end)
end}

-- -----------------------------------------------------------------------------
-- BASE INTERACTION EVENTS

local open_fluid_types = {
  ['pipe'] = true,
  ['pipe-to-ground'] = true,
  ['storage-tank'] = true,
  ['pump'] = true,
  ['offshore-pump'] = true,
  ['fluid-wagon'] = true,
  ['infinity-pipe'] = true
}

-- recipe book hotkey (default CONTROL + B)
event.register('rb-toggle-search', function(e)
  local player = game.get_player(e.player_index)
  -- open held item, if it has a material page
  if player.mod_settings['rb-open-item-hotkey'].value then
    local cursor_stack = player.cursor_stack
    if cursor_stack and cursor_stack.valid and cursor_stack.valid_for_read and global.recipe_book.material['item,'..cursor_stack.name] then
      event.raise(OPEN_GUI_EVENT, {player_index=e.player_index, gui_type='material', object={'item', cursor_stack.name}})
      return
    end
  end
  -- get player's currently selected entity to check for a fluid filter
  local selected = player.selected
  if player.mod_settings['rb-open-fluid-hotkey'].value then
    if selected and selected.valid and open_fluid_types[selected.type] then
      local fluidbox = selected.fluidbox
      if fluidbox and fluidbox.valid then
        local locked_fluid = fluidbox.get_locked_fluid(1)
        if locked_fluid then
          -- check recipe book to see if this fluid has a material page
          if global.recipe_book.material['fluid,'..locked_fluid] then
            event.raise(OPEN_GUI_EVENT, {player_index=e.player_index, gui_type='material', object={'fluid', locked_fluid}})
            return
          end
        end
      end
    end
  end
  event.raise(OPEN_GUI_EVENT, {player_index=e.player_index, gui_type='search'})
end)

-- shortcut
event.on_lua_shortcut(function(e)
  if e.prototype_name == 'rb-toggle-search' then
    -- read player's cursor stack to see if we should open the material GUI
    local player = game.get_player(e.player_index)
    local cursor_stack = player.cursor_stack
    if cursor_stack and cursor_stack.valid and cursor_stack.valid_for_read and global.recipe_book.material['item,'..cursor_stack.name] then
      -- the player is holding something, so open to its material GUI
      event.raise(OPEN_GUI_EVENT, {player_index=e.player_index, gui_type='material', object={'item', cursor_stack.name}})
    else
      event.raise(OPEN_GUI_EVENT, {player_index=e.player_index, gui_type='search'})
    end
  end
end)

-- reopen the search GUI when the back button is pressed
event.register(REOPEN_SOURCE_EVENT, function(e)
  local source_data = e.source_data
  if source_data.mod_name == 'RecipeBook' and source_data.gui_name == 'search' then
    search_gui.toggle(game.get_player(e.player_index), global.players[e.player_index], source_data)
  end
end)

-- open the specified GUI
event.register(OPEN_GUI_EVENT, function(e)
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
    elseif INFO_GUIS[gui_type] then
      if gui_type == 'material' then
        if type(e.object) ~= 'table' then
          error('Invalid material object, it must be a table!')
        end
        e.object = e.object[1]..','..e.object[2]
      end
      info_gui.open_or_update(player, player_table, gui_type, e.object, e.source_data)
    elseif gui_type == 'recipe_quick_reference' then
      if not player_table.gui.recipe_quick_reference[e.object] then
        recipe_quick_reference_gui.open(player, player_table, e.object)
      end
    else
      error('\''..gui_type..'\' is not a valid GUI type!')
    end
  else
    -- set flag and tell the player that they cannot open it
    player_table.flags.tried_to_open_gui = true
    player.print{'rb-message.translation-not-finished'}
  end
end)

-- -----------------------------------------------------------------------------
-- REMOTE INTERFACE

remote.add_interface('RecipeBook', {
  open_gui = function(player_index, gui_type, object, source_data)
    -- error checking
    if not object then error('Must provide an object!') end
    if source_data and (not source_data.mod_name or not source_data.gui_name) then
      error('Incomplete source_data table!')
    end
    -- raise internal mod event
    event.raise(OPEN_GUI_EVENT, {player_index=player_index, gui_type=gui_type, object=object, source_data=source_data})
  end,
  reopen_source_event = function() return REOPEN_SOURCE_EVENT end,
  version = function() return 2 end -- increment when backward-incompatible changes are made
})

-- -----------------------------------------------------------------------------
-- MIGRATIONS

-- table of migration functions
local migrations = {
  ['1.1.0'] = function()
    -- update active_translations_count to properly reflect the active translations
    local __translation = global.__lualib.translation
    local count = 0
    for _,t in pairs(__translation.players) do
      count = count + t.active_translations_count
    end
    __translation.active_translations_count = count
  end,
  ['1.1.5'] = function()
    -- delete all mod GUI buttons
    for _,t in pairs(global.players) do
      t.gui.mod_gui_button.destroy()
      t.gui.mod_gui_button = nil
    end
    -- remove GUI lualib table - it is no longer needed
    global.__lualib.gui = nil
  end,
  ['1.2.0'] = function()
    -- migrate recipe quick reference data format
    for _,t in pairs(global.players) do
      local rqr_gui = t.gui.recipe_quick_reference
      local new_t = {}
      if rqr_gui then
        -- add an empty filters table to prevent crashes
        rqr_gui.filters = {}
        -- nest into a parent table
        new_t = {[rqr_gui.recipe_name]=rqr_gui}
      end
      t.gui.recipe_quick_reference = new_t
    end
  end
}

-- handle migrations
event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, migrations) then
    -- close all player GUIs
    for _,p in ipairs(game.connected_players) do
      destroy_player_guis(p, global.players[p.index])
    end
    -- update player settings
    for _,p in pairs(game.players) do
      import_player_settings(p)
    end
    recipe_data.build()
    translate_for_all_players()
  end
end)