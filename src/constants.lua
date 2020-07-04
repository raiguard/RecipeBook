local constants = {}

local util = require("scripts.util")

constants.blacklisted_recipe_categories = {
  -- transport drones
  ["fluid-depot"] = true,
  ["transport-drone-request"] = true,
  ["transport-fluid-request"] = true,
  -- deep storage unit
  ["deep-storage-item"] = true,
  ["deep-storage-fluid"] = true,
  ["deep-storage-item-big"] = true,
  ["deep-storage-fluid-big"] = true,
  ["deep-storage-item-mk2/3"] = true,
  ["deep-storage-fluid-mk2/3"] = true
}

constants.empty_translations_table = {
  machine = {},
  material = {},
  other = {},
  recipe = {},
  resource = {},
  technology = {}
}

constants.input_sanitisers = {
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

constants.panes = {
  "home",
  "material",
  "recipe",
  "search"
}

constants.search_categories = {"material", "recipe"}

constants.unavailable_color_tbl = {255, 142, 142}
constants.unavailable_color = "255, 142, 142"

return constants