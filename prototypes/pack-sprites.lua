local bigpack = require("lib.pack")

--- @type table<SpritePath, true>
local sprites = {}
for name in pairs(data.raw["sprite"]) do
  if string.match(name, "^tooltip%-category%-") then
    sprites[name] = true
  end
end

data:extend({
  bigpack("rb_tooltip_category_sprites", serpent.line(sprites)),
})
