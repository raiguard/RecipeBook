local constants = {}

local event = require("__flib__.event")

local search_categories = {material={"rb-gui.material"}, recipe={"rb-gui.recipe"}}

constants.blacklisted_recipe_categories = {
  -- transport drones
  ["fluid-depot"] = true,
  ["transport-drone-request"] = true,
  ["transport-fluid-request"] = true
}

constants.search_category_by_index = {}
constants.search_category_items = {}
constants.search_category_to_index = {}
local i = 0
for internal, localised in pairs(search_categories) do
  i = i + 1
  constants.search_category_by_index[i] = internal
  constants.search_category_items[i] = localised
  constants.search_category_to_index[internal] = i
end

constants.content_panes = {home=true, material=true, recipe=true}

constants.empty_lookup_tables = {
  crafter = {lookup={}, sorted_translations={}},
  material = {lookup={}, sorted_translations={}},
  other = {lookup={}, sorted_translations={}},
  recipe = {lookup={}, sorted_translations={}},
  resource = {lookup={}, sorted_translations={}},
  technology = {lookup={}, sorted_translations={}}
}
constants.empty_translation_tables = {
  crafter = {},
  material = {},
  other = {},
  recipe = {},
  resource = {},
  technology = {}
}

constants.search_input_sanitizers = {
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
}

constants.interface_version = 2

constants.open_fluid_types = {
  ["fluid-wagon"] = true,
  ["infinity-pipe"] = true,
  ["offshore-pump"] = true,
  ["pipe-to-ground"] = true,
  ["pipe"] = true,
  ["pump"] = true,
  ["storage-tank"] = true
}

constants.open_gui_event = event.generate_id()
constants.reopen_source_event = event.generate_id()

constants.unavailable_font_color = "255, 142, 142"

return constants