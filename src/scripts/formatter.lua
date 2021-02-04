local formatter = {}

local math = require("__flib__.math")
local fixed_format = require("lib.fixed-precision-format")

local constants = require("constants")

local caches = {}

-- upvalues (for optimization)
local class_to_font_glyph = constants.class_to_font_glyph
local colors = constants.colors
local concat = table.concat
local unpack = table.unpack

-- string builders
local function build_rich_text(key, value, inner)
  return "["..key.."="..(key == "color" and colors[value].str or value).."]"..inner.."[/"..key.."]"
end
local function build_sprite(class, name)
  return "[img="..class.."/"..name.."]"
end

local function get_properties(obj_data, force_index, options)
  local opt = options or {}
  local researched = false
  if obj_data.researched_forces then
    researched = obj_data.researched_forces[force_index] or false
  elseif obj_data.available_to_all_forces or not obj_data.unlocked_by or #obj_data.unlocked_by == 0 or (obj_data.available_to_forces[force_index] and ((obj_data.temperatures_count and obj_data.temperatures_count <= 1) or not opt.fluid_temperature_key)) then
    researched = true
  elseif obj_data.available_to_forces[force_index] and opt.fluid_temperature_key then
    local min1, max1 = parse_fluid_temperature_key(opt.fluid_temperature_key)

    local atf = obj_data.available_to_forces[force_index]

    if atf then
      researched = true
    else
      for fluid_temperature_key, _ in pairs(atf) do
        local min2, max2 = parse_fluid_temperature_key(fluid_temperature_key)

        if min2 >= min1 and max2 <= max1 then
          researched = true
          break
        end
      end
    end
  end
  return obj_data.hidden, researched
end

-- todo: put in flib
local function parse_fluid_temperature_key(key)
  local min, max

  min, max = string.match(key, '^(%d+)%-(%d+)$')
  if min and max then
    return tonumber(min), tonumber(max)
  end

  min = string.match(key, '^(%d+)$')

  if min then
    return tonumber(min), tonumber(min)
  end

  max = string.match(key, '^≤(%d+)$')

  if max then
    return -1000000, tonumber(max)
  end

  min = string.match(key, '^≥(%d+)$')

  if min then
    return tonumber(min), 1000000
  end

  return min, max
end

local function get_should_show(obj_data, player_data, options)
  -- player data
  local force_index = player_data.force_index
  local player_settings = player_data.settings
  local show_hidden = player_settings.show_hidden
  local show_unresearched = player_settings.show_unresearched

  -- check hidden and researched status
  local is_hidden, is_researched = get_properties(obj_data, force_index, options)
  if (show_hidden or not is_hidden) and (show_unresearched or is_researched) then
    -- for recipes - check category to see if it should be shown
    local category = obj_data.category
    local categories = obj_data.recipe_categories
    if category then
      if player_settings.recipe_categories[category] then
        return true, is_hidden, is_researched
      end
    -- for materials - check if any of their categories are enabled
    elseif categories then
      local category_settings = player_settings.recipe_categories
      for category_name in pairs(categories) do
        if category_settings[category_name] then
          return true, is_hidden, is_researched
        end
      end
    else
      return true, is_hidden, is_researched
    end
  end
  return false, is_hidden, is_researched
end

local function get_caption(obj_data, player_data, is_hidden, options)
  -- locals
  local player_settings = player_data.settings
  local translations = player_data.translations

  -- object properties
  local internal_class = obj_data.internal_class
  local prototype_name = obj_data.prototype_name
  local sprite_class = obj_data.sprite_class

  -- translation key
  local translation_key = internal_class == "material" and sprite_class.."."..prototype_name or prototype_name

  -- glyph
  local glyph_str = ""
  if player_settings.show_glyphs then
    glyph_str = build_rich_text(
      "font",
      "RecipeBook",
      class_to_font_glyph[internal_class] or class_to_font_glyph[sprite_class]
    ).."  "
  end
  -- hidden
  local hidden_str = ""
  if is_hidden then
    hidden_str = build_rich_text("font", "default-semibold", translations.gui.hidden_abbrev).."  "
  end
  -- icon
  local icon_str = build_sprite(sprite_class, prototype_name).."  "
  -- amount string
  local amount_str = ""
  if options.amount_string then
    amount_str = build_rich_text("font", "default-semibold", options.amount_string).."  "
  end
  -- name
  local name_str = (
    player_settings.use_internal_names
    and obj_data.prototype_name
    or translations[internal_class][translation_key]
  )

  -- free fluid
  local freefluid_str = ""
  if internal_class == "recipe" and obj_data.category == "creative-mod_free-fluids" and player_settings.show_free_fluid_text_in_caption then
    freefluid_str = " ("..translations.gui.free_fluid..")"
  end

  -- temperature
  local temperature_str = ""
  if options.fluid_temperature_string and (not player_settings.hide_fluid_temperatures_when_single_temperature or obj_data.temperatures_count > 1) then
    temperature_str = options.fluid_temperature_string
  end

  -- output
  return glyph_str..hidden_str..icon_str..amount_str..name_str..freefluid_str..temperature_str
