local constants = {}

-- dictionary category -> affects research
-- anything with `0` as the value will be ignored for research
constants.disabled_recipe_categories = {
  -- editor extensions
  ["ee-testing-tool"] = 1,
  -- deep storage unit
  ["deep-storage-item"] = 0,
  ["deep-storage-fluid"] = 0,
  ["deep-storage-item-big"] = 0,
  ["deep-storage-fluid-big"] = 0,
  ["deep-storage-item-mk2/3"] = 0,
  ["deep-storage-fluid-mk2/3"] = 0,
  -- mining drones
  ["mining-depot"] = 0,
  -- transport drones
  ["fuel-depot"] = 0,
  ["transport-drone-request"] = 0,
  ["transport-fluid-request"] = 0
}

constants.class_to_font_glyph = {
  crafter = "D",
  fluid = "B",
  item = "C",
  lab = "D",
  offshore_pump = "D",
  recipe = "E",
  resource = "F",
  technology = "A"
}

constants.colors = {
  error = {
    str = "255, 90, 90",
    tbl = {255, 90, 90}
  },
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
  unresearched = {
    str = "255, 142, 142",
    tbl = {255, 142, 142}
  }
}

constants.empty_translations_table = {
  gui = {},
  crafter = {},
  lab = {},
  material = {},
  offshore_pump = {},
  recipe = {},
  resource = {},
  technology = {}
}

constants.input_sanitizers = {
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

constants.interface_classes = {
  fluid = "material",
  item = "material",
  recipe = "recipe"
}

constants.interface_version = 4

constants.list_box_item_styles = {
  available = "rb_list_box_item",
  unresearched = "rb_unresearched_list_box_item"
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

constants.search_categories_lookup = {}
constants.search_categories_localised = {}
for i, category in ipairs(constants.search_categories) do
  constants.search_categories_lookup[category] = i
  constants.search_categories_localised[i] = {"rb-gui."..category.."-lowercase"}
end

constants.search_results_limit = 150

constants.settings = {
  general = {
    open_item_hotkey = {
      default_value = true,
      has_tooltip = true
    },
    open_fluid_hotkey = {
      default_value = true,
      has_tooltip = true
    }
  },
  interface = {
    show_hidden = {
      default_value = false,
      has_tooltip = true
    },
    show_unresearched = {
      default_value = false,
      has_tooltip = true
    },
    show_glyphs = {
      default_value = true,
      has_tooltip = false
    },
    show_alternate_name = {
      default_value = false,
      has_tooltip = true
    },
    show_detailed_recipe_tooltips = {
      default_value = true,
      has_tooltip = true
    },
  },
  search = {
    use_fuzzy_search = {
      default_value = false,
      has_tooltip = true
    },
    use_internal_names = {
      default_value = false,
      has_tooltip = true
    }
  }
}

return constants
