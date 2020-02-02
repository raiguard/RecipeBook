-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CONTROL SCRIPTING

-- debug adapter
pcall(require,'__debugadapter__/debugadapter.lua')
if __DebugAdapter then
  script.on_event('DEBUG-INSPECT-GLOBAL', function(e)
    local breakpoint -- put breakpoint here to inspect global at any time
  end)
end

-- dependencies
local event = require('lualib/event')
local mod_gui = require('mod-gui')
local translation = require('lualib/translation')

-- modules
local search_gui = require('gui')

-- -----------------------------------------------------------------------------
-- RECIPE DATA

--[[
  RECIPE DATA STRUCTURE
    crafters
      {prototype, recipes}
    ingredients
      {prototype, as_ingredient, as_product},
    recipes
      {prototype, ingredients, products, crafters, technologies}
]]

-- builds recipe data table
local function build_recipe_data()
  local recipe_book = {}
  local translation_data = {}
  -- RECIPES
  do
    local data = {}
    local translations = {}
    -- build data
    for n,p in pairs(game.recipe_prototypes) do
      data[n] = {prototype=p, ingredients=p.ingredients, products=p.products}
      translations[#translations+1] = {internal=n, localised=p.localised_name}
    end
    -- add to tables
    recipe_book.recipes = data
    translation_data.recipes = translations
  end

  -- APPLY TO GLOBAL
  global.recipe_book = recipe_book
  global.__lualib.translation.translation_data = translation_data
end

local function translate_whole(player)
  for name,data in pairs(global.__lualib.translation.translation_data) do
    translation.start(player, name, data)
  end
end

local function translate_for_all_players()
  for _,player in ipairs(game.connected_players) do
    translate_whole(player)
  end
end

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS

local function setup_player(player, index)
  global.players[index] = {
    flags = {
      can_open_gui = false
    },
    gui = {},
    settings = {
      default_category = 'recipes',
      show_hidden = false
    }
  }
  if player.mod_settings['rb-show-mod-gui-button'].value then
    mod_gui.get_button_flow(player).add{type='button', name='recipe_book_button', style=mod_gui.button_style, caption='RB', tooltip={'mod-name.RecipeBook'}}
  end
end

event.on_init(function()
  global.players = {}
  for i,p in pairs(game.players) do
    setup_player(p, i)
  end
  build_recipe_data()
  translate_for_all_players()
end)

-- player insertion and removal
event.on_player_created(function(e)
  setup_player(game.get_player(e.player_index), e.player_index)
end)
event.on_player_removed(function(e)
  global.players[e.player_index] = nil
end)

-- retranslate all dictionaries for a player when they re-join
event.on_player_joined_game(function(e)
  global.players[e.player_index].flags.can_open_gui = false
  -- TODO: close open GUIs
  translate_whole(game.get_player(e.player_index))
end)

-- when a translation is finished
event.register(translation.finish_event, function(e)
  local player_table = global.players[e.player_index]
  if not player_table.dictionary then player_table.dictionary = {} end

  -- create searchable array
  local data = global.recipe_book[e.dictionary_name]
  local lookup = e.lookup
  local search = {}
  local sorted_results = e.sorted_results
  -- si: search index; ri: results index; ii: internals index
  local si = 0
  -- create an entry in the search table for every prototype that each result matches with
  for ri=1,#sorted_results do
    local translated = sorted_results[ri]
    local internals = lookup[translated]
    for ii=1,#internals do
      local internal = internals[ii]
      si = si + 1
      -- get whether or not it's hidden so we can include or not include it depending on the user's settings
      search[si] = {internal=internal, translated=translated, hidden=data[internal].prototype.hidden, sprite_category='recipe'}
    end
  end

  -- add to player table
  player_table.dictionary[e.dictionary_name] = {
    lookup = lookup,
    search = search,
    translations = e.translations
  }

  -- set flag if we're done
  if not global.__lualib.translation.players[e.player_index] then
    player_table.flags.can_open_gui = true
  end
end)

-- toggle the search GUI when the button or the hotkey are used
event.register('rb-toggle-search', function(e)
  search_gui.toggle(game.get_player(e.player_index), global.players[e.player_index])
end)
event.on_gui_click(function(e)
  search_gui.toggle(game.get_player(e.player_index), global.players[e.player_index])
end, {gui_filters='recipe_book_button'})

-- -----------------------------------------------------------------------------
-- MIGRATIONS

-- table of migration functions
local migrations = {}

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
      -- generic migrations
      build_recipe_data()
      translate_for_all_players()
    end
  end
end)