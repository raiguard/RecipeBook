local flib_format = require("__flib__.format")
local flib_math = require("__flib__.math")
local core_util = require("__core__.lualib.util")
local util = require("scripts.util")

--- @class GuiUtil
local gui_util = {}

--- @param crafting_time double?
--- @return LocalisedString?
function gui_util.format_crafting_time(crafting_time)
  if not crafting_time then
    return nil
  end
  return {
    "",
    "[img=quantity-time]",
    { "time-symbol-seconds", flib_math.floored(crafting_time, 0.01) },
    " ",
    { "description.crafting-time" },
  }
end

--- @param count uint?
--- @param time double?
--- @return LocalisedString
function gui_util.format_technology_count_and_time(count, time)
  if not count or not time then
    return
  end

  --- @type LocalisedString
  return {
    "",
    "[img=quantity-time]",
    { "time-symbol-seconds", flib_math.floored(time, 0.01) },
    " × ",
    flib_format.number(count, true),
  }
end

local temperature_edge = (2 - 2 ^ -23) * 2 ^ 127

--- @param id DatabaseID
--- @return LocalisedString
function gui_util.format_caption(id)
  --- @type LocalisedString
  local caption = { "" }
  if id.probability and id.probability < 1 then
    caption[#caption + 1] = {
      "",
      "[font=default-semibold]",
      { "format-percent", flib_math.round(id.probability * 100, 0.01) },
      "[/font] ",
    }
  end
  if id.amount then
    caption[#caption + 1] = {
      "",
      "[font=default-semibold]",
      core_util.format_number(flib_math.round(id.amount, 0.01), true),
      " ×[/font] ",
    }
  elseif id.amount_min and id.amount_max then
    caption[#caption + 1] = {
      "",
      "[font=default-semibold]",
      core_util.format_number(flib_math.round(id.amount_min, 0.01), true),
      "-",
      core_util.format_number(flib_math.round(id.amount_max, 0.01), true),
      " ×[/font] ",
    }
  end

  caption[#caption + 1] = util.get_prototype(id).localised_name --- @diagnostic disable-line:assign-type-mismatch

  if id.temperature then
    caption[#caption + 1] = { "", "  (", flib_math.round(id.temperature, 0.01), { "si-unit-degree-celsius" }, ")" }
  elseif id.minimum_temperature and id.maximum_temperature then
    local temperature_min = id.minimum_temperature --[[@as number]]
    local temperature_max = id.maximum_temperature --[[@as number]]
    local temperature_string
    if temperature_min == -temperature_edge then
      temperature_string = "≤ " .. flib_math.round(temperature_max, 0.01)
    elseif temperature_max == temperature_edge then
      temperature_string = "≥ " .. flib_math.round(temperature_min, 0.01)
    else
      temperature_string = ""
        .. flib_math.round(temperature_min, 0.01)
        .. " - "
        .. flib_math.round(temperature_max, 0.01)
    end
    caption[#caption + 1] = { "", "  (", temperature_string, { "si-unit-degree-celsius" }, ")" }
  end

  return caption
end

--- @param id DatabaseID
--- @return string? bottom
--- @return string? top
function gui_util.get_temperature_strings(id)
  local temperature = id.temperature
  local temperature_min = id.minimum_temperature
  local temperature_max = id.maximum_temperature
  local bottom
  local top
  if temperature then
    bottom = core_util.format_number(temperature, true)
    temperature_min = temperature
    temperature_max = temperature
  elseif temperature_min and temperature_max then
    if temperature_min == -temperature_edge then
      bottom = "≤" .. core_util.format_number(temperature_max, true)
    elseif temperature_max == temperature_edge then
      bottom = "≥" .. core_util.format_number(temperature_min, true)
    else
      bottom = core_util.format_number(temperature_min, true)
      top = core_util.format_number(temperature_max, true)
    end
  end

  return bottom, top
end

--- @alias FabState
--- | "default"
--- | "selected"
--- | "disabled"

--- @param button LuaGuiElement
--- @param state FabState
function gui_util.update_frame_action_button(button, state)
  if state == "default" then
    button.enabled = true
    button.toggled = false
  elseif state == "selected" then
    button.enabled = true
    button.toggled = true
  elseif state == "disabled" then
    button.enabled = false
    button.toggled = false
  end
end

--- @type table<string, LocalisedString>
gui_util.type_locale = {
  LuaEntityPrototype = { "description.rb-entity" },
  LuaEquipmentPrototype = { "gui-map-editor.character-equipment" },
  LuaFluidPrototype = { "gui-train.fluid" },
  LuaItemPrototype = { "description.rb-item" },
  LuaRecipePrototype = { "description.recipe" },
  LuaTechnologyPrototype = { "gui-map-generator.technology-difficulty-group-tile" },
  LuaTilePrototype = { "factoriopedia.tile" },
}

--- @type table<string, boolean>
gui_util.vehicles = {
  ["car"] = true,
  ["artillery-wagon"] = true,
  ["cargo-wagon"] = true,
  ["fluid-wagon"] = true,
  ["locomotive"] = true,
  ["spider-vehicle"] = true,
}

--- @return LocalisedString
function gui_util.format_power(input)
  local formatted = flib_format.number(input, true)
  if input < 1000 then
    return { "", formatted, " ", { "si-unit-symbol-watt" } }
  end
  return { "", formatted, { "si-unit-symbol-watt" } }
end

local tooltip_category_sprites = util.unpack("rb_tooltip_category_sprites")

--- @param id DatabaseID
--- @param fallback string
function gui_util.get_tooltip_category_sprite(id, fallback)
  local by_name = "tooltip-category-" .. id.name
  if tooltip_category_sprites[by_name] then
    return by_name
  end
  return "tooltip-category-" .. fallback
end

return gui_util
