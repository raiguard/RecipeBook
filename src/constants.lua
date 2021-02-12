local constants = {}

-- dictionary category -> affects research
-- anything with `0` as the value will be ignored for research
constants.disabled_recipe_categories = {
  -- creative mod
  ["creative-mod_free-fluids"] = 1,
  ["creative-mod_energy-absorption"] = 1,
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
  -- pyanodon's
  ["py-runoff"] = 1,
  ["py-venting"] = 1,
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

constants.class_to_type = {
  crafter = "entity",
  fluid = "fluid",
  item = "item",
  lab = "entity",
  offshore_pump = "entity",
  recipe = "recipe",
  resource = "entity",
  technology = "technology"
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
  yellow = {
    str = "255, 240, 69",
    tbl = {255, 240, 69}
  },
  unresearched = {
    str = "255, 142, 142",
    tbl = {255, 142, 142}
  }
}

constants.empty_translations_table = {
  gui = {},
  crafter = {},
  crafter_description = {},
  fluid = {},
  fluid_description = {},
  item = {},
  item_description = {},
  lab = {},
  lab_description = {},
  offshore_pump = {},
  offshore_pump_description = {},
  recipe = {},
  recipe_description = {},
  resource = {},
  resource_description = {},
  technology = {},
  technology_description = {}
}

constants.gui_strings = {
  -- internal classes
  {dictionary = "gui", internal = "crafter", localised = {"rb-gui.crafter"}},
  {dictionary = "gui", internal = "fluid", localised = {"rb-gui.fluid"}},
  {dictionary = "gui", internal = "item", localised = {"rb-gui.item"}},
  {dictionary = "gui", internal = "lab", localised = {"rb-gui.lab"}},
  {dictionary = "gui", internal = "offshore_pump", localised = {"rb-gui.offshore-pump"}},
  {dictionary = "gui", internal = "recipe", localised = {"rb-gui.recipe"}},
  {dictionary = "gui", internal = "resource", localised = {"rb-gui.resource"}},
  {dictionary = "gui", internal = "technology", localised = {"rb-gui.technology"}},
  -- captions
  {dictionary = "gui", internal = "hidden_abbrev", localised = {"rb-gui.hidden-abbrev"}},
  {dictionary = "gui", internal = "home_page", localised = {"rb-gui.home-page"}},
  -- tooltips
  {dictionary = "gui", internal = "blueprint_not_available", localised = {"rb-gui.blueprint-not-available"}},
  {dictionary = "gui", internal = "category", localised = {"rb-gui.category"}},
  {
    dictionary = "gui",
    internal = "control_click_to_view_fixed_recipe",
    localised = {"rb-gui.control-click-to-view-fixed-recipe"}
  },
  {dictionary = "gui", internal = "click_to_view", localised = {"rb-gui.click-to-view"}},
  {
    dictionary = "gui",
    internal = "click_to_view_required_fluid",
    localised = {"rb-gui.click-to-view-required-fluid"}
  },
  {dictionary = "gui", internal = "click_to_view_technology", localised = {"rb-gui.click-to-view-technology"}},
  {dictionary = "gui", internal = "crafting_categories", localised = {"rb-gui.crafting-categories"}},
  {dictionary = "gui", internal = "crafting_speed", localised = {"rb-gui.crafting-speed"}},
  {dictionary = "gui", internal = "crafting_time", localised = {"rb-gui.crafting-time"}},
  {dictionary = "gui", internal = "fixed_recipe", localised = {"rb-gui.fixed-recipe"}},
  {dictionary = "gui", internal = "fuel_categories", localised = {"rb-gui.fuel-categories"}},
  {dictionary = "gui", internal = "fuel_category", localised = {"rb-gui.fuel-category"}},
  {dictionary = "gui", internal = "fuel_value", localised = {"rb-gui.fuel-value"}},
  {dictionary = "gui", internal = "hidden", localised = {"rb-gui.hidden"}},
  {dictionary = "gui", internal = "ingredients_tooltip", localised = {"rb-gui.ingredients-tooltip"}},
  {dictionary = "gui", internal = "per_second", localised = {"rb-gui.per-second"}},
  {dictionary = "gui", internal = "products_tooltip", localised = {"rb-gui.products-tooltip"}},
  {dictionary = "gui", internal = "pumping_speed", localised = {"rb-gui.pumping-speed"}},
  {dictionary = "gui", internal = "required_fluid", localised = {"rb-gui.required-fluid"}},
  {dictionary = "gui", internal = "researching_speed", localised = {"rb-gui.researching-speed"}},
  {dictionary = "gui", internal = "rocket_parts_required", localised = {"rb-gui.rocket-parts-required"}},
  {dictionary = "gui", internal = "seconds_standalone", localised = {"rb-gui.seconds-standalone"}},
  {
    dictionary = "gui",
    internal = "shift_click_to_get_blueprint",
    localised = {"rb-gui.shift-click-to-get-blueprint"}
  },
  {
    dictionary = "gui",
    internal = "shift_click_to_view_base_fluid",
    localised = {"rb-gui.shift-click-to-view-base-fluid"}
  },
  {dictionary = "gui", internal = "stack_size", localised = {"rb-gui.stack-size"}},
  {dictionary = "gui", internal = "unresearched", localised = {"rb-gui.unresearched"}}
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
  crafter = true,
  fluid = true,
  item = true,
  recipe = true
}

constants.interface_version = 4

constants.list_box_item_styles = {
  available = "rb_list_box_item",
  unresearched = "rb_unresearched_list_box_item"
}

constants.main_pages = {
  "home",
  "crafter",
  "fluid",
  "item",
  "recipe",
  "search",
  "settings"
}

constants.max_listbox_height = 6

constants.nav_event_properties = {
  ["rb-jump-to-front"] = {action_name = "navigate_forward", shift = true},
  ["rb-navigate-backward"] = {action_name = "navigate_backward"},
  ["rb-navigate-forward"] = {action_name = "navigate_forward"},
  ["rb-return-to-home"] = {action_name = "navigate_backward", shift = true}
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

constants.search_categories = {"crafter", "fluid", "item", "recipe"}

constants.search_categories_lookup = {}
constants.search_categories_localised = {}
for i, category in ipairs(constants.search_categories) do
  constants.search_categories_lookup[category] = i
  constants.search_categories_localised[i] = {"rb-gui."..category}
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
    },
    pause_game_on_open = {
      default_value = false,
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
    show_descriptions = {
      default_value = true,
      has_tooltip = true
    },
    show_detailed_recipe_tooltips = {
      default_value = true,
      has_tooltip = true
    },
    preserve_session = {
      default_value = false,
      has_tooltip = true
    },
    highlight_last_selected = {
      default_value = true,
      has_tooltip = true
    },
    show_made_in_in_quick_ref = {
      default_value = true,
      has_tooltip = false
    }
  },
  search = {
    use_fuzzy_search = {
      default_value = false,
      has_tooltip = true
    },
    use_internal_names = {
      default_value = false,
      has_tooltip = true
    },
    show_fluid_temperatures = {
      default_value = true,
      has_tooltip = true
    },
    show_fluid_temperature_ranges = {
      default_value = true,
      has_tooltip = true
    }
  }
}

return constants
