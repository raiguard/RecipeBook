local gui = require("__flib__.gui")
local on_tick_n = require("__flib__.on-tick-n")
local table = require("__flib__.table")

local constants = require("constants")

local database = require("scripts.database")
local formatter = require("scripts.formatter")
local gui_util = require("scripts.gui.util")
local util = require("scripts.util")

local actions = {}

--- @param Gui SearchGui
--- @param e on_gui_click
function actions.reset_location(Gui, _, e)
  if e.button ~= defines.mouse_button_type.middle then
    return
  end

  if Gui.player_table.settings.general.interface.search_gui_location == "top_left" then
    local scale = Gui.player.display_scale
    Gui.refs.window.location = table.map(constants.search_gui_top_left_location, function(pos)
      return pos * scale
    end)
    Gui.refs.window.auto_center = false
  else
    Gui.refs.window.force_auto_center()
  end
end

--- @param Gui SearchGui
function actions.close(Gui, _, _)
  if not Gui.state.ignore_closed and not Gui.player_table.flags.technology_gui_open then
    Gui:close()
  end
end

--- @param Gui SearchGui
function actions.toggle_pinned(Gui, _, _)
  local player = Gui.player
  local refs = Gui.refs
  local state = Gui.state

  local pin_button = refs.titlebar.pin_button

  state.pinned = not state.pinned
  if state.pinned then
    pin_button.style = "flib_selected_frame_action_button"
    pin_button.sprite = "rb_pin_black"
    if player.opened == refs.window then
      state.ignore_closed = true
      player.opened = nil
      state.ignore_closed = false
    end
  else
    pin_button.style = "frame_action_button"
    pin_button.sprite = "rb_pin_white"
    player.opened = refs.window
  end
end

--- @param Gui SearchGui
function actions.toggle_settings(Gui, _, _)
  local state = Gui.state
  local player = Gui.player

  state.ignore_closed = true
  local SettingsGui = util.get_gui(Gui.player.index, "settings")
  if SettingsGui then
    SettingsGui:destroy()
  else
    SETTINGS_GUI.build(player, Gui.player_table)
  end
  state.ignore_closed = false
  local settings_button = Gui.refs.titlebar.settings_button
  if Gui.player_table.guis.settings then
    settings_button.style = "flib_selected_frame_action_button"
    settings_button.sprite = "rb_settings_black"
  else
    settings_button.style = "frame_action_button"
    settings_button.sprite = "rb_settings_white"
    if not state.pinned then
      player.opened = Gui.refs.window
    end
  end
end

--- @param Gui SearchGui
function actions.deselect_settings_button(Gui, _, _)
  local settings_button = Gui.refs.titlebar.settings_button
  settings_button.style = "frame_action_button"
  settings_button.sprite = "rb_settings_white"
  if not Gui.state.pinned and Gui.refs.window.visible then
    Gui.player.opened = Gui.refs.window
  end
end

--- @param Gui SearchGui
--- @param e on_gui_text_changed
function actions.update_search_query(Gui, _, e)
  local player_table = Gui.player_table
  local state = Gui.state
  local refs = Gui.refs

  local class_filter
  local query = string.lower(e.element.text)
  if string.find(query, "/") then
    -- The `_`s here are technically globals, but whatever
    _, _, class_filter, query = string.find(query, "^/(.-)/(.-)$")
    if class_filter then
      class_filter = string.lower(class_filter)
    end
    -- Check translations of each class filter
    local matched = false
    if class_filter then
      local gui_translations = player_table.translations.gui
      for _, class in pairs(constants.classes) do
        if class_filter == string.lower(gui_translations[class]) then
          matched = true
          class_filter = class
          break
        end
      end
    end
    -- Invalidate textfield
    if not class_filter or not query or not matched then
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
    if player_table.settings.general.search.fuzzy_search then
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
      { gui = "search", action = "update_search_results", player_index = e.player_index }
    )
    refs.search_textfield.style = "rb_search_textfield"
  else
    state.search_query = ""
    refs.search_textfield.style = "rb_search_invalid_textfield"
  end
end

--- @param Gui SearchGui
function actions.update_search_results(Gui, _, _)
  local player = Gui.player
  local player_table = Gui.player_table
  local state = Gui.state
  local refs = Gui.refs

  -- Data
  local player_data = formatter.build_player_data(player, player_table)
  local show_fluid_temperatures = player_table.settings.general.search.show_fluid_temperatures
  local search_type = player_table.settings.general.search.search_type

  -- Update results based on query
  local i = 0
  local pane = refs.search_results_pane
  local children = pane.children
  local max = constants.search_results_limit
  local class_filter = state.class_filter
  local query = state.search_query
  if class_filter ~= false and (class_filter or #query >= 2) then
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
            local obj_data = database[class][internal]

            -- Check temperature settings
            local passed = true
            if obj_data.class == "fluid" then
              local temperature_ident = obj_data.temperature_ident
              if temperature_ident then
                local is_range = temperature_ident.min ~= temperature_ident.max
                if is_range then
                  if show_fluid_temperatures ~= "all" then
                    passed = false
                  end
                else
                  if show_fluid_temperatures == "off" then
                    passed = false
                  end
                end
              end
            end

            if passed then
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
                  gui.update_tags(item, { context = { class = class, name = internal } })
                else
                  gui.add(pane, {
                    type = "button",
                    style = style,
                    caption = info.caption,
                    tooltip = info.tooltip,
                    enabled = info.enabled,
                    mouse_button_filter = { "left", "middle" },
                    tags = {
                      context = { class = class, name = internal },
                    },
                    actions = {
                      on_click = { gui = "search", action = "open_object" },
                    },
                  })
                  if i >= max then
                    break
                  end
                end
              end
            end
          end
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

--- @param Gui SearchGui
--- @param e on_gui_click
function actions.open_object(Gui, _, e)
  local context = gui_util.navigate_to(e)
  if context then
    local attach = Gui.player_table.settings.general.interface.attach_search_results
    local sticky = attach and e.button == defines.mouse_button_type.left
    local id = sticky and Gui.state.id and Gui.player_table.guis.info[Gui.state.id] and Gui.state.id or nil
    local parent = sticky and Gui.refs.window or nil
    OPEN_PAGE(Gui.player, Gui.player_table, context, { id = id, parent = parent })
    if sticky and not id then
      Gui.state.id = Gui.player_table.guis.info._active_id
    end
    if not sticky and Gui.player_table.settings.general.interface.close_search_gui_after_selection then
      actions.close(Gui)
    end
  end
end

--- @param Gui SearchGui
function actions.update_favorites(Gui, _, _)
  Gui:update_favorites()
end

--- @param Gui SearchGui
function actions.update_history(Gui, _, _)
  Gui:update_history()
end

--- @param Gui SearchGui
function actions.delete_favorites(Gui, _, _)
  Gui.player_table.favorites = {}
  Gui:update_favorites()
end

--- @param Gui SearchGui
function actions.delete_history(Gui, _, _)
  Gui.player_table.global_history = {}
  Gui:update_history()
end

return actions
