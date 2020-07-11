local util = require("__core__.lualib.util")

local constants = require("constants")

-- ! TODO move to flib

function util.shallow_copy(tbl)
  local new_t = {}
  for k, v in pairs(tbl) do
    new_t[k] = v
  end
  return new_t
end

-- because Lua doesn't have a math.round...
-- from http://lua-users.org/wiki/SimpleRound
function util.round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

-- * ----------------------------------------------------------------------------------------------------
-- * LISTBOX ITEM FORMATTERS

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

local function caption_formatter(item_data, player_data, show_glyph)
  local translations = player_data.translations[item_data.internal_class]
  local glyph = ""
  if show_glyph then
    local glyph_char = constants.class_to_font_glyph[item_data.internal_class] or constants.class_to_font_glyph[item_data.sprite_class]
    glyph = "[font=RecipeBook]"..glyph_char.."[/font]  "
  end
  local amount_string = item_data.amount_string and item_data.amount_string.."  " or ""
  local name = player_data.show_internal_names and item_data.prototype_name or translations[item_data.prototype_name]
    or translations[item_data.sprite_class.."."..item_data.prototype_name]
  return
    glyph
    .."[img="..item_data.sprite_class.."/"..item_data.prototype_name.."]  "
    ..amount_string
    ..name
end

local formatters = {
  machine = {
    tooltip = function(item_data, player_data)
      return "MACHINE TOOLTIP"
    end,
    enabled = false
  },
  material = {
    tooltip = function(item_data, player_data)
      return "MATERIAL TOOLTIP"
    end,
    enabled = true
  },
  recipe = {
    tooltip = function(item_data, player_data)
      return "RECIPE TOOLTIP"
    end,
    enabled = true
  },
  resource = {
    tooltip = function(item_data, player_data)
      return "RESOURCE TOOLTIP"
    end,
    enabled = false
  },
  technology = {
    tooltip = function(item_data, player_data)
      return "TECHNOLOGY TOOLTIP"
    end,
    enabled = true
  }
}

function util.format_item(item_data, player_data, show_glyph)
  show_glyph = true
  local should_show, _, is_available = get_should_show(item_data, player_data)
  if should_show then
    -- format and return
    local formatter_subtable = formatters[item_data.internal_class]
    return
      true,
      is_available and "rb_list_box_item" or "rb_unavailable_list_box_item",
      caption_formatter(item_data, player_data, show_glyph),
      formatter_subtable.tooltip(item_data, player_data),
      formatter_subtable.enabled
  else
    return false
  end
end

-- * ----------------------------------------------------------------------------------------------------

-- TODO hand-crafting indicator
function util.format_crafter_item(name, obj_data, player_info, recipe_data)
  local translation = player_info.translations.machine[name]
  local is_hidden = obj_data.hidden
  local is_available = obj_data.available_to_all_forces or obj_data.available_to_forces[player_info.force_index]

  local style = is_available and constants.list_box_item_styles.available or constants.list_box_item_styles.unavailable
  local caption = "[entity="..name.."]  ".."[font=default-semibold](" ..util.round(recipe_data.energy / obj_data.crafting_speed, 2).."s)[/font] "..name
  local tooltip =
    "[entity="..name.."]  "..name
    .."\n[color="..constants.colors.info.str.."]Machine[/color]"

  if is_hidden then
    caption = "[font=default-semibold](H)[/font]  "..caption
    tooltip = tooltip.."  |  Hidden"
  end
  if not is_available then
    tooltip = tooltip.."  |  [color="..constants.colors.unavailable.str.."]Unavailable[/color]"
  end

  return style, caption, tooltip, false
end

-- TODO time indicator
function util.format_material_item(obj, obj_data, player_info)
  local translation = player_info.translations.material[obj_data.sprite_class.."."..obj_data.prototype_name]
  local is_hidden = obj_data.hidden
  local is_available = obj_data.available_to_all_forces or obj_data.available_to_forces[player_info.force_index]

  local style = is_available and constants.list_box_item_styles.available or constants.list_box_item_styles.unavailable
  local caption = "[img="..obj_data.sprite_class.."/"..obj.name.."]  "
  if obj.amount_string then
    caption = caption.."[font=default-semibold]"..obj.amount_string.."[/font]  "..obj.name
  else
    caption = caption..obj.name
  end
  local tooltip =
    "[img="..obj_data.sprite_class.."/"..obj.name.."]  "..obj.name
    .."\n[color="..constants.colors.info.str.."]"..obj_data.sprite_class.."[/color]"

  if is_hidden then
    caption = "[font=default-semibold](H)[/font]  "..caption
    tooltip = tooltip.."  |  Hidden"
  end
  if not is_available then
    tooltip = tooltip.."  |  [color="..constants.colors.unavailable.str.."]Unavailable[/color]"
  end

  return style, caption, tooltip
end

function util.format_recipe_item(name, obj_data, player_info)
  local translation = player_info.translations.recipe[name]
  if not translation then translation = name end
  local is_hidden = obj_data.hidden
  local is_available = obj_data.available_to_all_forces or obj_data.available_to_forces[player_info.force_index]
  local style = is_available and constants.list_box_item_styles.available or constants.list_box_item_styles.unavailable
  local caption = "[img="..obj_data.sprite_class.."/"..name.."]  "..name
  local tooltip =
    "[img="..obj_data.sprite_class.."/"..name.."]  "..name
    .."\n[color="..constants.colors.info.str.."]"..obj_data.sprite_class.."[/color]"

  if is_hidden then
    caption = "[font=default-semibold](H)[/font]  "..caption
    tooltip = tooltip.."  |  Hidden"
  end
  if not is_available then
    tooltip = tooltip.."  |  [color="..constants.colors.unavailable.str.."]Unavailable[/color]"
  end

  return style, caption, tooltip
end

function util.format_resource_item(name, obj_data, player_info)
  local translation = player_info.translations.resource[name]
  local caption = "[entity="..name.."]  "..name
  local tooltip =
    "[entity="..name.."]  "..name
    .."\n[color="..constants.colors.info.str.."]Resource[/color]"

  return constants.list_box_item_styles.available, caption, tooltip, false
end

function util.format_technology_item(name, obj_data, player_info)
  local translation = player_info.translations.technology[name]
  local is_hidden = obj_data.hidden
  local is_researched = obj_data.researched_forces[player_info.force_index]
  local style = is_researched and constants.list_box_item_styles.available or constants.list_box_item_styles.unavailable
  local caption = "[technology="..name.."]  "..name
  local tooltip =
    "[technology="..name.."]  "..name
    .."\n[color="..constants.colors.info.str.."]Technology[/color]"

  if is_hidden then
    caption = "[font=default-semibold](H)[/font]  "..caption
    tooltip = tooltip.."  |  Hidden"
  end

  if not is_researched then
    tooltip = tooltip.."  |  [color="..constants.colors.unavailable.str.."]Unresearched[/color]"
  end

  tooltip = tooltip.."\nClick to view on technology screen."

  return style, caption, tooltip
end

return util