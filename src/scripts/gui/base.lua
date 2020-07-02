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
  dummy_content_listbox = {type="flow", direction="vertical", children={
    {type="label", style="bold_label", caption="Title"},
    {type="frame", style="deep_frame_in_shallow_frame", children={
      {type="scroll-pane", style="list_box_scroll_pane", style_mods={width=400, height=168}}
    }}
  }}
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
              {type="frame", style="subheader_frame", style_mods={height=28, horizontally_stretchable=true}, children={
                {type="label", style="bold_label", style_mods={left_margin=4}, caption="<"},
                {template="pushers.horizontal"},
                {type="label", style="bold_label", style_mods={left_margin=4}, caption="1-50  /  263"},
                {template="pushers.horizontal"},
                {type="label", style="bold_label", style_mods={right_margin=4}, caption=">"},
              }},
              {type="scroll-pane", style="list_box_scroll_pane", style_mods={horizontally_stretchable=true, vertically_stretchable=true}}
            }}
          }}
        }},
        {type="frame", style="inside_shallow_frame", direction="vertical", children={
          {type="frame", style="subheader_frame", children={
            {type="label", style="subheader_caption_label", caption="[recipe=chemical-plant]  Chemical Plant"},
            {template="pushers.horizontal"},
            {template="tool_button"},
            {template="tool_button"}
          }},
          {type="flow", style_mods={padding=12, vertical_spacing=6}, direction="vertical", children={
            {template="dummy_content_listbox"},
            {template="dummy_content_listbox"}
          }},
          {template="pushers.vertical"}
        }}
      }}
    }}
  })

  elems.window.force_auto_center()
  elems.titlebar_flow.drag_target = elems.window
end

return base_gui