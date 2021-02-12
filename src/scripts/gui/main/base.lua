local gui = require("__flib__.gui-beta")
local table = require("__flib__.table")

local constants = require("constants")
local formatter = require("scripts.formatter")

local info_list_box = require("scripts.gui.main.info-list-box")
local quick_ref_gui = require("scripts.gui.quick-ref")

local pages = {}
for _, name in ipairs(constants.main_pages) do
  pages[name] = require("scripts.gui.main.pages."..name)
end

local main_gui = {}

function main_gui.build(player, player_table)
  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      style = "outer_frame",
      visible = false,
      ref = {"base", "window", "frame"},
      actions = {
        on_closed = {gui = "main", action = "close"}
      },
      children = {
        -- main window
        {type = "frame", style = "inner_frame_in_outer_frame", direction = "vertical", children = {
          {type = "flow", style = "flib_titlebar_flow", ref = {"base", "titlebar", "flow"}, children = {
            {
              type = "sprite-button",
              style = "frame_action_button",
              sprite = "rb_nav_backward_white",
              hovered_sprite = "rb_nav_backward_black",
              clicked_sprite = "rb_nav_backward_black",
              mouse_button_filter = {"left"},
              enabled = false,
              ref = {"base", "titlebar", "nav_backward_button"},
              actions = {
                on_click = {gui = "main", action = "navigate_backward"}
              }
            },
            {
              type = "sprite-button",
              style = "frame_action_button",
              sprite = "rb_nav_forward_white",
              hovered_sprite = "rb_nav_forward_black",
              clicked_sprite = "rb_nav_forward_black",
              mouse_button_filter = {"left"},
              enabled = false,
              ref = {"base", "titlebar", "nav_forward_button"},
              actions = {
                on_click = {gui = "main", action = "navigate_forward"}
              }
            },
            {
              type = "label",
              style = "frame_title",
              style_mods = {left_margin = 4},
              caption = {"mod-name.RecipeBook"},
              ignored_by_interaction = true
            },
            {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
            {
              type = "sprite-button",
              style = "frame_action_button",
              sprite = "rb_pause_white",
              hovered_sprite = "rb_pause_black",
              clicked_sprite = "rb_pause_black",
              tooltip = {"rb-gui.pause-game"},
              mouse_button_filter = {"left"},
              ref = {"base", "titlebar", "pause_button"},
              actions = {
                on_click = {gui = "main", action = "toggle_paused"}
              }
            },
            {
              type = "sprite-button",
              style = "frame_action_button",
              sprite = "rb_pin_white",
              hovered_sprite = "rb_pin_black",
              clicked_sprite = "rb_pin_black",
              tooltip = {"rb-gui.keep-open"},
              mouse_button_filter = {"left"},
              ref = {"base", "titlebar", "pin_button"},
              actions = {
                on_click = {gui = "main", action = "toggle_pinned"}
              }
            },
            {
              type = "sprite-button",
              style = "frame_action_button",
              tooltip = {"rb-gui.settings"},
              sprite = "rb_settings_white",
              hovered_sprite = "rb_settings_black",
              clicked_sprite = "rb_settings_black",
              mouse_button_filter = {"left"},
              ref = {"base", "titlebar", "settings_button"},
              actions = {
                on_click = {gui = "main", action = "toggle_settings"}
              }
            },
            {
              type = "sprite-button",
              style = "frame_action_button",
              sprite = "utility/close_white",
              hovered_sprite = "utility/close_black",
              clicked_sprite = "utility/close_black",
              mouse_button_filter = {"left"},
              actions = {
                on_click = {gui = "main", action = "close"}
              }
            }
          }},
          {type = "flow", style = "rb_main_frame_flow", children = {
            -- search page
            {type = "frame", style = "inside_shallow_frame", direction = "vertical", children = pages.search.build()},
            -- info page
            {type = "frame", style = "rb_main_info_frame", direction = "vertical", children = {
              -- info bar
              {
                type = "frame",
                style = "subheader_frame",
                visible = false,
                ref = {"base", "info_bar", "frame"},
                children = {
                  {type = "label", style = "rb_toolbar_label", ref = {"base", "info_bar", "label"}},
                  {type = "empty-widget", style = "flib_horizontal_pusher"},
                  {
                    type = "sprite-button",
                    style = "tool_button",
                    sprite = "rb_fluid_black",
                    tooltip = {"rb-gui.view-base-fluid"},
                    mouse_button_filter = {"left"},
                    ref = {"base", "info_bar", "view_base_fluid_button"},
                    -- the action is set and changed in the open_page function
                  },
                  {
                    type = "sprite-button",
                    style = "tool_button",
                    sprite = "rb_clipboard_black",
                    tooltip = {"rb-gui.open-quick-reference"},
                    mouse_button_filter = {"left"},
                    ref = {"base", "info_bar", "quick_ref_button"},
                    actions = {
                      on_click = {gui = "main", action = "toggle_quick_ref"}
                    }
                  },
                  {
                    type = "sprite-button",
                    style = "tool_button",
                    sprite = "rb_favorite_black",
                    tooltip = {"rb-gui.add-to-favorites"},
                    mouse_button_filter = {"left"},
                    ref = {"base", "info_bar", "favorite_button"},
                    actions = {
                      on_click = {gui = "main", action = "toggle_favorite"}
                    }
                  }
                }
              },
              -- content scroll pane
              {type = "scroll-pane", style = "rb_naked_scroll_pane", children = {
                {
                  type = "flow",
                  style = "rb_main_info_pane_flow",
                  direction = "vertical",
                  visible = false,
                  ref = {"home", "flow"},
                  children = pages.home.build()
                },
                {
                  type = "flow",
                  style = "rb_main_info_pane_flow",
                  direction = "vertical",
                  visible = false,
                  ref = {"crafter", "flow"},
                  children = pages.crafter.build()
                },
                {
                  type = "flow",
                  style = "rb_main_info_pane_flow",
                  direction = "vertical",
                  visible = false,
                  ref = {"fluid", "flow"},
                  children = pages.fluid.build()
                },
                {
                  type = "flow",
                  style = "rb_main_info_pane_flow",
                  direction = "vertical",
                  visible = false,
                  ref = {"item", "flow"},
                  children = pages.item.build()
                },
                {
                  type = "flow",
                  style = "rb_main_info_pane_flow",
                  direction = "vertical",
                  visible = false,
                  ref = {"recipe", "flow"},
                  children = pages.recipe.build()
                },
                {
                  type = "flow",
                  style_mods = {
                    horizontally_stretchable = true,
                    vertically_stretchable = true,
                    horizontal_align = "center",
                    vertical_align = "center",
                    vertical_spacing = 12
                  },
                  direction = "vertical",
                  ref = {"empty_page_placeholder_flow"},
                  children = {
                    {
                      type = "label",
                      style = "heading_1_label",
                      style_mods = {
                        horizontal_align = "center",
                        vertical_align = "center",
                        single_line = false,
                        font_color = {36, 35, 36}
                      },
                      caption = {"rb-gui.nothing-to-see-here"}
                    },
                    {
                      type = "label",
                      style = "heading_2_label",
                      style_mods = {
                        horizontal_align = "center",
                        vertical_align = "center",
                        single_line = false,
                        font_color = {36, 35, 36}
                      },
                      caption = {"rb-gui.no-content-description"}
                    }
                  }
                }
              }}
            }}
          }
        }
      }},
      -- settings window
      {
        type = "frame",
        style = "inner_frame_in_outer_frame",
        direction = "vertical",
        visible = false,
        ref = {"settings", "window"},
        children = {
          {type = "flow", style = "flib_titlebar_flow", ref = {"settings", "titlebar_flow"}, children = {
            {type = "label", style = "frame_title", caption = {"gui-menu.settings"}, ignored_by_interaction = true},
            {type = "empty-widget", style = "flib_dialog_titlebar_drag_handle", ignored_by_interaction = true},
          }},
          {type = "frame", style = "inside_shallow_frame", children = {
            {
              type = "scroll-pane",
              style = "rb_settings_content_scroll_pane",
              direction = "vertical",
              children = pages.settings.build(player_table.settings)
            }
          }}
        }
      }
    }}
  })

  -- centering
  refs.base.window.frame.force_auto_center()
  refs.base.titlebar.flow.drag_target = refs.base.window.frame
  refs.settings.titlebar_flow.drag_target = refs.base.window.frame

  player_table.guis.main = {
    refs = refs,
    state = {
      open_page = {
        class = "home"
      },
      pinned = false,
      pinning = false,
      search = pages.search.init(),
      settings = pages.settings.init()
    }
  }

  -- open home page
  main_gui.open_page(player, player_table, "home")
