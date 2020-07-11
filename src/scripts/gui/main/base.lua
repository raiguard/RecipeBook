local main_gui = {}

local event = require("__flib__.event")
local gui = require("__flib__.gui")

local constants = require("constants")
local formatter = require("lib.formatter")

local pages = {}
for _, name in ipairs(constants.main_pages) do
  pages[name] = require("scripts.gui.main.pages."..name)
end

gui.add_templates{
  frame_action_button = {type="sprite-button", style="frame_action_button", mouse_button_filter={"left"}},
  info_list_box = {
    build = function(caption, rows, save_location)
      return {type="flow", direction="vertical", save_as=save_location..".flow", children={
        {type="label", style="bold_label", style_mods={bottom_margin=2}, caption=caption, save_as=save_location..".label"},
        {type="frame", style="deep_frame_in_shallow_frame", save_as=save_location..".frame",  children={
          {type="scroll-pane", style="rb_list_box_scroll_pane", style_mods={height=(rows * 28)}, save_as=save_location..".scroll_pane"}
        }}
      }}
    end,
    update = function(tbl, int_class, list_box, player_data)
      local recipe_book = global.recipe_book[int_class]

      -- scroll pane
      local scroll = list_box.scroll_pane
      local add = scroll.add
      local children = scroll.children

      -- loop through input table
      local i = 0
      for j = 1, #tbl do
        -- get object information
        local obj = tbl[j]
        local obj_data
        if int_class == "material" then
          obj_data = recipe_book[int_class == "material" and obj.type.."."..obj.name or obj]
          obj_data.amount_string = obj.amount_string
        else
          obj_data = recipe_book[obj]
        end
        local should_add, style, caption, tooltip, enabled = formatter.format_item(obj_data, player_data)

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
            add{type="button", name="rb_"..int_class.."_item__"..i, style=style, caption=caption, tooltip=tooltip, enabled=enabled}
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
        caption[2] = i
        list_box.label.caption = caption
      end
    end
  },
  pushers = {
    horizontal = {type="empty-widget", style="flib_horizontal_pusher"},
    vertical = {type="empty-widget", style="flib_vertical_pusher"}
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
        else
          favorites[index_name] = true
          table.insert(favorites, 1, state)
        end
        main_gui.open_page(
          game.get_player(e.player_index),
          player_table,
          state.class,
          state.name,
          true
        )
      end
    },
    nav_button = {
      backward = {
        on_gui_click = function(e)
          local player_table = global.players[e.player_index]
          local session_history = player_table.history.session
          -- latency protection
          if session_history.position < #session_history then
            session_history.position = session_history.position + 1
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

      end
    },
    settings_button = {
      on_gui_click = function(e)

      end
    },
    window = {
      on_gui_closed = function(e)
        local player_table = global.players[e.player_index]
        if not player_table.gui.main.base.window.pinned then
          gui.handlers.base.close_button.on_gui_click(e)
        end
      end
    }
  },
  shared = {
    list_box_item = {
      on_gui_click = function(e)
        local _, _, class, name = string.find(e.element.caption, "^.-%[img=(.-)/(.-)%].*$")
        event.raise(constants.events.open_page, {player_index=e.player_index, obj_class=class, obj_name=name})
      end
    }
  }
}

