local formatter = {}

local math = require("__flib__.math")
local fixed_format = require("lib.fixed-precision-format")
local locale = require("lib.locale")

local constants = require("constants")

local caches = {}

-- Upvalues (for optimization)
local class_to_font_glyph = constants.class_to_font_glyph
local class_to_type = constants.class_to_type
local concat = table.concat
local control = locale.control
local rich_text = locale.rich_text
local sprite = locale.sprite
local tooltip_kv = locale.tooltip_kv

local function get_properties(obj_data, force_index)
  local is_researched
  if obj_data.enabled_at_start then
    is_researched = true
  elseif obj_data.researched_forces then
    is_researched = obj_data.researched_forces[force_index] or false
  else
    is_researched = true
  end

  local is_enabled = true
  -- FIXME: find a better way to do this
  -- We have to get the current enabled status from the object itself
  -- Recipes are unlocked by "enabling" them, so only check if a recipe is actually disabled if it's researched
  if obj_data.class == "recipe" and is_researched then
    is_enabled = game.forces[force_index].recipes[obj_data.prototype_name].enabled
  elseif obj_data.class == "technology" then
    is_enabled = game.forces[force_index].technologies[obj_data.prototype_name].enabled
  end

  return obj_data.hidden, is_researched, is_enabled
end

local function get_should_show(obj_data, player_data)
  -- Player data
  local force_index = player_data.force_index
  local player_settings = player_data.settings
  local show_hidden = player_settings.show_hidden
  local show_unresearched = player_settings.show_unresearched
  local show_disabled = player_settings.show_disabled

  -- Check hidden and researched status
  local is_hidden, is_researched, is_enabled = get_properties(obj_data, force_index)
  if
    (show_hidden or not is_hidden)
    and (show_unresearched or is_researched)
    and (show_disabled or is_enabled)
  then
    -- For recipes - check category to see if it should be shown
    local category = obj_data.category
    local categories = obj_data.recipe_categories
    if category then
      if player_settings.recipe_categories[category] then
        return true, is_hidden, is_researched, is_enabled
      end
    -- For materials - check if any of their categories are enabled
    elseif categories then
      local category_settings = player_settings.recipe_categories
      for _, category_name in ipairs(categories) do
        if category_settings[category_name] then
          return true, is_hidden, is_researched, is_enabled
        end
      end
    else
      return true, is_hidden, is_researched, is_enabled
    end
  end
  return false, is_hidden, is_researched, is_enabled
end

local function get_caption(obj_data, player_data, is_hidden, is_enabled, is_label, amount)
  -- Locals
  local player_settings = player_data.settings
  local translations = player_data.translations

  -- Object properties
  local class = obj_data.class

  -- Glyph
  local glyph_str = ""
  if player_settings.show_glyphs and not is_label then
    glyph_str = rich_text(
      "font",
      "RecipeBook",
      class_to_font_glyph[class] or class_to_font_glyph[class]
    ).."  "
  end
  -- Hidden
  local hidden_str = ""
  if is_hidden then
    hidden_str = rich_text("font", "default-semibold", translations.gui.hidden_abbrev).."  "
  end
  -- Disabled
  local disabled_str = ""
  if not is_enabled then
    disabled_str = rich_text("font", "default-semibold", translations.gui.disabled_abbrev).."  "
  end
  -- Icon
  local icon_str = sprite(class_to_type[class], obj_data.prototype_name).."  "
  -- Amount string
  local amount_str = ""
  if amount then
    amount_str = rich_text("font", "default-semibold", amount).."  "
  end
  -- Name
  local internal_name = obj_data.name or obj_data.prototype_name
  local name_str = (
    player_settings.use_internal_names
    and internal_name
    or translations[class][internal_name]
  )

  -- Output
  return glyph_str..hidden_str..disabled_str..icon_str..amount_str..name_str
end