end

function main_gui.destroy(player_table)
  local gui_data = player_table.guis.main
  if gui_data then
    local frame = gui_data.refs.base.window.frame
    if frame and frame.valid then
      frame.destroy()
    end
  end
  player_table.guis.main = nil
end

function main_gui.open(player, player_table, skip_focus)
  local gui_data = player_table.guis.main
  local refs = gui_data.refs
  local window = refs.base.window.frame
  if window and window.valid then
    window.visible = true
    window.bring_to_front()
  end
  player_table.flags.gui_open = true
  if not gui_data.state.pinned then
    player.opened = window
  end
  player.set_shortcut_toggled("rb-toggle-gui", true)

  if not skip_focus then
    refs.search.textfield.focus()
    refs.search.textfield.select_all()
  end
  if game.is_multiplayer() then
    refs.base.titlebar.pause_button.visible = false
  elseif player_table.settings.pause_game_on_open then
    game.tick_paused = true
    refs.base.titlebar.pause_button.style = "flib_selected_frame_action_button"
    refs.base.titlebar.pause_button.sprite = "rb_pause_black"
  end
end

function main_gui.close(player, player_table)
  local gui_data = player_table.guis.main
  if gui_data then
    local frame = gui_data.refs.base.window.frame
    if frame and frame.valid then
      frame.visible = false
      if player.opened == frame then
        player.opened = nil
      end
    end
  end
  if game.tick_paused == true then
    game.tick_paused = false
    local refs = player_table.guis.main.refs
    refs.base.titlebar.pause_button.style = "frame_action_button"
    refs.base.titlebar.pause_button.sprite = "rb_pause_white"
  end
  player_table.flags.gui_open = false
  player.set_shortcut_toggled("rb-toggle-gui", false)
