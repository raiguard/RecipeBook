local table = require("__flib__.table")

local constants = {}

-- Dictionary category -> affects research
-- Anything with `0` as the value will be ignored for research
constants.disabled_recipe_categories = {
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
  ["py-runoff"] = 1,
  ["py-venting"] = 1,
  -- Transport drones
  ["fuel-depot"] = 0,
  ["transport-drone-request"] = 0,
  ["transport-fluid-request"] = 0
}

constants.disabled_groups = {
  -- Editor extensions
  ["ee-tools"] = true
}

constants.class_to_font_glyph = {
  crafter = "D",
  fluid = "B",
  item = "C",
  -- TODO: Add a glyph
  group = "Z",
  lab = "D",
  -- TODO: Add a special glyph?
  offshore_pump = "D",
  -- TODO: Add a glyph
  recipe_category = "Z",
  recipe = "E",
  resource = "F",
  technology = "A"
}

constants.class_to_type = {
  crafter = "entity",
  fluid = "fluid",
  item = "item",
  group = "item-group",
  lab = "entity",
  offshore_pump = "entity",
  recipe_category = false,
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
  ["furnace"] = "crafter",
  ["item-group"] = "group",
  ["item"] = "item",
  ["lab"] = "lab",
  ["offshore-pump"] = "offshore_pump",
  ["recipe-catgory"] = "recipe_category",
  ["recipe"] = "recipe",
  ["rocket-silo"] = "crafter",
  ["technology"] = "technology",
}

constants.empty_translations_table = {
  gui = {},
  crafter = {},
  crafter_description = {},
  fluid = {},
  fluid_description = {},
  group = {},
  group_description = {},
  item = {},
  item_description = {},
  lab = {},
  lab_description = {},
  offshore_pump = {},
  offshore_pump_description = {},
  recipe = {},
  recipe_category = {},
  recipe_category_description = {},
  recipe_description = {},
  resource = {},
  resource_description = {},
  technology = {},
  technology_description = {}
}

constants.global_history_size = 30

