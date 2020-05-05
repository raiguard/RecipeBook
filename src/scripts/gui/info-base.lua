local info_base_gui = {}

local event = require("__flib__.control.event")
local gui = require("__flib__.control.gui")

local constants = require("scripts.constants")
local lookup_tables = require("scripts.lookup-tables")

local pages = {}
for name in pairs(constants.info_guis) do
  pages[name] = require("scripts.gui.info-pages."..name)
end

local string_lower = string.lower
local table_insert = table.insert
local table_remove = table.remove

gui.add_handlers{
  info_base={
    close_button = {
      on_gui_click = function(e)
        info_base_gui.close(game.get_player(e.player_index), global.players[e.player_index])
      end
    },
    nav_backward_button = {
      on_gui_click = function(e)
        local player_table = global.players[e.player_index]
        local session_history = player_table.history.session
        local back_obj = session_history[session_history.position+1]
        if back_obj.mod_name and back_obj.gui_name then
          -- this is a source
          info_base_gui.close(game.get_player(e.player_index), player_table)
          event.raise(constants.reopen_source_event, {player_index=e.player_index, source_data=back_obj})
        else
          -- this is an info page
          session_history.position = session_history.position + 1
          info_base_gui.update_contents(game.get_player(e.player_index), player_table, back_obj.category, back_obj.name, nil, true)
        end
      end
    },
    nav_forward_button = {
      on_gui_click = function(e)
        local player_table = global.players[e.player_index]
        local session_history = player_table.history.session
        local forward_obj = session_history[session_history.position-1]
        session_history.position = session_history.position - 1
        -- update content
        info_base_gui.update_contents(game.get_player(e.player_index), player_table, forward_obj.category, forward_obj.name, nil, true)
      end
    },
    window = {
      on_gui_closed = function(e)
        info_base_gui.close(game.get_player(e.player_index), global.players[e.player_index])
      end
    }
  }
}

function info_base_gui.open(player, player_table, category, name, source_data)
  -- gui structure
  local gui_data = gui.build(player.gui.screen, {
    {type="frame", name="rb_info_window", style="dialog_frame", direction="vertical", handlers="info_base.window", save_as="window", children={
      -- titlebar
      {type="flow", style="rb_titlebar_flow", direction="horizontal", children={
        {type="sprite-button", style="rb_frame_action_button", sprite="rb_nav_backward", hovered_sprite="rb_nav_backward_dark",
          clicked_sprite="rb_nav_backward_dark", mouse_button_filter={"left"}, handlers="info_base.nav_backward_button", save_as="nav_backward_button"},
        {type="sprite-button", style="rb_frame_action_button", sprite="rb_nav_forward", hovered_sprite="rb_nav_forward_dark",
          clicked_sprite="rb_nav_forward_dark", mouse_button_filter={"left"}, handlers="info_base.nav_forward_button", save_as="nav_forward_button"},
        {type="label", style="frame_title", style_mods={left_padding=6}, save_as="window_title"},
        {type="empty-widget", style="rb_titlebar_draggable_space", save_as="drag_handle"},
        -- {type="sprite-button", style="rb_frame_action_button", sprite="rb_nav_search", hovered_sprite="rb_nav_search_dark",
        --   clicked_sprite="rb_nav_search_dark", mouse_button_filter={"left"}, handlers="info_base.search_button"},
        {template="close_button", handlers="info_base.close_button"}
      }},
      {type="frame", style="window_content_frame_packed", direction="vertical", children={
        -- toolbar
        {type="frame", style="subheader_frame", direction="horizontal", children={
          {type="sprite", style="rb_object_icon", save_as="object_icon"},
          {type="label", style="subheader_caption_label", style_mods={left_padding=0}, save_as="object_name"},
          {template="pushers.horizontal"}
        }},
        -- content container
        {type="flow", style_mods={padding=8}, save_as="content_container"}
      }}
    }}
  })

  -- drag handle
  gui_data.drag_handle.drag_target = gui_data.window

  -- opened
  player.opened = gui_data.window

  -- add to global
  player_table.gui.info = {base=gui_data}

  -- set initial content
  info_base_gui.update_contents(player, player_table, category, name, source_data)
end

function info_base_gui.close(player, player_table)
  local gui_data = player_table.gui
  -- destroy content / deregister handlers
  pages[gui_data.info.category].destroy(player, gui_data.info.base.content_container)
  -- destroy base
  gui.update_filters("info_base", player.index, nil, "remove")
  gui_data.info.base.window.destroy()
  -- remove data from global
  gui_data.info = nil
  -- reset session history
  player_table.history.session = {position=0}
end

function info_base_gui.update_contents(player, player_table, category, name, source_data, nav_button)
  local gui_data = player_table.gui.info
  local base_elems = gui_data.base
  local dictionary = lookup_tables[player.index]
  local object_data = global.recipe_book[category][name]

  -- update search history
  if not nav_button then
    table_insert(player_table.history.overall, 1, {category=category, name=name})
  end
  local session_history = player_table.history.session
  if source_data then
    -- reset session history
    player_table.history.session = {position=1, [1]={category=category, name=name}, [2]=source_data}
    session_history = player_table.history.session
  elseif not nav_button then
    -- modify session history
    if session_history.position > 1 then
      for _=1,session_history.position - 1 do
        table_remove(session_history, 1)
      end
      session_history.position = 1
    elseif session_history.position == 0 then
      session_history.position = 1
    end
    table_insert(session_history, 1, {category=category, name=name})
  end

  -- update titlebar
  local back_button = base_elems.nav_backward_button
  back_button.enabled = true
  local back_obj = session_history[session_history.position+1]
  if back_obj then
    if back_obj.mod_name and back_obj.gui_name then
      back_button.tooltip = {"rb-gui.back-to", {"rb-remote.source-"..back_obj.mod_name.."-"..back_obj.gui_name}}
    else
      back_button.tooltip = {"rb-gui.back-to", string_lower(dictionary[back_obj.category].translations[back_obj.name])}
    end
  else
    back_button.enabled = false
    back_button.tooltip = ""
  end
  local forward_button = base_elems.nav_forward_button
  if session_history.position > 1 then
    forward_button.enabled = true
    local forward_obj = session_history[session_history.position-1]
    forward_button.tooltip = {"rb-gui.forward-to", string_lower(dictionary[forward_obj.category].translations[forward_obj.name])}
  else
    forward_button.enabled = false
    forward_button.tooltip = ""
  end
  base_elems.window_title.caption = {"rb-gui."..category.."-upper"}

  -- update object name
  base_elems.object_icon.sprite = object_data.sprite_class.."/"..object_data.prototype_name
  base_elems.object_name.caption = dictionary[category].translations[name]

  -- update main content
  local content_container = base_elems.content_container
  if #content_container.children > 0 then
    -- destroy previous content
    pages[gui_data.category].destroy(player, content_container)
  end
  -- build new content
  gui_data.page = pages[category].create(player, player_table, content_container, name)

  -- center window
  base_elems.window.force_auto_center()

  -- update global data
  gui_data.category = category
  gui_data.name = name
end

function info_base_gui.open_or_update(player, player_table, category, name, source_data)
  -- check for pre-existing window
  if player_table.gui.info then
    info_base_gui.update_contents(player, player_table, category, name, source_data)
  else
    info_base_gui.open(player, player_table, category, name, source_data)
  end
end

return info_base_gui