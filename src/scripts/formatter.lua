local formatter = {}

local math = require("__flib__.math")
local fixed_format = require("lib.fixed-precision-format")

local constants = require("constants")

local util = require("scripts.util")

local caches = {}

-- upvalues (for optimization)
local class_to_font_glyph = constants.class_to_font_glyph
local class_to_type = constants.class_to_type
local concat = table.concat
local build_rich_text = util.build_rich_text
local build_sprite = util.build_sprite

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
  -- we have to get the current enabled status from the object itself
  -- recipes are unlocked by "enabling" them, so only check if a recipe is actually disabled if it's researched
  if obj_data.class == "recipe" and is_researched then
    is_enabled = game.forces[force_index].recipes[obj_data.prototype_name].enabled
  elseif obj_data.class == "technology" then
    is_enabled = game.forces[force_index].technologies[obj_data.prototype_name].enabled
  end

  return obj_data.hidden, is_researched, is_enabled
end

local function get_should_show(obj_data, player_data)
  -- player data
  local force_index = player_data.force_index
  local player_settings = player_data.settings
  local show_hidden = player_settings.show_hidden
  local show_unresearched = player_settings.show_unresearched
  local show_disabled = player_settings.show_disabled

  -- check hidden and researched status
  local is_hidden, is_researched, is_enabled = get_properties(obj_data, force_index)
  if
    (show_hidden or not is_hidden)
    and (show_unresearched or is_researched)
    and (show_disabled or is_enabled)
  then
    -- for recipes - check category to see if it should be shown
    local category = obj_data.category
    local categories = obj_data.recipe_categories
    if category then
      if player_settings.recipe_categories[category] then
        return true, is_hidden, is_researched, is_enabled
      end
    -- for materials - check if any of their categories are enabled
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

local function get_caption(obj_data, player_data, is_hidden, is_enabled, amount)
  -- locals
  local player_settings = player_data.settings
  local translations = player_data.translations

  -- object properties
  local class = obj_data.class

  -- glyph
  local glyph_str = ""
  if player_settings.show_glyphs then
    glyph_str = build_rich_text(
      "font",
      "RecipeBook",
      class_to_font_glyph[class] or class_to_font_glyph[class]
    ).."  "
  end
  -- hidden
  local hidden_str = ""
  if is_hidden then
    hidden_str = build_rich_text("font", "default-semibold", translations.gui.hidden_abbrev).."  "
  end
  -- disabled
  local disabled_str = ""
  if not is_enabled then
    disabled_str = build_rich_text("font", "default-semibold", translations.gui.disabled_abbrev).."  "
  end
  -- icon
  local icon_str = build_sprite(class_to_type[class], obj_data.prototype_name).."  "
  -- amount string
  local amount_str = ""
  if amount then
    amount_str = build_rich_text("font", "default-semibold", amount).."  "
  end
  -- name
  local internal_name = obj_data.name or obj_data.prototype_name
  local name_str = (
    player_settings.use_internal_names
    and internal_name
    or translations[class][internal_name]
  )

  -- output
  return glyph_str..hidden_str..disabled_str..icon_str..amount_str..name_str
end

local function get_base_tooltip(obj_data, player_data, is_hidden, is_researched, is_enabled)
  -- locals
  local player_settings = player_data.settings
  local translations = player_data.translations
  local gui_translations = translations.gui

  -- object properties
  local class = obj_data.class
  local internal_name = obj_data.name or obj_data.prototype_name

  -- translation
  local name = translations[class][internal_name]
  local description = translations[class.."_description"][internal_name]

  -- settings
  local show_alternate_name = player_settings.show_alternate_name
  local show_descriptions = player_settings.show_descriptions
  local use_internal_names = player_settings.use_internal_names

  -- title
  local name_str = use_internal_names and internal_name or name
  local title_str = (
    build_sprite(class_to_type[class], obj_data.prototype_name)
    .."  "
    ..build_rich_text(
      "font",
      "default-bold",
      build_rich_text("color", "heading", name_str)
    )
    .."\n"
  )
  -- alternate name
  local alternate_name_str = ""
  if show_alternate_name then
    alternate_name_str = build_rich_text("color", "green", use_internal_names and name or internal_name).."\n"
  end
  -- description
  local description_string = ""
  if description and show_descriptions then
    description_string = description and description.."\n" or ""
  end
  -- category class
  local category_class_str = build_rich_text("color", "info", gui_translations[class])
  -- hidden
  local hidden_str = ""
  if is_hidden then
    hidden_str = "  |  "..gui_translations.hidden
  end
  -- disabled
  local disabled_str = ""
  if not is_enabled then
    disabled_str = "  |  "..gui_translations.disabled
  end
  -- unresearched
  local unresearched_str = ""
  if not is_researched then
    unresearched_str = "  |  "..build_rich_text("color", "unresearched", gui_translations.unresearched)
  end

  return title_str..alternate_name_str..description_string..category_class_str..hidden_str..disabled_str..unresearched_str
