local formatter = {}

local memoize = require("lib.memoize")

local constants = require("constants")

--[[
  PLAYER_DATA:
    force_index
    show_hidden
    show_unavailable
    translations
]]

local function get_properties(item_data, force_index)
  return
    item_data.hidden,
    item_data.researched_forces
      and item_data.researched_forces[force_index]
      or item_data.available_to_all_forces
      or item_data.available_to_forces[force_index]
end

local function get_should_show(item_data, player_data)
  -- player data
  local show_hidden = player_data.show_hidden
  local show_unavailable = player_data.show_unavailable
  local force_index = player_data.force_index

  -- check hidden and available status
  local is_hidden, is_available = get_properties(item_data, force_index)
  if (show_hidden or not is_hidden) and (show_unavailable or is_available) then
    return true, is_hidden, is_available
  else
    return false, is_hidden, is_available
  end
end

local function caption_formatter(item_data, player_data, is_hidden)
  local translations = player_data.translations
  local translation_key = item_data.internal_class == "material" and item_data.sprite_class.."."..item_data.prototype_name or item_data.prototype_name
  local translation = translations[item_data.internal_class][translation_key]
  local glyph = ""
  if player_data.show_glyphs then
    local glyph_char = constants.class_to_font_glyph[item_data.internal_class] or constants.class_to_font_glyph[item_data.sprite_class]
    glyph = "[font=RecipeBook]"..glyph_char.."[/font]  "
  end
  local hidden_string = is_hidden and "[font=default-semibold]("..translations.gui.hidden_abbrev..")[/font]  " or ""
  local amount_string = item_data.amount_string and "[font=default-semibold]"..item_data.amount_string.."[/font]  " or ""
  local name = player_data.show_internal_names and item_data.prototype_name or translation
  return
    glyph
    ..hidden_string
    .."[img="..item_data.sprite_class.."/"..item_data.prototype_name.."]  "
    ..amount_string
    ..name
end

local function get_base_tooltip(item_data, player_data, is_hidden, is_available)
  local translations = player_data.translations
  local translation_key = item_data.internal_class == "material" and item_data.sprite_class.."."..item_data.prototype_name or item_data.prototype_name
  local translation = player_data.translations[item_data.internal_class][translation_key]
  local name = player_data.show_internal_names and item_data.prototype_name or translation
  local internal_name = player_data.show_internal_names and translation or item_data.prototype_name

  local category_class = item_data.sprite_class == "entity" and item_data.internal_class or item_data.sprite_class

  local hidden_string = is_hidden and "  |  "..translations.gui.hidden or ""
  local unavailable_string = not is_available and "  |  [color="..constants.colors.unavailable.str.."]"..translations.gui.unavailable.."[/color]" or ""

  return
    "[img="..item_data.sprite_class.."/"..item_data.prototype_name.."]  [font=default-bold][color="..constants.colors.heading.str.."]"..name.."[/color][/font]"
    .."\n[color="..constants.colors.green.str.."]"..internal_name.."[/color]"
    .."\n[color="..constants.colors.info.str.."]"..translations.gui[category_class].."[/color]"..hidden_string..unavailable_string
end

local formatters = {
  machine = {
    tooltip = function(item_data, player_data, is_hidden, is_available)
      return get_base_tooltip(item_data, player_data, is_hidden, is_available)
    end,
    enabled = false
  },
  material = {
    tooltip = function(item_data, player_data, is_hidden, is_available)
      return get_base_tooltip(item_data, player_data, is_hidden, is_available)
    end,
    enabled = true
  },
  recipe = {
    tooltip = function(item_data, player_data, is_hidden, is_available)
      return get_base_tooltip(item_data, player_data, is_hidden, is_available)
    end,
    enabled = true
  },
  resource = {
    tooltip = function(item_data, player_data, is_hidden, is_available)
      return get_base_tooltip(item_data, player_data, is_hidden, is_available)
    end,
    enabled = false
  },
  technology = {
    tooltip = function(item_data, player_data, is_hidden, is_available)
      return get_base_tooltip(item_data, player_data, is_hidden, is_available)
    end,
    enabled = true
  }
}

function formatter.format_item(item_data, player_data)
  local should_show, is_hidden, is_available = get_should_show(item_data, player_data)
  if should_show then
    -- format and return
    local formatter_subtable = formatters[item_data.internal_class]
    return
      true,
      is_available and "rb_list_box_item" or "rb_unavailable_list_box_item",
      caption_formatter(item_data, player_data, is_hidden),
      formatter_subtable.tooltip(item_data, player_data, is_hidden, is_available),
      formatter_subtable.enabled
  else
    return -- memoize does not work with nil values, so use placeholders
      false,
      false,
      false,
      false,
      false
  end
end

return formatter