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
  yellow = {
    str = "255, 240, 69",
    tbl = {255, 240, 69}
  },
  unresearched = {
    str = "255, 142, 142",
    tbl = {255, 142, 142}
  }
}

constants.initial_dictionaries = {
  gui = {
    -- classes
    crafter = {"rb-gui.crafter"},
    fluid = {"rb-gui.fluid"},
    item = {"rb-gui.item"},
    lab = {"rb-gui.lab"},
    offshore_pump = {"rb-gui.offshore-pump"},
    recipe = {"rb-gui.recipe"},
    resource = {"rb-gui.resource"},
    technology = {"rb-gui.technology"},
    -- captions
    hidden_abbrev = {"rb-gui.hidden-abbrev"},
    home_page = {"rb-gui.home-page"},
    -- tooltips
    blueprint_not_available = {"rb-gui.blueprint-not-available"},
    category = {"rb-gui.category"},
    control_click_to_view_fixed_recipe = {"rb-gui.control-click-to-view-fixed-recipe"},
    click_to_view = {"rb-gui.click-to-view"},
    click_to_view_required_fluid = {"rb-gui.click-to-view-required-fluid"},
    crafting_categories = {"rb-gui.crafting-categories"},
    crafting_speed = {"rb-gui.crafting-speed"},
    crafting_time = {"rb-gui.crafting-time"},
    disabled_abbrev = {"rb-gui.disabled-abbrev"},
    disabled = {"rb-gui.disabled"},
    fixed_recipe = {"rb-gui.fixed-recipe"},
    fuel_acceleration_multiplier = {"rb-gui.fuel-acceleration-multiplier"},
    fuel_categories = {"rb-gui.fuel-categories"},
    fuel_category = {"rb-gui.fuel-category"},
    fuel_emissions_multiplier = {"rb-gui.fuel-emissions-multiplier"},
    fuel_top_speed_multiplier = {"rb-gui.fuel-top-speed-multiplier"},
    fuel_value = {"rb-gui.fuel-value"},
    hidden = {"rb-gui.hidden"},
    ingredients_tooltip = {"rb-gui.ingredients-tooltip"},
    per_second = {"rb-gui.per-second"},
    products_tooltip = {"rb-gui.products-tooltip"},
    pumping_speed = {"rb-gui.pumping-speed"},
    required_fluid = {"rb-gui.required-fluid"},
    research_ingredients_per_unit_tooltip = {"rb-gui.research-ingredients-per-unit-tooltip"},
    research_units_tooltip = {"rb-gui.research-units-tooltip"},
    researching_speed = {"rb-gui.researching-speed"},
    rocket_parts_required = {"rb-gui.rocket-parts-required"},
    seconds_standalone = {"rb-gui.seconds-standalone"},
    shift_click_to_get_blueprint = {"rb-gui.shift-click-to-get-blueprint"},
    shift_click_to_view_base_fluid = {"rb-gui.shift-click-to-view-base-fluid"},
    shift_click_to_view_technology = {"rb-gui.shift-click-to-view-technology"},
    stack_size = {"rb-gui.stack-size"},
    unresearched = {"rb-gui.unresearched"}
  },
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

constants.main_pages = {
  "home",
  "crafter",
  "fluid",
  "item",
  "recipe",
  "technology"
}
-- interface can open any page but home
constants.interface_classes = table.invert(constants.main_pages)
constants.interface_classes.home = nil

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
      default_value = false,
      has_tooltip = true
    },
    show_unresearched = {
      default_value = false,
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