local function get_base_tooltip(obj_data, player_data, is_hidden, is_researched, is_enabled)
  -- Locals
  local player_settings = player_data.settings
  local translations = player_data.translations
  local gui_translations = translations.gui

  -- Object properties
  local class = obj_data.class
  local internal_name = obj_data.name or obj_data.prototype_name

  -- Translation
  local name = translations[class][internal_name]
  local description = translations[class.."_description"][internal_name]

  -- Settings
  local show_alternate_name = player_settings.show_alternate_name
  local show_descriptions = player_settings.show_descriptions
  local use_internal_names = player_settings.use_internal_names

  -- Title
  local name_str = use_internal_names and internal_name or name
  local title_str = (
    sprite(class_to_type[class], obj_data.prototype_name)
    .."  "
    ..rich_text(
      "font",
      "default-bold",
      rich_text("color", "heading", name_str)
    )
    .."\n"
  )
  -- Alternate name
  local alternate_name_str = ""
  if show_alternate_name then
    alternate_name_str = rich_text("color", "green", use_internal_names and name or internal_name).."\n"
  end
  -- Description
  local description_string = ""
  if description and show_descriptions then
    description_string = description and description.."\n" or ""
  end
  -- Category class
  local category_class_str = rich_text("color", "info", gui_translations[class])
  -- Hidden
  local hidden_str = ""
  if is_hidden then
    hidden_str = "  |  "..gui_translations.hidden
  end
  -- Disabled
  local disabled_str = ""
  if not is_enabled then
    disabled_str = "  |  "..gui_translations.disabled
  end
  -- Unresearched
  local unresearched_str = ""
  if not is_researched then
    unresearched_str = "  |  "..rich_text("color", "unresearched", gui_translations.unresearched)
  end

  return title_str
    ..alternate_name_str
    ..description_string
    ..category_class_str
    ..hidden_str
    ..disabled_str
    ..unresearched_str
end

local ingredients_products_keys = {ingredients = true, products = true}

