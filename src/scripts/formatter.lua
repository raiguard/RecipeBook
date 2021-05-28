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
local fixed_format = require("lib.fixed-precision-format")
local math = require("__flib__.math")
local misc = require("__flib__.misc")
local table = require("__flib__.table")

local constants = require("constants")

local caches = {}

local formatter = {}

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

local function rich_text(key, value, inner)
  return "["..key.."="..(key == "color" and constants.colors[value].str or value).."]"..inner.."[/"..key.."]"
end

local function sprite(class, name)
  return "[img="..class.."/"..name.."]"
end

local function control(content, action)
  return "\n"
    ..rich_text("color", "info", rich_text("font", "default-semibold", content..":"))
    .." "
    ..action
end

local function number(value)
  return misc.delineate_number(math.round_to(value, 2))
end

local function fuel_value(value, gui_translations)
  return fixed_format(value, 3, "2")..gui_translations.si_joule
end

local function percent(value, gui_translations)
  return expand_string(gui_translations.format_percent, number(value * 100))
end

local function seconds(value, gui_translations)
  return expand_string(gui_translations.format_seconds, number(value * 60))
end

local function seconds_from_ticks(value, gui_translations)
  return seconds(value / 60, gui_translations)
end

local function per_second(value, gui_translations)
  return number(value)..gui_translations.per_second_suffix
end

local function object(value, _, player_data, options)
  local obj_data = global.recipe_book[value.class][value.name]
  local info = formatter(obj_data, player_data, options)
  return info.caption
end

local function get_amount_string(amount_ident, player_data, options)
  local cache_key = build_cache_key(
    "amount_string",
    amount_ident.amount or "false",
    amount_ident.amount_min or "false",
    amount_ident.amount_max or "false",
    amount_ident.probability or "false",
    options.amount_only or "false"
  )
  local cache = caches[player_data.player_index]
  local cached = cache[cache_key]
  if cached then
    return cached
  end

  local amount = amount_ident.amount
  local output
  if options.amount_only then
    output = amount_ident.amount ~= nil
      and tostring(math.round_to(amount, 1))
      or "~"..math.round_to((amount_ident.amount_min + amount_ident.amount_max) / 2, 1)
  else
    local gui_translations = player_data.translations.gui
    -- Amount
    if amount then
      output = expand_string(gui_translations.format_amount, number(amount))
    else
      output = expand_string(
        gui_translations.format_amount,
        number(amount_ident.amount_min).." - "..number(amount_ident.amount_max)
      )
    end

    -- Probability
    local probability = amount_ident.probability
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
    "caption",
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
  if settings.show_glyphs and not options.hide_glyph then
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

local function get_base_tooltip(obj_data, obj_properties, player_data, options)
  local settings = player_data.settings
  local gui_translations = player_data.translations.gui

  local prototype_name = obj_data.prototype_name
  local name = obj_data.name or prototype_name
  local class = obj_data.class
  local type = constants.class_to_type[class]

  local cache = caches[player_data.player_index]
  local cache_key = build_cache_key(
    "base_tooltip",
    obj_data.class,
    name,
    obj_properties.enabled,
    obj_properties.hidden,
    obj_properties.researched
  )
  local cached = cache[cache_key]
  if cached then
    return cached
  end

  local before
  if type then
    before = sprite(type, prototype_name).."  "
  else
    before = ""
  end

  local name_str
  if settings.use_internal_names then
    name_str = name
  else
    name_str = player_data.translations[class][name]
  end

  local after = rich_text("font", "default-semibold", rich_text("color", "heading", name_str))
    .."\n"
    ..rich_text("color", "info", gui_translations[class])

  if not obj_properties.researched then
    after = after.."  |  "..rich_text("color", "unresearched", gui_translations.unresearched)
  end

  if not obj_properties.enabled then
    after = after.."  |  "..gui_translations.disabled
  end

  if obj_properties.hidden then
    after = after.."  |  "..gui_translations.hidden
  end

  local output = {before = before, after = after}
  cache[cache_key] = output
  return output
end

local function get_tooltip_deets(obj_data, obj_properties, player_data, options)
  local gui_translations = player_data.translations.gui

  local cache = caches[player_data.player_index]
  local cache_key = build_cache_key(
    "tooltip_deets",
    obj_data.class,
    obj_data.name or obj_data.prototype_name
  )
  local cached = cache[cache_key]
  if cached then
    return cached
  end

  local deets_structure = constants.tooltips[obj_data.class]

  local output = ""

  for _, deet in pairs(deets_structure) do
    local values
    local type = deet.type
    if type == "plain" then
      values = {obj_data[deet.source]}
    elseif type == "list" then
      values = table.array_copy(obj_data[deet.source])
    end

    local values_output = ""
    for _, value in pairs(values) do
      local fmtr = deet.formatter
      if fmtr then
        value = formatter[fmtr](value, gui_translations, player_data, deet.options)
      end
      if value then
        if type == "plain" then
          values_output = values_output.."  "..value
        elseif type == "list" then
          values_output = values_output.."\n    "..value
        end
      end
    end

    if #values_output > 0 then
      output = output
        .."\n"
        ..rich_text("font", "default-semibold", gui_translations[deet.label or deet.source]..":")
        ..values_output
    end
  end

  cache[cache_key] = output
  return output
