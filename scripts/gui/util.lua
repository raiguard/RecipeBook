local flib_math = require("__flib__.math")

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
    "[img=quantity-time][font=default-bold]",
    { "time-symbol-seconds", flib_math.floored(crafting_time, 0.01) },
    "[/font] ",
    { "description.crafting-time" },
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
