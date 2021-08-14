local table = require("__flib__.table")

local constants = {}

constants.category_classes = {
  "fuel_category",
  "group",
  "recipe_category",
  "resource_category",
}

constants.category_class_plurals = {
  fuel_category = "fuel_categories",
  group = "groups",
  recipe_category = "recipe_categories",
  resource_category = "resource_categories",
}

constants.classes = {
  "crafter",
  "fluid",
  "fuel_category",
  "group",
  "item",
  "lab",
  "mining_drill",
  "offshore_pump",
  "recipe",
  "recipe_category",
  "resource",
  "resource_category",
  "technology",
}

constants.class_to_font_glyph = {
  crafter = "E",
  fluid = "B",
  fuel_category = "G",
  group = "G",
  item = "C",
  lab = "D",
  mining_drill = "E",
  offshore_pump = "E",
  recipe_category = "G",
  recipe = "D",
  resource_category = "G",
  resource = "F",
  technology = "A"
}

constants.class_to_type = {
  crafter = "entity",
  fluid = "fluid",
  fuel_category = false,
  group = "item-group",
  item = "item",
  lab = "entity",
  mining_drill = "entity",
  offshore_pump = "entity",
  recipe_category = false,
  recipe = "recipe",
  resource_category = false,
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
  invisible = {
    str = "0, 0, 0, 0",
    tbl = {0, 0, 0, 0}
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

constants.default_max_rows = 8

constants.derived_type_to_class = {
  ["assembling-machine"] = "crafter",
  ["fluid"] = "fluid",
  ["fuel-category"] = "fuel_category",
  ["furnace"] = "crafter",
  ["item-group"] = "group",
  ["item"] = "item",
  ["lab"] = "lab",
  ["mining-drill"] = "mining_drill",
  ["offshore-pump"] = "offshore_pump",
  ["recipe-catgory"] = "recipe_category",
  ["recipe"] = "recipe",
  ["resource-catgory"] = "resource_category",
  ["resource"] = "resource",
  ["rocket-silo"] = "crafter",
  ["technology"] = "technology",
}

constants.disabled_categories = {
  fuel_category = {},
  group = {
    -- Editor extensions
    ["ee-tools"] = true
  },
  -- Dictionary category -> modifier
  -- `0` - Disabled by default, does not affect object availability
  -- `1` - Disabled by default
  recipe_category = {
    -- Creative mod
    ["creative-mod_free-fluids"] = 1,
    ["creative-mod_energy-absorption"] = 1,
    -- Editor extensions
    ["ee-testing-tool"] = 1,
    -- Deep storage unit
    ["deep-storage-item"] = 0,
    ["deep-storage-fluid"] = 0,
    ["deep-storage-item-big"] = 0,
    ["deep-storage-fluid-big"] = 0,
    ["deep-storage-item-mk2/3"] = 0,
    ["deep-storage-fluid-mk2/3"] = 0,
    -- Krastorio 2
    ["void-crushing"] = 0, -- This doesn't actually exist yet, but will soon!
    -- Mining drones
    ["mining-depot"] = 0,
    -- Pyanodon's
    ["py-incineration"] = 1,
    ["py-runoff"] = 1,
    ["py-venting"] = 1,
    -- Transport drones
    ["fuel-depot"] = 0,
    ["transport-drone-request"] = 0,
    ["transport-fluid-request"] = 0
  },
  resource_category = {}
}

constants.fake_fluid_fuel_category = "burnable-fluid"

constants.general_settings = {
  content = {
    show_disabled = {
      type = "bool",
      has_tooltip = true,
      default_value = false,
    },
    show_hidden = {
      type = "bool",
      has_tooltip = true,
      default_value = false,
    },
    show_unresearched = {
      type = "bool",
      has_tooltip = false,
      default_value = true,
    },
    show_made_in_in_quick_ref = {
      type = "bool",
      has_tooltip = false,
      default_value = false,
    },
  },
  captions = {
    show_internal_names = {
      type = "bool",
      has_tooltip = true,
      default_value = false,
    },
    show_glyphs = {
      type = "bool",
      has_tooltip = false,
      default_value = true,
    }
  },
  tooltips = {
    show_alternate_name = {
      type = "bool",
      has_tooltip = true,
      default_value = false,
    },
    show_descriptions = {
      type = "bool",
      has_tooltip = false,
      default_value = true,
    },
    show_detailed_tooltips = {
      type = "bool",
      has_tooltip = true,
      default_value = true,
    },
    show_interaction_helps = {
      type = "bool",
      has_tooltip = false,
      default_value = true,
    },
  },
  search = {
    fuzzy_search = {
      type = "bool",
      has_tooltip = true,
      default_value = false,
    },
    close_search_gui_after_selection = {
      type = "bool",
      has_tooltip = false,
      default_value = false,
    },
    show_fluid_temperatures = {
      type = "enum",
      options = {
        "off",
        "absolute_only",
        "all",
      },
      has_tooltip = true,
      default_value = "all",
    },
    search_type = {
      type = "enum",
      options = {
        "localised",
        "internal",
        "both",
      },
      has_tooltip = true,
      default_value = "localised",
    },
  },
}

constants.global_history_size = 30

constants.gui_sizes = {
  en = {
    search_width = 276,
  },
  ru = {
    search_width = 279,
  },
}

constants.gui_strings = {
  alt_click = {"gui.rb-alt-click"},
  burned_in = {"gui.rb-burned-in"},
  captions = {"gui.rb-captions"},
  category = {"gui.rb-category"},
  click = {"gui.rb-click"},
  close_search_gui_after_selection = {"gui.rb-close-search-gui-after-selection"},
  close_search_when_moving_info_pages = {"gui.rb-close-search-when-moving-info-pages"},
  compatible_fuels = {"gui.rb-compatible-fuels"},
  compatible_mining_drills = {"gui.rb-compatible-mining-drills"},
  compatible_modules = {"gui.rb-compatible-modules"},
  compatible_recipes = {"gui.rb-compatible-recipes"},
  compatible_resources = {"gui.rb-compatible-resources"},
  consumption_bonus = {"description.consumption-bonus"},
  content = {"gui.rb-content"},
  control_click = {"gui.rb-control-click"},
  crafter = {"gui.rb-crafter"},
  crafting_speed = {"description.crafting-speed"},
  crafting_time_desc = {"gui.rb-crafting-time-desc"},
  crafting_time = {"gui.rb-crafting-time"},
  default_temperature = {"gui.rb-default-temperature"},
  disabled_abbrev = {"gui.rb-disabled-abbrev"},
  disabled = {"entity-status.disabled"},
  fixed_recipe = {"gui.rb-fixed-recipe"},
  fluid = {"gui.rb-fluid"},
  fluids = {"gui.rb-fluids"},
  format_amount = {"gui.rb-format-amount"},
  format_area = {"gui.rb-format-area"},
  format_degrees = {"format-degrees-c-compact"},
  format_percent = {"format-percent"},
  format_seconds_parenthesis = {"gui.rb-format-seconds-parenthesis"},
  format_seconds = {"time-symbol-seconds"},
  fuel_categories = {"gui.rb-fuel-categories"},
  fuel_category = {"gui.rb-fuel-category"},
  fuel_pollution = {"description.fuel-pollution"},
  fuel_value = {"description.fuel-value"},
  fuzzy_search = {"gui.rb-fuzzy-search"},
  get_blueprint = {"gui.rb-get-blueprint"},
  go_backward = {"gui.rb-go-backward"},
  go_forward = {"gui.rb-go-forward"},
  go_to_the_back = {"gui.rb-go-to-the-back"},
  go_to_the_front = {"gui.rb-go-to-the-front"},
  group = {"gui.rb-group"},
  hidden_abbrev = {"gui.rb-hidden-abbrev"},
  hidden = {"gui.rb-hidden"},
  ingredient_in = {"gui.rb-ingredient-in"},
  ingredient_limit = {"gui.rb-ingredient-limit"},
  ingredients = {"gui.rb-ingredients"},
  inputs = {"gui.rb-inputs"},
  item = {"gui.rb-item"},
  items = {"gui.rb-items"},
  lab = {"gui.rb-lab"},
  list_box_label = {"gui.rb-list-box-label"},
  made_in = {"gui.rb-made-in"},
  middle_click = {"gui.rb-middle-click"},
  mined_from = {"gui.rb-mined-from"},
  mining_area = {"gui.rb-mining-area"},
  mining_drill = {"gui.rb-mining-drill"},
  mining_drills = {"gui.rb-mining-drills"},
  mining_speed = {"gui.rb-mining-speed"},
  mining_time = {"gui.rb-mining-time"},
  module_effects = {"gui.rb-module-effects"},
  modules = {"gui.rb-modules"},
  offshore_pump = {"gui.rb-offshore-pump"},
  open_in_technology_window = {"gui.rb-open-in-technology-window"},
  per_second_suffix = {"gui.rb-per-second-suffix"},
  placed_by = {"gui.rb-placed-by"},
  place_result = {"gui.rb-place-result"},
  pollution_bonus = {"description.pollution-bonus"},
  prerequisite_of = {"gui.rb-prerequisite-of"},
  prerequisites = {"gui.rb-prerequisites"},
  preserve_search_query = {"gui.rb-preserve-search-query"},
  productivity_bonus = {"description.productivity-bonus"},
  product_of = {"gui.rb-product-of"},
  products = {"gui.rb-products"},
  pumped_by = {"gui.rb-pumped-by"},
  pumping_speed = {"description.pumping-speed"},
  recipe_categories = {"gui.rb-recipe-categories"},
  recipe_category = {"gui.rb-recipe-category"},
  recipe = {"gui.rb-recipe"},
  recipes = {"gui.rb-recipes"},
  required_fluid = {"gui.rb-required-fluid"},
  required_units = {"gui.rb-required-units"},
  researched_in = {"gui.rb-researched-in"},
  research_ingredients_per_unit = {"gui.rb-research-ingredients-per-unit"},
  research_speed_desc = {"gui.rb-research-speed-desc"},
  research_speed = {"description.research-speed"},
  resource_categories = {"gui.rb-resource-categories"},
  resource_category = {"gui.rb-resource-category"},
  resource = {"gui.rb-resource"},
  resources = {"gui.rb-resources"},
  rocket_launch_payloads = {"gui.rb-rocket-launch-payloads"},
  rocket_launch_products = {"gui.rb-rocket-launch-products"},
  rocket_parts_required = {"gui.rb-rocket-parts-required"},
  search_gui_location = {"gui.rb-search-gui-location"},
  search = {"gui.rb-search"},
  search_type = {"gui.rb-search-type"},
  session_history = {"gui.rb-session-history"},
  shift_click = {"gui.rb-shift-click"},
  show_alternate_name = {"gui.rb-show-alternate-name"},
  show_descriptions = {"gui.rb-show-descriptions"},
  show_detailed_tooltips = {"gui.rb-show-detailed-tooltips"},
  show_disabled = {"gui.rb-show-disabled"},
  show_fluid_temperatures = {"gui.rb-show-fluid-temperatures"},
  show_glyphs = {"gui.rb-show-glyphs"},
  show_hidden = {"gui.rb-show-hidden"},
  show_interaction_helps = {"gui.rb-show-interaction-helps"},
  show_internal_names = {"gui.rb-show-internal-names"},
  show_made_in_in_quick_ref = {"gui.rb-show-made-in-in-quick-ref"},
  show_unresearched = {"gui.rb-show-unresearched"},
  si_joule = {"si-unit-symbol-joule"},
  size = {"gui.rb-size"},
  speed_bonus = {"description.speed-bonus"},
  stack_size = {"gui.rb-stack-size"},
  tech_level_desc = {"gui.rb-tech-level-desc"},
  tech_level = {"gui.rb-tech-level"},
  technology = {"gui.rb-technology"},
  temperatures = {"gui.rb-temperatures"},
  time_per_unit_desc = {"gui.rb-time-per-unit-desc"},
  time_per_unit = {"gui.rb-time-per-unit"},
  toggle_completed = {"gui.rb-toggle-completed"},
  tooltips = {"gui.rb-tooltips"},
  unlocked_by = {"gui.rb-unlocked-by"},
  unlocks_fluids = {"gui.rb-unlocks-fluids"},
  unlocks_items = {"gui.rb-unlocks-items"},
  unlocks_machines = {"gui.rb-unlocks-machines"},
  unlocks_recipes = {"gui.rb-unlocks-recipes"},
  unresearched = {"gui.rb-unresearched"},
  vehicle_acceleration = {"description.fuel-acceleration"},
  vehicle_top_speed = {"description.fuel-top-speed"},
  view_base_fluid = {"gui.rb-view-base-fluid"},
  view_details = {"gui.rb-view-details"},
  view_details_in_new_window = {"gui.rb-view-details-in-new-window"},
  view_fixed_recipe = {"gui.rb-view-fixed-recipe"},
  view_fluid = {"gui.rb-view-fluid"},
  view_required_fluid = {"gui.rb-view-required-fluid"},
  view_technology = {"gui.rb-view-technology"},
}

constants.header_button_tooltips = {
  quick_ref_button = {
    selected = {"gui.rb-close-quick-ref-window"},
    unselected = {"gui.rb-open-quick-ref-window"}
  },
  favorite_button = {
    selected = {"gui.rb-remove-from-favorites"},
    unselected = {"gui.rb-add-to-favorites"}
  },
}

-- NOTE: Modifiers must be in the order of "control", "shift", "alt" for those that are present
constants.interactions = {
  crafter = {
    {modifiers = {}, action = "view_details"},
    {button = "middle", modifiers = {}, action = "view_details_in_new_window"},
    {
      modifiers = {"shift"},
      action = "get_blueprint",
      test = function(obj_data, options)
        return options.blueprint_recipe and obj_data.blueprintable
      end
    },
    {
      modifiers = {"control"},
      action = "view_source",
      label = "view_fixed_recipe",
      source = "fixed_recipe",
      force_label = true
    }
  },
  fluid = {
    {modifiers = {}, action = "view_details"},
    {button = "middle", modifiers = {}, action = "view_details_in_new_window"},
    {
      modifiers = {"shift"},
      action = "view_source",
      label = "view_base_fluid",
      source = "base_fluid"
    }
  },
  fuel_category = {
    {modifiers = {}, action = "view_details"},
    {button = "middle", modifiers = {}, action = "view_details_in_new_window"},
  },
  item = {
    {modifiers = {}, action = "view_details"},
    {button = "middle", modifiers = {}, action = "view_details_in_new_window"},
  },
  group = {
    {modifiers = {}, action = "view_details"},
    {button = "middle", modifiers = {}, action = "view_details_in_new_window"},
  },
  lab = {
    {modifiers = {}, action = "view_details"},
    {button = "middle", modifiers = {}, action = "view_details_in_new_window"},
  },
  mining_drill = {
    {modifiers = {}, action = "view_details"},
    {button = "middle", modifiers = {}, action = "view_details_in_new_window"},
  },
  offshore_pump = {
    {modifiers = {}, action = "view_details"},
    {button = "middle", modifiers = {}, action = "view_details_in_new_window"},
    {
      modifiers = {"shift"},
      action = "view_source",
      label = "view_fluid",
      source = "fluid"
    }
  },
  recipe_category = {
    {modifiers = {}, action = "view_details"},
    {button = "middle", modifiers = {}, action = "view_details_in_new_window"},
  },
  recipe = {
    {modifiers = {}, action = "view_details"},
    {button = "middle", modifiers = {}, action = "view_details_in_new_window"},
  },
  resource = {
    {modifiers = {}, action = "view_details"},
    {button = "middle", modifiers = {}, action = "view_details_in_new_window"},
    {
      modifiers = {"shift"},
      action = "view_source",
      label = "view_required_fluid",
      source = "required_fluid"
    }
  },
  resource_category = {
    {modifiers = {}, action = "view_details"},
    {button = "middle", modifiers = {}, action = "view_details_in_new_window"},
  },
  technology = {
    {modifiers = {}, action = "view_details"},
    {button = "middle", modifiers = {}, action = "view_details_in_new_window"},
    {modifiers = {"shift"}, action = "open_in_technology_window"}
  }
}

constants.input_sanitizers = {
  ["%%"] = "%%%%",
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

constants.interface_version = 4

constants.machine_classes = {
  "crafter",
  "lab",
  "mining_drill",
  -- "offshore_pump",
}
constants.machine_classes_lookup = table.invert(constants.machine_classes)

constants.nav_event_properties = {
  ["rb-jump-to-front"] = {delta = 1, shift = true},
  ["rb-navigate-backward"] = {delta = -1},
  ["rb-navigate-forward"] = {delta = 1},
  ["rb-return-to-home"] = {delta = -1, shift = true}
}

constants.pages = {
  crafter = {
    {type = "table", rows = {
      {type = "plain", source = "crafting_speed", formatter = "number"},
      {type = "goto", source = "fixed_recipe", options = {always_show = true, hide_glyph = true}},
      {type = "plain", source = "rocket_parts_required", formatter = "number"},
      {type = "plain", source = "ingredient_limit", formatter = "number"},
      {type = "plain", source = "size", formatter = "area"},
    }},
    {type = "list_box", source = "compatible_recipes", max_rows = 10},
    {type = "list_box", source = "recipe_categories"},
    {type = "list_box", source = "compatible_fuels"},
    {type = "list_box", source = "fuel_categories"},
    {type = "list_box", source = "unlocked_by"},
    {type = "list_box", source = "placed_by"}
  },
  fluid = {
    {type = "table", rows = {
      {type = "plain", source = "default_temperature", formatter = "temperature"},
      {type = "plain", source = "fuel_value", formatter = "fuel_value"},
      {type = "goto", source = "fuel_category", options = {hide_glyph = true}},
      {type = "goto", source = "group", options = {hide_glyph = true}},
    }},
    {type = "list_box", source = "ingredient_in"},
    {type = "list_box", source = "product_of"},
    {type = "list_box", source = "mined_from"},
    {type = "list_box", source = "pumped_by"},
    {type = "list_box", source = "burned_in"},
    {type = "list_box", source = "unlocked_by"},
    {type = "list_box", source = "temperatures", use_pairs = true}
  },
  fuel_category = {
    {type = "list_box", source = "fluids"},
    {type = "list_box", source = "items"},
  },
  group = {
    {type = "list_box", source = "fluids"},
    {type = "list_box", source = "items"},
    {type = "list_box", source = "recipes"}
  },
  item = {
    {type = "table", rows = {
      {type = "plain", source = "stack_size", formatter = "number"},
      {type = "plain", source = "fuel_value", formatter = "fuel_value"},
      {
        type = "plain",
        source = "fuel_emissions_multiplier",
        label = "fuel_pollution",
        formatter = "percent"
      },
      {
        type = "plain",
        source = "fuel_acceleration_multiplier",
        label = "vehicle_acceleration",
        formatter = "percent"
      },
      {
        type = "plain",
        source = "fuel_top_speed_multiplier",
        label = "vehicle_top_speed",
        formatter = "percent"
      },
      {type = "goto", source = "fuel_category", options = {hide_glyph = true}},
      {type = "goto", source = "group", options = {hide_glyph = true}},
      {type = "goto", source = "place_result"},
    }},
    {type = "table", source = "module_effects"},
    {type = "list_box", source = "ingredient_in"},
    {type = "list_box", source = "product_of"},
    {type = "list_box", source = "rocket_launch_payloads"},
    {type = "list_box", source = "rocket_launch_products"},
    {type = "list_box", source = "mined_from"},
    {type = "list_box", source = "researched_in"},
    {type = "list_box", source = "burned_in"},
    {type = "list_box", source = "unlocked_by"},
  },
  lab = {
    {type = "table", rows = {
      {
        type = "plain",
        source = "researching_speed",
        label = "research_speed",
        label_tooltip = "research_speed_desc",
        formatter = "number"
      },
      {type = "plain", source = "size", formatter = "area"},
    }},
    {type = "list_box", source = "inputs"},
    {type = "list_box", source = "compatible_fuels"},
    {type = "list_box", source = "fuel_categories"},
    {type = "list_box", source = "unlocked_by"},
    {type = "list_box", source = "placed_by"}
  },
  mining_drill = {
    {type = "table", rows = {
      {type = "plain", source = "mining_speed", formatter = "per_second"},
      {type = "plain", source = "mining_area", formatter = "area"},
      {type = "plain", source = "size", formatter = "area"},
    }},
    {type = "list_box", source = "compatible_resources"},
    {type = "list_box", source = "resource_categories"},
    {type = "list_box", source = "compatible_fuels"},
    {type = "list_box", source = "fuel_categories"},
    {type = "list_box", source = "unlocked_by"},
    {type = "list_box", source = "placed_by"}
  },
  offshore_pump = {
    {type = "table", rows = {
      {type ="plain", source = "pumping_speed", formatter = "per_second"},
      {type = "goto", source = "fluid", options = {always_show = true, hide_glyph = true}},
      {type = "plain", source = "size", formatter = "area"},
    }},
    {type = "list_box", source = "unlocked_by"},
    {type = "list_box", source = "placed_by"}
  },
  recipe_category = {
    {type = "list_box", source = "fluids"},
    {type = "list_box", source = "items"},
    {type = "list_box", source = "recipes"},
  },
  recipe = {
    {type = "table", rows = {
      {type = "goto", source = "recipe_category", options = {hide_glyph = true}},
      {type = "goto", source = "group", options = {hide_glyph = true}},
      {
        type = "plain",
        source = "energy",
        label = "crafting_time",
        label_tooltip = "crafting_time_desc",
        formatter = "seconds_from_ticks",
      },
    }},
    {type = "list_box", source = "ingredients", always_show = true},
    {type = "list_box", source = "products", always_show = true},
    {type = "list_box", source = "made_in"},
    {type = "list_box", source = "unlocked_by"},
    {type = "list_box", source = "compatible_modules"},
  },
  resource = {
    {type = "table", rows = {
      {type = "goto", source = "resource_category", options = {always_show = true, hide_glyph = true}},
      {type = "goto", source = "required_fluid", options = {always_show = true, hide_glyph = true}},
      {type = "plain", source = "mining_time", formatter = "seconds_from_ticks"}
    }},
    {type = "list_box", source = "products"},
    {type = "list_box", source = "compatible_mining_drills"}
  },
  resource_category = {
    {type = "list_box", source = "resources"},
    {type = "list_box", source = "mining_drills"}
  },
  technology = {
    {type = "table", rows = {
      {type = "plain", source = "research_unit_count", label = "required_units", formatter = "number"},
      {
        type = "tech_level_selector",
        source = "research_unit_count_formula",
        label = "tech_level",
        label_tooltip = "tech_level_desc"
      },
      {
        type = "tech_level_research_unit_count",
        source = "research_unit_count_formula",
        label = "required_units",
        formatter = "number"
      },
      {
        type = "plain",
        source = "research_unit_energy",
        label = "time_per_unit",
        label_tooltip = "time_per_unit_desc",
        formatter = "seconds_from_ticks"
      }
    }},
    {type = "list_box", source = "research_ingredients_per_unit"},
    {type = "list_box", source = "unlocks_fluids"},
    {type = "list_box", source = "unlocks_items"},
    {type = "list_box", source = "unlocks_machines"},
    {type = "list_box", source = "unlocks_recipes"},
    {type = "list_box", source = "prerequisites"},
    {type = "list_box", source = "prerequisite_of"}
  }
}

constants.prototypes = {}

constants.prototypes.filtered_entities = {
  character = {{filter = "type", type = "character"}},
  crafter = {
    {filter = "type", type = "assembling-machine"},
    {filter = "type", type = "furnace"},
    {filter = "type", type = "rocket-silo"},
  },
  lab = {{filter = "type", type = "lab"}},
  mining_drill = {{filter = "type", type = "mining-drill"}},
  offshore_pump = {{filter = "type", type = "offshore-pump"}},
  resource = {{filter = "type", type = "resource"}},
}

constants.prototypes.straight_conversions = {
  "fluid",
  "fuel_category",
  "item",
  "item_group",
  "module_category",
  "recipe",
  "recipe_category",
  "resource_category",
  "technology",
}

constants.search_results_limit = 500
constants.search_results_visible_items = 15
constants.search_timeout = 30

constants.session_history_size = 20

constants.tooltips = {
  crafter = {
    {type = "plain", source = "crafting_speed", formatter = "number"},
    {type = "plain", source = "fixed_recipe", formatter = "object", options = {hide_glyph = true}},
    {type = "plain", source = "rocket_parts_required", formatter = "number"},
    {type = "plain", source = "ingredient_limit", formatter = "number"},
    {
      type = "list",
      source = "recipe_categories",
      formatter = "object",
      options = {hide_glyph = true}
    }
  },
  fluid = {
    {type = "plain", source = "default_temperature", formatter = "temperature"},
    {type = "plain", source = "fuel_value", formatter = "fuel_value"},
    {type = "plain", source = "fuel_category", formatter = "object", options = {hide_glyph = true}},
    {type = "plain", source = "group", formatter = "object", options = {hide_glyph = true}}
  },
  fuel_category = {},
  group = {},
  item = {
    {type = "plain", source = "stack_size", formatter = "number"},
    {type = "plain", source = "fuel_value", formatter = "fuel_value"},
    {type = "plain", source = "fuel_emissions_multiplier", label = "fuel_pollution", formatter = "percent"},
    {type = "plain", source = "fuel_acceleration_multiplier", label = "vehicle_acceleration", formatter = "percent"},
    {type = "plain", source = "fuel_top_speed_multiplier", label = "vehicle_top_speed", formatter = "percent"},
    {type = "plain", source = "fuel_category", formatter = "object", options = {hide_glyph = true}},
    {type = "plain", source = "group", formatter = "object", options = {hide_glyph = true}},
  },
  lab = {
    {type = "plain", source = "research_speed", formatter = "number"},
    {type = "list", source = "inputs", formatter = "object", options = {hide_glyph = true}}
  },
  mining_drill = {
    {type = "plain", source = "mining_speed", formatter = "per_second"},
    {type = "plain", source = "mining_area", formatter = "area"},
    {type = "list", source = "resource_categories", formatter = "object"}
  },
  offshore_pump = {
    {type = "plain", source = "pumping_speed", formatter = "per_second"},
    {
      type = "plain",
      source = "fluid",
      formatter = "object",
      options = {always_show = true, hide_glyph = true}
    }
  },
  recipe_category = {},
  recipe = {
    {
      type = "plain",
      source = "recipe_category",
      formatter = "object",
      options = {hide_glyph = true}
    },
    {type = "plain", source = "group", formatter = "object", options = {hide_glyph = true}},
    {type = "plain", source = "energy", label = "crafting_time", formatter = "seconds_from_ticks"},
    {type = "list", source = "ingredients", formatter = "object", options = {always_show = true}},
    {type = "list", source = "products", formatter = "object", options = {always_show = true}}
  },
  resource = {
    {
      type = "plain",
      source = "resource_category",
      formatter = "object",
      options = {always_show = true, hide_glyph = true}
    },
    {type = "plain", source = "required_fluid", formatter = "object", options = {always_show = true, hide_glyph = true}},
    {type = "plain", source = "mining_time", formatter = "seconds_from_ticks"},
    {type = "list", source = "products", formatter = "object"}
  },
  resource_category = {},
  technology = {
    {type = "plain", source = "research_unit_count", label = "required_units", formatter = "number"},
    {type = "plain", source = "research_unit_energy", label = "time_per_unit", formatter = "seconds_from_ticks"},
    {type = "list", source = "research_ingredients_per_unit", formatter = "object", options = {always_show = true}}
  }
}

return constants
