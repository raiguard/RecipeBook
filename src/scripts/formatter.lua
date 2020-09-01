local formatter = {}

local constants = require("constants")

local caches = {}

-- upvalues (for optimization)
local class_to_font_glyph = constants.class_to_font_glyph
local colors = constants.colors
local concat = table.concat
local floor = math.floor

-- round
local function round(num, decimals)
  local mult = 10^(decimals or 0)
  return floor(num * mult + 0.5) / mult
end

local function build_rich_text(key, value, inner, suffix)
  return concat{"[", key, "=", key == "color" and colors[value].str or value, "]", inner, "[/", key, "]", suffix}
end

local function build_sprite(class, name, suffix)
  return concat{"[img=", class, "/", name, "]", suffix}
end

-- string builder
local function builder_add(self, str)
  self[#self+1] = str
end
local function builder_output(self)
  return concat(self)
end
local function create_builder()
  return {
    add = builder_add,
    output = builder_output
  }
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

local function caption_formatter(obj_data, player_data, is_hidden, amount)
  -- locals
  local player_settings = player_data.settings
  local translations = player_data.translations

  -- object properties
  local internal_class = obj_data.internal_class
  local prototype_name = obj_data.prototype_name
  local rocket_parts = obj_data.rocket_parts_required
  local sprite_class = obj_data.sprite_class

  -- translation key
  local translation_key = internal_class == "material" and concat{sprite_class, ".", prototype_name} or prototype_name

  -- build string
  local builder = create_builder()
  -- glyph
  if player_settings.show_glyphs then
    builder:add(build_rich_text("font", "RecipeBook", class_to_font_glyph[internal_class] or class_to_font_glyph[sprite_class], "  "))
  end
  -- hidden
  if is_hidden then
    builder:add(build_rich_text("font", "default-semibold", translations.gui.hidden_abbrev, "  "))
  end
  -- icon
  builder:add(build_sprite(sprite_class, prototype_name, "  "))
  -- rocket parts
  if rocket_parts then
    builder:add(build_rich_text("font", "default-semibold", rocket_parts.."x", "  "))
  end
  -- amount string
  if amount then
    builder:add(build_rich_text("font", "default-semibold", amount, "  "))
  end
  -- name
  builder:add(player_settings.use_internal_names and obj_data.prototype_name or translations[internal_class][translation_key])

  -- output
  return builder:output()
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
  local translation = translations[internal_class][internal_class == "material" and concat{sprite_class, ".", prototype_name} or prototype_name]

  -- settings
  local show_alternate_name = player_settings.show_alternate_name
  local use_internal_names = player_settings.use_internal_names

  -- build string
  local builder = create_builder()
  -- title
  builder:add(build_sprite(sprite_class, prototype_name, "  "))
  builder:add(build_rich_text("font", "default-bold", build_rich_text("color", "heading", use_internal_names and prototype_name or translation), "\n"))
  -- alternate name
  if show_alternate_name then
    builder:add(build_rich_text("color", "green", use_internal_names and translation or prototype_name, "\n"))
  end
  -- category class
  local category_class = obj_data.sprite_class == "entity" and obj_data.internal_class or obj_data.sprite_class
  builder:add(build_rich_text("color", "info", gui_translations[category_class]))
  -- hidden
  if is_hidden then
    builder:add("  |  "..gui_translations.hidden)
  end
  -- unresearched
  if not is_researched then
    builder:add("  |  "..build_rich_text("color", "unresearched", gui_translations.unresearched))
  end

  return builder
end

local ingredients_products_keys = {ingredients=true, products=true}

local formatters = {
  crafter = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_label)
      -- locals
      local translations = player_data.translations
      local gui_translations = translations.gui

      -- build string
      local builder = get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
      -- rocket parts
      local rocket_parts_required = obj_data.rocket_parts_required
      if rocket_parts_required then
        builder:add("\n")
        builder:add(build_rich_text("font", "default-semibold", gui_translations.rocket_parts_required, " "))
        builder:add(rocket_parts_required)
      end
      -- fixed recipe
      local fixed_recipe = obj_data.fixed_recipe
      local fixed_recipe_help_text
      if fixed_recipe then
        -- get fixed recipe data
        local fixed_recipe_data = global.recipe_book.recipe[obj_data.fixed_recipe]
        if fixed_recipe_data then
          -- view text
          fixed_recipe_help_text = "\n"..gui_translations.shift_click_to_view_fixed_recipe
          -- fixed recipe
          builder:add("\n")
          builder:add(build_rich_text("font", "default-semibold", gui_translations.fixed_recipe, " "))
          local _, style, label = formatter.format(fixed_recipe_data, player_data, nil, true)
          if style == "rb_unresearched_list_box_item" then
            builder:add(build_rich_text("color", "unavailable", label))
          else
            builder:add(label)
          end
        end
      end
      -- crafting speed
      builder:add("\n"..build_rich_text("font", "default-semibold", gui_translations.crafting_speed, " "))
      builder:add(round(obj_data.crafting_speed, 2))
      -- crafting categories
      builder:add("\n"..build_rich_text("font", "default-semibold", gui_translations.crafting_categories))
      local categories = obj_data.categories
      for i = 1, #categories do
        builder:add("\n  "..categories[i])
      end
      -- interaction help
      if obj_data.blueprintable then
        builder:add("\n"..gui_translations.click_to_get_blueprint)
      else
        builder:add("\n"..build_rich_text("color", "error", gui_translations.blueprint_not_available))
      end
      -- fixed recipe help
      if fixed_recipe_help_text then
        builder:add(fixed_recipe_help_text)
      end

      return builder:output()
    end,
    enabled = function(obj_data) return obj_data.blueprintable end
  },
  lab = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_label)
      local builder = get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
      -- researching speed
      builder:add("\n")
      builder:add(build_rich_text("font", "default-semibold", player_data.translations.gui.researching_speed, " "))
      builder:add(round(obj_data.researching_speed, 2))

      return builder:output()
    end,
    enabled = function() return false end
  },
  material = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_label)
      -- locals
      local gui_translations = player_data.translations.gui

      -- build string
      local builder = get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
      -- stack size
      local stack_size = obj_data.stack_size
      if stack_size then
        builder:add("\n")
        builder:add(build_rich_text("font", "default-semibold", gui_translations.stack_size, " "..stack_size))
      end
      -- interaction help
      if not is_label then
        builder:add("\n"..gui_translations.click_to_view)
      end

      return builder:output()
    end,
    enabled = function() return true end
  },
  offshore_pump = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_label)
      -- locals
      local gui_translations = player_data.translations.gui

      -- build string
      local builder = get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
      -- pumping speed
      builder:add("\n"..build_rich_text("font", "default-semibold", gui_translations.pumping_speed, " "))
      builder:add(round(obj_data.pumping_speed * 60, 0)..gui_translations.per_second)

      return builder:output()
    end,
    enabled = function() return false end
  },
  recipe = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_label)
      -- locals
      local materials_data = global.recipe_book.material
      local translations = player_data.translations
      local gui_translations = translations.gui

      -- build string
      local builder = get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
      -- ingredients and products
      for material_type in pairs(ingredients_products_keys) do
        builder:add("\n"..build_rich_text("font", "default-semibold", gui_translations[material_type.."_tooltip"]))
        local materials = obj_data[material_type]
        for i = 1, #materials do
          local material = materials[i]
          local material_data = materials_data[material.type.."."..material.name]
          if material_data then
            builder:add("\n  ")
            local _, style, label = formatter.format(material_data, player_data, material.amount_string, true)
            if style == "rb_unresearched_list_box_item" then
              builder:add(build_rich_text("color", "unresearched", label))
            else
              builder:add(label)
            end
          end
        end
      end
      -- interaction help
      if not is_label then
        builder:add("\n"..gui_translations.click_to_view)
      end

      return builder:output()
    end,
    enabled = function() return true end
  },
  resource = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_label)
      return get_base_tooltip(obj_data, player_data, is_hidden, is_researched):output()
    end,
    enabled = function() return false end
  },
  technology = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_label)
      local builder = get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
      -- interaction help
      builder:add("\n"..player_data.translations.gui.click_to_view_technology)
      return builder:output()
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
      caption_formatter(obj_data, player_data, is_hidden, amount_string),
      formatter_subtable.tooltip(obj_data, player_data, is_hidden, is_researched, is_label),
      formatter_subtable.enabled(obj_data, player_data, is_hidden, is_researched)
  else
    return false
  end
end

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
    return table.unpack(cached_return)
  else
    local should_show, style, caption, tooltip, enabled = format_item(obj_data, player_data, amount_string, always_show, is_label)
    cache[cache_key] = { should_show, style, caption, tooltip, enabled }
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