end

function main_gui.toggle(player, player_table)
  if player_table.flags.gui_open then
    main_gui.close(player, player_table)
  else
    if not player_table.settings.preserve_session then
      local session_history = player_table.history.session
      session_history.position = #session_history
      local back_obj = session_history[session_history.position]
      main_gui.open_page(player, player_table, back_obj.class, back_obj.name, {skip_history = true})
    end
    main_gui.open(player, player_table)
  end
end

function main_gui.check_can_open(player, player_table)
  if player_table.flags.can_open_gui then
    return true
  else
    player.print{"rb-message.cannot-open-gui"}
    player_table.flags.show_message_after_translation = true
    return false
  end
end

function main_gui.open_page(player, player_table, class, name, options)
  options = options or {}
  name = name or ""
  local gui_data = player_table.guis.main
  local refs = gui_data.refs
  local translations = player_table.translations

  -- don't do anything if the page is already open
  local open_page_data = gui_data.state.open_page
  if not options.force_open then
    if
      open_page_data.class ~= "home"
      and open_page_data.class == class
      and open_page_data.name == name
    then
      return
    end
  end

  -- assemble various player data to be passed later
  local player_data = {
    favorites = player_table.favorites,
    force_index = player.force.index,
    history = player_table.history.global,
    open_page_data = open_page_data,
    player_index = player.index,
    settings = player_table.settings,
    translations = player_table.translations
  }

  -- update search history
  local history = player_table.history
  local session_history = history.session
  local global_history = history.global
  if not options.skip_history then
    -- global history
    local combined_name = class.."."..name
    if global_history[combined_name] then
      for i = 1, #global_history do
        local entry = global_history[i]
        if entry.class.."."..entry.name == combined_name then
          table.remove(global_history, i)
          break
        end
      end
    else
      global_history[combined_name] = true
    end
    table.insert(global_history, 1, {class = class, name = name})
    local last_entry = global_history[31]
    if last_entry then
      table.remove(global_history, 31)
      global_history[last_entry.class.."."..last_entry.name] = nil
    end

    -- session history
    if session_history.position > 1 then
      for _ = 1, session_history.position - 1 do
        table.remove(session_history, 1)
      end
      session_history.position = 1
    elseif session_history.position == 0 then
      session_history.position = 1
    end
    table.insert(session_history, 1, {class = class, name = name})
  end

  -- update nav buttons
  local position = session_history.position
  local tooltip_str_tbl = {}
  for i = 1, #session_history do
    local entry = session_history[i]
    local label = (
      "[font=default-bold][color="
      ..(position == i and constants.colors.green.str or "0,0,0,0")
      .."]>[/color][/font]   "
    )
    if entry.class == "home" then
      label = label.."[font=default-semibold]"..translations.gui.home_page.."[/font]"
    else
      local obj_data = global.recipe_book[entry.class][entry.name]
      local data = formatter(obj_data, player_data, {always_show = true, is_label = true})
      local caption = data.caption
      if not data.is_researched then
        caption = "[color="..constants.colors.unresearched.str.."]"..caption.."[/color]"
      end
      label = label..caption
    end
    label = label.."\n"
    tooltip_str_tbl[i] = label
  end
  local tooltip_str = table.concat(tooltip_str_tbl)
  local backward_button = refs.base.titlebar.nav_backward_button
  local forward_button = refs.base.titlebar.nav_forward_button
  backward_button.tooltip = {
    "",
    "[font=default-bold][color="..constants.colors.heading.str.."]",
    {"rb-gui.session-history"},
    "[/color][/font]\n",
    tooltip_str,
    {"rb-gui.navigate-backward-tooltip"}
  }
  forward_button.tooltip = {
    "",
    "[font=default-bold][color="..constants.colors.heading.str.."]",
    {"rb-gui.session-history"},
    "[/color][/font]\n",
    tooltip_str,
    {"rb-gui.navigate-forward-tooltip"}
  }
  if position == 1 then
    forward_button.enabled = false
    forward_button.sprite = "rb_nav_forward_disabled"
  else
    forward_button.enabled = true
    forward_button.sprite = "rb_nav_forward_white"
  end
  if position < #session_history then
    backward_button.enabled = true
    backward_button.sprite = "rb_nav_backward_white"
  else
    backward_button.enabled = false
    backward_button.sprite = "rb_nav_backward_disabled"
  end

  -- update / toggle info bar
  local info_bar = refs.base.info_bar
  if class == "home" then
    info_bar.frame.visible = false
  else
    info_bar.frame.visible = true

    local obj_data = global.recipe_book[class][name]

    local data = formatter(
      obj_data,
      player_data,
      {always_show = true, is_label = true}
    )
    info_bar.label.caption = data.caption
    info_bar.label.tooltip = data.tooltip

    if class == "recipe" then
      local quick_ref_button = info_bar.quick_ref_button
      quick_ref_button.visible = true
      if player_table.guis.quick_ref[name] then
        quick_ref_button.style = "flib_selected_tool_button"
      else
        quick_ref_button.style = "tool_button"
      end
    else
      info_bar.quick_ref_button.visible = false
    end

    local base_button = info_bar.view_base_fluid_button
    if class == "fluid" and obj_data.temperature_data then
      base_button.visible = true
      gui.update_tags(
        base_button,
        {flib = {on_click = {gui = "main", action = "open_page", class = "fluid", name = obj_data.prototype_name}}}
      )
    else
      base_button.visible = false
    end

    if player_table.favorites[class.."."..name] then
      info_bar.favorite_button.style = "flib_selected_tool_button"
      info_bar.favorite_button.tooltip = {"rb-gui.remove-from-favorites"}
    else
      info_bar.favorite_button.style = "tool_button"
      info_bar.favorite_button.tooltip = {"rb-gui.add-to-favorites"}
    end
  end

  -- update page information
  local num_items = pages[class].update(name, gui_data, player_data)

  -- show placeholder if there are no items
  if num_items == 0 and class ~= "home" then
    refs.empty_page_placeholder_flow.visible = true
  else
    refs.empty_page_placeholder_flow.visible = false
  end

  -- update visible page
  refs[gui_data.state.open_page.class].flow.visible = false
  gui_data.refs[class].flow.visible = true

  -- update state
  gui_data.state.open_page = {
    class = class,
    name = name
  }
