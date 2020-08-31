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

-- string builder
local function builder_add(self, str)
  local arr = self.arr
  arr[#arr+1] = str
end
local function builder_add_rich_text(self, key, value, inner, suffix)
  local rich_text_arr = {"[", key, "=", key == "color" and colors[value].str or value, "]", inner, "[/", key, "]", suffix}
  local arr = self.arr
  local arr_len = #arr
  for i = 1, #rich_text_arr do
    arr[arr_len + i] = rich_text_arr[i]
  end
end
local function builder_add_sprite(self, class, name, suffix)
  local sprite_arr = {"[img=", class, "/", name, "]", suffix}
  local arr = self.arr
  local arr_len = #arr
  for i = 1, #sprite_arr do
    arr[arr_len + i] = sprite_arr[i]
  end
end
local function builder_output(self)
  return concat(self.arr)
end
local function create_builder()
  return {
    add = builder_add,
    add_rich_text = builder_add_rich_text,
    add_sprite = builder_add_sprite,
    arr = {},
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

  -- key and translation
  local translation_key = obj_data.internal_class == "material" and concat{sprite_class, ".", prototype_name} or prototype_name
  local translation = translations[internal_class][translation_key]

  -- build string
  local builder = create_builder()
  -- glyph
  if player_settings.show_glyphs then
    builder:add_rich_text("font", "RecipeBook", class_to_font_glyph[internal_class] or class_to_font_glyph[sprite_class], "  ")
  end
  -- hidden
  if is_hidden then
    builder:add_rich_text("font", "default-semibold", translations.gui.hidden_abbrev, "  ")
  end
  -- icon
  builder:add_sprite(sprite_class, prototype_name, "  ")
  -- rocket parts
  if rocket_parts then
    builder:add_rich_text("font", "default-semibold", rocket_parts.."x", "  ")
  end
  -- amount string
  if amount then
    builder:add_rich_text("font", "default-semibold", amount, "  ")
  end
  -- name
  builder:add(player_settings.use_internal_names and obj_data.prototype_name or translation)

  -- output
  return builder:output()
end

local function get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
  local translations = player_data.translations
  local translation_key = obj_data.internal_class == "material" and obj_data.sprite_class.."."..obj_data.prototype_name or obj_data.prototype_name
  local translation = player_data.translations[obj_data.internal_class][translation_key]
  local use_internal_names = player_data.settings.use_internal_names
  local name = use_internal_names and obj_data.prototype_name or translation
  local alternate_name = player_data.settings.show_alternate_name and ("\n"..(use_internal_names and translation or obj_data.prototype_name)) or ""

  local category_class = obj_data.sprite_class == "entity" and obj_data.internal_class or obj_data.sprite_class

  local hidden_string = is_hidden and "  |  "..translations.gui.hidden or ""
  local unresearched_string = not is_researched and "  |  [color="..colors.unresearched.str.."]"..translations.gui.unresearched.."[/color]" or ""

  return
    "[img="..obj_data.sprite_class.."/"..obj_data.prototype_name.."]  [font=default-bold][color="..colors.heading.str.."]"..name.."[/color][/font]"
    .."[color="..colors.green.str.."]"..alternate_name.."[/color]"
    .."\n[color="..colors.info.str.."]"..translations.gui[category_class].."[/color]"..hidden_string..unresearched_string
end

local formatters = {
  crafter = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_label)
      local rocket_parts_text = obj_data.rocket_parts_required
        and "\n[font=default-semibold]"..player_data.translations.gui.rocket_parts_required.."[/font] "..obj_data.rocket_parts_required
        or ""
      local fixed_recipe_text = ""
      local fixed_recipe_view_text = ""
      if obj_data.fixed_recipe then
        local fixed_recipe_data = global.recipe_book.recipe[obj_data.fixed_recipe]
        if fixed_recipe_data then
          fixed_recipe_view_text = "\n"..player_data.translations.gui.shift_click_to_view_fixed_recipe
          local _, style, label = formatter.format(fixed_recipe_data, player_data, nil, true)
          -- remove glyph from label
          label = string.gsub(label, "%[font=RecipeBook%].%[/font%]  ", "")
          local color_prefix = ""
          local color_suffix = ""
          if style == "rb_unresearched_list_box_item" then
            color_prefix = "[color="..colors.unresearched.str.."]"
            color_suffix = "[/color]"
          end
          fixed_recipe_text = "\n[font=default-semibold]"..player_data.translations.gui.fixed_recipe.."[/font]  "..color_prefix..label..color_suffix
        end
      end

      local crafting_speed_string = "\n[font=default-semibold]"..player_data.translations.gui.crafting_speed.."[/font] "..round(obj_data.crafting_speed, 3)

      local categories_string = "\n[font=default-semibold]"..player_data.translations.gui.crafting_categories.."[/font]"
      local categories = obj_data.categories
      for i = 1, #categories do
        categories_string = categories_string.."\n  "..categories[i]
      end

      local blueprint_text = obj_data.blueprintable and "\n"..player_data.translations.gui.click_to_get_blueprint
        or "\n[color="..colors.error.str.."]"..player_data.translations.gui.blueprint_not_available.."[/color]"
      return get_base_tooltip(obj_data, player_data, is_hidden, is_researched)..rocket_parts_text..fixed_recipe_text..crafting_speed_string..categories_string
        ..blueprint_text..fixed_recipe_view_text
    end,
    enabled = function(obj_data) return obj_data.blueprintable end
  },
  lab = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_label)
      local researching_speed_text = "\n[font=default-semibold]"..player_data.translations.gui.researching_speed.."[/font] "
        ..round(obj_data.researching_speed, 3)
      return get_base_tooltip(obj_data, player_data, is_hidden, is_researched)..researching_speed_text
    end,
    enabled = function() return false end
  },
  material = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_label)
      local interaction_help = is_label and "" or ("\n"..player_data.translations.gui.click_to_view)
      local stack_size = obj_data.stack_size and "\n[font=default-semibold]"..player_data.translations.gui.stack_size.."[/font] "..obj_data.stack_size or ""
      return get_base_tooltip(obj_data, player_data, is_hidden, is_researched)..stack_size..interaction_help
    end,
    enabled = function() return true end
  },
  offshore_pump = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_label)
      local pumping_speed_text = "\n[font=default-semibold]"..player_data.translations.gui.pumping_speed.."[/font] "..round(obj_data.pumping_speed * 60, 1)
        ..player_data.translations.gui.per_second
      return get_base_tooltip(obj_data, player_data, is_hidden, is_researched)..pumping_speed_text
    end,
    enabled = function() return false end
  },
  recipe = {
    tooltip = function(obj_data, player_data, is_hidden, is_researched, is_label)
      local materials_data = global.recipe_book.material

      -- ingredients
      local ingredients_string = "\n[font=default-semibold]"..player_data.translations.gui.ingredients_tooltip.."[/font]"
      local ingredients = obj_data.ingredients
      for i = 1, #ingredients do
        local ingredient = ingredients[i]
        local ingredient_data = materials_data[ingredient.type.."."..ingredient.name]
        if ingredient_data then
          local _, style, label = formatter.format(ingredient_data, player_data, ingredient.amount_string, true)
          local color_prefix = ""
          local color_suffix = ""
          if style == "rb_unresearched_list_box_item" then
            color_prefix = "[color="..colors.unresearched.str.."]"
            color_suffix = "[/color]"
          end
          ingredients_string = ingredients_string.."\n  "..color_prefix..label..color_suffix
        end
      end

      -- products
      local products_string = "\n[font=default-semibold]"..player_data.translations.gui.products_tooltip.."[/font]"
      local products = obj_data.products
      for i = 1, #products do
        local product = products[i]
        local product_data = materials_data[product.type.."."..product.name]
        if product_data then
          local _, style, label = formatter.format(product_data, player_data, product.amount_string, true)
          local color_prefix = ""
          local color_suffix = ""
          if style == "rb_unresearched_list_box_item" then
            color_prefix = "[color="..colors.unresearched.str.."]"
            color_suffix = "[/color]"
          end
          products_string = products_string.."\n  "..color_prefix..label..color_suffix
        end
      end

      local interaction_help = is_label and "" or ("\n"..player_data.translations.gui.click_to_view)
      return get_base_tooltip(obj_data, player_data, is_hidden, is_researched)..ingredients_string..products_string..interaction_help
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
      local interaction_help = is_label and "" or ("\n"..player_data.translations.gui.click_to_view_technology)
      return get_base_tooltip(obj_data, player_data, is_hidden, is_researched)..interaction_help
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