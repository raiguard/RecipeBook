local constants = {}

-- CONTROL-STAGE ONLY

if script then
  local event = require("__flib__.event")

  constants.events = {
    open_page = event.generate_id(),
    update_quick_ref_button = event.generate_id()
  }
end

-- BOTH STAGES

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

constants.class_to_font_glyph = {
  fluid = "B",
  item = "C",
  machine = "D",
  recipe = "E",
  resource = "F",
  technology = "A"
}

constants.colors = {
  green = {
    str = "210, 253, 145",
    tbl = {210, 253, 145}
  },
  heading = {
    str = "255, 230, 192",
    tbl = {255, 230, 192}
  },
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
  gui = {},
  machine = {},
  material = {},
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

constants.interface_version = 3

constants.list_box_item_styles = {
  available = "rb_list_box_item",
  unavailable = "rb_unavailable_list_box_item"
}

constants.main_pages = {
  "home",
  "material",
  "recipe",
  "search",
  "settings"
}

constants.open_fluid_types = {
  ["fluid-wagon"] = true,
  ["infinity-pipe"] = true,
  ["offshore-pump"] = true,
  ["pipe-to-ground"] = true,
  ["pipe"] = true,
  ["pump"] = true,
  ["storage-tank"] = true
}

constants.search_categories = {"material", "recipe"}

constants.search_results_limit = 150

return constants