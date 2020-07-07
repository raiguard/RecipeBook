local home_pane = {}

local gui = require("__flib__.gui")

gui.add_templates{
  --! DEBUGGING
  dummy_content_listbox = function(caption, rows)
    return {type="flow", direction="vertical", children={
      {type="flow", children={
        {type="label", style="bold_label", style_mods={bottom_margin=2}, caption=caption},
        {template="pushers.horizontal"},
        {type="sprite-button", style="tool_button_red", style_mods={width=22, height=22, padding=0}, sprite="utility/trash"}
      }},
      {type="frame", style="deep_frame_in_shallow_frame", children={
        {type="scroll-pane", style="rb_list_box_scroll_pane", style_mods={horizontally_stretchable=true, height=(rows * 28)}}
      }}
    }}
  end
}

home_pane.base_template = {
  {type="frame", style="subheader_frame", children={
    {type="label", style="subheader_caption_label", caption="[recipe=chemical-plant]  Chemical Plant"},
    {template="pushers.horizontal"},
    -- {template="tool_button"},
    {template="tool_button", sprite="rb_clipboard_black"},
    {template="tool_button", sprite="rb_favorite_black"}
  }},
  {type="scroll-pane", style="rb_main_info_scroll_pane", vertical_scroll_policy="auto-and-reserve-space", children={
    gui.templates.dummy_content_listbox("Favorites", 7),
    {template="pushers.vertical"},
    gui.templates.dummy_content_listbox("History", 7)
  }}
}

return home_pane