local constants = {}

local event = require("__flib__.event")

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

constants.colors = {
  info = {
    str = "128, 206, 240",
    tbl = {128, 206, 240}
  },
  unavailable = {
    str = "255, 142, 142",
    tbl = {255, 142, 142}
  }
}

constants.empty_translations_table = {
  machine = {},
  material = {},
  other = {},
  recipe = {},
  resource = {},
  technology = {}
}

constants.events = {
  open_page = event.generate_id()
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

constants.interface_version = 3

constants.panes = {
  "home",
  "material",
  "recipe",
  "search"
}

constants.search_categories = {"material", "recipe"}

return constants