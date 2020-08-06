local main_gui = {}

local gui = require("__flib__.gui")

local constants = require("constants")
local formatter = require("scripts.formatter")

local quick_ref_gui = require("scripts.gui.quick-ref")

local pages = {}
for _, name in ipairs(constants.main_pages) do
  pages[name] = require("scripts.gui.main.pages."..name)
end

-- get the width and height of an area
local function area_dimensions(area)
  local width = math.abs(area.left_top.x - area.right_bottom.x)
  local height = math.abs(area.left_top.y - area.right_bottom.y)
  return width, height
end

gui.add_templates{
  frame_action_button = {type="sprite-button", style="frame_action_button", mouse_button_filter={"left"}},
  info_list_box = {
    build = function(caption, rows, save_location)
      return {type="flow", direction="vertical", save_as=save_location..".flow", children={
        {type="label", style="rb_info_list_box_label", caption=caption, save_as=save_location..".label"},
        {type="frame", style="deep_frame_in_shallow_frame", save_as=save_location..".frame",  children={
          {type="scroll-pane", style="rb_list_box_scroll_pane", style_mods={height=(rows * 28)}, save_as=save_location..".scroll_pane"}
        }}
      }}
    end,
    update = function(tbl, int_class, list_box, player_data, always_show, starting_index)
      starting_index = starting_index or 0
      local recipe_book = global.recipe_book[int_class]

      -- scroll pane
      local scroll = list_box.scroll_pane
      local add = scroll.add
      local children = scroll.children

      -- loop through input table
      local i = starting_index
      for j = 1, #tbl do
        -- get object information
        local obj = tbl[j]
        local obj_data
        if int_class == "material" then
          obj_data = recipe_book[obj.type.."."..obj.name]
        elseif int_class == "crafter" then
          obj_data = recipe_book[obj.name]
        else
          obj_data = recipe_book[obj]
        end
        local should_add, style, caption, tooltip, enabled = formatter(obj_data, player_data, obj.amount_string, always_show)

        if should_add then
          i = i + 1
          -- update or add item
          local item = children[i]
          if item then
            item.style = style
            item.caption = caption
            item.tooltip = tooltip
            item.enabled = enabled
          else
            add{type="button", name="rb_list_box_item__"..i, style=style, caption=caption, tooltip=tooltip, enabled=enabled}
          end
        end
      end
      -- destroy extraneous items
      for j = i + 1, #children do
        children[j].destroy()
      end

      -- set listbox properties
      if i == 0 then
        list_box.flow.visible = false
      else
        list_box.flow.visible = true
        scroll.style.height = math.min((28 * i), (28 * 6))

        local caption = list_box.label.caption
        caption[2] = i - starting_index
        list_box.label.caption = caption
      end
    end
  },
  pushers = {
    horizontal = {type="empty-widget", style="rb_horizontal_pusher"},
    vertical = {type="empty-widget", style="rb_vertical_pusher"}
  },
  tool_button = {type="sprite-button", style="tool_button", mouse_button_filter={"left"}},
}

