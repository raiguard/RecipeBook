local settings_gui = {}

local gui = require("__flib__.gui")

function settings_gui.create(player, player_table)
  local gui_data = gui.build(player.gui.screen, {
    {type="frame", direction="vertical", save_as="window", children={
      {type="flow", save_as="titlebar_flow", children={
        {type="label", style="frame_title", caption={"rb-gui.mod-settings"}, elem_mods={ignored_by_interaction=true}},
        {type="empty-widget", style="rb_dialog_titlebar_drag_handle", elem_mods={ignored_by_interaction=true}}
      }},
      {type="frame", style="inside_deep_frame_for_tabs", children={
        {type="tabbed-pane", children={
          {type="tab-and-content", tab={type="tab", caption="General"}, content={type="empty-widget", style_mods={width=300, height=400}}},
          {type="tab-and-content", tab={type="tab", caption="Category"}, content={type="empty-widget", style_mods={width=300, height=400}}},
          {type="tab-and-content", tab={type="tab", caption="About"}, content={type="empty-widget", style_mods={width=300, height=400}}}
        }}
      }},
      {type="flow", style="dialog_buttons_horizontal_flow", children={
        {type="button", style="back_button", caption={"gui.cancel"}},
        {type="empty-widget", style="rb_dialog_footer_drag_handle", style_mods={height=32}, save_as="footer_drag_handle"},
        {type="button", style="confirm_button", caption={"gui.confirm"}}
      }}
    }}
  })

  gui_data.window.force_auto_center()
  gui_data.titlebar_flow.drag_target = gui_data.window
  gui_data.footer_drag_handle.drag_target = gui_data.window

  player_table.gui.settings = gui_data
end

function settings_gui.destroy(player, player_table)
  player_table.gui.settings.window.destroy()
  player_table.gui.settings = nil
end

return settings_gui