local formatter = {}

local fixed_format = require("lib.fixed-precision-format")

local constants = require("constants")

local crafter_form = require("tooltip-formatters.crafter")
local fluid_form = require("tooltip-formatters.fluid")
local item_form = require("tooltip-formatters.item")
local lab_form = require("tooltip-formatters.lab")
local offshore_pump_form = require("tooltip-formatters.offshore-pump")
local recipe_form = require("tooltip-formatters.recipe")
local resource_form = require("tooltip-formatters.resource")
local technology_form = require("tooltip-formatters.technology")

local caches = {}

-- upvalues (for optimization)
local class_to_font_glyph = constants.class_to_font_glyph
local class_to_type = constants.class_to_type
local colors = constants.colors
local concat = table.concat

-- string builders
local function build_rich_text(key, value, inner)
  return "["..key.."="..(key == "color" and colors[value].str or value).."]"..inner.."[/"..key.."]"
end
local function build_sprite(class, name)
  return "[img="..class.."/"..name.."]"
end

local function get_properties(obj_data, force_index)
  local researched
  if obj_data.enabled_at_start then
    researched = true
  elseif obj_data.researched_forces then
    researched = obj_data.researched_forces[force_index] or false
  else
    researched = true
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
      for _, category_name in ipairs(categories) do
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
  return glyph_str..hidden_str..icon_str..amount_str..name_str
end

local function get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
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
  -- unresearched
  local unresearched_str = ""
  if not is_researched then
    unresearched_str = "  |  "..build_rich_text("color", "unresearched", gui_translations.unresearched)
  end

  return title_str..alternate_name_str..description_string..category_class_str..hidden_str..unresearched_str
end

local functions = {
  get_base_tooltip = get_base_tooltip,
  build_rich_text = build_rich_text,
  formatter = formatter,
  concat = concat,
  fixed_format = fixed_format
}

crafter_form.init(functions)
fluid_form.init(functions)
item_form.init(functions)
lab_form.init(functions)
offshore_pump_form.init(functions)
recipe_form.init(functions)
resource_form.init(functions)
technology_form.init(functions)

local formatters = {
  crafter = {
    tooltip = crafter_form.tooltip_formatter,
    enabled = function() return true end
  },
  fluid = {
    tooltip = fluid_form.tooltip_formatter,
    enabled = function() return true end
  },
  item = {
    tooltip = item_form.tooltip_formatter,
    enabled = function() return true end
  },
  lab = {
    tooltip = lab_form.tooltip_formatter,
    enabled = function() return false end
  },
  offshore_pump = {
    tooltip = offshore_pump_form.tooltip_formatter,
    enabled = function() return false end
  },
  recipe = {
    tooltip = recipe_form.tooltip_formatter,
    enabled = function() return true end
  },
  resource = {
    tooltip = resource_form.tooltip_formatter,
    enabled = function(obj_data) return obj_data.required_fluid and true or false end
  },
  technology = {
    tooltip = technology_form.tooltip_formatter,
    enabled = function() return true end
  }
}

local function format_item(obj_data, player_data, options)
  local should_show, is_hidden, is_researched = get_should_show(obj_data, player_data)
  if options.always_show or should_show then
    -- format and return
    local formatter_subtable = formatters[obj_data.class]
    return {
      caption = get_caption(obj_data, player_data, is_hidden, options.amount_string),
      is_enabled = formatter_subtable.enabled(obj_data),
      is_researched = is_researched,
      tooltip = formatter_subtable.tooltip(
        obj_data,
        player_data,
        is_hidden,
        is_researched,
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
  local _, is_researched = get_properties(obj_data, player_data.force_index)
  local cache_key = (
    obj_data.class
    .."."..(obj_data.name or obj_data.prototype_name)
    .."."..tostring(is_researched)
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
