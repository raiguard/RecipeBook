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

-- listbox item formatters

function util.format_generic_item(obj, int_class, player_info)
  local translation = player_info.translations[int_class][obj.prototype_name]
  local is_hidden = obj.hidden
  local is_available = obj.available_to_all_forces or obj.available_to_forces[player_info.force_index]
  local style = is_available and constants.list_box_item_styles.available or constants.list_box_item_styles.unavailable
  local caption = "["..obj.sprite_class.."="..obj.prototype_name.."]  "..translation
  local tooltip =
    "["..obj.sprite_class.."="..obj.prototype_name.."]  "..translation
    .."\n[color="..constants.colors.info.str.."]"..obj.sprite_class.."[/color]"

  if is_hidden then
    caption = "(H)  "..caption
    tooltip = tooltip.."  |  Hidden"
  end
  if not is_available then
    tooltip = tooltip.."  |  [color="..constants.colors.unavailable.str.."]Unavailable[/color]"
  end

  return style, caption, tooltip
end

function util.format_resource_item(obj, int_class, player_info)
  local translation = player_info.translations.resource[obj.prototype_name]
  local caption = "[entity="..obj.prototype_name.."]  "..translation
  local tooltip =
    "[entity="..obj.prototype_name.."]  "..translation
    .."\n[color="..constants.colors.info.str.."]Resource[/color]"

  return constants.list_box_item_styles.available, caption, tooltip, false
end

function util.format_technology_item(obj, int_class, player_info)
  local translation = player_info.translations.technology[obj.prototype_name]
  local is_researched = obj.researched_forces[player_info.force_index]
  local style = is_researched and constants.list_box_item_styles.available or constants.list_box_item_styles.unavailable
  local caption = "[technology="..obj.prototype_name.."]  "..translation
  local tooltip =
    "[technology="..obj.prototype_name.."]  "..translation
    .."\n[color="..constants.colors.info.str.."]Technology[/color]"

  if not is_researched then
    tooltip = tooltip.."  |  [color="..constants.colors.unavailable.str.."]Unresearched[/color]"
  end

  tooltip = tooltip.."\nClick to view on technology screen."

  return style, caption, tooltip
end

return util