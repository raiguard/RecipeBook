local constants = {}

-- CONTROL-STAGE ONLY

if script then
  local event = require("__flib__.event")

  constants.events = {
    open_page = event.generate_id(),
    update_list_box_items = event.generate_id(),
    update_quick_ref_button = event.generate_id()
  }
end

-- BOTH STAGES

constants.disabled_recipe_categories = {
  -- editor extensions
  ["ee-testing-tool"] = true,
  -- deep storage unit
  ["deep-storage-item"] = true,
  ["deep-storage-fluid"] = true,
  ["deep-storage-item-big"] = true,
  ["deep-storage-fluid-big"] = true,
  ["deep-storage-item-mk2/3"] = true,
  ["deep-storage-fluid-mk2/3"] = true,
  -- mining drones
  ["mining-depot"] = true,
  -- transport drones
  ["fuel-depot"] = true,
  ["transport-drone-request"] = true,
  ["transport-fluid-request"] = true
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
  unresearched = {
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

constants.interface_classes = {
  fluid = "material",
  item = "material",
  recipe = "recipe"
}

constants.interface_version = 3

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
for i, category in ipairs(constants.search_categories) do
  constants.search_categories_lookup[category] = i
end

constants.search_results_limit = 150

constants.settings = {
  general = {
    open_item_hotkey = {
      prototype_name = "rb-open-item-hotkey",
      has_tooltip = true
    },
    open_fluid_hotkey = {
      prototype_name = "rb-open-fluid-hotkey",
      has_tooltip = true
    },
    show_hidden = {
      prototype_name = "rb-show-hidden-objects",
      has_tooltip = false
    },
    show_unresearched = {
      prototype_name = "rb-show-unresearched-objects",
      has_tooltip = false
    },
    show_internal_names = {
      prototype_name = "rb-show-internal-names",
      has_tooltip = true
    },
    show_glyphs = {
      prototype_name = "rb-show-glyphs",
      has_tooltip = false
    }
  },
  search = {
    use_fuzzy_search = {
      prototype_name = "rb-use-fuzzy-search",
      has_tooltip = true
    }
  }
}

constants.setting_prototype_names = {}
for _, t in pairs(constants.settings) do
  for name, data in pairs(t) do
    constants.setting_prototype_names[name] = data.prototype_name
  end
end

return constants