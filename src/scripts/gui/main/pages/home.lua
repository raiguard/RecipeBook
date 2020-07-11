local home_page = {}

local gui = require("__flib__.gui")

local constants = require("constants")
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
            player_info
          )
          -- TODO create a font with recipe and material icons
          caption = "[font=RecipeBook]("..constants.class_to_font_glyph[int_class].."[/font]  "..caption
          style = string.gsub(style, "rb_", "rb_adjusted_")
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

local test_objects = {
  {"machine", "crash-site-assembling-machine-1-repaired"},
  {"material", "fluid.ammonia"},
  {"material", "item.matter-cube"},
  {"recipe", "kr-burn-heavy-oil"},
  {"resource", "stone"},
  {"technology", "kr-air-purification"}
}

function home_page.update(_, gui_data, player_info)
  -- local update = gui.templates.home.list_box_updater
  -- update("favorites", gui_data, player_info)
  -- update("history", gui_data, player_info)
  local scroll = gui_data.home.favorites.scroll_pane
  scroll.clear()
  for _, data in ipairs(test_objects) do
    local item_data = global.recipe_book[data[1]][data[2]]
    local should_add, style, caption, tooltip, enabled = util.format_item(item_data, player_info)
    if should_add then
      scroll.add{type="button", style=style, caption=caption, tooltip=tooltip, enabled=enabled}
    end
  end
end

return home_page