gui.add_handlers{
  base = {
    close_button = {
      on_gui_click = function(e)
        main_gui.close(game.get_player(e.player_index), global.players[e.player_index])
      end
    },
    favorite_button = {
      on_gui_click = function(e)
        local player_table = global.players[e.player_index]
        local favorites = player_table.favorites
        local gui_data = player_table.gui.main
        local state = gui_data.state
        local index_name = state.class.."."..state.name
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
          table.insert(favorites, 1, state)

          e.element.style = "rb_selected_tool_button"
          e.element.tooltip = {"rb-gui.remove-from-favorites"}
        end
      end
    },
    nav_button = {
      backward = {
        on_gui_click = function(e)
          local player_table = global.players[e.player_index]
          local session_history = player_table.history.session
          -- latency protection
          if session_history.position < #session_history then
            if e.button == defines.mouse_button_type.left then
              -- go back one
              session_history.position = session_history.position + 1
            else
              -- go all the way back
              session_history.position = #session_history
            end
            local back_obj = session_history[session_history.position]
            main_gui.open_page(
              game.get_player(e.player_index),
              player_table,
              back_obj.class,
              back_obj.name,
              true
            )
          end
        end
      },
      forward = {
        on_gui_click = function(e)
          local player_table = global.players[e.player_index]
          local session_history = player_table.history.session
          -- latency protection
          if session_history.position > 1 then
            session_history.position = session_history.position - 1
            local forward_object = session_history[session_history.position]
            main_gui.open_page(
              game.get_player(e.player_index),
              player_table,
              forward_object.class,
              forward_object.name,
              true
            )
          end
        end
      }
    },
    pin_button = {
      on_gui_click = function(e)
        local player = game.get_player(e.player_index)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.main.base
        if gui_data.window.pinned then
          gui_data.titlebar.pin_button.style = "frame_action_button"
          gui_data.window.pinned = false
          gui_data.window.frame.force_auto_center()
          player.opened = gui_data.window.frame
        else
          gui_data.titlebar.pin_button.style = "rb_selected_frame_action_button"
          gui_data.window.pinned = true
          gui_data.window.frame.auto_center = false
          player.opened = nil
        end
      end
    },
    quick_reference_button = {
      on_gui_click = function(e)
        local player = game.get_player(e.player_index)
        local player_table = global.players[e.player_index]
        local name = player_table.gui.main.state.name
        if player_table.gui.quick_ref[name] then
          quick_ref_gui.destroy(player, player_table, name)
          player_table.gui.main.base.info_bar.quick_ref_button.style = "tool_button"
        else
          quick_ref_gui.create(player, player_table, name)
          player_table.gui.main.base.info_bar.quick_ref_button.style = "rb_selected_tool_button"
        end
      end
    },
    settings_button = {
      on_gui_click = function(e)
        local player = game.get_player(e.player_index)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.main
        if gui_data.settings.open then
          gui_data.settings.open = false
          gui_data.settings.window.visible = false
          gui_data.base.titlebar.settings_button.style = "frame_action_button"
        else
          gui_data.settings.open = true
          gui_data.settings.window.visible = true
          gui_data.base.titlebar.settings_button.style = "rb_selected_frame_action_button"
        end
      end
    },
    window = {
      on_gui_closed = function(e)
        local player_table = global.players[e.player_index]
        if not player_table.gui.main.base.window.pinned and not player_table.flags.technology_gui_open then
          gui.handlers.base.close_button.on_gui_click(e)
        end
      end
    }
  },
  shared = {
    list_box_item = {
      on_gui_click = function(e)
        local _, _, class, name = string.find(e.element.caption, "^.-%[img=(.-)/(.-)%]  .*$")
        local player = game.get_player(e.player_index)
        local player_table = global.players[e.player_index]
        if class == "technology" then
          player_table.flags.technology_gui_open = true
          player.open_technology_gui(name)
        elseif class == "entity" then
          local recipe_name = player_table.gui.main.state.name
          local cursor_stack = player.cursor_stack
          player.clean_cursor()
          if cursor_stack and cursor_stack.valid then
            -- entities with an even number of tiles to a side need to be set at -0.5 instead of 0
            local width, height = area_dimensions(game.entity_prototypes[name].collision_box)
            cursor_stack.set_stack{name="rb-crafter-blueprint", count=1}
            cursor_stack.set_blueprint_entities{
              {
                entity_number = 1,
                name = name,
                position = {
                  math.ceil(width) % 2 == 0 and -0.5 or 0,
                  math.ceil(height) % 2 == 0 and -0.5 or 0
                },
                recipe = recipe_name
              }
            }
          end
        else
          main_gui.open_page(player, player_table, class, name)
        end
      end
    }
  }
}

