local event = require("__flib__.event")

local category_by_index = {"material", "recipe"}

-- TODO dynamically generate translation tables from list of categories

return {
  blacklisted_recipe_categories = {
    -- transport drones
    ["fluid-depot"] = true,
    ["transport-drone-request"] = true,
    ["transport-fluid-request"] = true
  },
  category_by_index = category_by_index,
  category_to_index = {material=1, recipe=2},
  empty_lookup_tables = {
    crafter = {lookup={}, sorted_translations={}},
    material = {lookup={}, sorted_translations={}},
    other = {lookup={}, sorted_translations={}},
    recipe = {lookup={}, sorted_translations={}},
    resource = {lookup={}, sorted_translations={}},
    technology = {lookup={}, sorted_translations={}}
  },
  empty_translation_tables = {
    crafter = {},
    material = {},
    other = {},
    recipe = {},
    resource = {},
    technology = {}
  },
  info_guis = {material=true, recipe=true},
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
  reopen_source_event = event.generate_id(),
  unavailable_font_color = "255, 142, 142"
}