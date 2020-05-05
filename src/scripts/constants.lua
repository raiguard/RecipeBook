local event = require("__flib__.control.event")

local category_by_index = {"crafter", "material", "recipe"}
local category_to_index = {crafter=1, material=2, recipe=3}

return {
  category_by_index = category_by_index,
  category_to_index = category_to_index,
  empty_translation_tables = {
    crafter = {},
    material = {},
    other = {},
    recipe = {},
    technology = {}
  },
  interface_version = 2,
  num_categories = #category_by_index,
  open_fluid_types = {
    ["fluid-wagon"] = true,
    ["infinity-pipe"] = true,
    ["offshore-pump"] = true,
    ["pipe-to-ground"] = true,
    ["pipe"] = true,
    ["pump"] = true,
    ["storage-tank"] = true
  },
  open_gui_event = event.generate_id(),
  reopen_source_event = event.generate_id()
}