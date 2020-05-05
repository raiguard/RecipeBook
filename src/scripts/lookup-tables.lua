local lookup_tables = {}

local constants = require("scripts.constants")

local string = string
local table = table

function lookup_tables.add(player_table, dictionary_name, internal_name, translation)
  translation = string.lower(translation)
  local tables = player_table.translation_lookup_tables[dictionary_name]
  local lookup = tables.lookup
  local translation_lookup = lookup[translation]
  if translation_lookup then
    translation_lookup[#translation_lookup+1] = internal_name
  else
    lookup[translation] = {internal_name}
  end
  local sorted_translations = tables.sorted_translations
  sorted_translations[#sorted_translations+1] = translation
end

function lookup_tables.destroy(player_index)
  lookup_tables[player_index] = nil
end

function lookup_tables.transfer(player_index, player_table)
  local translations = player_table.translations
  lookup_tables[player_index] = {}
  local tables = lookup_tables[player_index]
  -- copy over the sub-tables so they won't get destroyed
  for category, t in pairs(player_table.translation_lookup_tables) do
    tables[category] = t
    table.sort(t.sorted_translations)
    t.translations = translations[category]
  end
  player_table.translation_lookup_tables = nil
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