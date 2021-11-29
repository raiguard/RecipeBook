local dictionary = require("__flib__.dictionary")
local table = require("__flib__.table")

local constants = require("constants")
local formatter = require("scripts.formatter")
local recipe_book = require("scripts.recipe-book")

local info_gui = require("scripts.gui.info.index")
local quick_ref_gui = require("scripts.gui.quick-ref.index")
local search_gui = require("scripts.gui.search.index")
local settings_gui = require("scripts.gui.settings.index")

local player_data = {}

function player_data.init(player_index)
  --- @class PlayerTable
  local data = {
    favorites = {},
    flags = {
      can_open_gui = false,
      show_message_after_translation = false,
      technology_gui_open = false,
    },
    language = nil, --- @type string|nil
    global_history = {},
    guis = {
      --- @type table<number|string, QuickRefGui|number>
      info = { _next_id = 1 },
      --- @type table<string, QuickRefGui>
      quick_ref = {},
    },
    settings = {
      general = {},
      categories = {},
    },
    translations = nil, --- @type table|nil
  }
  global.players[player_index] = data
end

function player_data.update_settings(player, player_table)
  local former_settings = player_table.settings
  local settings = {
    general = {},
    categories = {},
    pages = {},
  }

  -- General settings
  for category_name, settings_data in pairs(constants.general_settings) do
    local former_category_settings = former_settings.general[category_name] or {}
    local category_settings = {}
    settings.general[category_name] = category_settings
    for setting_name, setting_ident in pairs(settings_data) do
      if setting_ident.type == "bool" then
        local former_setting = former_category_settings[setting_name]
        if former_setting ~= nil then
          category_settings[setting_name] = former_setting
        else
          category_settings[setting_name] = setting_ident.default_value
        end
      elseif setting_ident.type == "enum" then
        local former_setting = former_category_settings[setting_name]
        if former_setting ~= nil and table.find(setting_ident.options, former_setting) then
          category_settings[setting_name] = former_setting
        else
          category_settings[setting_name] = setting_ident.default_value
        end
      end
    end
  end

  -- Categories
  for _, category_class_name in pairs(constants.category_classes) do
    local former_category_settings = former_settings.categories[category_class_name] or {}
    local category_settings = {}
    settings.categories[category_class_name] = category_settings
    for category_name in pairs(recipe_book[category_class_name]) do
      local disabled_by_default = constants.disabled_categories[category_class_name][category_name]
      local former_setting = former_category_settings[category_name]
      if former_setting ~= nil then
        category_settings[category_name] = former_setting
      else
        category_settings[category_name] = not disabled_by_default
      end
    end
  end

  -- Pages
  -- Default state (normal / collapsed / hidden)
  -- Max rows
  for class, page_ident in pairs(constants.pages) do
    local former_page_settings = (former_settings.pages or {})[class] or {}
    local page_settings = {}
    settings.pages[class] = page_settings
    for i, component_ident in pairs(page_ident) do
      local component_name = component_ident.label or component_ident.source or i
      local former_component_settings = former_page_settings[component_name] or {}
      local component_settings = {
        default_state = former_component_settings.default_state or component_ident.default_state or "normal",
      }
      page_settings[component_name] = component_settings
      if component_ident.type == "list_box" then
        component_settings.max_rows = former_component_settings.max_rows
          or component_ident.max_rows
          or constants.default_max_rows
      end
      -- Default state
      -- Row settings for fixed tables
      if component_ident.rows then
        local former_row_settings = component_settings.rows or {}
        local row_settings = {}
        component_settings.rows = row_settings

        for _, row_ident in pairs(component_ident.rows) do
          local row_name = row_ident.label or row_ident.source
          row_settings[row_name] = former_row_settings[row_name] or row_ident.default_state or true
        end
      end
    end
  end

  -- Save to `global`
  player_table.settings = settings

  -- Create or purge memoizer cache
  formatter.create_cache(player.index)
end

function player_data.validate_favorites(favorites)
  while true do
    local i = 1
    local obj = favorites[i]
    if obj then
      if recipe_book[obj.class] and recipe_book[obj.class][obj.name] then
        i = i + 1
      else
        table.remove(favorites, i)
        favorites[obj.class .. "." .. obj.name] = nil
      end
    else
      break
    end
  end
end

function player_data.validate_global_history(global_history)
  for i = #global_history, 1, -1 do
    local entry = global_history[i]
    if not (recipe_book[entry.class] and recipe_book[entry.class][entry.name]) then
      table.remove(global_history, i)
      global_history[entry.class .. "." .. entry.name] = nil
    end
  end
end

function player_data.refresh(player, player_table)
  -- Destroy GUIs
  info_gui.root.destroy_all(player_table)
  quick_ref_gui.destroy_all(player, player_table)
  if player_table.guis.search then
    search_gui.root.destroy(player, player_table)
  end
  if player_table.guis.settings then
    settings_gui.root.destroy(player_table)
  end

  -- Set flag
  player_table.flags.can_open_gui = false

  -- Set shortcut state
  player.set_shortcut_toggled("rb-search", false)
  player.set_shortcut_available("rb-search", false)

  -- Validate favorites
  player_data.validate_favorites(player_table.favorites)

  -- Validate global history
  player_data.validate_global_history(player_table.global_history)

  -- Update settings
  player_data.update_settings(player, player_table)

  -- Run translations
  player_table.language = nil
  player_table.translations = nil
  if player.connected then
    dictionary.translate(player)
  end
end

function player_data.remove(player_index)
  global.players[player_index] = nil
end

function player_data.check_cursor_stack(player)
  local cursor_stack = player.cursor_stack
  if cursor_stack and cursor_stack.valid and cursor_stack.valid_for_read and recipe_book.item[cursor_stack.name] then
    return cursor_stack.name
  end
  return false
end

function player_data.update_global_history(global_history, new_context)
  new_context = table.shallow_copy(new_context)
  local ident = new_context.class .. "." .. new_context.name
  if global_history[ident] then
    for i, context in ipairs(global_history) do
      if context.class == new_context.class and context.name == new_context.name then
        -- Custom implementation of table.insert and table.remove that does the minimal amount of work needed
        global_history[i] = nil
        local prev = new_context
        local current
        for j = 1, i do
          current = global_history[j]
          global_history[j] = prev
          prev = current
        end
        break
      end
    end
  else
    table.insert(global_history, 1, new_context)
    global_history[ident] = true
  end

  for i = constants.global_history_size + 1, #global_history do
    local context = global_history[i]
    local ident = context.class .. "." .. context.name
    global_history[ident] = nil
    global_history[i] = nil
  end
end

return player_data