local formatters = {
  crafter = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_enabled, is_label, blueprint_recipe)
      -- Locals
      local translations = player_data.translations
      local gui_translations = translations.gui

      -- Object properties
      local categories = obj_data.categories
      local rocket_parts_required = obj_data.rocket_parts_required
      local fixed_recipe = obj_data.fixed_recipe

      -- Build string
      local base_str = get_base_tooltip(obj_data, player_data, is_hidden, is_researched, is_enabled)
      -- Rocket parts
      local rocket_parts_str = ""
      if rocket_parts_required then
        rocket_parts_str = "\n"
          ..rich_text("font", "default-semibold", gui_translations.rocket_parts_required..":")
          .." "
          ..rocket_parts_required
      end
      -- Fixed recipe
      local fixed_recipe_str = ""
      local fixed_recipe_help_str = ""
      if fixed_recipe then
        -- Get fixed recipe data
        local fixed_recipe_data = global.recipe_book.recipe[obj_data.fixed_recipe]
        if fixed_recipe_data then
          -- Fixed recipe
          local recipe_info = formatter(fixed_recipe_data, player_data, {always_show = true, is_label = true})
          if recipe_info.is_researched then
            fixed_recipe_str = tooltip_kv(gui_translations.fixed_recipe, recipe_info.caption)
          else
            fixed_recipe_str = tooltip_kv(
              gui_translations.fixed_recipe,
              rich_text("color", "unresearched", recipe_info.caption)
            )
          end
          -- Help text
          if not is_label then
            fixed_recipe_help_str = control(gui_translations.control_click, gui_translations.view_fixed_recipe)
          end
        end
      end
      -- Crafting speed
      local crafting_speed_str = tooltip_kv(gui_translations.crafting_speed, math.round_to(obj_data.crafting_speed, 2))
      -- Crafting categories
      local crafting_categories_str_arr = {tooltip_kv(gui_translations.crafting_categories)}
      for i = 1, #categories do
        crafting_categories_str_arr[i + 1] = "\n  "..categories[i]
      end
      local crafting_categories_str = concat(crafting_categories_str_arr)

      local open_page_help_str = ""
      local blueprintable_str = ""
      if not is_label then
        -- Open page help
        open_page_help_str = control(gui_translations.click, gui_translations.view_details)
        -- Blueprintable
        if blueprint_recipe then
          if obj_data.blueprintable then
            blueprintable_str = control(gui_translations.shift_click, gui_translations.get_blueprint)
          else
            blueprintable_str = "\n"..rich_text("color", "error", gui_translations.blueprint_not_available)
          end
        end
      end

      return (
        base_str
        ..rocket_parts_str
        ..fixed_recipe_str
        ..crafting_speed_str
        ..crafting_categories_str
        ..open_page_help_str
        ..blueprintable_str
        ..fixed_recipe_help_str
      )
    end,
    enabled = function() return true end
  },
  fluid = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_enabled, is_label)
      -- Locals
      local gui_translations = player_data.translations.gui

      -- Build string
      local base_str = get_base_tooltip(obj_data, player_data, is_hidden, is_researched, is_enabled)
      -- Fuel value
      local fuel_value_str = ""
      if obj_data.fuel_value then
        fuel_value_string = tooltip_kv(gui_translations.fuel_value, fixed_format(obj_data.fuel_value, 3, "2").."J")
      end
      -- Interaction help
      local interaction_help_str = ""
      if not is_label then
        interaction_help_str = control(gui_translations.click, gui_translations.view_details)
        if obj_data.temperature_data then
          interaction_help_str = interaction_help_str
            ..control(gui_translations.shift_click, gui_translations.view_base_fluid)
        end
      end

      return base_str..fuel_value_str..interaction_help_str
    end,
    enabled = function() return true end
  },
  item = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_enabled, is_label)
      -- Locals
      local gui_translations = player_data.translations.gui

      -- Object properties
      local stack_size = obj_data.stack_size

      -- Build string
      local base_str = get_base_tooltip(obj_data, player_data, is_hidden, is_researched, is_enabled)
      -- Stack size
      local stack_size_str = ""
      if stack_size then
        stack_size_str = tooltip_kv(gui_translations.stack_size, stack_size)
      end
      -- Fuel value
      local fuel_value_str = ""
      if obj_data.fuel_value then
        fuel_value_str = tooltip_kv(gui_translations.fuel_value, fixed_format(obj_data.fuel_value, 3, "2").."J")
      end
      -- Fuel emissions
      local fuel_pollution_str = ""
      local fuel_pollution = obj_data.fuel_emissions_multiplier
      if fuel_pollution then
        fuel_pollution_str = tooltip_kv(gui_translations.fuel_pollution, math.round_to(fuel_pollution * 100, 2))
      end
      -- Fuel acceleration
      local vehicle_acceleration_str = ""
      local vehicle_acceleration = obj_data.fuel_acceleration_multiplier
      if vehicle_acceleration then
        vehicle_acceleration_str = tooltip_kv(
          gui_translations.vehicle_acceleration,
          math.round_to(vehicle_acceleration * 100, 2)
        )
      end
      -- Fuel top speed
      local vehicle_top_speed_str = ""
      local vehicle_top_speed = obj_data.fuel_top_speed_multiplier
      if vehicle_top_speed then
        vehicle_top_speed_str = tooltip_kv(
          gui_translations.vehicle_top_speed,
          math.round_to(vehicle_top_speed * 100, 2)
        )
      end
      -- Interaction help
      local interaction_help_str = ""
      if not is_label then
        interaction_help_str = control(gui_translations.click, gui_translations.view_details)
      end

      return (
        base_str
        ..stack_size_str
        ..fuel_value_str
        ..fuel_pollution_str
        ..vehicle_acceleration_str
        ..vehicle_top_speed_str
        ..interaction_help_str
      )
    end,
    enabled = function() return true end
  },
  lab = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_enabled, _)
      local base_str = get_base_tooltip(obj_data, player_data, is_hidden, is_researched, is_enabled)
      -- Researching speed
      local research_speed_str = tooltip_kv(
        player_data.translations.gui.research_speed,
        math.round_to(obj_data.researching_speed, 2)
      )

      return base_str..research_speed_str
    end,
    enabled = function() return true end
  },
  offshore_pump = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_enabled, _)
      -- Locals
      local gui_translations = player_data.translations.gui

      -- Build string
      local base_str = get_base_tooltip(obj_data, player_data, is_hidden, is_researched, is_enabled)
      -- Pumping speed
      local pumping_speed_str = tooltip_kv(
        gui_translations.pumping_speed,
        math.round(obj_data.pumping_speed * 60).." "..gui_translations.per_second
      )

      return base_str..pumping_speed_str
    end,
    enabled = function() return false end
  },
  recipe = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_enabled, is_label)
      -- Locals
      local recipe_book = global.recipe_book
      local gui_translations = player_data.translations.gui
      local player_settings = player_data.settings

      -- Build string
      local base_str = get_base_tooltip(obj_data, player_data, is_hidden, is_researched, is_enabled)
      -- Crafting_category
      local category_str = tooltip_kv(gui_translations.category, obj_data.category)
      -- Crafting time, ingredients and products
      local ip_str_arr = {}
      if player_settings.show_detailed_tooltips and not is_label then
        -- Crafting time
        -- TODO: Unify `seconds` translation somehow
        ip_str_arr[1] = tooltip_kv(gui_translations.crafting_time, math.round_to(obj_data.energy, 2).." s")
        -- Ingredients and products
        for material_type in pairs(ingredients_products_keys) do
          local materials = obj_data[material_type]
          local materials_len = #materials
          if materials_len > 0 then
            ip_str_arr[#ip_str_arr + 1] = tooltip_kv(gui_translations[material_type])
            for i = 1, #materials do
              local material = materials[i]
              local material_data = recipe_book[material.class][material.name]
              if material_data then
                local data = formatter(
                  material_data,
                  player_data,
                  {amount_string = material.amount_string, always_show = true}
                )
                local label = data.caption
                if data.is_researched then
                  ip_str_arr[#ip_str_arr + 1] = "\n  "..label
                else
                  ip_str_arr[#ip_str_arr + 1] = "\n  "..rich_text("color", "unresearched", label)
                end
              end
            end
          end
        end
      end
      local ip_str = concat(ip_str_arr)
      -- Interaction help
      local interaction_help_str = ""
      if not is_label then
        interaction_help_str = control(gui_translations.click, gui_translations.view_details)
      end

      return base_str..category_str..ip_str..interaction_help_str
    end,
    enabled = function() return true end
  },
  resource = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_enabled, _)
      local base_str = get_base_tooltip(obj_data, player_data, is_hidden, is_researched, is_enabled)
      local gui_translations = player_data.translations.gui
      local required_fluid_str = ""
      local interaction_help_str = ""
      local required_fluid = obj_data.required_fluid
      if required_fluid then
        local fluid_data = global.recipe_book.fluid[required_fluid.name]
        if fluid_data then
          local data = formatter(
            fluid_data,
            player_data,
            {amount_string = required_fluid.amount_string, always_show = true, is_label = true}
          )
          local label = data.caption
          if not data.is_researched then
            label = rich_text("color", "unresearched", label)
          end
          required_fluid_str = tooltip_kv(gui_translations.required_fluid, label)
          interaction_help_str = control(gui_translations.click, gui_translations.view_required_fluid)
        end
      end
      return base_str..required_fluid_str..interaction_help_str
    end,
    enabled = function(obj_data) return obj_data.required_fluid and true or false end
  },
  technology = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_enabled, is_label)
      local base_str = get_base_tooltip(obj_data, player_data, is_hidden, is_researched, is_enabled)
      local gui_translations = player_data.translations.gui
      local player_settings = player_data.settings
      local recipe_book = global.recipe_book

      -- Units count, ingredients
      local tech_str_arr = {}
      if player_settings.show_detailed_tooltips and not is_label then
        -- Units count
        local unit_count = obj_data.research_unit_count or game.evaluate_expression(
          obj_data.research_unit_count_formula,
          {L = obj_data.min_level, l = obj_data.min_level}
        )

        tech_str_arr[1] = tooltip_kv(gui_translations.required_units, unit_count)
        -- TODO: Standardize `per second` translation somehow
        tech_str_arr[2] = tooltip_kv(gui_translations.time_per_unit, obj_data.research_unit_energy.." s")
        tech_str_arr[3] = tooltip_kv(gui_translations.research_ingredients_per_unit)

        -- Ingredients
        local ingredients = obj_data.research_ingredients_per_unit
        for i = 1, #ingredients do
          local ingredient = ingredients[i]
          local ingredient_data = recipe_book[ingredient.class][ingredient.name]
          if ingredient_data then
            local data = formatter(
              ingredient_data,
              player_data,
              {amount_string = ingredient.amount_string, always_show = true}
            )
            local label = data.caption
            if data.is_researched then
              tech_str_arr[#tech_str_arr + 1] = "\n  "..label
            else
              tech_str_arr[#tech_str_arr + 1] = "\n  "..rich_text("color", "unresearched", label)
            end
          end
        end
      end

      local tech_str = concat(tech_str_arr)
      -- Interaction help
      local interaction_help_str = ""
      if not is_label then
        interaction_help_str = control(gui_translations.click, gui_translations.view_details)
          ..control(gui_translations.shift_click, gui_translations.open_in_technology_window)
      end

      return base_str..tech_str..interaction_help_str
    end,
    enabled = function() return true end
  }
}