end

function main_gui.handle_action(msg, e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.guis.main
  local state = gui_data.state
  local refs = gui_data.refs

  if msg.page == "search" then
    pages.search.handle_action(msg, e)
  elseif msg.page == "settings" then
    pages.settings.handle_action(msg, e)
  else
    if msg.action == "open_page" then
      main_gui.open_page(player, player_table, msg.class, msg.name)
      if not player_table.flags.gui_open then
        main_gui.open(player, player_table, true)
      end
    elseif msg.action == "handle_list_box_item_click" then
      local class, name = info_list_box.handle_click(e, player, player_table)
      if class then
        main_gui.open_page(player, player_table, class, name)
      end
    elseif msg.action == "close" then
      if not state.pinning and not player_table.flags.technology_gui_open then
        main_gui.close(player, player_table)
      end
    elseif msg.action == "toggle_favorite" then
      local favorites = player_table.favorites
      local open_page = state.open_page
      local index_name = open_page.class.."."..open_page.name
      if favorites[index_name] then
        for i = 1, #favorites do
          local obj = favorites[i]
          if obj.class.."."..obj.name == index_name then
            table.remove(favorites, i)
            break
          end
        end
        favorites[index_name] = nil

        e.element.style = "tool_button"
        e.element.tooltip = {"rb-gui.add-to-favorites"}
      else
        favorites[index_name] = true
        table.insert(favorites, 1, open_page)

        e.element.style = "flib_selected_tool_button"
        e.element.tooltip = {"rb-gui.remove-from-favorites"}
      end
    elseif msg.action == "toggle_quick_ref" then
      local name = player_table.guis.main.state.open_page.name
      if player_table.guis.quick_ref[name] then
        quick_ref_gui.destroy(player_table, name)
        refs.base.info_bar.quick_ref_button.style = "tool_button"
      else
        quick_ref_gui.build(player, player_table, name)
        refs.base.info_bar.quick_ref_button.style = "flib_selected_tool_button"
      end
    elseif msg.action == "navigate_backward" then
      local session_history = player_table.history.session
      -- latency protection
      if session_history.position < #session_history then
        if e.shift then
          -- go all the way back
          session_history.position = #session_history
        else
          -- go back one
          session_history.position = session_history.position + 1
        end
        local back_obj = session_history[session_history.position]
        main_gui.open_page(
          game.get_player(e.player_index),
          player_table,
          back_obj.class,
          back_obj.name,
          {skip_history = true}
        )
      end
    elseif msg.action == "navigate_forward" then
      local session_history = player_table.history.session
      -- latency protection
      if session_history.position > 1 then
        if e.shift then
          -- go all the way forward
          session_history.position = 1
        else
          -- go forward one
          session_history.position = session_history.position - 1
        end
        local forward_object = session_history[session_history.position]
        main_gui.open_page(
          game.get_player(e.player_index),
          player_table,
          forward_object.class,
          forward_object.name,
          {skip_history = true}
        )
      end
    elseif msg.action == "toggle_pinned" then
      if state.pinned then
        refs.base.titlebar.pin_button.style = "frame_action_button"
        refs.base.titlebar.pin_button.sprite = "rb_pin_white"
        state.pinned = false
        refs.base.window.frame.force_auto_center()
        player.opened = refs.base.window.frame
      else
        refs.base.titlebar.pin_button.style = "flib_selected_frame_action_button"
        refs.base.titlebar.pin_button.sprite = "rb_pin_black"
        state.pinned = true
        refs.base.window.frame.auto_center = false
        state.pinning = true
        player.opened = nil
        state.pinning = false
      end
    elseif msg.action == "toggle_settings" then
      if state.settings.open then
        state.settings.open = false
        refs.settings.window.visible = false
        refs.base.titlebar.settings_button.style = "frame_action_button"
        refs.base.titlebar.settings_button.sprite = "rb_settings_white"
      else
        state.settings.open = true
        refs.settings.window.visible = true
        refs.base.titlebar.settings_button.style = "flib_selected_frame_action_button"
        refs.base.titlebar.settings_button.sprite = "rb_settings_black"
      end
    elseif msg.action == "toggle_paused" then
      if game.tick_paused then
        game.tick_paused = false
        refs.base.titlebar.pause_button.style = "frame_action_button"
        refs.base.titlebar.pause_button.sprite = "rb_pause_white"
      elseif not game.is_multiplayer() then
        game.tick_paused = true
        refs.base.titlebar.pause_button.style = "flib_selected_frame_action_button"
        refs.base.titlebar.pause_button.sprite = "rb_pause_black"
      end

    end
  end
end

function main_gui.refresh_contents(player, player_table)
  -- update all items
  main_gui.handle_action({gui = "main", page = "search"}, {player_index = player.index})
  local open_page = player_table.guis.main.state.open_page
  main_gui.open_page(
    player,
    player_table,
    open_page.class,
    open_page.name,
    {force_open = true, skip_history = true}
  )
end

function main_gui.update_quick_ref_button(player_table)
  local gui_data = player_table.guis.main
  local open_page = gui_data.state.open_page
  if open_page.class == "recipe" then
    local quick_ref_button = gui_data.refs.base.info_bar.quick_ref_button
    -- check for the quick ref window
    if player_table.guis.quick_ref[open_page.name] then
      quick_ref_button.style = "flib_selected_tool_button"
    else
      quick_ref_button.style = "tool_button"
    end
  end
end

function main_gui.update_settings(player_table)
  pages.settings.update(player_table.settings, player_table.guis.main.settings)
end

return main_gui
