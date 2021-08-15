local on_tick_n = require("__flib__.on-tick-n")

local constants = require("constants")

local shared = require("scripts.shared")

local root = require("scripts.gui.settings.root")
local search_actions = require("scripts.gui.search.actions")

local actions = {}

function actions.close(data)
  root.destroy(data.player_table)
  search_actions.deselect_settings_button(search_actions.get_action_data(data.msg, data.e))
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
  if player_table.settings.general.search.fuzzy_search then
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

function actions.change_general_setting(data)
  local msg = data.msg
  local type = msg.type
  local category = msg.category
  local name = msg.name
  local setting_ident = constants.general_settings[category][name]
  local settings = data.player_table.settings.general[category]

  local new_value
  local element = data.e.element

  -- NOTE: This shouldn't ever happen, but we will avoid a crash just in case!
  if not element.valid then return end

  if type == "bool" then
    new_value = element.state
  elseif type == "enum" then
    local selected_index = element.selected_index
    new_value = setting_ident.options[selected_index]
  end

  -- NOTE: This _also_ shouldn't ever happen, but you can't be too safe!
  if new_value ~= nil then
    settings[name] = new_value
    shared.refresh_contents(data.player, data.player_table)
    -- Update enabled statuses
    root.update_contents(data.player, data.player_table, "general")
  end
end

function actions.change_category(data)
  data.state.selected_category = data.e.element.selected_index
  root.update_contents(data.player, data.player_table, "categories")
end

function actions.change_category_setting(data)
  local msg = data.msg
  local class = msg.class
  local name = msg.name

  local category_settings = data.player_table.settings.categories[class]
  category_settings[name] = data.e.element.state
  shared.refresh_contents(data.player, data.player_table)
end

function actions.change_page(data)
  data.state.selected_page = data.e.element.selected_index
  root.update_contents(data.player, data.player_table, "pages")
end

function actions.change_default_state(data)
  local msg = data.msg
  local class = msg.class
  local component = msg.component

  local component_settings = data.player_table.settings.pages[class][component]
  if component_settings then
    component_settings.default_state = constants.component_states[data.e.element.selected_index]
  end
  shared.refresh_contents(data.player, data.player_table)
end

function actions.change_max_rows(data)
  local msg = data.msg
  local class = msg.class
  local component = msg.component

  local component_settings = data.player_table.settings.pages[class][component]
  if component_settings then
    -- TODO: Sanitize?
    component_settings.max_rows = tonumber(data.e.element.text)
  end
  shared.refresh_contents(data.player, data.player_table)
end

return actions
