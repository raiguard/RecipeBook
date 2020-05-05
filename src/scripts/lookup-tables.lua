local lookup_tables = {}

local constants = require("scripts.constants")

local string = string
local table = table

function lookup_tables.add(player_index, dictionary, internal, translation)
  -- TODO
end

function lookup_tables.create(player_index)
  -- TODO
end

function lookup_tables.destroy(player_index)
  lookup_tables[player_index] = nil
end

function lookup_tables.finish(player_index, player_table)
  local translation_lookup_tables = player_table.translation_lookup_tables
  lookup_tables[player_index] = {
    lookup = translation_lookup_tables.lookup,
    sorted_translations = translation_lookup_tables.sorted_translations,
    translations = player_table.translations
  }
  player_table.translation_lookup_tables = nil
  table.sort(lookup_tables[player_index].sorted_translations)
end

function lookup_tables.generate()
  for player_index, player_table in pairs(global.players) do
    local flags = player_table.flags
    if not flags.translating and not flags.translate_on_join then
      local tables = table.deepcopy(constants.empty_translation_tables)
      for dictionary_name, t in pairs(tables) do
        local lookup = {}
        local sorted_translations = {}
        local translations = player_table.translations[dictionary_name]
        local i = 0
        for internal, translation in pairs(translations) do
          translation = string.lower(translation)
          local translation_lookup = lookup[translation]
          if translation_lookup then
            translation_lookup[#translation_lookup+1] = internal
          else
            lookup[translation] = {internal}
          end
          i = i + 1
          sorted_translations[i] = translation
        end
        table.sort(sorted_translations)
        t.lookup = lookup
        t.sorted_translations = sorted_translations
        t.translations = player_table.translations[dictionary_name]
      end
      lookup_tables[player_index] = tables
    end
  end
end

return lookup_tables