function main_gui.create(player, player_table)
  local gui_data = gui.build(player.gui.screen, {
    {type="frame", style="outer_frame", elem_mods={visible=false}, handlers="base.window", save_as="base.window.frame", children={
      -- main window
      {type="frame", style="inner_frame_in_outer_frame", direction="vertical", children={
        {type="flow", save_as="base.titlebar.flow", children={
          {template="frame_action_button", sprite="rb_nav_backward_white", hovered_sprite="rb_nav_backward_black", clicked_sprite="rb_nav_backward_black",
            mouse_button_filter={"left", "right"}, elem_mods={enabled=false}, handlers="base.nav_button.backward", save_as="base.titlebar.nav_backward_button"},
          {template="frame_action_button", sprite="rb_nav_forward_white", hovered_sprite="rb_nav_forward_black", clicked_sprite="rb_nav_forward_black",
            elem_mods={enabled=false}, handlers="base.nav_button.forward", save_as="base.titlebar.nav_forward_button"},
          {type="empty-widget"}, -- spacer
          {type="label", style="frame_title", caption={"mod-name.RecipeBook"}, elem_mods={ignored_by_interaction=true}},
          {type="empty-widget", style="rb_titlebar_drag_handle", elem_mods={ignored_by_interaction=true}},
          {template="frame_action_button", tooltip={"rb-gui.keep-open"}, sprite="rb_pin_white", hovered_sprite="rb_pin_black", clicked_sprite="rb_pin_black",
            handlers="base.pin_button", save_as="base.titlebar.pin_button"},
          {template="frame_action_button", tooltip={"rb-gui.settings"}, sprite="rb_settings_white", hovered_sprite="rb_settings_black",
            clicked_sprite="rb_settings_black", handlers="base.settings_button", save_as="base.titlebar.settings_button"},
          {template="frame_action_button", sprite="utility/close_white", hovered_sprite="utility/close_black", clicked_sprite="utility/close_black",
            handlers="base.close_button"}
        }},
        {type="flow", style="rb_main_frame_flow", children={
          -- search page
          {type="frame", style="inside_shallow_frame", direction="vertical", children=pages.search.build()},
          -- info page
          {type="frame", style="rb_main_info_frame", direction="vertical", children={
            -- info bar
            {type="frame", style="subheader_frame", elem_mods={visible=false}, save_as="base.info_bar.frame", children={
              {type="label", style="rb_toolbar_label", save_as="base.info_bar.label"},
              {template="pushers.horizontal"},
              {template="tool_button", sprite="rb_clipboard_black", tooltip={"rb-gui.open-quick-reference"}, handlers="base.quick_reference_button",
                save_as="base.info_bar.quick_ref_button"},
              {template="tool_button", sprite="rb_favorite_black", tooltip={"rb-gui.add-to-favorites"}, handlers="base.favorite_button",
                save_as="base.info_bar.favorite_button"}
            }},
            -- content scroll pane
            {type="scroll-pane", style="rb_naked_scroll_pane", children={
              {type="flow", style="rb_main_info_pane_flow", direction="vertical", elem_mods={visible=false}, save_as="home.flow",
                children=pages.home.build()},
              {type="flow", style="rb_main_info_pane_flow", direction="vertical", elem_mods={visible=false}, save_as="material.flow",
                children=pages.material.build()},
              {type="flow", style="rb_main_info_pane_flow", direction="vertical", elem_mods={visible=false}, save_as="recipe.flow",
                children=pages.recipe.build()}
            }}
          }}
        }}
      }},
      -- settings window
      {type="frame", style="inner_frame_in_outer_frame", direction="vertical", elem_mods={visible=false}, save_as="settings.window", children={
        {type="flow", save_as="settings.titlebar_flow", children={
          {type="label", style="frame_title", caption={"gui-menu.settings"}, elem_mods={ignored_by_interaction=true}},
          {type="empty-widget", style="rb_dialog_titlebar_drag_handle", elem_mods={ignored_by_interaction=true}},
        }},
        {type="frame", style="inside_shallow_frame", children={
          {type="scroll-pane", style="rb_settings_content_scroll_pane", direction="vertical", children=pages.settings.build(player_table.settings)}
        }}
      }}
    }}
  })

  -- centering
  gui_data.base.window.frame.force_auto_center()
  gui_data.base.titlebar.flow.drag_target = gui_data.base.window.frame
  gui_data.settings.titlebar_flow.drag_target = gui_data.base.window.frame

  -- base setup
  gui_data.base.window.pinned = false
  gui.update_filters("shared.list_box_item", player.index, {"rb_list_box_item"}, "add")

  -- page setup
  gui_data = pages.search.setup(player, player_table, gui_data)
  pages.settings.setup(player)

  -- state setup
  gui_data.state = {
    int_class = "home"
  }

  -- save to global
  player_table.gui.main = gui_data

  -- open home page
  main_gui.open_page(player, player_table, "home")
end

function main_gui.destroy(player, player_table)
  for _, name in ipairs{"base", "shared", "search"} do
    gui.update_filters(name, player.index, nil, "remove")
  end
  local gui_data = player_table.gui.main
  if gui_data then
    local frame = gui_data.base.window.frame
    if frame and frame.valid then
      frame.destroy()
    end
  end
  player_table.gui.main = nil
end

function main_gui.open(player, player_table, skip_focus)
  local window = player_table.gui.main.base.window.frame
  if window and window.valid then
    window.visible = true
  end
  player_table.flags.gui_open = true
  if not player_table.gui.main.base.window.pinned then
    player.opened = window
  end
  player.set_shortcut_toggled("rb-toggle-gui", true)

  if not skip_focus then
    player_table.gui.main.search.textfield.focus()
    player_table.gui.main.search.textfield.select_all()
  end
end

function main_gui.close(player, player_table)
  local gui_data = player_table.gui.main
  if gui_data then
    local frame = player_table.gui.main.base.window.frame
    if frame and frame.valid then
      frame.visible = false
    end
  end
  player_table.flags.gui_open = false
  player.opened = nil
  player.set_shortcut_toggled("rb-toggle-gui", false)
end

function main_gui.toggle(player, player_table)
  if player_table.flags.gui_open then
    main_gui.close(player, player_table)
  else
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

