local gui = require("__flib__.gui-beta")
local math = require("__flib__.math")
local locale = require("lib.locale")

local constants = require("constants")

local formatter = require("scripts.formatter")
local shared = require("scripts.shared")
local util = require("scripts.util")

local components = {
  list_box = require("scripts.gui.info.list-box"),
  table = require("scripts.gui.info.table")
}

local info_gui = {}

local function tool_button(sprite, tooltip, ref, action)
  return {
      type = "sprite-button",
      style = "tool_button",
      sprite = sprite,
      tooltip = tooltip,
      mouse_button_filter = {"left"},
      ref = ref,
      actions = {
        on_click = action
      }
    }

end

function info_gui.build(player, player_table, context)
  local id = player_table.guis.info._next_id
  player_table.guis.info._next_id = id + 1
  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      style_mods = {width = 430},
      direction = "vertical",
      ref = {"window", "frame"},
      actions = {
        on_closed = {gui = "info", id = id, action = "close"}
      },
      {type = "flow", style = "flib_titlebar_flow", ref = {"titlebar", "flow"},
        util.frame_action_button(
          "rb_nav_backward",
          nil,
          {"titlebar", "nav_backward_button"},
          {gui = "info", id = id, action = "navigate", delta = -1}
        ),
        util.frame_action_button(
          "rb_nav_forward",
          nil,
          {"titlebar", "nav_forward_button"},
          {gui = "info", id = id, action = "navigate", delta = 1}
        ),
        {
          type = "label",
          style = "frame_title",
          style_mods = {left_margin = 4},
          ignored_by_interaction = true,
          ref = {"titlebar", "label"}
        },
        {
          type = "empty-widget",
          style = "flib_titlebar_drag_handle",
          ignored_by_interaction = true,
          ref = {"titlebar", "drag_handle"}
        },
        {
          type = "textfield",
          style_mods = {
            top_margin = -3,
            right_padding = 3,
            width = 120
          },
          visible = false,
          ref = {"titlebar", "search_textfield"},
          actions = {
            on_text_changed = {gui = "info", id = id, action = "update_search_query"}
          }
        },
        util.frame_action_button(
          "utility/search",
          {"gui.rb-search-instruction"},
          {"titlebar", "search_button"},
          {gui = "info", id = id, action = "toggle_search"}
        ),
        -- util.frame_action_button(
        --   "rb_pin",
        --   {"gui.rb-pin-instruction"},
        --   {"titlebar", "pin_button"},
        --   {gui = "info", id = id, action = "toggle_pinned"}
        -- ),
        -- util.frame_action_button(
        --   "rb_settings",
        --   {"gui.rb-settings-instruction"},
        --   {"titlebar", "settings_button"},
        --   {gui = "info", id = id, action = "toggle_settings"}
        -- ),
        util.frame_action_button(
          "utility/close",
          {"gui.close-instruction"},
          {"titlebar", "close_button"},
          {gui = "info", id = id, action = "close"}
        )
      },
      {
        type = "frame",
        style = "inside_shallow_frame",
        direction = "vertical",
        ref = {"page_frame"},
        {type = "frame", style = "subheader_frame",
          {
            type = "label",
            style = "rb_toolbar_label",
            ref = {"header", "label"}
          },
          {type = "empty-widget", style = "flib_horizontal_pusher"},
          tool_button(
            "rb_technology_gui_black",
            {"gui.rb-open-in-technology-window"},
            {"header", "open_in_tech_window_button"},
            {gui = "info", id = id, action = "open_in_tech_window"}
          ),
          tool_button(
            "rb_fluid_black",
            {"gui.rb-go-to-base-fluid"},
            {"header", "go_to_base_fluid_button"},
            {gui = "info", id = id, action = "go_to_base_fluid"}
          ),
          tool_button(
            "rb_clipboard_black",
            {"gui.rb-toggle-quick-ref-window"},
            {"header", "quick_ref_button"},
            {gui = "info", id = id, action = "toggle_quick_ref"}
          ),
          tool_button(
            "rb_favorite_black",
            {"gui.rb-add-to-favorites"},
            {"header", "favorite_button"},
            {gui = "info", id = id, action = "toggle_favorite"}
          )
        },
        {
          type = "scroll-pane",
          style = "rb_page_scroll_pane",
          style_mods = {maximal_height = 900},
          ref = {"page_scroll_pane"}
        },
        {type = "flow", style = "rb_warning_flow", direction = "vertical", visible = false, ref = {"warning_flow"},
          {type = "label", style = "bold_label", caption = {"gui.rb-no-content-warning"}, ref = {"warning_text"}}
        }
      }
    }
  })

  refs.titlebar.flow.drag_target = refs.window.frame
  refs.window.frame.force_auto_center()

  refs.page_components = {}

  player_table.guis.info[id] = {
    refs = refs,
    state = {
      history = {_index = 1, context},
      search_opened = false,
      search_query = "",
      warning_shown = false
    }
  }

  info_gui.update_contents(player, player_table, id)
