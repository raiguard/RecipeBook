--[[
  DESIGN NOTES:
  - Amount strings are not pre-processed, but are generated as part of the format call (allowing for locale differences)
  - Multiple caches:
    - Base caption
    - Base tooltip
    - Tooltip contents
    - Amount strings
    - Control hints?
  - The output is assembled from these individual caches
    - Perhaps the final outputs should be cached as well?
    - The idea here is to avoid re-generating the entire caption and tooltip when just the amount or control hints are
      different
  - Consider moving the show / don't show logic to `util` instead of `formatter`, so it can be used elsewhere
  - Per-instance settings:
    - show_glyphs
    - show_tooltip_details
    - amount_only
    - is_label: show_glyphs = false, show_tooltip_details = false
]]
local math = require("__flib__.math")
local misc = require("__flib__.misc")
local table = require("__flib__.table")

local constants = require("constants")

local caches = {}

local formatter = {}

local caches_template = {
  caption = {},
  amount_string = {},
  -- tooltip_base = {},
  -- tooltip_deets = {},
  -- control_hints = {},
}

local function build_cache_key(...)
  return table.concat(table.map({...}, function(v) return tostring(v) end), ".")
end

local function expand_string(source, ...)
  local arg = {...}
  for i = 1, #arg do
    source = string.gsub(source, "__"..i.."__", arg[i])
  end
  return source
end

local function number(value)
  return misc.delineate_number(math.round_to(value, 2))
end

local function rich_text(key, value, inner)
  return "["..key.."="..(key == "color" and constants.colors[value].str or value).."]"..inner.."[/"..key.."]"
end

local function sprite(class, name)
  return "[img="..class.."/"..name.."]"
end

local function get_amount_string(amount_data, gui_translations, player_index, amount_only)
  local cache_key = build_cache_key(
    amount_data.amount or "nil",
    amount_data.amount_min or "nil",
    amount_data.amount_max or "nil",
    amount_data.probability or "nil"
  )
  local cache = caches[player_index].amount_string
  local cached = cache[cache_key]
  if cached then
    return cached
  end

  local amount = amount_data.amount
  local output
  if amount_only then
    output = amount_data.amount == nil
      and tostring(math.round_to(amount, 1))
      or "~"..math.round_to((amount_data.amount_min + amount_data.amount_max) / 2, 1)
  else
    -- Amount
    if amount then
      output = expand_string(gui_translations.format_amount, number(amount))
    else
      output = expand_string(
        gui_translations.format_amount,
        number(amount_data.amount_min).." - "..number(amount_data.amount_max)
      )
    end

    -- Probability
    local probability = amount_data.probability
    if probability and probability < 1 then
      output = (probability * 100).."% "..output
    end
  end

  cache[cache_key] = output
  return output
end

local function get_caption(obj_data, obj_properties, player_data, options)
  local settings = player_data.settings
  local gui_translations = player_data.translations.gui

  local prototype_name = obj_data.prototype_name
  local name = obj_data.name or prototype_name

  local cache = caches[player_data.player_index]
  local cache_key = build_cache_key(
    obj_data.class,
    name,
    obj_properties.enabled,
    obj_properties.hidden
  )
  local cached = cache[cache_key]
  if cached then
    return cached
  end

  local class = obj_data.class

  local before = ""
  if settings.show_glyphs then
    before = rich_text(
      "font",
      "RecipeBook",
      constants.class_to_font_glyph[class] or constants.class_to_font_glyph[class]
    ).."  "
  end

  if obj_properties.hidden then
    before = before..rich_text("font", "default-semibold", gui_translations.hidden_abbrev).."  "
  end
  if not obj_properties.enabled then
    before = before..rich_text("font", "default-semibold", gui_translations.disabled_abbrev).."  "
  end

  local type = constants.class_to_type[class]
  if type then
    before = before..sprite(type, prototype_name).."  "
  end

  local after
  if settings.use_internal_names then
    after = name
  else
    after = player_data.translations[class][name]
  end

  local output = {before = before, after = after}
  cache[cache_key] = output
  return output
end

local function get_obj_properties(obj_data, force)
  local researched
  if obj_data.enabled_at_start then
    researched = true
  elseif obj_data.researched_forces then
    researched = obj_data.researched_forces[force.index] or false
  else
    researched = true
  end

  local enabled = true
  -- We have to get the current enabled status from the object itself
  -- Recipes are unlocked by "enabling" them, so only check a recipe if it's researched
  if obj_data.class == "recipe" and researched then
    enabled = force.recipes[obj_data.prototype_name].enabled
  elseif obj_data.class == "technology" then
    enabled = force.technologies[obj_data.prototype_name].enabled
  end

  return {hidden = obj_data.hidden, researched = researched, enabled = enabled}
end

function formatter.format(obj_data, player_data, options)
  options = options or {}

  local obj_properties = get_obj_properties(obj_data, player_data.force)
  local amount_ident = options.amount_ident

  -- Caption
  local caption = get_caption(obj_data, obj_properties, player_data, options)
  local output
  if amount_ident then
    output = caption.before
    ..rich_text(
      "font",
      "default-semibold",
      get_amount_string(amount_ident, player_data.translations.gui, player_data.player_index, options.amount_only)
    )
    .."  "
    ..caption.after
  else
    output = caption.before..caption.after
  end

  return {
    caption = output,
    enabled = true,
    researched  = true,
    tooltip = "",
  }
end

function formatter.create_cache(player_index)
  caches[player_index] = table.shallow_copy(caches_template)
end

function formatter.build_player_data(player, player_table)
  return {
    favorites = player_table.favorites,
    force = player.force,
    history = player_table.history.global,
    player_index = player.index,
    settings = player_table.settings,
    translations = player_table.translations
  }
end

function formatter.create_test_gui(player, player_table)
  local rb = global.recipe_book
  local test_objects = {
    {rb.crafter["assembling-machine-3"], {}},
    {rb.fluid["steam.975"], {amount_ident = {amount = 55, probability = 0.75}}},
    {rb.group["production"], {}},
    {rb.item["loader"], {amount_ident = {amount_min = 4, amount_max = 7}}},
    {rb.lab["lab"], {}},
    {rb.recipe["advanced-oil-processing"], {amount_ident = {amount = 69}}},
    {rb.recipe_category["crafting-with-fluid"], {}},
    {rb.technology["kr-logo"], {}},
  }
  local player_data = formatter.build_player_data(player, player_table)
  local frame = player.gui.screen.add{type = "frame", style = "deep_frame_in_shallow_frame", direction = "vertical"}
  for _, obj in pairs(test_objects) do
    local info = formatter(obj[1], player_data, obj[2])
    if info then
      frame.add{type = "button", style = "rb_list_box_item", caption = info.caption}
    end
  end
end

setmetatable(formatter, {__call = function(_, ...) return formatter.format(...) end})

return formatter
