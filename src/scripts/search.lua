local search = {}

local constants = require("scripts.constants")
local lookup_tables = require("scripts.lookup-tables")

--[[
  GOALS:
    - Only certain amount of iterations per tick
    - Iterations should be split between players if multiple are searching concurrently
  ITERATION:
    - For every entry in the sorted_translations table:
      - If the query matches the translation:
        - Retrieve recipe book data
        - Check if object is hidden and is show_hidden is enabled
        - Check if the object is unlocked
          - If unlocked, add to unlocked results table
          - If not, add to locked results table
]]

function search.iterate(e)
  local player_tables = global.players
  local players = global.searching_players
  local num_searching_players = #players
  local iterations = math.floor(200 / num_searching_players)
  local recipe_book = global.recipe_book
  if iterations < 1 then iterations = 1 end

  for searching_players_index = 1, num_searching_players do
    -- player data
    local player_index = players[searching_players_index]
    local player_table = player_tables[player_index]
    local force_index = game.get_player(player_index).force.index
    -- gui data
    local gui_data = player_table.gui.search
    local category = gui_data.category
    local query = gui_data.query
    local skip_matching = query == ""
    -- iteration data
    local search_data = player_table.search
    local output_data = search_data.output
    local i = 0
    -- listbox
    local results_listbox = gui_data.results_listbox
    local add_item = results_listbox.add_item
    -- lookup tables
    local player_lookup_tables = lookup_tables[player_index][category]
    local lookup = player_lookup_tables.lookup
    local sorted_translations = player_lookup_tables.sorted_translations
    local translations = player_lookup_tables.translations
    -- object data
    local objects = recipe_book[category]
    -- settings
    local show_hidden = player_table.settings.show_hidden
    local show_unavailable = player_table.settings.show_unavailable

    while i <= iterations do
      i = i + 1
      if search_data.state == "sort" then
        local current_index = search_data.next_index
        local translated_name = sorted_translations[current_index]
        if translated_name then
          if skip_matching or string.find(translated_name, query) then
            local internal_names = lookup[translated_name]
            if internal_names then
              for internal_names_index = 1, #internal_names do
                local name = internal_names[internal_names_index]
                local t = objects[name]
                -- check conditions
                if (show_hidden or not t.hidden) then
                  if t.available_to_forces[force_index] then
                    local caption = "[img="..t.sprite_class.."/"..t.prototype_name.."]  "..translations[name]
                    output_data.available_size = output_data.available_size + 1
                    output_data.available[output_data.available_size] = caption
                  elseif show_unavailable then
                    local caption = "[color="..constants.warning_red_color.."][img="..t.sprite_class.."/"..t.prototype_name.."]  "..translations[name].."[/color]"
                    output_data.unavailable_size = output_data.unavailable_size + 1
                    output_data.unavailable[output_data.unavailable_size] = caption
                  end
                end
              end
            end
          end
          search_data.next_index = current_index + 1
        else
          search_data.add_table = "available"
          search_data.next_index = 1
          search_data.state = "add"
        end
      elseif search_data.state == "add" then
        local item_index = search_data.next_index
        local next_item = output_data[search_data.add_table][item_index]
        if next_item then
          add_item(next_item)
          search_data.next_index = item_index + 1
        elseif search_data.add_table == "available" then
          search_data.add_table = "unavailable"
          search_data.next_index = 1
        else
          search_data.state = "finish"
        end
      elseif search_data.state == "finish" then
        if search_data.output.available_size == 0 and search_data.output.unavailable_size == 0 then
          -- no results
          gui_data.results_cover_label.caption = {"rb-gui.no-results"}
        else
          gui_data.results_listbox.visible = true
          gui_data.results_cover_frame.visible = false
        end
        search.cancel(player_index, player_table)
        break
      end
    end
  end
end

function search.start(player_index, player_table, query)
  local gui_data = player_table.gui.search

  -- set GUI state
  -- TODO do this on a delay to prevent flickering with a low number of items
  gui_data.results_listbox.clear_items()
  gui_data.results_listbox.visible = false
  gui_data.results_cover_frame.visible = true
  gui_data.results_cover_label.caption = {"rb-gui.searching"}

  -- save iteration data
  player_table.search = {
    next_index = 1,
    output = {
      available = {},
      available_size = 0,
      unavailable = {},
      unavailable_size = 0
    },
    query = query,
    state = "sort"
  }

  -- set flags
  player_table.flags.searching = true
  local player_insertion_index = #global.searching_players + 1
  global.searching_players[player_insertion_index] = player_index
  player_table.search.insertion_index = player_insertion_index
end

function search.cancel(player_index, player_table)
  table.remove(global.searching_players, player_table.search.insertion_index)
  player_table.search = nil
  player_table.flags.searching = false
end

return search

--[[
  local player_table = global.players[e.player_index]
  local gui_data = player_table.gui.search
  local show_hidden = player_table.settings.show_hidden
  local query = string_lower(e.text)
  -- fuzzy search
  if player_table.settings.use_fuzzy_search then
    query = string_gsub(query, ".", "%1.*")
  end
  local category = gui_data.category
  local objects = global.recipe_book[category]
  local dictionary = lookup_tables[e.player_index][category]
  local lookup = dictionary.lookup
  local sorted_translations = dictionary.sorted_translations
  local translations = dictionary.translations
  local results_listbox = gui_data.results_listbox
  local skip_matching = query == ""
  local items = {}
  local i = 0
  for i1=1,#sorted_translations do
    local translation = sorted_translations[i1]
    if skip_matching or string_find(translation, query) then
      local names = lookup[translation]
      if names then
        for i2=1,#names do
          local name = names[i2]
          local t = objects[name]
          -- check conditions
          if (show_hidden or not t.hidden) then
            local caption = "[img="..t.sprite_class.."/"..t.prototype_name.."]  "..translations[name] -- get the non-lowercase version
            i = i + 1
            items[i] = caption
          end
        end
      end
    end
  end
  results_listbox.items = items
  if e.selected_index then
    results_listbox.scroll_to_item(e.selected_index)
  end
]]