constants.gui_strings = {
  {dictionary = "gui", internal = "alt_click", localised = {"gui.rb-alt-click"}},
  {dictionary = "gui", internal = "category", localised = {"gui.rb-category"}},
  {dictionary = "gui", internal = "click", localised = {"gui.rb-click"}},
  {dictionary = "gui", internal = "compatible_recipes", localised = {"gui.rb-compatible-recipes"}},
  {dictionary = "gui", internal = "control_click", localised = {"gui.rb-control-click"}},
  {dictionary = "gui", internal = "crafter", localised = {"gui.rb-crafter"}},
  {dictionary = "gui", internal = "crafting_speed", localised = {"description.crafting-speed"}},
  {dictionary = "gui", internal = "crafting_time_desc", localised = {"gui.rb-crafting-time-desc"}},
  {dictionary = "gui", internal = "crafting_time", localised = {"gui.rb-crafting-time"}},
  {dictionary = "gui", internal = "disabled_abbrev", localised = {"gui.rb-disabled-abbrev"}},
  {dictionary = "gui", internal = "disabled", localised = {"entity-status.disabled"}},
  {dictionary = "gui", internal = "fixed_recipe", localised = {"gui.rb-fixed-recipe"}},
  {dictionary = "gui", internal = "fluid", localised = {"gui.rb-fluid"}},
  {dictionary = "gui", internal = "fluids", localised = {"gui.rb-fluids"}},
  {dictionary = "gui", internal = "format_amount", localised = {"gui.rb-format-amount"}},
  {dictionary = "gui", internal = "format_percent", localised = {"format-percent"}},
  {dictionary = "gui", internal = "format_seconds", localised = {"time-symbol-seconds"}},
  {dictionary = "gui", internal = "format_seconds_parenthesis", localised = {"gui.rb-format-seconds-parenthesis"}},
  {dictionary = "gui", internal = "fuel_pollution", localised = {"description.fuel-pollution"}},
  {dictionary = "gui", internal = "fuel_value", localised = {"description.fuel-value"}},
  {dictionary = "gui", internal = "get_blueprint", localised = {"gui.rb-get-blueprint"}},
  {dictionary = "gui", internal = "go_backward", localised = {"gui.rb-go-backward"}},
  {dictionary = "gui", internal = "go_forward", localised = {"gui.rb-go-forward"}},
  {dictionary = "gui", internal = "go_to_the_back", localised = {"gui.rb-go-to-the-back"}},
  {dictionary = "gui", internal = "go_to_the_front", localised = {"gui.rb-go-to-the-front"}},
  {dictionary = "gui", internal = "group", localised = {"gui.rb-group"}},
  {dictionary = "gui", internal = "hidden_abbrev", localised = {"gui.rb-hidden-abbrev"}},
  {dictionary = "gui", internal = "hidden", localised = {"gui.rb-hidden"}},
  {dictionary = "gui", internal = "ingredient_in", localised = {"gui.rb-ingredient-in"}},
  {dictionary = "gui", internal = "ingredients", localised = {"gui.rb-ingredients"}},
  {dictionary = "gui", internal = "inputs", localised = {"gui.rb-inputs"}},
  {dictionary = "gui", internal = "item", localised = {"gui.rb-item"}},
  {dictionary = "gui", internal = "items", localised = {"gui.rb-items"}},
  {dictionary = "gui", internal = "lab", localised = {"gui.rb-lab"}},
  {dictionary = "gui", internal = "list_box_label", localised = {"gui.rb-list-box-label"}},
  {dictionary = "gui", internal = "made_in", localised = {"gui.rb-made-in"}},
  {dictionary = "gui", internal = "mined_from", localised = {"gui.rb-mined-from"}},
  {dictionary = "gui", internal = "offshore_pump", localised = {"gui.rb-offshore-pump"}},
  {dictionary = "gui", internal = "open_in_technology_window", localised = {"gui.rb-open-in-technology-window"}},
  {dictionary = "gui", internal = "per_second_suffix", localised = {"gui.rb-per-second-suffix"}},
  {dictionary = "gui", internal = "placeable_by", localised = {"gui.rb-placeable-by"}},
  {dictionary = "gui", internal = "place_result", localised = {"gui.rb-place-result"}},
  {dictionary = "gui", internal = "prerequisite_of", localised = {"gui.rb-prerequisite-of"}},
  {dictionary = "gui", internal = "prerequisites", localised = {"gui.rb-prerequisites"}},
  {dictionary = "gui", internal = "product_of", localised = {"gui.rb-product-of"}},
  {dictionary = "gui", internal = "products", localised = {"gui.rb-products"}},
  {dictionary = "gui", internal = "pumped_by", localised = {"gui.rb-pumped-by"}},
  {dictionary = "gui", internal = "pumping_speed", localised = {"description.pumping-speed"}},
  {dictionary = "gui", internal = "recipe_categories", localised = {"gui.rb-recipe-categories"}},
  {dictionary = "gui", internal = "recipe_category", localised = {"gui.rb-recipe-category"}},
  {dictionary = "gui", internal = "recipe", localised = {"gui.rb-recipe"}},
  {dictionary = "gui", internal = "recipes", localised = {"gui.rb-recipes"}},
  {dictionary = "gui", internal = "required_units", localised = {"gui.rb-required-units"}},
  {dictionary = "gui", internal = "researched_in", localised = {"gui.rb-researched-in"}},
  {dictionary = "gui", internal = "research_ingredients_per_unit", localised = {"gui.rb-research-ingredients-per-unit"}},
  {dictionary = "gui", internal = "research_speed_desc", localised = {"gui.rb-research-speed-desc"}},
  {dictionary = "gui", internal = "research_speed", localised = {"description.research-speed"}},
  {dictionary = "gui", internal = "resource", localised = {"gui.rb-resource"}},
  {dictionary = "gui", internal = "rocket_launch_payloads", localised = {"gui.rb-rocket-launch-payloads"}},
  {dictionary = "gui", internal = "rocket_launch_products", localised = {"gui.rb-rocket-launch-products"}},
  {dictionary = "gui", internal = "rocket_parts_required", localised = {"gui.rb-rocket-parts-required"}},
  {dictionary = "gui", internal = "session_history", localised = {"gui.rb-session-history"}},
  {dictionary = "gui", internal = "shift_click", localised = {"gui.rb-shift-click"}},
  {dictionary = "gui", internal = "si_joule", localised = {"si-unit-symbol-joule"}},
  {dictionary = "gui", internal = "stack_size", localised = {"gui.rb-stack-size"}},
  {dictionary = "gui", internal = "technology", localised = {"gui.rb-technology"}},
  {dictionary = "gui", internal = "temperatures", localised = {"gui.rb-temperatures"}},
  {dictionary = "gui", internal = "time_per_unit_desc", localised = {"gui.rb-time-per-unit-desc"}},
  {dictionary = "gui", internal = "time_per_unit", localised = {"gui.rb-time-per-unit"}},
  {dictionary = "gui", internal = "toggle_completed", localised = {"gui.rb-toggle-completed"}},
  {dictionary = "gui", internal = "unlocked_by", localised = {"gui.rb-unlocked-by"}},
  {dictionary = "gui", internal = "unlocks_fluids", localised = {"gui.rb-unlocks-fluids"}},
  {dictionary = "gui", internal = "unlocks_items", localised = {"gui.rb-unlocks-items"}},
  {dictionary = "gui", internal = "unlocks_recipes", localised = {"gui.rb-unlocks-recipes"}},
  {dictionary = "gui", internal = "unresearched", localised = {"gui.rb-unresearched"}},
  {dictionary = "gui", internal = "vehicle_acceleration", localised = {"description.fuel-acceleration"}},
  {dictionary = "gui", internal = "vehicle_top_speed", localised = {"description.fuel-top-speed"}},
  {dictionary = "gui", internal = "view_base_fluid", localised = {"gui.rb-view-base-fluid"}},
  {dictionary = "gui", internal = "view_details", localised = {"gui.rb-view-details"}},
  {dictionary = "gui", internal = "view_fixed_recipe", localised = {"gui.rb-view-fixed-recipe"}},
  {dictionary = "gui", internal = "view_fluid", localised = {"gui.rb-view-fluid"}},
  {dictionary = "gui", internal = "view_required_fluid", localised = {"gui.rb-view-required-fluid"}},
  {dictionary = "gui", internal = "view_technology", localised = {"gui.rb-view-technology"}},
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
    {
      modifiers = {"shift"},
      action = "view_source",
      label = "view_base_fluid",
      source = "base_fluid"
    }
  },
  item = {
    {modifiers = {}, action = "view_details"}
  },
  group = {
    {modifiers = {}, action = "view_details"}
  },
  lab = {
    {modifiers = {}, action = "view_details"}
  },
  offshore_pump = {
    {modifiers = {}, action = "view_details"},
    {
      modifiers = {"shift"},
      action = "view_source",
      label = "view_fluid",
      source = "fluid"
    }
  },
  recipe_category = {
    {modifiers = {}, action = "view_details"}
  },
  recipe = {
    {modifiers = {}, action = "view_details"}
  },
  resource = {
    {
      modifiers = {},
      action = "view_source",
      label = "view_required_fluid",
      source = "required_fluid"
    }
  },
  technology = {
    {modifiers = {}, action = "view_details"},
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

constants.list_box_item_styles = {
  available = "rb_list_box_item",
  unresearched = "rb_unresearched_list_box_item"
}

constants.max_listbox_height = 8

constants.nav_event_properties = {
  ["rb-jump-to-front"] = {action_name = "navigate_forward", shift = true},
  ["rb-navigate-backward"] = {action_name = "navigate_backward"},
  ["rb-navigate-forward"] = {action_name = "navigate_forward"},
  ["rb-return-to-home"] = {action_name = "navigate_backward", shift = true}
}

constants.pages = {
  crafter = {
    {type = "table", rows = {
      {type = "plain", source = "crafting_speed", formatter = "number"},
      {type = "goto", source = "fixed_recipe", options = {hide_glyph = true}},
      {type = "plain", source = "rocket_parts_required", formatter = "number"}
    }},
    {type = "list_box", source = "compatible_recipes", max_rows = 10},
    -- TODO: Make invisible by default
    {type = "list_box", source = "recipe_categories"},
    {type = "list_box", source = "unlocked_by"},
    {type = "list_box", source = "placeable_by"}
  },
  fluid = {
    {type = "table", rows = {
      {type = "plain", source = "fuel_value", formatter = "fuel_value"},
      {type = "goto", source = "group", options = {hide_glyph = true}},
    }},
    {type = "list_box", source = "ingredient_in"},
    {type = "list_box", source = "product_of"},
    {type = "list_box", source = "mined_from"},
    {type = "list_box", source = "pumped_by"},
    {type = "list_box", source = "unlocked_by"},
    {type = "list_box", source = "temperatures", use_pairs = true}
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
      {type = "goto", source = "group", options = {hide_glyph = true}},
      {type = "goto", source = "place_result"}
    }},
    {type = "list_box", source = "ingredient_in"},
    {type = "list_box", source = "product_of"},
    {type = "list_box", source = "rocket_launch_payloads"},
    {type = "list_box", source = "rocket_launch_products"},
    {type = "list_box", source = "mined_from"},
    {type = "list_box", source = "researched_in"},
    {type = "list_box", source = "unlocked_by"}
  },
  lab = {
    {type = "table", rows = {
      {
        type = "plain",
        source = "researching_speed",
        label = "research_speed",
        label_tooltip = "research_speed_desc",
        formatter = "number"
      }
    }},
    {type = "list_box", source = "inputs"},
    {type = "list_box", source = "unlocked_by"},
    {type = "list_box", source = "placeable_by"}
  },
  offshore_pump = {
    {type = "table", rows = {
      {type ="plain", source = "pumping_speed", formatter = "per_second"},
      {type = "goto", source = "fluid", options = {always_show = true, hide_glyph = true}},
    }},
    {type = "list_box", source = "unlocked_by"},
    {type = "list_box", source = "placeable_by"}
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
        formatter = "seconds_from_ticks"
      },
    }},
    {type = "list_box", source = "ingredients", always_show = true},
    {type = "list_box", source = "products", always_show = true},
    {type = "list_box", source = "made_in"},
    {type = "list_box", source = "unlocked_by"}
  },
  technology = {
    {type = "table", rows = {
      {type = "plain", source = "research_unit_count", label = "required_units", formatter = "number"},
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
    {type = "list_box", source = "unlocks_recipes"},
    {type = "list_box", source = "prerequisites"},
    {type = "list_box", source = "prerequisite_of"}
  }
}

constants.search_results_limit = 150

constants.session_history_size = 20

-- TODO: Redo entire settings functionality
constants.settings = {
  interface = {
    show_hidden = {
      default_value = false,
      has_tooltip = true
    },
    show_unresearched = {
      default_value = true,
      has_tooltip = true
    },
    show_disabled = {
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
    use_internal_names = {
      default_value = false,
      has_tooltip = true
    },
    show_descriptions = {
      default_value = true,
      has_tooltip = true
    },
    show_detailed_tooltips = {
      default_value = true,
      has_tooltip = true
    },
    show_interaction_helps = {
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

constants.tooltips = {
  crafter = {
    {type = "plain", source = "crafting_speed", formatter = "number"},
    {type = "plain", source = "fixed_recipe", formatter = "object", options = {hide_glyph = true, label_only = true}},
    {type = "plain", source = "rocket_parts_required", formatter = "number"},
    {
      type = "list",
      source = "recipe_categories",
      formatter = "object",
      options = {hide_glyph = true, label_only = true}
    }
  },
  fluid = {
    {type = "plain", source = "fuel_value", formatter = "fuel_value"},
    {type = "plain", source = "group", formatter = "object", options = {hide_glyph = true, label_only = true}}
  },
  group = {},
  item = {
    {type = "plain", source = "stack_size", formatter = "number"},
    {type = "plain", source = "fuel_value", formatter = "fuel_value"},
    {type = "plain", source = "fuel_emissions_multiplier", label = "fuel_pollution", formatter = "percent"},
    {type = "plain", source = "fuel_acceleration_multiplier", label = "vehicle_acceleration", formatter = "percent"},
    {type = "plain", source = "fuel_top_speed_multiplier", label = "vehicle_top_speed", formatter = "percent"},
    {type = "plain", source = "group", formatter = "object", options = {hide_glyph = true, label_only = true}},
  },
  lab = {
    {type = "plain", source = "research_speed", formatter = "number"},
    {type = "list", source = "inputs", formatter = "object", options = {hide_glyph = true, label_only = true}}
  },
  offshore_pump = {
    {type = "plain", source = "pumping_speed", formatter = "per_second"},
    {
      type = "plain",
      source = "fluid",
      formatter = "object",
      options = {always_show = true, label_only = true, hide_glyph = true}
    }
  },
  recipe_category = {},
  recipe = {
    {
      type = "plain",
      source = "recipe_category",
      formatter = "object",
      options = {hide_glyph = true, label_only = true}
    },
    {type = "plain", source = "group", formatter = "object", options = {hide_glyph = true, label_only = true}},
    {type = "plain", source = "energy", label = "crafting_time", formatter = "seconds_from_ticks"},
    {type = "list", source = "ingredients", formatter = "object", options = {always_show = true}},
    {type = "list", source = "products", formatter = "object", options = {always_show = true}}
  },
  resource = {
    {type = "plain", source = "required_fluid", formatter = "object", options = {always_show = true, hide_glyph = true}}
  },
  technology = {
    {type = "plain", source = "research_unit_count", label = "required_units", formatter = "number"},
    {type = "plain", source = "research_unit_energy", label = "time_per_unit", formatter = "seconds_from_ticks"},
    {type = "list", source = "research_ingredients_per_unit", formatter = "object", options = {always_show = true}}
  }
}

return constants