end

local ingredients_products_keys = {ingredients = true, products = true}

local formatters = {
  crafter = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_enabled, is_label, blueprint_recipe)
      -- locals
      local translations = player_data.translations
      local gui_translations = translations.gui

      -- object properties
      local categories = obj_data.categories
      local rocket_parts_required = obj_data.rocket_parts_required
      local fixed_recipe = obj_data.fixed_recipe

      -- build string
      local base_str = get_base_tooltip(obj_data, player_data, is_hidden, is_researched, is_enabled)
      -- rocket parts
      local rocket_parts_str = ""
      if rocket_parts_required then
        rocket_parts_str = (
          "\n"
          ..build_rich_text("font", "default-semibold", gui_translations.rocket_parts_required)
          .." "
          ..rocket_parts_required
        )
      end
      -- fixed recipe
      local fixed_recipe_str = ""
      local fixed_recipe_help_str = ""
      if fixed_recipe then
        -- get fixed recipe data
        local fixed_recipe_data = global.recipe_book.recipe[obj_data.fixed_recipe]
        if fixed_recipe_data then
          local title_str = ("\n"..build_rich_text("font", "default-semibold", gui_translations.fixed_recipe).."  ")
          -- fixed recipe
          local data = formatter(fixed_recipe_data, player_data, {always_show = true})
          local label = data.caption
          -- remove glyph from caption, since it's implied
          if player_data.settings.show_glyphs then
            label = string.gsub(label, "^.-nt%]  ", "")
          end
          if data.is_researched then
            fixed_recipe_str = title_str..label
          else
            fixed_recipe_str = title_str..build_rich_text("color", "unresearched", label)
          end
          -- help text
          if not is_label then
            fixed_recipe_help_str = "\n"..gui_translations.control_click_to_view_fixed_recipe
          end
        end
      end
      -- crafting speed
      local crafting_speed_str = (
        "\n"
        ..build_rich_text("font", "default-semibold", gui_translations.crafting_speed)
        .." "
        ..math.round_to(obj_data.crafting_speed, 2)
      )
      -- crafting categories
      local crafting_categories_str_arr = {
        "\n"
        ..build_rich_text("font", "default-semibold", gui_translations.crafting_categories)
      }
      for i = 1, #categories do
        crafting_categories_str_arr[#crafting_categories_str_arr+1] = "\n  "..categories[i]
      end
      local crafting_categories_str = concat(crafting_categories_str_arr)
      -- fuel categories
      local fuel_categories_str_arr = {}
      local fuel_categories = obj_data.fuel_categories
      if fuel_categories then
        fuel_categories_str_arr[1] = "\n"..build_rich_text("font", "default-semibold", gui_translations.fuel_categories)
        for i = 1, #fuel_categories do
          fuel_categories_str_arr[#fuel_categories_str_arr+1] = "\n  "..fuel_categories[i]
        end
      end
      local fuel_categories_str = concat(fuel_categories_str_arr)
      local open_page_help_str = ""
      local blueprintable_str = ""
      if not is_label then
        -- open page help
        open_page_help_str = "\n"..gui_translations.click_to_view
        -- blueprintable
        if blueprint_recipe then
          if obj_data.blueprintable then
            blueprintable_str = "\n"..gui_translations.shift_click_to_get_blueprint
          else
            blueprintable_str = "\n"..build_rich_text("color", "error", gui_translations.blueprint_not_available)
          end
        end
      end

      return (
        base_str
        ..rocket_parts_str
        ..fixed_recipe_str
        ..crafting_speed_str
        ..crafting_categories_str
        ..fuel_categories_str
        ..open_page_help_str
        ..blueprintable_str
        ..fixed_recipe_help_str
      )
    end,
    enabled = function() return true end
  },
  fluid = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_enabled, is_label)
      -- locals
      local gui_translations = player_data.translations.gui

      -- build string
      local base_str = get_base_tooltip(obj_data, player_data, is_hidden, is_researched, is_enabled)
      -- fuel value
      local fuel_value_str = ""
      if obj_data.fuel_value then
        fuel_value_str = (
          "\n"
          ..build_rich_text("font", "default-semibold", gui_translations.fuel_value)
          .." "
          ..fixed_format(obj_data.fuel_value, 3, "2")
          .."J"
        )
      end
      -- interaction help
      local interaction_help_str = ""
      if not is_label then
        interaction_help_str = "\n"..gui_translations.click_to_view
        if obj_data.temperature_data then
          interaction_help_str = interaction_help_str.."\n"..gui_translations.shift_click_to_view_base_fluid
        end
      end

      return base_str..fuel_value_str..interaction_help_str
    end,
    enabled = function() return true end
  },
  item = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_enabled, is_label)
      -- locals
      local gui_translations = player_data.translations.gui

      -- object properties
      local stack_size = obj_data.stack_size

      -- build string
      local base_str = get_base_tooltip(obj_data, player_data, is_hidden, is_researched, is_enabled)
      -- stack size
      local stack_size_str = ""
      if stack_size then
        stack_size_str = "\n"..build_rich_text("font", "default-semibold", gui_translations.stack_size).." "..stack_size
      end
      -- fuel category
      local fuel_category_str = ""
      if obj_data.fuel_category then
        fuel_category_str = (
          "\n"
          ..build_rich_text("font", "default-semibold", gui_translations.fuel_category)
          .." "
          ..obj_data.fuel_category
        )
      end
      -- fuel value
      local fuel_value_str = ""
      if obj_data.fuel_value then
        fuel_value_str = (
          "\n"
          ..build_rich_text("font", "default-semibold", gui_translations.fuel_value)
          .." "
          ..fixed_format(obj_data.fuel_value, 3, "2")
          .."J"
        )
      end
      -- fuel emissions
      local fuel_emissions_str = ""
      if obj_data.fuel_emissions_multiplier then
        fuel_emissions_str = (
          "\n"
          ..build_rich_text("font", "default-semibold", gui_translations.fuel_emissions_multiplier)
          .." "
          ..math.round_to(obj_data.fuel_emissions_multiplier * 100, 2)
          .."%"
        )
      end
      -- fuel acceleration
      local fuel_acceleration_str = ""
      if obj_data.fuel_acceleration_multiplier then
        fuel_acceleration_str = (
          "\n"
          ..build_rich_text("font", "default-semibold", gui_translations.fuel_acceleration_multiplier)
          .." "
          ..math.round_to(obj_data.fuel_acceleration_multiplier * 100, 2)
          .."%"
        )
      end
      -- fuel top speed
      local fuel_top_speed_str = ""
      if obj_data.fuel_top_speed_multiplier then
        fuel_top_speed_str = (
          "\n"
          ..build_rich_text("font", "default-semibold", gui_translations.fuel_top_speed_multiplier)
          .." "
          ..math.round_to(obj_data.fuel_top_speed_multiplier * 100, 2)
          .."%"
        )
      end
      -- interaction help
      local interaction_help_str = ""
      if not is_label then
        interaction_help_str = "\n"..gui_translations.click_to_view
      end

      return (
        base_str
        ..stack_size_str
        ..fuel_category_str
        ..fuel_value_str
        ..fuel_emissions_str
        ..fuel_acceleration_str
        ..fuel_top_speed_str
        ..interaction_help_str
      )
    end,
    enabled = function() return true end
  },
  lab = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_enabled, _)
      local base_str = get_base_tooltip(obj_data, player_data, is_hidden, is_researched, is_enabled)
      -- researching speed
      local researching_speed_str = (
        "\n"
        ..build_rich_text("font", "default-semibold", player_data.translations.gui.researching_speed)
        .." "
        ..math.round_to(obj_data.researching_speed, 2)
      )

      return base_str..researching_speed_str
    end,
    enabled = function() return false end
  },
  offshore_pump = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_enabled, _)
      -- locals
      local gui_translations = player_data.translations.gui

      -- build string
      local base_str = get_base_tooltip(obj_data, player_data, is_hidden, is_researched, is_enabled)
      -- pumping speed
      local pumping_speed_str = (
        "\n"
        ..build_rich_text("font", "default-semibold", gui_translations.pumping_speed)
        .." "
        ..math.round_to(obj_data.pumping_speed * 60, 0)
        ..gui_translations.per_second
      )

      return base_str..pumping_speed_str
    end,
    enabled = function() return false end
  },
  recipe = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_enabled, is_label)
      -- locals
      local recipe_book = global.recipe_book
      local gui_translations = player_data.translations.gui
      local player_settings = player_data.settings

      -- build string
      local base_str = get_base_tooltip(obj_data, player_data, is_hidden, is_researched, is_enabled)
      -- crafting_category
      local category_str = (
        "\n"
        ..build_rich_text("font", "default-semibold", gui_translations.category)
        .." "
        ..obj_data.category
      )
      -- crafting time, ingredients and products
      local ip_str_arr = {}
      if player_settings.show_detailed_tooltips and not is_label then
        -- crafting time
        ip_str_arr[1] = (
          "\n"
          ..build_rich_text("font", "default-semibold", gui_translations.crafting_time)
          .." "..math.round_to(obj_data.energy, 2)
          .." "
          ..gui_translations.seconds_standalone
        )
        -- ingredients and products
        for material_type in pairs(ingredients_products_keys) do
          local materials = obj_data[material_type]
          local materials_len = #materials
          if materials_len > 0 then
            ip_str_arr[#ip_str_arr+1] = (
              "\n"
              ..build_rich_text("font", "default-semibold", gui_translations[material_type.."_tooltip"])
            )
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
                  ip_str_arr[#ip_str_arr+1] = "\n  "..label
                else
                  ip_str_arr[#ip_str_arr+1] = "\n  "..build_rich_text("color", "unresearched", label)
                end
              end
            end
          end
        end
      end
      local ip_str = concat(ip_str_arr)
      -- interaction help
      local interaction_help_str = ""
      if not is_label then
        interaction_help_str = "\n"..gui_translations.click_to_view
      end

      return base_str..category_str..ip_str..interaction_help_str
    end,
    enabled = function() return true end
  },
  resource = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_enabled, _)
      local base_str = get_base_tooltip(obj_data, player_data, is_hidden, is_researched, is_enabled)
      local required_fluid_str = ""
      local interaction_help_str = ""
      local required_fluid = obj_data.required_fluid
      if required_fluid then
        local fluid_data = global.recipe_book.fluid[required_fluid.name]
        if fluid_data then
          local data = formatter(
            fluid_data,
            player_data,
            {amount_string = required_fluid.amount_string, always_show = true}
          )
          local label = data.caption
          -- remove glyph from caption, since it's implied
          if player_data.settings.show_glyphs then
            label = string.gsub(label, "^.-nt%]  ", "")
          end
          if not data.is_researched then
            label = build_rich_text("color", "unresearched", label)
          end
          required_fluid_str = (
            "\n"
            ..build_rich_text("font", "default-semibold", player_data.translations.gui.required_fluid)
            .."  "
            ..label
          )
          interaction_help_str = "\n"..player_data.translations.gui.click_to_view_required_fluid
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

      -- units count, ingredients
      local tech_str_arr = {}
      if player_settings.show_detailed_tooltips and not is_label then
        -- units count
        local unit_count = obj_data.research_unit_count or game.evaluate_expression(
          obj_data.research_unit_count_formula,
          {L = obj_data.min_level, l = obj_data.min_level}
        )

        tech_str_arr[1] = (
          "\n"
          ..build_rich_text("font", "default-semibold", gui_translations.research_units_tooltip)
          .." "..unit_count
        )
        tech_str_arr[#tech_str_arr+1] = (
          "\n"
          ..build_rich_text("font", "default-semibold", gui_translations.research_ingredients_per_unit_tooltip)
        )

        -- time ingredient
        if obj_data.research_unit_energy then
          local time_item_prefix = player_data.settings.show_glyphs and "[font=RecipeBook]Z[/font]   " or ""
          tech_str_arr[#tech_str_arr+1] = "\n  ".. time_item_prefix.."[img=quantity-time]   "
          ..obj_data.research_unit_energy.." "..gui_translations.seconds_standalone

        end
        -- ingredients
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
              tech_str_arr[#tech_str_arr+1] = "\n  "..label
            else
              tech_str_arr[#tech_str_arr+1] = "\n  "..build_rich_text("color", "unresearched", label)
            end
          end
        end
      end

      local tech_str = concat(tech_str_arr)
      -- interaction help
      local interaction_help_str = ""
      if not is_label then
        interaction_help_str = "\n"..gui_translations.click_to_view
        interaction_help_str = interaction_help_str.."\n"..player_data.translations.gui.shift_click_to_view_technology
      end

      return base_str..tech_str..interaction_help_str
    end,
    enabled = function() return true end
  }
}

local function format_item(obj_data, player_data, options)
  local should_show, is_hidden, is_researched, is_enabled = get_should_show(obj_data, player_data)
  if options.always_show or should_show then
    -- format and return
    local formatter_subtable = formatters[obj_data.class]
    return {
      caption = get_caption(obj_data, player_data, is_hidden, is_enabled, options.amount_string),
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

-- get the corresponding data from the cache, or generate it (memoized)
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

-- when calling the module directly, call formatter.format
setmetatable(formatter, { __call = function(_, ...) return formatter.format(...) end })

return formatter