end

local function get_interaction_helps(obj_data, obj_properties, player_data, options)
  local gui_translations = player_data.translations.gui

  local cache = caches[player_data.player_index]
  local cache_key = build_cache_key(
    "interaction_helps",
    obj_data.class,
    obj_data.name or obj_data.prototype_name
  )
  local cached = cache[cache_key]
  if cached then
    return cached
  end

  local output = ""

  local helps = constants.interaction_helps[obj_data.class]

  for _, help in pairs(helps) do
    local value = ""
    local skip_label = false
    local option = help.option
    if option and not options[option] then
      if help.alternate_label then
        -- HACK: This is hardcoded, since alternate_label is always an error right now
        value = rich_text("color", "error", gui_translations[help.alternate_label])
        skip_label = true
      end
    else
      local source = help.source
      if source then
        local obj_value = obj_data[source]
        if obj_value then
          if help.force_label then
            value = gui_translations[help.label]
          else
            local fmtr = help.formatter
            if fmtr then
              value = formatter[fmtr](obj_value, gui_translations, player_data, help.options)
            else
              value = gui_translations[obj_value]
            end
          end
        end
      else
        value = gui_translations[help.label]
      end
    end

    if #value > 0 then
      local input_name = help.modifier and help.modifier.."_click" or "click"
      local label = skip_label and "" or rich_text(
        "font",
        "default-semibold",
        rich_text("color", "info", gui_translations[input_name]..": ")
      )
      output = output.."\n"..label..value
    end
  end

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

  return {hidden = obj_data.hidden or false, researched = researched, enabled = enabled}
end

function formatter.format(obj_data, player_data, options)
  options = options or {}

  local obj_properties = get_obj_properties(obj_data, player_data.force)
  local amount_ident = options.amount_ident

  -- Caption
  local caption_output
  if amount_ident and options.amount_only then
    caption_output = get_amount_string(amount_ident, player_data, options)
  else
    local caption = get_caption(obj_data, obj_properties, player_data, options)
    if amount_ident then
      caption_output = caption.before
      ..rich_text(
        "font",
        "default-semibold",
        get_amount_string(amount_ident, player_data, options)
      )
      .."  "
      ..caption.after
    else
      caption_output = caption.before..caption.after
    end
  end

  -- Tooltip
  local base_tooltip = get_base_tooltip(obj_data, obj_properties, player_data, options)
  local tooltip_output
  if amount_ident and options.amount_only then
    tooltip_output = base_tooltip.before
      ..rich_text(
        "font",
        "default-bold",
        -- TODO: Perhaps don't pass an empty options table here
        rich_text("color", "heading", get_amount_string(amount_ident, player_data, {}))
      )
      .."  "
      ..base_tooltip.after
  else
    tooltip_output = base_tooltip.before..base_tooltip.after
  end
  local settings = player_data.settings
  if settings.show_detailed_tooltips then
    tooltip_output = tooltip_output..get_tooltip_deets(obj_data, obj_properties, player_data, options)
  end
  if settings.show_interaction_helps then
    tooltip_output = tooltip_output..get_interaction_helps(obj_data, obj_properties, player_data, options)
  end

  return {
    caption = caption_output,
    enabled = obj_properties.enabled,
    researched  = obj_properties.researched,
    tooltip = tooltip_output,
  }
end

function formatter.create_cache(player_index)
  caches[player_index] = {}
end

function formatter.create_all_caches()
  for i in pairs(global.players) do
    caches[i] = {}
  end
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
    {rb.crafter["rocket-silo"], {}},
    {rb.fluid["steam.975"], {amount_ident = {amount = 55, probability = 0.75}}},
    {rb.group["production"], {}},
    {rb.item["loader"], {amount_ident = {amount_min = 4, amount_max = 7}}},
    {rb.item["coal"], {amount_ident = {amount_min = 4, amount_max = 7}, amount_only = true}},
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
      frame.add{type = "button", style = "rb_list_box_item", caption = info.caption, tooltip = info.tooltip}
    end
  end
end

formatter.build_cache_key = build_cache_key
formatter.control = control
formatter.expand_string = expand_string
formatter.fuel_value = fuel_value
formatter.number = number
formatter.object = object
formatter.percent = percent
formatter.per_second = per_second
formatter.rich_text = rich_text
formatter.seconds_from_ticks = seconds_from_ticks
formatter.seconds = seconds
formatter.sprite = sprite

setmetatable(formatter, {__call = function(_, ...) return formatter.format(...) end})

return formatter
