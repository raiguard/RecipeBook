local formatter = {}

local constants = require("constants")

local caches = {}

local function get_properties(obj_data, force_index)
  local researched
  if obj_data.researched_forces then
    researched = obj_data.researched_forces[force_index] or false
  else
    researched = obj_data.available_to_all_forces or obj_data.available_to_forces[force_index] or false
  end
  return obj_data.hidden, researched
end

local function get_should_show(obj_data, player_data)
  -- player data
  local force_index = player_data.force_index
  local player_settings = player_data.settings
  local show_hidden = player_settings.show_hidden
  local show_unresearched = player_settings.show_unresearched

  -- check hidden and researched status
  local is_hidden, is_researched = get_properties(obj_data, force_index)
  if (show_hidden or not is_hidden) and (show_unresearched or is_researched) then
    -- for recipes - check category to see if it should be shown
    local category = obj_data.category
    local categories = obj_data.recipe_categories
    if category then
      if player_settings.recipe_categories[category] then
        return true, is_hidden, is_researched
      end
    elseif categories then
      local category_settings = player_settings.recipe_categories
      for category_name in pairs(categories) do
        if category_settings[category_name] then
          return true, is_hidden, is_researched
        end
      end
    else
      return true, is_hidden, is_researched
    end
  end
  return false, is_hidden, is_researched
end

local function caption_formatter(obj_data, player_data, is_hidden, amount, is_info_label)
  local player_settings = player_data.settings
  local translations = player_data.translations
  local translation_key = obj_data.internal_class == "material" and obj_data.sprite_class.."."..obj_data.prototype_name or obj_data.prototype_name
  local translation = translations[obj_data.internal_class][translation_key]
  local font_prefix = is_info_label and "" or "[font=default-semibold]"
  local font_suffix = is_info_label and "" or "[/font]"
  local glyph = ""
  if player_settings.show_glyphs then
    local glyph_char = constants.class_to_font_glyph[obj_data.internal_class] or constants.class_to_font_glyph[obj_data.sprite_class]
    glyph = "[font=RecipeBook]"..glyph_char.."[/font]  "
  end
  local hidden_string = is_hidden and font_prefix.."("..translations.gui.hidden_abbrev..")"..font_suffix.."  " or ""
  local amount_string = amount and font_prefix..amount..font_suffix.."  " or ""
  local name = player_settings.show_internal_names and obj_data.prototype_name or translation
  return
    glyph
    ..hidden_string
    .."[img="..obj_data.sprite_class.."/"..obj_data.prototype_name.."]  "
    ..amount_string
    ..name
end

local function get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
  local translations = player_data.translations
  local translation_key = obj_data.internal_class == "material" and obj_data.sprite_class.."."..obj_data.prototype_name or obj_data.prototype_name
  local translation = player_data.translations[obj_data.internal_class][translation_key]
  local show_internal_names = player_data.settings.show_internal_names
  local name = show_internal_names and obj_data.prototype_name or translation
  local internal_name = show_internal_names and translation or obj_data.prototype_name

  local category_class = obj_data.sprite_class == "entity" and obj_data.internal_class or obj_data.sprite_class

  local hidden_string = is_hidden and "  |  "..translations.gui.hidden or ""
  local unresearched_string = not is_researched and "  |  [color="..constants.colors.unresearched.str.."]"..translations.gui.unresearched.."[/color]" or ""

  return
    "[img="..obj_data.sprite_class.."/"..obj_data.prototype_name.."]  [font=default-bold][color="..constants.colors.heading.str.."]"..name.."[/color][/font]"
    .."\n[color="..constants.colors.green.str.."]"..internal_name.."[/color]"
    .."\n[color="..constants.colors.info.str.."]"..translations.gui[category_class].."[/color]"..hidden_string..unresearched_string
end

local tooltip_formatters = {
  machine = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched)
      return get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
    end,
    enabled = false
  },
  material = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched)
      return get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
    end,
    enabled = true
  },
  recipe = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched)
      return get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
    end,
    enabled = true
  },
  resource = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched)
      return get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
    end,
    enabled = false
  },
  technology = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched)
      return get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
    end,
    enabled = true
  }
}

local function format_item(obj_data, player_data, amount_string, is_info_label)
  local should_show, is_hidden, is_researched = get_should_show(obj_data, player_data)
  if is_info_label or should_show then
    -- format and return
    local formatter_subtable = tooltip_formatters[obj_data.internal_class]
    return
      true,
      is_researched and "rb_list_box_item" or "rb_unresearched_list_box_item",
      caption_formatter(obj_data, player_data, is_hidden, amount_string, is_info_label),
      formatter_subtable.tooltip(obj_data, player_data, is_hidden, is_researched),
      formatter_subtable.enabled
  else
    return false
  end
end

function formatter.format(obj_data, player_data, amount_string, is_info_label)
  local player_index = player_data.player_index
  local cache = caches[player_index]
  local _, is_researched = get_properties(obj_data, player_data.force_index)
  local cache_key = obj_data.sprite_class
  .."."..obj_data.prototype_name
  .."."..(amount_string or "false")
  .."."..tostring(is_researched)
  .."."..tostring(is_info_label)
  local cached_return = cache[cache_key]
  if cached_return then
    return table.unpack(cached_return)
  else
    local should_show, style, caption, tooltip, enabled = format_item(obj_data, player_data, amount_string, is_info_label)
    cache[cache_key] = { should_show, style, caption, tooltip, enabled }
    return should_show, style, caption, tooltip, enabled
  end
end

function formatter.create_cache(player_index)
  caches[player_index] = {}
end

function formatter.create_all_caches()
  for i in pairs(global.players) do
    caches[i] = {}
  end
end

formatter.purge_cache = formatter.create_cache

function formatter.destroy_cache(player_index)
  caches[player_index] = nil
end

-- when calling the module directly, call formatter.format
setmetatable(formatter, { __call = function(_, ...) return formatter.format(...) end })

return formatter