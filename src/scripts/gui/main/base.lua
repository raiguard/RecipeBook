local main_gui = {}

local event = require("__flib__.event")
local gui = require("__flib__.gui")

local constants = require("constants")

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
    update = function(tbl, int_class, formatter, list_box, player_info, parent_data)
      local source_tbl = global.recipe_book[int_class]

      local scroll = list_box.scroll_pane
      local add = scroll.add
      local children = scroll.children
      local i = 0
      for j = 1, #tbl do
        local obj = tbl[j]
        local obj_data = source_tbl[type(obj) == "table" and obj.type.."."..obj.name or obj]
        -- TODO maybe handle this with a log?
        if obj_data then
          if
            (player_info.show_hidden or not obj_data.hidden)
            and (player_info.show_unavailable or obj_data.available_to_forces)
          then
            i = i + 1
            local style, caption, tooltip, enabled = formatter(obj, obj_data, int_class, player_info, parent_data)
            if enabled == nil then enabled = true end
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
      end
      for j = i + 1, #children do
        children[j].destroy()
      end

      if i == 0 then
        list_box.flow.visible = false
      else
        list_box.flow.visible = true
        scroll.style.height = math.min((28 * i), (28 * 6))
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
          elem_mods={enabled=false}},
        {template="frame_action_button", sprite="rb_nav_forward_white", hovered_sprite="rb_nav_forward_black", clicked_sprite="rb_nav_forward_black",
          elem_mods={enabled=false}},
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
            {template="tool_button", sprite="rb_clipboard_black", tooltip={"rb-gui.open-quick-reference"}, save_as="base.info_bar.quick_reference_button"},
            {template="tool_button", sprite="rb_favorite_black", tooltip={"rb-gui.add-to-favorites"}, save_as="base.info_bar.favorite_button"}
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
    page = "home"
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
  if player_table.flags.gui_open then
    main_gui.close(player, player_table)
  else
    main_gui.open(player, player_table)
  end
end

function main_gui.open_page(player, player_table, obj_class, obj_name)
  obj_name = obj_name or ""
  local gui_data = player_table.gui.main
  local translations = player_table.translations
  local int_class = (obj_class == "fluid" or obj_class == "item") and "material" or obj_class
  local int_name = (obj_class == "fluid" or obj_class == "item") and obj_class.."."..obj_name or obj_name

  -- TODO add to history

  -- update / toggle info bar
  local info_bar = gui_data.base.info_bar
  if obj_class == "home" then
    info_bar.frame.visible = false
  else
    info_bar.frame.visible = true
    info_bar.label.caption = "[img="..obj_class.."/"..obj_name.."]  "..translations.gui[int_class].." - "..translations[int_class][int_name]

    if obj_class == "recipe" then
      info_bar.quick_reference_button.visible = true
    else
      info_bar.quick_reference_button.visible = false
    end

    -- TODO set button states
  end

  -- update page information
  pages[int_class].update(int_name, gui_data, {
    show_hidden = player_table.settings.show_hidden,
    show_unavailable = player_table.settings.show_unavailable,
    translations = player_table.translations,
    force_index = player.force.index
  })

  -- update visible page
  gui_data[gui_data.state.page].flow.visible = false
  gui_data[int_class].flow.visible = true

  -- update state
  gui_data.state = {
    page = int_class,
    obj_class = obj_class,
    obj_name = obj_name
  }
end

function main_gui.update_page(player, player_table)

end

return main_gui