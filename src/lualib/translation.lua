-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- RAILUALIB TRANSLATION LIBRARY
-- Requests and organizes translations for localised strings

-- DOCUMENTATION: https://github.com/raiguard/Factorio-SmallMods/wiki/Translation-Library-Documentation

-- dependencies
local event = require('lualib/event')
local util = require('__core__/lualib/util')

-- locals
local math_floor = math.floor
local string_gsub = string.gsub
local string_lower = string.lower
local table_sort = table.sort

-- -----------------------------------------------------------------------------

local translation = {}
translation.start_event = event.generate_id('translation_start')
translation.finish_event = event.generate_id('translation_finish')
translation.canceled_event = event.generate_id('translation_canceled')

-- converts a localised string into a format readable by the API
-- basically just spits out the table in string form
local function serialise_localised_string(t)
  local output = '{'
  if type(t) == 'string' then return t end
  for _,v in pairs(t) do
    if type(v) == 'table' then
      output = output..serialise_localised_string(v)
    else
      output = output..'\''..v..'\', '
    end
  end
  output = string_gsub(output, ', $', '')..'}'
  return output
end

-- translate 80 entries per tick
local function translate_batch(e)
  local __translation = global.__lualib.translation
  local iterations = math_floor(80 / __translation.dictionary_count)
  if iterations < 1 then iterations = 1 end
  for pi,pt in pairs(__translation.players) do -- for each player that is doing a translation
    local player = game.get_player(pi)
    if not player or not player.connected then -- the player was destroyed or disconnected
      translation.cancel_all_for_player(player)
      return
    end
    local request_translation = player.request_translation
    for _,t in pairs(pt) do -- for each dictionary that they're translating
      local next_index = t.next_index
      local strings = t.strings
      local strings_len = t.strings_len
      for i=next_index,next_index+iterations do
        if i > strings_len then
          t.next_index = i
          if not t.iterated_twice then
            if t.reiterate_tick then
              if e.tick >= t.reiterate_tick then
                -- reset iteration to go over it again...
                t.iterated_twice = true
                t.next_index = 1
              end
            else
              -- set to reiterate after one second if not all of the translations have finished by then
              t.reiterate_tick = e.tick + 60
            end
          end
          goto continue
        end
        request_translation(strings[i])
      end
      t.next_index = next_index + iterations
      ::continue::
    end
  end
end

