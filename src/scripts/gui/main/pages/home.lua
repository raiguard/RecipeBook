local home_page = {}

local gui = require("__flib__.gui")

local formatter = require("scripts.formatter")

gui.add_templates{
  home = {
    -- this is separate from the generic list box updater because the input format is different
    list_box_updater = function(tbl_name, gui_data, player_data, home_data)
      local recipe_book = global.recipe_book
      local tbl = home_data[tbl_name]

      -- list box
      local list_box = gui_data.home[tbl_name]
      local scroll = list_box.scroll_pane
      local add = scroll.add
      local children = scroll.children

      -- loop through input table
      local i = 0
      for j = 1, #tbl do
        -- get object information
        local entry = tbl[j]
        if entry.int_class ~= "home" then
          local obj_data = recipe_book[entry.int_class][entry.int_name]
          local should_add, style, caption, tooltip = formatter(obj_data, player_data)

          if should_add then
            i = i + 1
            -- add or update item
            local item = children[i]
            if item then
              item.style = style
              item.caption = caption
              item.tooltip = tooltip
            else
              add{type="button", name="rb_list_box_item__"..i, style=style, caption=caption, tooltip=tooltip}
            end
          end
        end
      end

      -- destroy extraneous items
      for j = i + 1, #children do
        children[j].destroy()
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

function home_page.update(_, gui_data, player_data, home_data)
  local update = gui.templates.home.list_box_updater
  update("favorites", gui_data, player_data, home_data)
  update("history", gui_data, player_data, home_data)
end

return home_page