end

local function get_base_tooltip(obj_data, player_data, is_hidden, is_researched, fluid_temperature_string)
  -- locals
  local player_settings = player_data.settings
  local translations = player_data.translations
  local gui_translations = translations.gui
  local fluid_temperature_str = fluid_temperature_string or ""

  -- object properties
  local internal_class = obj_data.internal_class
  local prototype_name = obj_data.prototype_name
  local sprite_class = obj_data.sprite_class

  -- translation
  local name = translations[internal_class][
    internal_class == "material"
    and sprite_class.."."..prototype_name
    or prototype_name
  ]..fluid_temperature_str
  local description = translations[internal_class.."_description"][
    internal_class == "material"
    and sprite_class.."."..prototype_name
    or prototype_name
  ]

  -- settings
  local show_alternate_name = player_settings.show_alternate_name
  local show_descriptions = player_settings.show_descriptions
  local use_internal_names = player_settings.use_internal_names

  -- title
  local title_str = (
    build_sprite(sprite_class, prototype_name)
    .."  "
    ..build_rich_text(
      "font",
      "default-bold",
      build_rich_text("color", "heading", use_internal_names and prototype_name or name)
    )
    .."\n"
  )
  -- alternate name
  local alternate_name_str = ""
  if show_alternate_name then
    alternate_name_str = build_rich_text("color", "green", use_internal_names and name or prototype_name).."\n"
  end
  -- description
  local description_string = ""
  if description and show_descriptions then
    description_string = description and description.."\n" or ""
  end
  -- category class
  local category_class = obj_data.sprite_class == "entity" and obj_data.internal_class or obj_data.sprite_class
  local category_class_str = build_rich_text("color", "info", gui_translations[category_class])
  -- hidden
  local hidden_str = ""
  if is_hidden then
    hidden_str = "  |  "..gui_translations.hidden
  end
  -- unresearched
  local unresearched_str = ""
  if not is_researched then
    unresearched_str = "  |  "..build_rich_text("color", "unresearched", gui_translations.unresearched)
  end

  return title_str..alternate_name_str..description_string..category_class_str..hidden_str..unresearched_str
end

local ingredients_products_keys = {ingredients = true, products = true}

