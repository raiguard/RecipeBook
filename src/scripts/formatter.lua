local formatter = {}

local constants = require("constants")

local caches = {}

-- upvalues (for optimization)
local class_to_font_glyph = constants.class_to_font_glyph
local colors = constants.colors
local concat = table.concat
local floor = math.floor
local unpack = table.unpack

-- from http://lua-users.org/wiki/SimpleRound
local function round(num, decimals)
  local mult = 10^(decimals or 0)
  return floor(num * mult + 0.5) / mult
end

-- string builders
local function build_rich_text(key, value, inner)
  return "["..key.."="..(key == "color" and colors[value].str or value).."]"..inner.."[/"..key.."]"
end
local function build_sprite(class, name)
  return "[img="..class.."/"..name.."]"
end

local function get_properties(obj_data, force_index)
  local researched
  if obj_data.researched_forces then
    researched = obj_data.researched_forces[force_index] or false
  else
    researched = obj_data.available_to_all_forces or obj_data.available_to_forces[force_index] or false
  end
  return obj_data.hidden, researched
end

local function get_should_show(obj_data, player_data)
  -- player data
  local force_index = player_data.force_index
  local player_settings = player_data.settings
  local show_hidden = player_settings.show_hidden
  local show_unresearched = player_settings.show_unresearched

  -- check hidden and researched status
  local is_hidden, is_researched = get_properties(obj_data, force_index)
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

local function get_caption(obj_data, player_data, is_hidden, amount)
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
    glyph_str = build_rich_text("font", "RecipeBook", class_to_font_glyph[internal_class] or class_to_font_glyph[sprite_class]).."  "
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
  if amount then
    amount_str = build_rich_text("font", "default-semibold", amount).."  "
  end
  -- name
  local name_str = player_settings.use_internal_names and obj_data.prototype_name or translations[internal_class][translation_key]

  -- output
  return glyph_str..hidden_str..icon_str..amount_str..name_str
end

local function get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
  -- locals
  local player_settings = player_data.settings
  local translations = player_data.translations
  local gui_translations = translations.gui

  -- object properties
  local internal_class = obj_data.internal_class
  local prototype_name = obj_data.prototype_name
  local sprite_class = obj_data.sprite_class

  -- translation
  local translation = translations[internal_class][internal_class == "material" and sprite_class.."."..prototype_name or prototype_name]

  -- settings
  local show_alternate_name = player_settings.show_alternate_name
  local use_internal_names = player_settings.use_internal_names

  -- title
  local title_str = build_sprite(sprite_class, prototype_name).."  "
    ..build_rich_text("font", "default-bold", build_rich_text("color", "heading", use_internal_names and prototype_name or translation)).."\n"
  -- alternate name
  local alternate_name_str = ""
  if show_alternate_name then
    alternate_name_str = build_rich_text("color", "green", use_internal_names and translation or prototype_name).."\n"
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

  return title_str..alternate_name_str..category_class_str..hidden_str..unresearched_str
end

local ingredients_products_keys = {ingredients=true, products=true}

