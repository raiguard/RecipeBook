local event = require("__flib__.control.event")
local gui = require("__flib__.control.gui")

local constants = require("scripts.constants")

local string_find = string.find
local string_sub = string.sub

gui.add_templates{
  close_button = {type="sprite-button", style="rb_frame_action_button", sprite="utility/close_white", hovered_sprite="utility/close_black",
    clicked_sprite="utility/close_black", mouse_button_filter={"left"}},
  pushers = {
    horizontal = {type="empty-widget", style_mods={horizontally_stretchable=true}},
    vertical = {type="empty-widget", style_mods={vertically_stretchable=true}}
  },
  listbox_with_label = function(name)
    return
    {type="flow", direction="vertical", children={
      {type="label", style="rb_listbox_label", save_as=name.."_label"},
      {type="frame", style="rb_listbox_frame", save_as=name.."_frame", children={
        {type="list-box", style="rb_listbox", save_as=name.."_listbox"}
      }}
    }}
  end,
  quick_reference_scrollpane = function(name)
    return
    {type="flow", direction="vertical", children={
      {type="label", style="rb_listbox_label", save_as=name.."_label"},
      {type="frame", style="rb_icon_slot_table_frame", style_mods={maximal_height=160}, children={
        {type="scroll-pane", style="rb_icon_slot_table_scrollpane", children={
          {type="table", style="rb_icon_slot_table", style_mods={width=200}, column_count=5, save_as=name.."_table"}
        }}
      }}
    }}
  end
}

gui.add_handlers{
  common={
    generic_open_from_listbox = function(e)
      local _,_,category,object_name = string_find(e.element.get_item(e.element.selected_index), "^%[img=(.-)/(.-)%].*$")
      event.raise(constants.open_gui_event, {player_index=e.player_index, gui_type=category, object=object_name})
    end,
    open_material_from_listbox = function(e)
      local selected_item = e.element.get_item(e.element.selected_index)
      if string_sub(selected_item, 1, 1) == " " then
        e.element.selected_index = 0
      else
        local _,_,object_class,object_name = string_find(selected_item, "^%[img=(.-)/(.-)%].*$")
        event.raise(constants.open_gui_event, {player_index=e.player_index, gui_type="material", object={object_class, object_name}})
      end
    end,
    open_crafter_from_listbox = function(e)
      local _,_,object_name = string_find(e.element.get_item(e.element.selected_index), "^%[img=.-/(.-)%].*$")
      if object_name == "character" then
        e.element.selected_index = 0
      else
        event.raise(constants.open_gui_event, {player_index=e.player_index, gui_type="crafter", object=object_name})
      end
    end,
    open_technology_from_listbox = function(e)
      local _,_,name = e.element.get_item(e.element.selected_index):find("^.*/(.*)%].*$")
      e.element.selected_index = 0
      game.get_player(e.player_index).open_technology_gui(name)
    end
  }
}