end

function info_gui.destroy(player_table, id)
  local gui_data = player_table.guis.info[id]
  if gui_data then
    gui_data.refs.window.frame.destroy()
    player_table.guis.info[id] = nil
  end
end

function info_gui.destroy_all(player_table)
  for id in pairs(player_table.guis.info) do
    if id ~= "_next_id" then
      info_gui.destroy(player_table, id)
    end
  end
end

function info_gui.find_open_context(player_table, context)
  local open = {}
  for id, gui_data in pairs(player_table.guis.info) do
    if id ~= "_next_id" then
      local state = gui_data.state
      local opened_context = state.history[state.history._index]
      -- TODO: Shouldn't ever be `nil`
      if opened_context and opened_context.class == context.class and opened_context.name == context.name then
        open[#open + 1] = id
      end
    end
  end

  return open
end

function info_gui.update_contents(player, player_table, id, new_context)
  local gui_data = player_table.guis.info[id]
  local state = gui_data.state
  local refs = gui_data.refs

  -- HISTORY

  -- Add new history if needed
  local history = state.history
  if new_context then
    -- Remove all entries after this
    local history_len = #history
    for i = history._index + 1, #history do
      history[i] = nil
    end
    -- Insert new entry
    history_len = #history
    history[history_len + 1] = new_context
    history._index = history_len + 1
  end

  -- COMMON DATA

  local context = new_context or history[history._index]
  local obj_data = global.recipe_book[context.class][context.name]

  local player_data = {
    favorites = player_table.favorites,
    force_index = player.force.index,
    history = player_table.history.global,
    player_index = player.index,
    settings = player_table.settings,
    translations = player_table.translations
  }
  local gui_translations = player_data.translations.gui

  -- TITLEBAR

  -- Nav buttons

  -- Generate tooltips
  local history_index = history._index
  local history_len = #history
  local entries = {}
  for i, history_context in ipairs(history) do
    local obj_data = global.recipe_book[history_context.class][history_context.name]
    local info = formatter(obj_data, player_data, {always_show = true})
    local caption = info.caption
    if not info.is_researched then
      caption = locale.rich_text("color", "unresearched", caption)
    end
    entries[history_len - (i - 1)] = locale.rich_text(
      "font",
      "default-semibold",
      locale.rich_text("color", history_index == i and "green" or "invisible", ">")
    ).."   "..caption
  end
  local entries = table.concat(entries, "\n")
  local base_tooltip = locale.rich_text(
    "font",
    "default-bold",
    locale.rich_text("color", "heading", gui_translations.session_history)
  ).."\n"..entries

  -- Apply button properties
  local nav_backward_button = refs.titlebar.nav_backward_button
  if history._index == 1 then
    nav_backward_button.enabled = false
    nav_backward_button.sprite = "rb_nav_backward_disabled"
  else
    nav_backward_button.enabled = true
    nav_backward_button.sprite = "rb_nav_backward_white"
  end
  nav_backward_button.tooltip = base_tooltip
    ..locale.control(gui_translations.click, gui_translations.go_backward)
    ..locale.control(gui_translations.shift_click, gui_translations.go_to_the_back)

  local nav_forward_button = refs.titlebar.nav_forward_button
  if history._index == #history then
    nav_forward_button.enabled = false
    nav_forward_button.sprite = "rb_nav_forward_disabled"
  else
    nav_forward_button.enabled = true
    nav_forward_button.sprite = "rb_nav_forward_white"
  end
  nav_forward_button.tooltip = base_tooltip
    ..locale.control(gui_translations.click, gui_translations.go_forward)
    ..locale.control(gui_translations.shift_click, gui_translations.go_to_the_front)

  -- Label
  local label = refs.titlebar.label
  label.caption = constants.class_to_titlebar_label[context.class]

  -- HEADER

  -- Label
  local title_info = formatter(obj_data, player_data, {always_show = true, is_label = true})
  local label = refs.header.label
  label.caption = title_info.caption
  label.tooltip = title_info.tooltip

  -- Buttons
  if context.class == "technology" then
    refs.header.open_in_tech_window_button.visible = true
    -- TODO: Tech level
  else
    refs.header.open_in_tech_window_button.visible = false
  end
  if context.class == "fluid" and obj_data.temperature_ident then
    refs.header.go_to_base_fluid_button.visible = true
  else
    refs.header.go_to_base_fluid_button.visible = false
  end
  if context.class == "recipe" then
    local button = refs.header.quick_ref_button
    button.visible = true
    local is_selected = player_table.guis.quick_ref[context.name]
    button.style = is_selected and "flib_selected_tool_button" or "tool_button"
    button.tooltip = {"gui.rb-"..(is_selected and "close" or "open").."-quick-ref-window"}
  else
    refs.header.quick_ref_button.visible = false
  end
  local favorite_button = refs.header.favorite_button
  if player_table.favorites[context.class.."."..context.name] then
    favorite_button.style = "flib_selected_tool_button"
    favorite_button.tooltip = {"gui.rb-remove-from-favorites"}
  else
    favorite_button.style = "tool_button"
    favorite_button.tooltip = {"gui.rb-add-to-favorites"}
  end

  -- PAGE

  local pane = refs.page_scroll_pane
  local page_refs = refs.page_components

  local i = 0
  local visible = false
  -- Add or update relevant components
  for _, component_data in pairs(constants.pages[context.class]) do
    i = i + 1
    local component = components[component_data.type]
    local component_refs = page_refs[i]
    if not component_refs or component_refs.type ~= component.type then
      -- Destroy old elements
      if component_refs then
        component_refs.root.destroy()
      end
      -- Create new elements
      component_refs = component.build(pane, i, component_data)
      component_refs.type = component_data.type
      page_refs[i] = component_refs
    end

    local comp_visible = component.update(
      component_data,
      component_refs,
      obj_data,
      player_data,
      {context = context, gui_id = id, search_query = state.search_query}
    )

    visible = visible or comp_visible
  end
  -- Destroy extraneous components
  for j = i + 1, #page_refs do
    page_refs[j].root.destroy()
    page_refs[j] = nil
  end

  -- Show error frame if nothing is visible
  if not visible and not state.warning_shown then
    state.warning_shown = true
    pane.visible = false
    refs.page_frame.style = "rb_inside_warning_frame"
    refs.warning_flow.visible = true
    if state.search_query == "" then
      refs.warning_text.caption = {"gui.rb-no-content-warning"}
    else
      refs.warning_text.caption = {"gui.rb-no-results"}
    end
  elseif visible and state.warning_shown then
    state.warning_shown = false
    pane.visible = true
    refs.page_frame.style = "inside_shallow_frame"
    refs.warning_flow.visible = false
  end
end

function info_gui.handle_action(msg, e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]

  local gui_data = player_table.guis.info[msg.id]
  local state = gui_data.state
  local refs = gui_data.refs

  local context = state.history[state.history._index]

  if msg.action == "close" then
    info_gui.destroy(player_table, msg.id)
  elseif msg.action == "bring_to_front" then
    refs.window.frame.bring_to_front()
  elseif msg.action == "toggle_search" then
    local opened = state.search_opened
    state.search_opened = not opened

    local search_button = refs.titlebar.search_button
    local search_textfield = refs.titlebar.search_textfield
    if opened then
      -- Reset query and GUI properties
      search_button.sprite = "utility/search_white"
      search_button.style = "frame_action_button"
      search_textfield.text = ""
      state.search_query = ""
      search_textfield.visible = false
      -- Refresh page
      info_gui.update_contents(player, player_table, msg.id)
    else
      -- Show search textfield
      search_button.sprite = "utility/search_black"
      search_button.style = "flib_selected_frame_action_button"
      search_textfield.visible = true
      search_textfield.focus()
    end
  elseif msg.action == "navigate" then
    -- Update position in history
    local delta = msg.delta
    local history = state.history
    if e.shift then
      if delta < 0 then
        history._index = 1
      else
        history._index = #history
      end
    else
      history._index = math.clamp(history._index + delta, 1, #history)
    end
    -- Update contents
    info_gui.update_contents(player, player_table, msg.id)
  elseif msg.action == "update_search_query" then
    local query = string.lower(e.element.text)
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

    -- Update based on query
    info_gui.update_contents(player, player_table, msg.id)
  elseif msg.action == "navigate_to" then
    local context = util.navigate_to(e)
    if context then
      if e.button == defines.mouse_button_type.middle then
        info_gui.build(player, player_table, context)
      else
        info_gui.update_contents(player, player_table, msg.id, context)
      end
    end
  elseif msg.action == "open_in_tech_window" then
    player.open_technology_gui(context.name)
  elseif msg.action == "go_to_base_fluid" then
    local base_fluid = global.recipe_book.fluid[context.name].prototype_name
    info_gui.update_contents(player, player_table, msg.id, {class = "fluid", name = base_fluid})
  elseif msg.action == "toggle_quick_ref" then
    shared.toggle_quick_ref(player, player_table, context.name)
  elseif msg.action == "toggle_favorite" then
    local favorites = player_table.favorites
    local combined_name = context.class.."."..context.name
    local to_state
    if favorites[combined_name] then
      to_state = false
      favorites[combined_name] = nil
    else
      -- Copy the table instead of passing a reference
      favorites[combined_name] = {class = context.class, name = context.name}
      to_state = true
    end
    shared.update_header_button(player, player_table, context, "favorite_button", to_state)
  elseif msg.action == "update_header_button" then
    local button = refs.header[msg.button]
    if msg.to_state then
      button.style = "flib_selected_tool_button"
      button.tooltip = constants.header_button_tooltips[msg.button].selected
    else
      button.style = "tool_button"
      button.tooltip = constants.header_button_tooltips[msg.button].unselected
    end
  end
end

return info_gui
