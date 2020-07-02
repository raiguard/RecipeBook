local base_gui = {}

local gui = require("__flib__.gui")

local constants = require("constants")

gui.add_templates{
  frame_action_button = {type="sprite-button", style="frame_action_button", mouse_button_filter={"left"}},
  pushers = {
    horizontal = {type="empty-widget", style="flib_horizontal_pusher"},
    vertical = {type="empty-widget", style="flib_vertical_pusher"}
  },
  tool_button = {type="sprite-button", style="tool_button", mouse_button_filter={"left"}},
  --! DEBUGGING
  dummy_content_listbox = function(caption, rows)
    return {type="flow", direction="vertical", children={
      {type="label", style="bold_label", caption=caption},
      {type="frame", style="deep_frame_in_shallow_frame", children={
        {type="scroll-pane", style="list_box_scroll_pane", style_mods={width=400, height=(rows * 28)}}
      }}
    }}
  end
}

gui.add_handlers{
  base = {
    close_button = {
      on_gui_click = function(e)
        base_gui.close(game.get_player(e.player_index), global.players[e.player_index])
      end
    },
    pin_button = {
      on_gui_click = function(e)
        local player = game.get_player(e.player_index)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.base
        if gui_data.pinned then
          gui_data.pin_button.style = "frame_action_button"
          gui_data.pinned = false
          gui_data.window.force_auto_center()
          player.opened = gui_data.window
        else
          gui_data.pin_button.style = "rb_selected_frame_action_button"
          gui_data.pinned = true
          gui_data.window.auto_center = false
          player.opened = nil

        end
      end
    },
    window = {
      on_gui_closed = function(e)
        local player_table = global.players[e.player_index]
        if not player_table.gui.base.pinned then
          gui.handlers.base.close_button.on_gui_click(e)
        end
      end
    }
  }
}

function base_gui.create(player, player_table)
  local elems = gui.build(player.gui.screen, {
    {type="frame", direction="vertical", elem_mods={visible=false}, handlers="base.window", save_as="window", children={
      {type="flow", save_as="titlebar_flow", children={
        {template="frame_action_button", sprite="rb_nav_backward_white", hovered_sprite="rb_nav_backward_black", clicked_sprite="rb_nav_backward_black",
          elem_mods={enabled=false}},
        {template="frame_action_button", sprite="rb_nav_forward_white", hovered_sprite="rb_nav_forward_black", clicked_sprite="rb_nav_forward_black",
          elem_mods={enabled=false}},
        {type="empty-widget"},
        {type="label", style="frame_title", caption={"mod-name.RecipeBook"}, elem_mods={ignored_by_interaction=true}},
        {type="empty-widget", style="rb_drag_handle", elem_mods={ignored_by_interaction=true}},
        {template="frame_action_button", sprite="rb_pin_white", hovered_sprite="rb_pin_black", clicked_sprite="rb_pin_black", handlers="base.pin_button",
          save_as="pin_button"},
        {template="frame_action_button", sprite="utility/close_white", hovered_sprite="utility/close_black", clicked_sprite="utility/close_black",
          handlers="base.close_button"}
      }},
      {type="flow", style_mods={horizontal_spacing=12}, children={
        {type="frame", style="inside_shallow_frame", direction="vertical", children={
          {type="frame", style="subheader_frame", children={
            {type="label", style="subheader_caption_label", caption={"rb-gui.search-by"}},
            {template="pushers.horizontal"},
            {type="drop-down", items=constants.search_categories, selected_index=2}
          }},
          {type="flow", style_mods={padding=12, top_padding=8, right_padding=0, vertical_spacing=10}, direction="vertical", children={
            {type="textfield", style_mods={width=250, right_margin=12}},
            {type="frame", style="deep_frame_in_shallow_frame", style_mods={width=250, height=392}, direction="vertical", children={
              -- {type="frame", style="subheader_frame", style_mods={height=28, horizontally_stretchable=true}, children={
              --   {type="label", style="bold_label", style_mods={left_margin=4}, caption="<"},
              --   {template="pushers.horizontal"},
              --   {type="label", style="bold_label", style_mods={left_margin=4}, caption="1-50  /  263"},
              --   {template="pushers.horizontal"},
              --   {type="label", style="bold_label", style_mods={right_margin=4}, caption=">"},
              -- }},
              {type="scroll-pane", style="list_box_scroll_pane", style_mods={horizontally_stretchable=true, vertically_stretchable=true}}
            }}
          }}
        }},
        {type="frame", style="inside_shallow_frame", direction="vertical", children={
          {type="frame", style="subheader_frame", children={
            {type="label", style="subheader_caption_label", caption="[recipe=chemical-plant]  Chemical Plant"},
            {template="pushers.horizontal"},
            -- {template="tool_button"},
            {template="tool_button", sprite="rb_favorite_black"}
          }},
          {type="flow", style_mods={padding=12, vertical_spacing=6}, direction="vertical", children={
            gui.templates.dummy_content_listbox("Favorites", 6),
            {template="pushers.vertical"},
            gui.templates.dummy_content_listbox("History", 7)
          }}
        }}
      }}
    }}
  })

  elems.window.force_auto_center()
  elems.titlebar_flow.drag_target = elems.window

  elems.pinned = false

  player_table.gui.base = elems
end

function base_gui.destroy(player, player_table)

end

function base_gui.open(player, player_table)
  local window = player_table.gui.base.window
  if window and window.valid then
    window.visible = true
  end
  player_table.flags.gui_open = true
  if not player_table.gui.base.pinned then
    player.opened = window
  end
  player.set_shortcut_toggled("rb-toggle-gui", true)
end

function base_gui.close(player, player_table)
  local window = player_table.gui.base.window
  if window and window.valid then
    window.visible = false
  end
  player_table.flags.gui_open = false
  player.opened = nil
  player.set_shortcut_toggled("rb-toggle-gui", false)
end

function base_gui.toggle(player, player_table)
  if player_table.flags.gui_open then
    base_gui.close(player, player_table)
  else
    base_gui.open(player, player_table)
  end
end

return base_gui