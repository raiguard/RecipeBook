local event = require("__flib__.control.event")

local category_by_index = {"crafter", "material", "recipe"}

return {
  blacklisted_recipe_categories = {
    ["transport-drone-request"] = true
  },
  category_by_index = category_by_index,
  category_to_index = {crafter=1, material=2, recipe=3},
  empty_lookup_tables = {
    crafter = {lookup={}, sorted_translations={}},
    material = {lookup={}, sorted_translations={}},
    other = {lookup={}, sorted_translations={}},
    recipe = {lookup={}, sorted_translations={}},
    technology = {lookup={}, sorted_translations={}}
  },
  empty_translation_tables = {
    crafter = {},
    material = {},
    other = {},
    recipe = {},
    technology = {}
  },
  info_guis = {crafter=true, material=true, recipe=true},
  input_sanitizers = {
    ["%("] = "%%(",
    ["%)"] = "%%)",
    ["%.^[%*]"] = "%%.",
    ["%+"] = "%%+",
    ["%-"] = "%%-",
    ["^[%.]%*"] = "%%*",
    ["%?"] = "%%?",
    ["%["] = "%%[",
    ["%]"] = "%%]",
    ["%^"] = "%%^",
    ["%$"] = "%%$"
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