local flib_format = require("__flib__.format")
local flib_math = require("__flib__.math")
-- local core_util = require("__core__.lualib.util")

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
  local sprite_base = string.match(button.sprite, "(.*)_[a-z]")
  if state == "default" then
    button.enabled = true
    button.toggled = false
    button.sprite = sprite_base .. "_white"
  elseif state == "selected" then
    button.enabled = true
    button.toggled = true
    button.sprite = sprite_base .. "_black"
  elseif state == "disabled" then
    button.enabled = false
    button.toggled = false
    button.sprite = sprite_base .. "_disabled"
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
}

return gui_util
