local constants = require("constants")

local locale = {}

local colors = constants.colors

function locale.with_colon(input)
  return input..":"
end

function locale.with_suffix(input, suffix)
  return input.." "..suffix
end

function locale.rich_text(key, value, inner)
  return "["..key.."="..(key == "color" and colors[value].str or value).."]"..inner.."[/"..key.."]"
end

function locale.sprite(class, name)
  return "[img="..class.."/"..name.."]"
end

function locale.control(control, action)
  return "\n"
    ..locale.rich_text("color", "info", locale.rich_text("font", "default-semibold", control..":"))
    .." "
    ..action
end

function locale.tooltip_kv(label, value)
  return "\n"..locale.rich_text("font", "default-semibold", label..":").." "..(value or "")
end

return locale
