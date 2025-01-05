local flib_format = require("__flib__.format")
local flib_math = require("__flib__.math")
local core_util = require("__core__.lualib.util")

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

return gui_util
