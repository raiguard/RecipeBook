local quick_ref_gui = {}

local gui = require("__flib__.gui")

gui.add_handlers{
  quick_ref = {
    close_button = {
      on_gui_click = function(e)

      end
    },
    open_info_button = {
      on_gui_click = function(e)

      end
    },
    material_button = {
      on_gui_click = function(e)

      end
    }
  }
}

function quick_ref_gui.create(player, player_table, name)
  local gui_data, filters = gui.build(player.gui.screen, {
    {type="frame", direcion="vertical", save_as="window", children={
      {type="flow", save_as="titlebar.flow", children={
        {type="label", style="frame_title", caption={"rb-gui.recipe"}, elem_mods={ignored_by_interaction=true}},
        {type="empty-widget", style="rb_drag_handle", elem_mods={ignored_by_interaction=true}},
        {template="frame_action_button", tooltip={"rb-gui.view-details"}, sprite="rb_expand_white", hovered_sprite="rb_expand_black",
          clicked_sprite="rb_expand_black", handlers="quick_ref.expand_button", save_as="quick_ref.titlebar.expand_button"},
        {template="frame_action_button", sprite="utility/close_white", hovered_sprite="utility/close_black", clicked_sprite="utility/close_black",
          handlers="quick_ref.close_button"}
      }},
      {type="frame", style="inside_shallow_frame", direction="vertical", children={
        {type="frame", style="subheader_frame", children={
          {type="label", style="rb_toolbar_label", save_as="toolbar_label"}
        }}
      }},
      {type="flow", style_mods={padding=12, right_padding=0}, children={

      }}
    }}
  })
  gui_data.titlebar.flow.drag_target = gui_data.window


end

function quick_ref_gui.destroy(player, player_table, name)

end

return quick_ref_gui