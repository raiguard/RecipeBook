local settings_page = {}

local event = require("__flib__.event")
local gui = require("__flib__.gui")

local constants = require("constants")

gui.add_handlers{
  settings = {
    checkbox = {
      on_gui_checked_state_changed = function(e)
        local player = game.get_player(e.player_index)
        local player_table = global.players[e.player_index]
        local checked_state = e.element.state
        local _, _, setting_name = string.find(e.element.name, "^rb_setting__(.*)$")
        if string.find(setting_name, "recipe_category") then
          local _, _, category_name = string.find(setting_name, "^recipe_category_(.*)$")
          player_table.settings.recipe_categories[category_name] = checked_state
        else
          -- set a flag to avoid iterating over all settings
          player_table.flags.updating_setting = true
          player.mod_settings[constants.setting_prototype_names[setting_name]] = {value=checked_state}
          player_table.settings[setting_name] = checked_state
          player_table.flags.updating_setting = false
        end
        event.raise(constants.events.update_list_box_items, {player_index=e.player_index})
      end
    }
  }
}

function settings_page.build(settings)
  local output = {}

  -- generic - auto-generated from constants
  for category_name, elements in pairs(constants.settings) do
    local category_output = {type="frame", style="rb_settings_category_frame", direction="vertical", children={
      {type="label", style="caption_label", caption={"rb-gui."..category_name}}
    }}
    for name, data in pairs(elements) do
      category_output.children[#category_output.children+1] = {type="checkbox", name="rb_setting__"..name, caption={"mod-setting-name."..data.prototype_name},
        tooltip=data.has_tooltip and {"mod-setting-description."..data.prototype_name} or nil, state=settings[name], save_as="settings."..name}
    end
    output[#output+1] = category_output
  end

  -- categories - auto-generated from recipe_category_prototypes
  local recipe_categories_output = {type="frame", style="rb_settings_category_frame", direction="vertical", children={
    {type="label", style="caption_label", caption={"rb-gui.recipe-categories"}, tooltip={"rb-gui.recipe-categories-tooltip"}}
  }}
  for name in pairs(game.recipe_category_prototypes) do
    recipe_categories_output.children[#recipe_categories_output.children+1] = {type="checkbox", name="rb_setting__recipe_category_"..name, caption=name,
      state=settings.recipe_categories[name], save_as="settings.recipe_category."..name}
  end
  output[#output+1] = recipe_categories_output
  return output
end

function settings_page.setup(player)
  gui.update_filters("settings.checkbox", player.index, {"rb_setting"}, "add")
end

function settings_page.update(player_settings, gui_data)
  for _, names in pairs(constants.settings) do
    for name in pairs(names) do
      gui_data[name].state = player_settings[name]
    end
  end

  for name in pairs(game.recipe_category_prototypes) do
    gui_data.recipe_category[name] = player_settings.recipe_categories[name]
  end
end

return settings_page