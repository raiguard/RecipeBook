local main_gui = {}

local gui = require("__flib__.gui")

local constants = require("constants")

local panes = {}
for _, name in ipairs(constants.main_panes) do
  panes[name] = require("scripts.gui.main.panes."..name)
end

gui.add_templates{
  frame_action_button = {type="sprite-button", style="frame_action_button", mouse_button_filter={"left"}},
  info_list_box = function(caption, rows, save_location)
    return {type="flow", direction="vertical", children={
      {type="label", style="bold_label", style_mods={bottom_margin=2}, caption=caption, save_as=save_location..".label"},
      {type="frame", style="deep_frame_in_shallow_frame", save_as=save_location..".frame",  children={
        {type="scroll-pane", style="rb_list_box_scroll_pane", style_mods={height=(rows * 28)}, save_as=save_location..".scroll_pane"}
      }}
    }}
  end,
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
  }
}

function main_gui.create(player, player_table)
  local data = gui.build(player.gui.screen, {
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
        -- search pane
        panes.search.base_template,
        -- info pane
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
              children=panes.home.build()},
            {type="flow", style="rb_main_info_pane_flow", direction="vertical", elem_mods={visible=false}, save_as="material.flow",
              children=panes.material.build()},
            {type="flow", style="rb_main_info_pane_flow", direction="vertical", elem_mods={visible=false}, save_as="recipe.flow",
              children=panes.recipe.build()}
          }}
        }}
      }}
    }}
  })

  data.base.window.frame.force_auto_center()
  data.base.titlebar.flow.drag_target = data.base.window.frame

  data.base.window.pinned = false

  data = panes.search.setup(player, player_table, data)

  data.state = {
    pane = "home"
  }

  player_table.gui.main = data

  main_gui.open_page(player, player_table, "home")
end

function main_gui.destroy(player, player_table)

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
  local window = player_table.gui.main.base.window.frame
  if window and window.valid then
    window.visible = false
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

function main_gui.update_state(player, player_table, state_changes)

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
    info_bar.label.caption = "["..obj_class.."="..obj_name.."]  "..translations[int_class][int_name]

    if obj_class == "recipe" then
      info_bar.quick_reference_button.visible = true
    else
      info_bar.quick_reference_button.visible = false
    end

    -- TODO set button states
  end

  -- update pane information
  panes[int_class].update(gui_data[int_class].flow, gui_data, translations)

  -- update visible pane
  gui_data[gui_data.state.pane].flow.visible = false
  gui_data[int_class].flow.visible = true

  gui_data.state.pane = int_class
end

return main_gui