function main_gui.create(player, player_table)
  local gui_data = gui.build(player.gui.screen, {
    {type="frame", direction="vertical", elem_mods={visible=false}, handlers="base.window", save_as="base.window.frame", children={
      {type="flow", save_as="base.titlebar.flow", children={
        {template="frame_action_button", sprite="rb_nav_backward_white", hovered_sprite="rb_nav_backward_black", clicked_sprite="rb_nav_backward_black",
          elem_mods={enabled=false}, handlers="base.nav_button.backward", save_as="base.titlebar.nav_backward_button"},
        {template="frame_action_button", sprite="rb_nav_forward_white", hovered_sprite="rb_nav_forward_black", clicked_sprite="rb_nav_forward_black",
          elem_mods={enabled=false}, handlers="base.nav_button.forward", save_as="base.titlebar.nav_forward_button"},
        {type="empty-widget"},
        {type="label", style="frame_title", caption={"mod-name.RecipeBook"}, elem_mods={ignored_by_interaction=true}},
        {type="empty-widget", style="rb_drag_handle", elem_mods={ignored_by_interaction=true}},
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
            {type="label", style="rb_info_bar_label", save_as="base.info_bar.label"},
            {template="pushers.horizontal"},
            {template="tool_button", sprite="rb_clipboard_black", tooltip={"rb-gui.open-quick-reference"}, handlers="base.quick_reference_button",
              save_as="base.info_bar.quick_reference_button"},
            {template="tool_button", sprite="rb_favorite_black", tooltip={"rb-gui.add-to-favorites"}, handlers="base.favorite_button",
              save_as="base.info_bar.favorite_button"}
          }},
          -- content scroll pane
          {type="scroll-pane", style="rb_main_info_scroll_pane", children={
            {type="flow", style="rb_main_info_pane_flow", direction="vertical", elem_mods={visible=false}, save_as="home.flow",
              children=pages.home.build()},
            {type="flow", style="rb_main_info_pane_flow", direction="vertical", elem_mods={visible=false}, save_as="material.flow",
              children=pages.material.build()},
            {type="flow", style="rb_main_info_pane_flow", direction="vertical", elem_mods={visible=false}, save_as="recipe.flow",
              children=pages.recipe.build()}
          }}
        }}
      }}
    }}
  })

  -- centering
  gui_data.base.window.frame.force_auto_center()
  gui_data.base.titlebar.flow.drag_target = gui_data.base.window.frame

  -- base setup
  gui_data.base.window.pinned = false
  gui.update_filters("shared.list_box_item", player.index, {"rb_list_box_item", "rb_material_item", "rb_recipe_item"}, "add")

  -- page setup
  gui_data = pages.search.setup(player, player_table, gui_data)

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
  if not player_table.gui.main.base.pinned then
    player.opened = window
  end
  player.set_shortcut_toggled("rb-toggle-gui", true)

  if not skip_focus then
    player_table.gui.main.search.textfield.focus()
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
  if player_table.flags.can_open_gui then
    if player_table.flags.gui_open then
      main_gui.close(player, player_table)
    else
      main_gui.open(player, player_table)
    end
  else
    player.print{"rb-message.cannot-open-gui"}
    player_table.flags.show_message_after_translation = true
  end
end

function main_gui.open_page(player, player_table, obj_class, obj_name, nav_button)
  obj_name = obj_name or ""
  local gui_data = player_table.gui.main
  local translations = player_table.translations
  local int_class = (obj_class == "fluid" or obj_class == "item") and "material" or obj_class
  local int_name = (obj_class == "fluid" or obj_class == "item") and obj_class.."."..obj_name or obj_name

  -- assemble various player data to be passed later
  local player_data = {
    favorites = player_table.favorites,
    force_index = player.force.index,
    history = player_table.history.global,
    show_glyphs = player_table.settings.show_glyphs,
    show_hidden = player_table.settings.show_hidden,
    show_internal_names = player_table.settings.show_internal_names,
    show_unavailable = player_table.settings.show_unavailable,
    translations = player_table.translations
  }

  -- update search history
  local history = player_table.history
  local session_history = history.session
  local global_history = history.global
  if not nav_button then
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
    info_bar.label.caption = "[img="..obj_class.."/"..obj_name.."]  "..translations[int_class][int_name]

    if obj_class == "recipe" then
      info_bar.quick_reference_button.visible = true
    else
      info_bar.quick_reference_button.visible = false
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
  pages[int_class].update(int_name, gui_data, player_data)

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

return main_gui