function main_gui.open_page(player, player_table, obj_class, obj_name, skip_history)
  obj_name = obj_name or ""
  local gui_data = player_table.gui.main
  local translations = player_table.translations
  local int_class = (obj_class == "fluid" or obj_class == "item") and "material" or obj_class
  local int_name = (obj_class == "fluid" or obj_class == "item") and obj_class.."."..obj_name or obj_name

  -- assemble various player data to be passed later
  local player_data = {
    force_index = player.force.index,
    player_index = player.index,
    settings = player_table.settings,
    translations = player_table.translations
  }

  -- extra data for the home page
  -- this cannot be kept in player_data due to memoization. if it were,
  -- the cache would be invalidated whenever the player did anything
  local home_data = {
    favorites = player_table.favorites,
    history = player_table.history.global
  }

  -- update search history
  local history = player_table.history
  local session_history = history.session
  local global_history = history.global
  if not skip_history then
    -- global history
    local combined_name = obj_class.."."..obj_name
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
    table.insert(global_history, 1, {int_class=int_class, int_name=int_name, class=obj_class, name=obj_name})
    local last_entry = global_history[31]
    if last_entry then
      table.remove(global_history, 31)
      global_history[last_entry.class.."."..last_entry.name] = nil
    end

    -- session history
    if session_history.position > 1 then
      for _ = 1,session_history.position - 1 do
        table.remove(session_history, 1)
      end
      session_history.position = 1
    elseif session_history.position == 0 then
      session_history.position = 1
    end
    table.insert(session_history, 1, {int_class=int_class, int_name=int_name, class=obj_class, name=obj_name})
  end

  -- update nav buttons
  local back_button = gui_data.base.titlebar.nav_backward_button
  back_button.enabled = true
  local back_obj = session_history[session_history.position + 1]
  if back_obj then
    if back_obj.int_class == "home" then
      back_button.tooltip = {"rb-gui.back-to", {"rb-gui.home"}}
    else
      back_button.tooltip = {"rb-gui.back-to", string.lower(translations[back_obj.int_class][back_obj.int_name])}
    end
  else
    back_button.enabled = false
    back_button.tooltip = ""
  end
  local forward_button = gui_data.base.titlebar.nav_forward_button
  if session_history.position > 1 then
    forward_button.enabled = true
    local forward_obj = session_history[session_history.position-1]
    forward_button.tooltip = {"rb-gui.forward-to", string.lower(translations[forward_obj.int_class][forward_obj.int_name])}
  else
    forward_button.enabled = false
    forward_button.tooltip = ""
  end

  -- update / toggle info bar
  local info_bar = gui_data.base.info_bar
  if obj_class == "home" then
    info_bar.frame.visible = false
  else
    info_bar.frame.visible = true

    local _, _, caption, tooltip = formatter(global.recipe_book[int_class][int_name], player_data, nil, true)
    info_bar.label.caption = caption
    info_bar.label.tooltip = tooltip

    if obj_class == "recipe" then
      local quick_ref_button = info_bar.quick_ref_button
      quick_ref_button.visible = true
      if player_table.gui.quick_ref[obj_name] then
        quick_ref_button.style = "rb_selected_tool_button"
      else
        quick_ref_button.style = "tool_button"
      end
    else
      info_bar.quick_ref_button.visible = false
    end

    if player_table.favorites[obj_class.."."..obj_name] then
      info_bar.favorite_button.style = "rb_selected_tool_button"
      info_bar.favorite_button.tooltip = {"rb-gui.remove-from-favorites"}
    else
      info_bar.favorite_button.style = "tool_button"
      info_bar.favorite_button.tooltip = {"rb-gui.add-to-favorites"}
    end
  end

  -- update page information
  pages[int_class].update(int_name, gui_data, player_data, home_data)

  -- update visible page
  gui_data[gui_data.state.int_class].flow.visible = false
  gui_data[int_class].flow.visible = true

  -- update state
  gui_data.state = {
    int_class = int_class,
    int_name = int_name,
    class = obj_class,
    name = obj_name
  }
end

function main_gui.update_list_box_items(player, player_table)
  -- purge player's cache
  formatter.purge_cache(player.index)
  -- update all items
  gui.handlers.search.textfield.on_gui_text_changed{player_index=player.index}
  local state = player_table.gui.main.state
  main_gui.open_page(
    player,
    player_table,
    state.class,
    state.name,
    true
  )
end

function main_gui.update_quick_ref_button(player_table)
  local gui_data = player_table.gui.main
  local state = gui_data.state
  if state.class == "recipe" then
    local quick_ref_button = gui_data.base.info_bar.quick_ref_button
    -- check for the quick ref window
    if player_table.gui.quick_ref[state.name] then
      quick_ref_button.style = "rb_selected_tool_button"
    else
      quick_ref_button.style = "tool_button"
    end
  end
end

function main_gui.update_settings(player_table)
  pages.settings.update(player_table.settings, player_table.gui.main.settings)
end

return main_gui