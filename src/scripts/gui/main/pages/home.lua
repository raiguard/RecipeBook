local home_page = {}

local gui = require("__flib__.gui")

local util = require("scripts.util")

gui.add_templates{
  home = {
    list_box_updater = function(tbl_name, gui_data, player_info)
      local recipe_book = global.recipe_book
      local tbl = player_info[tbl_name]
      local list_box = gui_data.home[tbl_name]
      local scroll = list_box.scroll_pane
      local add = scroll.add
      local children = scroll.children
      local i = 0
      for _ = 1, #tbl do
        i = i + 1
        local data = tbl[i]
        local int_class = data.int_class
        local int_name = data.int_name
        local name = data.name
        if data.int_class ~= "home" then
          local style, caption, tooltip = util["format_"..data.int_class.."_item"](
            int_class == "material" and data or name,
            recipe_book[int_class][int_name],
            int_class,
            player_info
          )
          -- TODO create a font with recipe and material icons
          caption = "[font=default-semibold]("..string.sub(int_class, 1, 1)..")[/font]  "..caption
          local item = children[i]
          if item then
            item.style = style
            item.caption = caption
            item.tooltip = tooltip
          else
            add{type="button", name="rb_"..int_class.."_item__"..i, style=style, caption=caption, tooltip=tooltip}
          end
        end
      end
    end
  }
}

function home_page.build()
  return {
    gui.templates.info_list_box.build({"rb-gui.favorites"}, 7, "home.favorites"),
    {template="pushers.vertical"},
    gui.templates.info_list_box.build({"rb-gui.history"}, 8, "home.history")
  }
end

function home_page.update(_, gui_data, player_info)
  local update = gui.templates.home.list_box_updater
  update("favorites", gui_data, player_info)
  update("history", gui_data, player_info)
end

return home_page