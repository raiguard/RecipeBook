local gui = require("__flib__.gui-beta")
local on_tick_n = require("__flib__.on-tick-n")

local constants = require("constants")

local formatter = require("scripts.formatter")
local shared = require("scripts.shared")
local util = require("scripts.util")

local root = require("scripts.gui.search.root")
local settings_root = require("scripts.gui.settings.root")

local actions = {}

function actions.get_action_data(msg, e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]

  local gui_data = player_table.guis.search
  if not gui_data then return end

  return {
    e = e,
    gui_data = gui_data,
    msg = msg,
    player = player,
    player_table = player_table,
    refs = gui_data.refs,
    state = gui_data.state,
  }
end

function actions.close(data)
  root.close(data.player, data.player_table)
end

function actions.toggle_settings(data)
  settings_root.toggle(data.player, data.player_table)
  local settings_button = data.refs.titlebar.settings_button
  if data.player_table.guis.settings then
    settings_button.style = "flib_selected_frame_action_button"
    settings_button.sprite = "rb_settings_black"
  else
    settings_button.style = "frame_action_button"
    settings_button.sprite = "rb_settings_white"
  end
end

function actions.deselect_settings_button(data)
  local settings_button = data.refs.titlebar.settings_button
  settings_button.style = "frame_action_button"
  settings_button.sprite = "rb_settings_white"
end

function actions.update_search_query(data)
  local player_table = data.player_table
  local state = data.state
  local refs = data.refs

  local class_filter
  local query = string.lower(data.e.element.text)
  if string.find(query, "/") then
    -- NOTE: The `_`s here are technically globals, but whatever
    _, _, class_filter, query = string.find(query, "^/(.-)/(.-)$")
    if class_filter then
      class_filter = string.gsub(class_filter, " ", "_")
    end
    if not class_filter or not query or not constants.pages[class_filter] then
      class_filter = false
      query = nil
    end
  end
  -- Remove results update action if there is one
  if state.update_results_ident then
    on_tick_n.remove(state.update_results_ident)
    state.update_results_ident = nil
  end
  if query then
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
    state.class_filter = class_filter
    -- Update in a while
    state.update_results_ident = on_tick_n.add(
      game.tick + constants.search_timeout,
      {gui = "search", action = "update_search_results", player_index = data.e.player_index}
    )
    refs.search_textfield.style = "flib_widthless_textfield"
    -- HACK: Make this a data stage style
    refs.search_textfield.style.horizontally_stretchable = true
  else
    state.search_query = ""
    refs.search_textfield.style = "flib_widthless_invalid_textfield"
    -- HACK: Make this a data stage style
    refs.search_textfield.style.horizontally_stretchable = true
  end
end

function actions.update_search_results(data)
  local player = data.player
  local player_table = data.player_table
  local state = data.state
  local refs = data.refs

  -- Data
  local player_data = formatter.build_player_data(player, player_table)
  local show_fluid_temperatures = player_table.settings.general.search.show_fluid_temperatures
  local search_type = player_table.settings.general.search.search_type

  -- Update results based on query
  local i = 0
  local pane = refs.search_results_pane
  local children = pane.children
  local add = pane.add
  local max = constants.search_results_limit
  local class_filter = state.class_filter
  local query = state.search_query
  if class_filter ~= false then
    for class in pairs(constants.pages) do
      if not class_filter or class_filter == class then
        for internal, translation in pairs(player_table.translations[class]) do
          -- Match against search string
          local matched
          if search_type == "both" then
            matched = string.find(string.lower(internal), query) or string.find(string.lower(translation), query)
          elseif search_type == "internal" then
            matched = string.find(string.lower(internal), query)
          elseif search_type == "localised" then
            matched = string.find(string.lower(translation), query)
          end

          if matched then
            local obj_data = global.recipe_book[class][internal]

            -- Check temperature settings
            if obj_data.class == "fluid" then
              local temperature_ident = obj_data.temperature_ident
              if temperature_ident then
                local is_range = temperature_ident.min ~= temperature_ident.max
                if is_range then
                  if show_fluid_temperatures ~= "all" then
                    goto continue
                  end
                else
                  if show_fluid_temperatures == "off" then
                    goto continue
                  end
                end
              end
            end

            local info = formatter(obj_data, player_data)
            if info then
              i = i + 1
              local style = info.researched and "rb_list_box_item" or "rb_unresearched_list_box_item"
              local item = children[i]
              if item then
                item.style = style
                item.caption = info.caption
                item.tooltip = info.tooltip
                item.enabled = info.enabled
                gui.update_tags(item, {context = {class = class, name = internal}})
              else
                add{
                  type = "button",
                  style = style,
                  caption = info.caption,
                  tooltip = info.tooltip,
                  enabled = info.enabled,
                  mouse_button_filter = {"left", "middle"},
                  tags = {
                    [script.mod_name] = {
                      context = {class = class, name = internal},
                      flib = {
                        on_click = {gui = "search", action = "open_object"}
                      },
                    }
                  }
                }
                if i >= max then
                  break
                end
              end
            end
          end

          ::continue::
        end
      end
      if i >= max then
        break
      end
    end
  end
  -- Destroy extraneous items
  for j = i + 1, #children do
    children[j].destroy()
  end
end

function actions.open_object(data)
  local context = util.navigate_to(data.e)
  if context then
    -- TODO: Shared won't be needed any more!
    shared.open_page(data.player, data.player_table, context)
    if data.player_table.settings.general.search.close_search_gui_after_selection then
      actions.close(data)
    end
  end
end

function actions.update_favorites(data)
  local player = data.player
  local player_table = data.player_table
  local refs = data.refs
  util.update_list_box(
    refs.favorites_pane,
    player_table.favorites,
    formatter.build_player_data(player, player_table),
    pairs,
    {always_show = true}
  )
  refs.delete_favorites_button.enabled = table_size(player_table.favorites) > 0 and true or false
  shared.update_all_favorite_buttons(player, player_table)
end

function actions.update_history(data)
  local player = data.player
  local player_table = data.player_table
  local refs = data.refs
  util.update_list_box(
    refs.history_pane,
    player_table.global_history,
    formatter.build_player_data(player, player_table),
    ipairs,
    {always_show = true}
  )
  refs.delete_history_button.enabled = table_size(player_table.global_history) > 0 and true or false
  end

function actions.delete_favorites(data)
  -- TODO: Update all favorite buttons
  data.player_table.favorites = {}
  actions.update_favorites(data)
end

function actions.delete_history(data)
  data.player_table.global_history = {}
  actions.update_history(data)
end

return actions
