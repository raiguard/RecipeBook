local formatter = {}

local constants = require("constants")

local caches = {}

local function get_properties(obj_data, force_index)
  local available
  if obj_data.researched_forces then
    available = obj_data.researched_forces[force_index] or false
  else
    available = obj_data.available_to_all_forces or obj_data.available_to_forces[force_index] or false
  end
  return obj_data.hidden, available
end

local function get_should_show(obj_data, player_data)
  -- player data
  local show_hidden = player_data.show_hidden
  local show_unavailable = player_data.show_unavailable
  local force_index = player_data.force_index

  -- check hidden and available status
  local is_hidden, is_available = get_properties(obj_data, force_index)
  if (show_hidden or not is_hidden) and (show_unavailable or is_available) then
    return true, is_hidden, is_available
  else
    return false, is_hidden, is_available
  end
end

local function caption_formatter(obj_data, player_data, is_hidden, amount)
  local translations = player_data.translations
  local translation_key = obj_data.internal_class == "material" and obj_data.sprite_class.."."..obj_data.prototype_name or obj_data.prototype_name
  local translation = translations[obj_data.internal_class][translation_key]
  local glyph = ""
  if player_data.show_glyphs then
    local glyph_char = constants.class_to_font_glyph[obj_data.internal_class] or constants.class_to_font_glyph[obj_data.sprite_class]
    glyph = "[font=RecipeBook]"..glyph_char.."[/font]  "
  end
  local hidden_string = is_hidden and "[font=default-semibold]("..translations.gui.hidden_abbrev..")[/font]  " or ""
  local amount_string = amount and "[font=default-semibold]"..amount.."[/font]  " or ""
  local name = player_data.show_internal_names and obj_data.prototype_name or translation
  return
    glyph
    ..hidden_string
    .."[img="..obj_data.sprite_class.."/"..obj_data.prototype_name.."]  "
    ..amount_string
    ..name
end

local function get_base_tooltip(obj_data, player_data, is_hidden, is_available)
  local translations = player_data.translations
  local translation_key = obj_data.internal_class == "material" and obj_data.sprite_class.."."..obj_data.prototype_name or obj_data.prototype_name
  local translation = player_data.translations[obj_data.internal_class][translation_key]
  local name = player_data.show_internal_names and obj_data.prototype_name or translation
  local internal_name = player_data.show_internal_names and translation or obj_data.prototype_name

  local category_class = obj_data.sprite_class == "entity" and obj_data.internal_class or obj_data.sprite_class

  local hidden_string = is_hidden and "  |  "..translations.gui.hidden or ""
  local unavailable_string = not is_available and "  |  [color="..constants.colors.unavailable.str.."]"..translations.gui.unavailable.."[/color]" or ""

  return
    "[img="..obj_data.sprite_class.."/"..obj_data.prototype_name.."]  [font=default-bold][color="..constants.colors.heading.str.."]"..name.."[/color][/font]"
    .."\n[color="..constants.colors.green.str.."]"..internal_name.."[/color]"
    .."\n[color="..constants.colors.info.str.."]"..translations.gui[category_class].."[/color]"..hidden_string..unavailable_string
end

local tooltip_formatters = {
  machine = {
    tooltip = function(obj_data, player_data, is_hidden, is_available)
      return get_base_tooltip(obj_data, player_data, is_hidden, is_available)
    end,
    enabled = false
  },
  material = {
    tooltip = function(obj_data, player_data, is_hidden, is_available)
      return get_base_tooltip(obj_data, player_data, is_hidden, is_available)
    end,
    enabled = true
  },
  recipe = {
    tooltip = function(obj_data, player_data, is_hidden, is_available)
      return get_base_tooltip(obj_data, player_data, is_hidden, is_available)
    end,
    enabled = true
  },
  resource = {
    tooltip = function(obj_data, player_data, is_hidden, is_available)
      return get_base_tooltip(obj_data, player_data, is_hidden, is_available)
    end,
    enabled = false
  },
  technology = {
    tooltip = function(obj_data, player_data, is_hidden, is_available)
      return get_base_tooltip(obj_data, player_data, is_hidden, is_available)
    end,
    enabled = true
  }
}

local function format_item(obj_data, player_data, amount_string)
  local should_show, is_hidden, is_available = get_should_show(obj_data, player_data)
  if should_show then
    -- format and return
    local formatter_subtable = tooltip_formatters[obj_data.internal_class]
    return
      true,
      is_available and "rb_list_box_item" or "rb_unavailable_list_box_item",
      caption_formatter(obj_data, player_data, is_hidden, amount_string),
      formatter_subtable.tooltip(obj_data, player_data, is_hidden, is_available),
      formatter_subtable.enabled
  else
    return false
  end
end

function formatter.format(obj_data, player_data, amount_string)
  local player_index = player_data.player_index
  local cache = caches[player_index]
  local _, is_available = get_properties(obj_data, player_data.force_index)
  local cache_key = obj_data.sprite_class.."."..obj_data.prototype_name.."."..(amount_string or "false").."."..tostring(is_available)
  local cached_return = cache[cache_key]
  if cached_return then
    return table.unpack(cached_return)
  else
    local should_show, style, caption, tooltip, enabled = format_item(obj_data, player_data, amount_string)
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