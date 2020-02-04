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
local gui = require('lualib/gui')
local mod_gui = require('mod-gui')
local translation = require('lualib/translation')

-- globals
open_gui_event = event.generate_id('open_gui')
reopen_source_event = event.generate_id('reopen_source')
info_guis = {crafter=true, material=true, recipe=true}

-- modules
local search_gui = require('gui/search')
local info_gui = require('gui/info-base')

-- GUI templates
gui.add_templates{
  close_button = {type='sprite-button', style='close_button', sprite='utility/close_white', hovered_sprite='utility/close_black',
    clicked_sprite='utility/close_black', handlers='close_button', mouse_button_filter={'left'}},
  pushers = {
    horizontal = {type='empty-widget', style={horizontally_stretchable=true}},
    vertical = {type='empty-widget', style={vertically_stretchable=true}}
  },
  listbox_with_label = function(name)
    return
    {type='flow', direction='vertical', children={
      {type='label', style='rb_listbox_label', save_as=name..'_label'},
      {type='frame', style='rb_listbox_frame', save_as=name..'_frame', children={
        {type='list-box', style='rb_listbox', save_as=name..'_listbox'}
      }}
    }}
  end
}

-- -----------------------------------------------------------------------------
-- RECIPE DATA

-- builds recipe data table
local function build_recipe_data()
  -- table skeletons
  local recipe_book = {
    crafter = {},
    material = {},
    recipe = {}
  }
  local translation_data = {
    crafter = {},
    material = {},
    recipe = {}
  }
  
  -- iterate crafters
  local crafters = game.get_filtered_entity_prototypes{
    {filter='type', type='assembling-machine'},
    {filter='type', type='furnace'}
  }
  for name,prototype in pairs(crafters) do
    recipe_book.crafter[name] = {
      prototype = prototype,
      hidden = prototype.has_flag('hidden'),
      categories = prototype.crafting_categories,
      recipes = {},
      sprite_class = 'entity'
    }
    translation_data.crafter[#translation_data.crafter+1] = {internal=name, localised=prototype.localised_name}
  end

  -- iterate materials
  local materials = util.merge{game.fluid_prototypes, game.item_prototypes}
  for name,prototype in pairs(materials) do
    local is_fluid = prototype.object_name == 'LuaFluidPrototype' and true or false
    local hidden
    if is_fluid then
      hidden = prototype.hidden
    else
      hidden = prototype.has_flag('hidden')
    end
    recipe_book.material[name] = {
      prototype = prototype,
      hidden = hidden,
      as_ingredient = {},
      as_product = {},
      sprite_class = is_fluid and 'fluid' or 'item'
    }
    translation_data.material[#translation_data.material+1] = {internal=name, localised=prototype.localised_name}
  end

  -- iterate recipes
  for name,prototype in pairs(game.recipe_prototypes) do
    local data = {
      prototype = prototype,
      hidden = prototype.hidden,
      made_in = {},
      unlocked_by = {},
      sprite_class = 'recipe'
    }
    -- made-in
    local category = prototype.category
    for crafter_name,crafter_data in pairs(recipe_book.crafter) do
      if crafter_data.categories[category] then
        data.made_in[#data.made_in+1] = {name=crafter_name, crafting_speed=crafter_data.prototype.crafting_speed}
      end
    end
    -- as ingredient
    local ingredients = prototype.ingredients
    for i=1,#ingredients do
      local ingredient = ingredients[i]
      local ingredient_data = recipe_book.material[ingredient.name]
      if ingredient_data then
        ingredient_data.as_ingredient[#ingredient_data.as_ingredient+1] = name
      end
    end
    -- as product
    local products = prototype.products
    for i=1,#products do
      local product = products[i]
      local product_data = recipe_book.material[product.name]
      if product_data then
        product_data.as_product[#product_data.as_product+1] = name
      end
    end
    -- insert into recipe book
    recipe_book.recipe[name] = data
    -- translation data
    translation_data.recipe[#translation_data.recipe+1] = {internal=name, localised=prototype.localised_name}
  end

  -- iterate technologies (to populate the recipe unlocked_by tables)
  for name,prototype in pairs(game.technology_prototypes) do
    for _,modifier in ipairs(prototype.effects) do
      if modifier.type == 'unlock-recipe' then
        local recipe = recipe_book.recipe[modifier.recipe]
        recipe.unlocked_by[#recipe.unlocked_by+1] = name
      end
    end
  end

  -- apply to global
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
    history = {
      session = {},
      overall = {}
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
      local object_data = data[internal]
      si = si + 1
      -- get whether or not it's hidden so we can include or not include it depending on the user's settings
      search[si] = {internal=internal, translated=translated, hidden=object_data.hidden, sprite_class=object_data.sprite_class}
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
    if player_table.flags.tried_to_open_gui then
      player_table.flags.tried_to_open_gui = nil
      game.get_player(e.player_index).print{'rb-message.translation-finished'}
    end
  end
end)

-- toggle the search GUI when the button or the hotkey are used
event.register('rb-toggle-search', function(e)
  search_gui.toggle(game.get_player(e.player_index), global.players[e.player_index])
end)
event.on_gui_click(function(e)
  search_gui.toggle(game.get_player(e.player_index), global.players[e.player_index])
end, {gui_filters='recipe_book_button'})

-- reopen the search GUI when the back button is pressed
event.register(reopen_source_event, function(e)
  if e.source == 'rb_search' then
    search_gui.toggle(game.get_player(e.player_index), global.players[e.player_index])
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
      
    elseif info_guis[gui_type] then
      info_gui.open_or_update(player, player_table, gui_type, e.object_name, e.source)
    elseif gui_type == 'recipe_quick_reference' then

    end
  else
    -- set flag and tell the player that they cannot open it
    player_table.flags.tried_to_open_gui = true
    player.print{'rb-message.translation-not-finished'}
  end
end)

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