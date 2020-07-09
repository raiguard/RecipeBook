local util = require("__core__.lualib.util")

local constants = require("constants")

--! TODO move to flib

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

-- listbox item formatters

-- TODO hand-crafting indicator
function util.format_crafter_item(name, obj_data, int_class, player_info, recipe_data)
  local translation = player_info.translations.machine[name]
  local is_hidden = obj_data.hidden
  local is_available = obj_data.available_to_all_forces or obj_data.available_to_forces[player_info.force_index]

  local style = is_available and constants.list_box_item_styles.available or constants.list_box_item_styles.unavailable
  local caption = "[entity="..name.."]  ".."[font=default-semibold](" ..util.round(recipe_data.energy / obj_data.crafting_speed, 2).."s)[/font] "..translation
  local tooltip =
    "[entity="..name.."]  "..translation
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
function util.format_material_item(obj, obj_data, int_class, player_info)
  local translation = player_info.translations[int_class][obj_data.sprite_class.."."..obj_data.prototype_name]
  local is_hidden = obj_data.hidden
  local is_available = obj_data.available_to_all_forces or obj_data.available_to_forces[player_info.force_index]

  local style = is_available and constants.list_box_item_styles.available or constants.list_box_item_styles.unavailable
  local caption = "[img="..obj_data.sprite_class.."/"..obj.name.."]  [font=default-semibold]"..obj.amount_string.."[/font]  "..translation
  local tooltip =
    "[img="..obj_data.sprite_class.."/"..obj.name.."]  "..translation
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

function util.format_recipe_item(name, obj_data, int_class, player_info)
  local translation = player_info.translations[int_class][name]
  if not translation then translation = name end
  local is_hidden = obj_data.hidden
  local is_available = obj_data.available_to_all_forces or obj_data.available_to_forces[player_info.force_index]
  local style = is_available and constants.list_box_item_styles.available or constants.list_box_item_styles.unavailable
  local caption = "[img="..obj_data.sprite_class.."/"..name.."]  "..translation
  local tooltip =
    "[img="..obj_data.sprite_class.."/"..name.."]  "..translation
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

function util.format_resource_item(name, obj_data, int_class, player_info)
  local translation = player_info.translations.resource[name]
  local caption = "[entity="..name.."]  "..translation
  local tooltip =
    "[entity="..name.."]  "..translation
    .."\n[color="..constants.colors.info.str.."]Resource[/color]"

  return constants.list_box_item_styles.available, caption, tooltip, false
end

function util.format_technology_item(name, obj_data, int_class, player_info)
  local translation = player_info.translations.technology[name]
  local is_hidden = obj_data.hidden
  local is_researched = obj_data.researched_forces[player_info.force_index]
  local style = is_researched and constants.list_box_item_styles.available or constants.list_box_item_styles.unavailable
  local caption = "[technology="..name.."]  "..translation
  local tooltip =
    "[technology="..name.."]  "..translation
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