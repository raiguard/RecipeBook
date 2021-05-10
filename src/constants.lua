local table = require("__flib__.table")

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
  -- krastorio 2
  ["void-crushing"] = 0, -- this doesn't actually exist yet, but will soon!
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

constants.class_to_titlebar_label = {
  crafter = {"gui.rb-crafter"},
  fluid = {"gui.rb-fluid"},
  item = {"gui.rb-item"},
  lab = {"gui.rb-lab"},
  offshore_pump = {"gui.rb-offshore-pump"},
  recipe = {"gui.rb-recipe"},
  resource = {"gui.rb-resource"},
  technology = {"gui.rb-technology"}
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

constants.type_to_class = {
  ["assembling-machine"] = "crafter",
  ["fluid"] = "fluid",
  ["furnace"] = "crafter",
  ["item"] = "item",
  ["lab"] = "lab",
  ["recipe"] = "recipe",
  ["rocket-silo"] = "crafter",
  ["technology"] = "technology",
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
  {dictionary = "gui", internal = "crafting_categories", localised = {"rb-gui.crafting-categories"}},
  {dictionary = "gui", internal = "crafting_speed", localised = {"rb-gui.crafting-speed"}},
  {dictionary = "gui", internal = "crafting_time", localised = {"rb-gui.crafting-time"}},
  {dictionary = "gui", internal = "disabled_abbrev", localised = {"rb-gui.disabled-abbrev"}},
  {dictionary = "gui", internal = "disabled", localised = {"rb-gui.disabled"}},
  {dictionary = "gui", internal = "fixed_recipe", localised = {"rb-gui.fixed-recipe"}},
  {dictionary = "gui", internal = "fuel_acceleration_multiplier", localised = {"rb-gui.fuel-acceleration-multiplier"}},
  {dictionary = "gui", internal = "fuel_categories", localised = {"rb-gui.fuel-categories"}},
  {dictionary = "gui", internal = "fuel_category", localised = {"rb-gui.fuel-category"}},
  {dictionary = "gui", internal = "fuel_emissions_multiplier", localised = {"rb-gui.fuel-emissions-multiplier"}},
  {dictionary = "gui", internal = "fuel_top_speed_multiplier", localised = {"rb-gui.fuel-top-speed-multiplier"}},
  {dictionary = "gui", internal = "fuel_value", localised = {"rb-gui.fuel-value"}},
  {dictionary = "gui", internal = "hidden", localised = {"rb-gui.hidden"}},
  {dictionary = "gui", internal = "ingredients_tooltip", localised = {"rb-gui.ingredients-tooltip"}},
  {dictionary = "gui", internal = "nav_backward_tooltip", localised = {"gui.rb-nav-backward-tooltip"}},
  {dictionary = "gui", internal = "nav_forward_tooltip", localised = {"gui.rb-nav-forward-tooltip"}},
  {dictionary = "gui", internal = "per_second", localised = {"rb-gui.per-second"}},
  {dictionary = "gui", internal = "products_tooltip", localised = {"rb-gui.products-tooltip"}},
  {dictionary = "gui", internal = "pumping_speed", localised = {"rb-gui.pumping-speed"}},
  {dictionary = "gui", internal = "required_fluid", localised = {"rb-gui.required-fluid"}},
  {
    dictionary = "gui",
    internal = "research_ingredients_per_unit_tooltip",
    localised = {"rb-gui.research-ingredients-per-unit-tooltip"}
  },
  {dictionary = "gui", internal = "research_units_tooltip", localised = {"rb-gui.research-units-tooltip"}},
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
  {
    dictionary = "gui",
    internal = "shift_click_to_view_technology",
    localised = {"rb-gui.shift-click-to-view-technology"}
  },
  {dictionary = "gui", internal = "session_history", localised = {"gui.rb-session-history"}},
  {dictionary = "gui", internal = "stack_size", localised = {"rb-gui.stack-size"}},
  {dictionary = "gui", internal = "unresearched", localised = {"rb-gui.unresearched"}}
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

constants.open_fluid_types = {
  ["fluid-wagon"] = true,
  ["infinity-pipe"] = true,
  ["offshore-pump"] = true,
  ["pipe-to-ground"] = true,
  ["pipe"] = true,
  ["pump"] = true,
  ["storage-tank"] = true
}

constants.pages = {
  crafter = {
    {type = "list_box", source = "compatible_recipes", max_rows = 10},
    {type = "list_box", source = "unlocked_by"},
    {type = "list_box", source = "placeable_by"}
  },
  fluid = {
    {type = "list_box", source = "ingredient_in"},
    {type = "list_box", source = "product_of"},
    {type = "list_box", source = "mined_from"},
    {type = "list_box", source = "pumped_by"},
    {type = "list_box", source = "unlocked_by"},
    {type = "list_box", source = "temperatures", use_pairs = true}
  },
  item = {
    {type = "list_box", source = "ingredient_in"},
    {type = "list_box", source = "product_of"},
    {type = "list_box", source = "rocket_launch_payloads"},
    {type = "list_box", source = "rocket_launch_products"},
    {type = "list_box", source = "mined_from"},
    {type = "list_box", source = "usable_in"},
    {type = "list_box", source = "unlocked_by"}
  },
  lab = {
    {type = "list_box", source = "inputs"},
    {type = "list_box", source = "unlocked_by"},
    {type = "list_box", source = "placeable_by"}
  },
  recipe = {
    {type = "table", rows = {{type = "plain", name = "category"}, {type = "plain", name = "energy"}}},
    {type = "list_box", source = "ingredients", always_show = true},
    {type = "list_box", source = "products", always_show = true},
    {type = "list_box", source = "made_in"},
    {type = "list_box", source = "unlocked_by"}
  },
  technology = {
    {type = "table", rows = {{type = "plain", name = "research_unit_count"}}},
    {type = "list_box", source = "research_ingredients_per_unit"},
    {type = "list_box", source = "unlocks_fluids"},
    {type = "list_box", source = "unlocks_items"},
    {type = "list_box", source = "unlocks_recipes"},
    {type = "list_box", source = "prerequisites"},
    {type = "list_box", source = "prerequisite_of"}
  }
}

constants.search_categories = {"crafter", "fluid", "item", "recipe", "technology"}

constants.search_categories_lookup = {}
constants.search_categories_localised = {}
for i, category in ipairs(constants.search_categories) do
  constants.search_categories_lookup[category] = i
  constants.search_categories_localised[i] = {"rb-gui."..category}
end

constants.search_results_limit = 150

constants.settings = {
  general = {
    open_selected_object = {
      default_value = true,
      has_tooltip = true
    }
  },
  interface = {
    show_hidden = {
      -- FIXME:
      default_value = false,
      has_tooltip = true
    },
    show_unresearched = {
      -- FIXME:
      default_value = true,
      has_tooltip = true
    },
    show_disabled = {
      -- FIXME:
      default_value = true,
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

return constants
