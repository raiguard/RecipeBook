local on_tick_n = require("__flib__.on-tick-n")

local constants = require("constants")

local root = require("scripts.gui.settings.root")
local search_actions = require("scripts.gui.search.actions")

local actions = {}

function actions.close(data)
  search_actions.deselect_settings_button(search_actions.get_action_data(data.msg, data.e))
  root.destroy(data.player_table)
end

function actions.toggle_search(data)
  local state = data.state
  local refs = data.refs

  local opened = state.search_opened
  state.search_opened = not opened

  local search_button = refs.titlebar.search_button
  local search_textfield = refs.titlebar.search_textfield
  if opened then
    search_button.style = "frame_action_button"
    search_button.sprite = "utility/search_white"
    search_textfield.visible = false

    if state.search_query ~= "" then
      -- Reset query
      search_textfield.text = ""
      state.search_query = ""
      -- Immediately refresh page
      actions.update_search_results(data)
    end
  else
    -- Show search textfield
    search_button.style = "flib_selected_frame_action_button"
    search_button.sprite = "utility/search_black"
    search_textfield.visible = true
    search_textfield.focus()
  end
end

function actions.update_search_query(data)
  local player_table = data.player_table
  local state = data.state

  local query = string.lower(data.e.element.text)
  -- Fuzzy search
  if player_table.settings.use_fuzzy_search then
    query = string.gsub(query, ".", "%1.*")
  end
  -- Input sanitization
  for pattern, replacement in pairs(constants.input_sanitizers) do
    query = string.gsub(query, pattern, replacement)
  end
  -- Save query
  state.search_query = query

  -- Remove scheduled update if one exists
  if state.update_results_ident then
    on_tick_n.remove(state.update_results_ident)
    state.update_results_ident = nil
  end

  if query == "" then
    -- Update now
    actions.update_search_results(data)
  else
    -- Update in a while
    state.update_results_ident = on_tick_n.add(
      game.tick + constants.search_timeout,
      {gui = "settings", action = "update_search_results", player_index = data.e.player_index}
    )
  end
end

function actions.update_search_results(data)
  root.update_contents(data.player, data.player_table)
end

return actions