-- sorts a translated string into its appropriate dictionary
local function sort_translated_string(e)
  local __translation = global.__lualib.translation
  local player_translation = __translation.players[e.player_index]
  local serialised = serialise_localised_string(e.localised_string)
  for name,t in pairs(player_translation) do
    local value = t.data[serialised]
    if value then
      if e.translated and e.result ~= '' then
        local result = e.result
        if t.convert_to_lowercase then
          result = string_lower(result)
        end
        -- lookup
        local lookup = t.lookup[result]
        if lookup then
          lookup[#lookup+1] = value
        else
          t.lookup[result] = {value}
        end
        -- searchable
        t.sorted_results[#t.sorted_results+1] = result
        -- translation
        local translation = t.translations[value]
        if translation then
          error('Duplicate key \''..value..'\' in dictionary: '..t.name)
        else
          t.translations[value] = result
        end
      else
        log(name..':  key \''..serialised..'\' was not successfully translated, and will not be included in the output.')
      end
      t.data[serialised] = nil
      if table_size(t.data) == 0 then -- this set has completed translation
        player_translation[name] = nil
        if table_size(player_translation) == 0 then -- remove player from translating table if they're done
          __translation.players[e.player_index] = nil
          if table_size(__translation.players) == 0 then -- deregister events if we're all done
            event.deregister(defines.events.on_tick, translate_batch, 'translation_translate_batch')
            event.deregister(defines.events.on_string_translated, sort_translated_string, 'translation_sort_result')
          end
        end
        -- sort results array
        table_sort(t.sorted_results)
        -- raise events to finish up
        event.raise(translation.update_dictionary_count_event, {delta=-1})
        event.raise(translation.finish_event, {player_index=e.player_index, dictionary_name=name, lookup=t.lookup, sorted_results=t.sorted_results,
          translations=t.translations})
      end
      return
    end
  end
end

translation.serialise_localised_string = serialise_localised_string

-- begin translating strings
function translation.start(player, dictionary_name, data, options)
  options = options or {}
  local __translation = global.__lualib.translation
  if not __translation.players[player.index] then __translation.players[player.index] = {} end
  local player_translation = __translation.players[player.index]
  if player_translation[dictionary_name] then
    log('Cancelling and restarting translation of '..dictionary_name..' for '..player.name)
    translation.cancel(player, dictionary_name)
  end
  -- parse data table to create iteration tables
  local translation_data = {}
  local strings = {}
  for i=1,#data do
    local t = data[i]
    local localised = t.localised
    translation_data[serialise_localised_string(localised)] = t.internal
    strings[i] = localised
  end
  player_translation[dictionary_name] = {
    -- tables
    data = translation_data, -- this table gets destroyed as it is translated, so deepcopy it
    strings = strings,
    -- iteration
    next_index = 1,
    player = player,
    -- request_translation = player.request_translation,
    strings_len = #strings,
    -- settings
    convert_to_lowercase = options.convert_to_lowercase,
    -- output
    lookup = {},
    sorted_results = {},
    translations = {}
  }
  event.raise(translation.update_dictionary_count_event, {delta=1})
  event.raise(translation.start_event, {player_index=player.index, dictionary_name=dictionary_name})
  if not event.is_registered('translation_translate_batch') then -- register events if needed
    event.on_tick(translate_batch, {name='translation_translate_batch'})
    event.on_string_translated(sort_translated_string, {name='translation_sort_result'})
  end
end

-- cancel a translation
function translation.cancel(player, dictionary_name)
  local __translation = global.__lualib.translation
  local player_translation = __translation.players[player.index]
  if not player_translation[dictionary_name] then
    error('Tried to cancel a translation that isn\'t running!')
  end
  player_translation[dictionary_name] = nil
  event.raise(translation.update_dictionary_count_event, {delta=1})
  if table_size(player_translation) == 0 then -- remove player from translating table if they're done
    __translation.players[player.index] = nil
    if table_size(__translation.players) == 0 then -- deregister events if we're all done
      event.deregister(defines.events.on_tick, translate_batch, 'translation_translate_batch')
      event.deregister(defines.events.on_string_translated, sort_translated_string, 'translation_sort_result')
    end
  end
end

-- cancels all translations for a player
function translation.cancel_all_for_player(player)
  local __translation = global.__lualib.translation
  local player_translation = __translation.players[player.index]
  for name,_ in pairs(player_translation) do
    translation.cancel(player, name)
  end
end

-- cancels ALL translations for this mod
function translation.cancel_all()
  for i,t in pairs(global.__lualib.translation.players) do
    local player = game.get_player(i)
    for name,_ in pairs(t) do
      translation.cancel(player, name)
    end
  end
end

-- REMOTE INTERFACE: CROSS-MOD SYNCRONISATION

local function setup_remote()
  if not remote.interfaces['railualib_translation'] then -- create the interface
    local functions = {
      retranslate_all_event = function() return event.generate_id('retranslate_all_event') end,
      update_dictionary_count_event = function() return event.generate_id('update_dictionary_count_event') end
    }
    remote.add_interface('railualib_translation', functions)
    commands.add_command(
      'retranslate-all-dictionaries',
      {'qis-command-help.retranslate-all-dictionaries'},
      function(e)
        event.raise(translation.retranslate_all_event, {})
      end
    )
  end
  translation.retranslate_all_event = remote.call('railualib_translation', 'retranslate_all_event')
  translation.update_dictionary_count_event = remote.call('railualib_translation', 'update_dictionary_count_event')
  event.register(translation.update_dictionary_count_event, function(e)
    local __translation = global.__lualib.translation
    __translation.dictionary_count = __translation.dictionary_count + e.delta
  end)
end

event.on_init(function()
  if not global.__lualib then global.__lualib = {} end
  global.__lualib.translation = {
    dictionary_count = 0,
    players = {}
  }
  setup_remote()
end)

event.on_load(function()
  setup_remote()
  -- re-register events
  event.load_conditional_handlers{
    translation_translate_batch = translate_batch,
    translation_sort_result = sort_translated_string
  }
end)

return translation