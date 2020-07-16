local settings_page = {}

local constants = require("constants")

function settings_page.build()
  local output = {
    {type="label", style="bold_label", caption={"rb-gui.general"}},
    {type="checkbox", caption={"mod-setting-name.rb-open-item-hotkey"}, state=false},
    {type="checkbox", caption={"mod-setting-name.rb-open-fluid-hotkey"}, state=false},
    {type="checkbox", caption={"mod-setting-name.rb-show-hidden-objects"}, state=false},
    {type="checkbox", caption={"mod-setting-name.rb-show-unavailable-objects"}, state=false},
    {type="checkbox", caption={"mod-setting-name.rb-use-fuzzy-search"}, state=false},
    {type="checkbox", caption={"mod-setting-name.rb-show-internal-names"}, state=false},
    {type="checkbox", caption={"mod-setting-name.rb-show-glyphs"}, state=false},
    {type="label", style="bold_label", caption={"rb-gui.categories"}, tooltip={"rb-gui.categories-tooltip"}}
  }
  for name in pairs(game.recipe_category_prototypes) do
    output[#output+1] = {type="checkbox", caption=name, state=true}
  end
  return output
end

function settings_page.setup(player, player_table, gui_data)
  gui_data.search.category = "recipe"
  return gui_data
end

return settings_page