local formatters = {
  crafter = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, options)
      -- locals
      local translations = player_data.translations
      local gui_translations = translations.gui

      -- object properties
      local categories = obj_data.categories
      local rocket_parts_required = obj_data.rocket_parts_required
      local fixed_recipe = obj_data.fixed_recipe

      -- build string
      local base_str = get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
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
          local _, style, label = formatter(fixed_recipe_data, player_data, {always_show = true})
          -- remove glyph from caption, since it's implied
          if player_data.settings.show_glyphs then
            label = string.gsub(label, "^.-nt%]  ", "")
          end
          if style == "rb_unresearched_list_box_item" then
            fixed_recipe_str = title_str..build_rich_text("color", "unresearched", label)
          else
            fixed_recipe_str = title_str..label
          end
          -- help text
          fixed_recipe_help_str = "\n"..gui_translations.control_click_to_view_fixed_recipe
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
      -- open page help
      local open_page_help_str = "\n"..gui_translations.click_to_view
      -- blueprintable
      local blueprintable_str = ""
      if options.blueprint_recipe then
        if obj_data.blueprintable then
          blueprintable_str = "\n"..gui_translations.shift_click_to_get_blueprint
        else
          blueprintable_str = "\n"..build_rich_text("color", "error", gui_translations.blueprint_not_available)
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
  lab = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, options)
      local base_str = get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
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
  material = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, options)
      -- locals
      local gui_translations = player_data.translations.gui

      -- object properties
      local stack_size = obj_data.stack_size

      -- build string
      local base_str = get_base_tooltip(obj_data, player_data, is_hidden, is_researched, options.fluid_temperature_string)
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
      -- interaction help
      local interaction_help_str = ""
      if not options.is_label then
        interaction_help_str = "\n"..gui_translations.click_to_view

        if obj_data.temperatures_count and obj_data.temperatures_count > 1 and not options.fluid_temperature_force then
          interaction_help_str = interaction_help_str.."\n"..gui_translations.shift_click_to_view
        end
      end

      return base_str..stack_size_str..fuel_category_str..fuel_value_str..interaction_help_str
    end,
    enabled = function() return true end
  },
  offshore_pump = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, options)
      -- locals
      local gui_translations = player_data.translations.gui

      -- build string
      local base_str = get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
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
    tooltip = function(obj_data, player_data, is_hidden, is_researched, options)
      -- locals
      local materials_data = global.recipe_book.material
      local gui_translations = player_data.translations.gui
      local player_settings = player_data.settings

      -- build string
      local base_str = get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
      -- crafting_category
      local category_str = (
        "\n"
        ..build_rich_text("font", "default-semibold", gui_translations.category)
        .." "
        ..obj_data.category
      )
      -- crafting time, ingredients and products
      local ip_str_arr = {}
      if player_settings.show_detailed_recipe_tooltips and not options.is_label then
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
              local material_data = materials_data[material.type.."."..material.name]
              if material_data then
                local _, style, label = formatter(
                  material_data,
                  player_data,
                  {amount_string = material.amount_string, fluid_temperature_string = material.fluid_temperature_string, always_show = true}
                )
                if style == "rb_unresearched_list_box_item" then
                  ip_str_arr[#ip_str_arr+1] = "\n  "..build_rich_text("color", "unresearched", label)
                else
                  ip_str_arr[#ip_str_arr+1] = "\n  "..label
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
    tooltip = function(obj_data, player_data, is_hidden, is_researched, options)
      local base_str = get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
      local required_fluid_str = ""
      local interaction_help_str = ""
      local required_fluid = obj_data.required_fluid
      if required_fluid then
        local fluid_data = global.recipe_book.material["fluid."..required_fluid.name]
        if fluid_data then
          local _, style, label = formatter(fluid_data, player_data, {amount_string = required_fluid.amount_string})
          -- remove glyph from caption, since it's implied
          if player_data.settings.show_glyphs then
            label = string.gsub(label, "^.-nt%]  ", "")
          end
          if style == "rb_unresearched_list_box_item" then
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
    tooltip = function(obj_data, player_data, is_hidden, is_researched, options)
      local base_str = get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
      -- interaction help
      local interaction_help_str = "\n"..player_data.translations.gui.click_to_view_technology

      return base_str..interaction_help_str
    end,
    enabled = function() return true end
  }
}

local function format_item(obj_data, player_data, options)
  local should_show, is_hidden, is_researched = get_should_show(obj_data, player_data,options)
  if options.always_show or should_show then
    -- format and return
    local formatter_subtable = formatters[obj_data.internal_class]
    return
      true,
      is_researched and "rb_list_box_item" or "rb_unresearched_list_box_item",
      get_caption(obj_data, player_data, is_hidden, options),
      formatter_subtable.tooltip(
        obj_data,
        player_data,
        is_hidden,
        is_researched,
        options
      ),
      formatter_subtable.enabled(obj_data)
  else
    return false
  end
end

-- get the corresponding data from the cache, or generate it (memoized)
function formatter.format(obj_data, player_data, options)
  options = options or {}

  local player_index = player_data.player_index
  local cache = caches[player_index]
  local _, is_researched = get_properties(obj_data, player_data.force_index, options)
  local cache_key = (
    obj_data.sprite_class
    .."."..obj_data.prototype_name
    .."."..tostring(is_researched)
    .."."..tostring(options.amount_string)
    .."."..tostring(options.fluid_temperature_string)
    .."."..tostring(options.always_show)
    .."."..tostring(options.is_label)
    .."."..tostring(options.blueprint_recipe)
  )
  local cached_return --= cache[cache_key]
  if cached_return then
    return unpack(cached_return)
  else
    local should_show, style, caption, tooltip, enabled = format_item(
      obj_data,
      player_data,
      options
    )
    cache[cache_key] = {should_show, style, caption, tooltip, enabled}
    return should_show, style, caption, tooltip, enabled
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