local formatters = {
  crafter = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_label)
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
        rocket_parts_str = "\n"..build_rich_text("font", "default-semibold", gui_translations.rocket_parts_required).." "..rocket_parts_required
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
          local _, style, label = formatter.format(fixed_recipe_data, player_data, nil, true)
          if style == "rb_unresearched_list_box_item" then
            fixed_recipe_str = title_str..build_rich_text("color", "unresearched", label)
          else
            fixed_recipe_str = title_str..label
          end
          -- help text
          fixed_recipe_help_str = "\n"..gui_translations.shift_click_to_view_fixed_recipe
        end
      end
      -- crafting speed
      local crafting_speed_str = "\n"..build_rich_text("font", "default-semibold", gui_translations.crafting_speed).." "..round(obj_data.crafting_speed, 2)
      -- crafting categories
      local crafting_categories_str_arr = {"\n"..build_rich_text("font", "default-semibold", gui_translations.crafting_categories)}
      for i = 1, #categories do
        crafting_categories_str_arr[#crafting_categories_str_arr+1] = "\n  "..categories[i]
      end
      local crafting_categories_str = concat(crafting_categories_str_arr)
      -- blueprintable
      local blueprintable_str = ""
      if obj_data.blueprintable then
        blueprintable_str = "\n"..gui_translations.click_to_get_blueprint
      else
        blueprintable_str = "\n"..build_rich_text("color", "error", gui_translations.blueprint_not_available)
      end

      return base_str..rocket_parts_str..fixed_recipe_str..crafting_speed_str..crafting_categories_str..blueprintable_str..fixed_recipe_help_str
    end,
    enabled = function(obj_data) return obj_data.blueprintable end
  },
  lab = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_label)
      local base_str = get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
      -- researching speed
      local researching_speed_str = "\n"..build_rich_text("font", "default-semibold", player_data.translations.gui.researching_speed).." "
        ..round(obj_data.researching_speed, 2)

      return base_str..researching_speed_str
    end,
    enabled = function() return false end
  },
  material = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_label)
      -- locals
      local gui_translations = player_data.translations.gui

      -- object properties
      local stack_size = obj_data.stack_size

      -- build string
      local base_str = get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
      -- stack size
      local stack_size_str = ""
      if stack_size then
        stack_size_str = "\n"..build_rich_text("font", "default-semibold", gui_translations.stack_size).." "..stack_size
      end
      -- interaction help
      local interaction_help_str = ""
      if not is_label then
        interaction_help_str = "\n"..gui_translations.click_to_view
      end

      return base_str..stack_size_str..interaction_help_str
    end,
    enabled = function() return true end
  },
  offshore_pump = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_label)
      -- locals
      local gui_translations = player_data.translations.gui

      -- build string
      local base_str = get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
      -- pumping speed
      local pumping_speed_str = "\n"..build_rich_text("font", "default-semibold", gui_translations.pumping_speed).." "..round(obj_data.pumping_speed * 60, 0)
        ..gui_translations.per_second

      return base_str..pumping_speed_str
    end,
    enabled = function() return false end
  },
  recipe = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_label)
      -- locals
      local materials_data = global.recipe_book.material
      local gui_translations = player_data.translations.gui
      local player_settings = player_data.settings

      -- build string
      local base_str = get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
      -- crafting_category
      local category_str = "\n"..build_rich_text("font", "default-semibold", gui_translations.category).." "..obj_data.category
      -- crafting time, ingredients and products
      local ip_str_arr = {}
      if player_settings.show_detailed_recipe_tooltips and not is_label then
        -- crafting time
        ip_str_arr[1] = "\n"..build_rich_text("font", "default-semibold", gui_translations.crafting_time).." "..round(obj_data.energy, 2).." "
          ..gui_translations.seconds_standalone
        -- ingredients and products
        for material_type in pairs(ingredients_products_keys) do
          local materials = obj_data[material_type]
          local materials_len = #materials
          if materials_len > 0 then
            ip_str_arr[#ip_str_arr+1] = "\n"..build_rich_text("font", "default-semibold", gui_translations[material_type.."_tooltip"])
            for i = 1, #materials do
              local material = materials[i]
              local material_data = materials_data[material.type.."."..material.name]
              if material_data then
                local _, style, label = formatter.format(material_data, player_data, material.amount_string, true)
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
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_label)
      return get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
    end,
    enabled = function() return false end
  },
  technology = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_label)
      local base_str = get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
      -- interaction help
      local interaction_help_str = "\n"..player_data.translations.gui.click_to_view_technology

      return base_str..interaction_help_str
    end,
    enabled = function() return true end
  }
}

local function format_item(obj_data, player_data, amount_string, always_show, is_label)
  local should_show, is_hidden, is_researched = get_should_show(obj_data, player_data)
  if always_show or should_show then
    -- format and return
    local formatter_subtable = formatters[obj_data.internal_class]
    return
      true,
      is_researched and "rb_list_box_item" or "rb_unresearched_list_box_item",
      get_caption(obj_data, player_data, is_hidden, amount_string),
      formatter_subtable.tooltip(obj_data, player_data, is_hidden, is_researched, is_label),
      formatter_subtable.enabled(obj_data, player_data, is_hidden, is_researched)
  else
    return false
  end
end

-- get the corresponding data from the cache, or generate it (memoized)
function formatter.format(obj_data, player_data, amount_string, always_show, is_label)
  local player_index = player_data.player_index
  local cache = caches[player_index]
  local _, is_researched = get_properties(obj_data, player_data.force_index)
  local cache_key = obj_data.sprite_class
  .."."..obj_data.prototype_name
  .."."..(amount_string or "false")
  .."."..tostring(is_researched)
  .."."..tostring(always_show)
  .."."..tostring(is_label)
  local cached_return = cache[cache_key]
  if cached_return then
    return unpack(cached_return)
  else
    local should_show, style, caption, tooltip, enabled = format_item(obj_data, player_data, amount_string, always_show, is_label)
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