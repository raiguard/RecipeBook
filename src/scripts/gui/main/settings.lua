local gui = require("__flib__.gui-beta")

local constants = require("constants")
local shared = require("scripts.shared")

local settings_page = {}

function settings_page.build(settings)
  local output = {}

  -- generic - auto-generated from constants
  for category_name, elements in pairs(constants.settings) do
    local category_output = (
      {type = "frame", style = "rb_settings_category_frame", direction = "vertical", children = {
        {type = "label", style = "caption_label", caption = {"rb-gui."..category_name}}
      }}
    )
    for name, data in pairs(elements) do
      category_output.children[#category_output.children+1] = {
        type = "checkbox",
        caption = {"rb-gui.setting-"..name},
        tooltip = data.has_tooltip and {"rb-gui.setting-"..name.."-tooltip"} or nil,
        state = settings[name],
        ref = {"settings", name},
        tags = {setting_name = name},
        actions = {
          on_click = {gui = "main", page = "settings", action = "update_setting"}
        }
      }
    end
    output[#output+1] = category_output
  end

  -- categories - auto-generated from recipe_category_prototypes
  local recipe_categories_output = {
    type = "frame",
    style = "rb_settings_category_frame",
    direction = "vertical",
    children = {
      {
        type = "label",
        style = "caption_label",
        caption = {"rb-gui.recipe-categories"},
        tooltip = {"rb-gui.recipe-categories-tooltip"}
      }
    }
  }
  for name in pairs(game.recipe_category_prototypes) do
    recipe_categories_output.children[#recipe_categories_output.children + 1] = {
      type = "checkbox",
      caption = name,
      state = settings.recipe_categories[name],
      ref = {"settings", "recipe_category", name},
      tags = {category_name = name},
      actions = {
        on_click = {gui = "main", page = "settings", action = "update_setting"}
      }
    }
  end
  output[#output + 1] = recipe_categories_output

  return {
    type = "frame",
    style = "inner_frame_in_outer_frame",
    direction = "vertical",
    visible = false,
    ref = {"settings", "window"},
    children = {
      {type = "flow", style = "flib_titlebar_flow", ref = {"settings", "titlebar_flow"}, children = {
        {type = "label", style = "frame_title", caption = {"gui-menu.settings"}, ignored_by_interaction = true},
        {type = "empty-widget", style = "flib_dialog_titlebar_drag_handle", ignored_by_interaction = true},
      }},
      {type = "frame", style = "inside_shallow_frame", children = {
        {
          type = "scroll-pane",
          style = "rb_settings_content_scroll_pane",
          direction = "vertical",
          children = output
        }
      }}
    }
  }
end

function settings_page.init()
  return {
    open = false
  }
end

function settings_page.update(player_settings, gui_data)
  local refs = gui_data.refs.settings
  for _, names in pairs(constants.settings) do
    for name in pairs(names) do
      refs[name].state = player_settings[name]
    end
  end

  for name in pairs(game.recipe_category_prototypes) do
    refs.recipe_category[name] = player_settings.recipe_categories[name]
  end
end

function settings_page.handle_action(msg, e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]

  if msg.action == "update_setting" then
    local tags = gui.get_tags(e.element)
    local checked_state = e.element.state
    if tags.category_name then
      player_table.settings.recipe_categories[tags.category_name] = checked_state
    else
      -- set a flag to avoid iterating over all settings
      player_table.flags.updating_setting = true
      player_table.settings[tags.setting_name] = checked_state
      player_table.flags.updating_setting = false
    end
    shared.refresh_contents(player, player_table)
  end
end

return settings_page
