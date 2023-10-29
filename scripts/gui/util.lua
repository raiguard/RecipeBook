local math = require("__flib__/math")

local database = require("__RecipeBook__/scripts/database")
local util = require("__RecipeBook__/scripts/util")

--- @class GuiUtil
local gui_util = {}

--- @param obj GenericObject
--- @param include_icon boolean?
--- @return LocalisedString
function gui_util.build_caption(obj, include_icon)
  --- @type LocalisedString
  local caption = { "", "              " }
  if include_icon then
    caption[#caption + 1] = "[img=" .. obj.type .. "/" .. obj.name .. "]  "
  end
  if obj.probability and obj.probability < 1 then
    caption[#caption + 1] = {
      "",
      "[font=default-semibold]",
      { "format-percent", math.round(obj.probability * 100, 0.01) },
      "[/font] ",
    }
  end
  if obj.amount then
    caption[#caption + 1] = {
      "",
      "[font=default-semibold]",
      util.format_number(obj.amount),
      " ×[/font]  ",
    }
  elseif obj.amount_min and obj.amount_max then
    caption[#caption + 1] = {
      "",
      "[font=default-semibold]",
      util.format_number(obj.amount_min),
      " - ",
      util.format_number(obj.amount_max),
      " ×[/font]  ",
    }
  end

  -- TODO: Optimize this
  caption[#caption + 1] = game[obj.type .. "_prototypes"][obj.name].localised_name

  if obj.temperature then
    caption[#caption + 1] = { "", "  (", { "format-degrees-c-compact", math.round(obj.temperature, 0.01) }, ")" }
  elseif obj.minimum_temperature and obj.maximum_temperature then
    local temperature_min = obj.minimum_temperature --[[@as number]]
    local temperature_max = obj.maximum_temperature --[[@as number]]
    local temperature_string
    if temperature_min == math.min_double then
      temperature_string = "≤ " .. math.round(temperature_max, 0.01)
    elseif temperature_max == math.max_double then
      temperature_string = "≥ " .. math.round(temperature_min, 0.01)
    else
      temperature_string = "" .. math.round(temperature_min, 0.01) .. " - " .. math.round(temperature_max, 0.01)
    end
    caption[#caption + 1] = { "", "  (", { "format-degrees-c-compact", temperature_string }, ")" }
  end

  return caption
end

-- --- @param obj GenericObject
-- --- @return LocalisedString
-- function gui_util.build_remark(obj)
--   --- @type LocalisedString
--   local remark = { "" }
--   if obj.required_fluid then
--     remark[#remark + 1] = { "", gui_util.build_caption(obj.required_fluid, true) }
--   end
--   if obj.duration then
--     remark[#remark + 1] = { "", "  [img=quantity-time] ", { "time-symbol-seconds", math.round(obj.duration, 0.01) } }
--   end
--   if obj.temperature then
--     remark[#remark + 1] = { "", "  ", { "format-degrees-c-compact", math.round(obj.temperature, 0.01) } }
--   elseif obj.minimum_temperature and obj.maximum_temperature then
--     local temperature_min = obj.minimum_temperature --[[@as number]]
--     local temperature_max = obj.maximum_temperature --[[@as number]]
--     local temperature_string
--     if temperature_min == math.min_double then
--       temperature_string = "≤ " .. math.round(temperature_max, 0.01)
--     elseif temperature_max == math.max_double then
--       temperature_string = "≥ " .. math.round(temperature_min, 0.01)
--     else
--       temperature_string = "" .. math.round(temperature_min, 0.01) .. " - " .. math.round(temperature_max, 0.01)
--     end
--     remark[#remark + 1] = { "", "  ", { "format-degrees-c-compact", temperature_string } }
--   end
--   return remark
-- end

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

gui_util.has_derived_types = {
  LuaEntityPrototype = true,
  LuaItemPrototype = true,
}

gui_util.type_string = {
  -- LuaEntityPrototype = "entity",
  LuaFluidPrototype = "fluid",
  -- LuaItemPrototype = "item",
  LuaRecipePrototype = "recipe",
  LuaTechnologyPrototype = "technology",
}

--- @type table<string, LocalisedString>
gui_util.type_locale = {
  LuaEntityPrototype = { "description.rb-entity" },
  LuaFluidPrototype = { "gui-train.fluid" },
  LuaItemPrototype = { "description.rb-item" },
  LuaRecipePrototype = { "description.recipe" },
  LuaTechnologyPrototype = { "gui-map-generator.technology-difficulty-group-tile" },
}

return gui_util