local function format_item(obj_data, player_data, options)
  local should_show, is_hidden, is_researched, is_enabled = get_should_show(obj_data, player_data)
  if options.always_show or should_show then
    -- Format and return
    local formatter_subtable = formatters[obj_data.class]
    return {
      caption = get_caption(obj_data, player_data, is_hidden, is_enabled, options.is_label, options.amount_string),
      is_enabled = formatter_subtable.enabled(obj_data),
      is_researched = is_researched,
      tooltip = formatter_subtable.tooltip(
        obj_data,
        player_data,
        is_hidden,
        is_researched,
        is_enabled,
        options.is_label,
        options.blueprint_recipe
      )
    }
  else
    return false
  end
end

-- Get the corresponding data from the cache, or generate it (memoized)
function formatter.format(obj_data, player_data, options)
  options = options or {}

  local player_index = player_data.player_index
  local cache = caches[player_index]
  local _, is_researched, is_enabled = get_properties(obj_data, player_data.force_index)
  local cache_key = (
    obj_data.class
    .."."..(obj_data.name or obj_data.prototype_name)
    .."."..tostring(is_researched)
    .."."..tostring(is_enabled)
    .."."..tostring(options.amount_string)
    .."."..tostring(options.always_show)
    .."."..tostring(options.is_label)
    .."."..tostring(options.blueprint_recipe)
  )
  local cached_return = cache[cache_key]
  if cached_return ~= nil then
    return cached_return
  else
    local data = format_item(obj_data, player_data, options)
    cache[cache_key] = data
    return data
  end
end

function formatter.create_cache(player_index)
  caches[player_index] = {}
end

function formatter.create_all_caches()
  for i in pairs(global.players) do
    caches[i] = {}
  end
end

formatter.purge_cache = formatter.create_cache

function formatter.destroy_cache(player_index)
  caches[player_index] = nil
end

function formatter.build_player_data(player, player_table)
  return {
    favorites = player_table.favorites,
    force_index = player.force.index,
    history = player_table.history.global,
    player_index = player.index,
    settings = player_table.settings,
    translations = player_table.translations
  }
end

-- When calling the module directly, call formatter.format
setmetatable(formatter, { __call = function(_, ...) return formatter.format(...) end })

return formatter

