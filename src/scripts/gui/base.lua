local base_gui = {}

local gui = require("__flib__.gui")

gui.add_templates{
  frame_action_button = {type="sprite-button", style="frame_action_button", mouse_button_filter={"left"}}
}

function base_gui.create(player, player_table)
  local elems = gui.build(player.gui.screen, {
    {type="frame", direction="vertical", save_as="window", children={
      {type="flow", save_as="titlebar_flow", children={
        {template="frame_action_button"},
        {template="frame_action_button"},
        {type="empty-widget"},
        {type="label", style="frame_title", caption={"mod-name.RecipeBook"}, elem_mods={ignored_by_interaction=true}},
        {type="empty-widget", style="rb_drag_handle", elem_mods={ignored_by_interaction=true}},
        {template="frame_action_button", sprite="utility/close_white", hovered_sprite="utility/close_black", clicked_sprite="utility/close_black"}
      }},
      {type="frame", style="inside_shallow_frame_with_padding", style_mods={width=500, height=300}}
    }}
  })

  elems.window.force_auto_center()
  elems.titlebar_flow.drag_target = elems.window
end

return base_gui