local flib_dictionary = require("__flib__/dictionary-lite")
local flib_format = require("__flib__/format")
local flib_math = require("__flib__/math")

local util = {}

--- @param obj Ingredient|Product|DatabaseRecipeDefinition
--- @return LocalisedString
function util.build_caption(obj)
  --- @type LocalisedString
  local caption = { "", "            " }
  if obj.probability and obj.probability < 1 then
    caption[#caption + 1] = {
      "",
      "[font=default-semibold]",
      { "format-percent", flib_math.round(obj.probability * 100, 0.01) },
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
  caption[#caption + 1] = game[obj.type .. "_prototypes"][obj.name].localised_name

  if obj.type == "fluid" then
    local temperature = obj.temperature
    local temperature_min = obj.minimum_temperature
    local temperature_max = obj.maximum_temperature
    --- @type string?
    local temperature_string
    if temperature then
      temperature_string = flib_format.number(temperature)
    elseif temperature_min and temperature_max then
      if temperature_min == flib_math.min_double then
        temperature_string = "≤" .. flib_format.number(temperature_max)
      elseif temperature_max == flib_math.max_double then
        temperature_string = "≥" .. flib_format.number(temperature_min)
      else
        temperature_string = "" .. flib_format.number(temperature_min) .. "-" .. flib_format.number(temperature_max)
      end
    end

    if temperature_string then
      caption[#caption + 1] = { "", " (", { "format-degrees-c-compact", temperature_string }, ")" }
    end
  end

  return caption
end

function util.build_dictionaries()
  flib_dictionary.new("search")
  for _, item in pairs(game.item_prototypes) do
    flib_dictionary.add("search", "item/" .. item.name, { "?", item.localised_name, item.name })
  end
  for _, fluid in pairs(game.fluid_prototypes) do
    flib_dictionary.add("search", "fluid/" .. fluid.name, { "?", fluid.localised_name, fluid.name })
  end
end

--- @alias GenericPrototype LuaEntityPrototype|LuaFluidPrototype|LuaItemPrototype|LuaRecipePrototype|LuaTechnologyPrototype

local has_derived_types = {
  entity = true,
  item = true,
}

--- @param player LuaPlayer
--- @param type string
--- @return LocalisedString
function util.build_tooltip(player, type)
  --- @type LocalisedString
  local control_hints = { "" }
  if player.mod_settings["rb-show-control-hints"].value then
    if type == "technology" then
      control_hints = { "", { "gui.rb-left-click-instruction", { "gui.rb-view-technology" } } }
    else
      control_hints = {
        "",
        { "gui.rb-left-click-instruction", { "gui.rb-view-recipes" } },
        "\n",
        { "gui.rb-right-click-instruction", { "gui.rb-view-usage" } },
      }
    end
  end

  return control_hints
end

--- @param num number
--- @return string
function util.format_number(num)
  return flib_format.number(flib_math.round(num, 0.01))
end

--- @param entity_name string
--- @return string?
function util.get_item_to_place(entity_name)
  local prototype = game.entity_prototypes[entity_name]
  if not prototype then
    return
  end
  local items_to_place_this = prototype.items_to_place_this
  if not items_to_place_this then
    return
  end
  local _, item = next(items_to_place_this)
  if item then
    return item.name
  end
end

--- @param recipe LuaRecipePrototype
--- @return boolean
function util.is_hand_craftable(recipe)
  -- TODO: Account for other characters and god controller?
  if
    recipe.object_name == "LuaRecipePrototype"
    and not game.entity_prototypes["character"].crafting_categories[recipe.category]
  then
    return false
  elseif
    recipe.object_name == "rb-pseudo-mining"
    and not game.entity_prototypes["character"].resource_categories[recipe.category]
  then
    return false
  elseif recipe.object_name == "rb-pseudo-rocket-launch" or recipe.object_name == "rb-pseudo-burning" then
    return false
  end
  for _, ingredient in pairs(recipe.ingredients) do
    if ingredient.type == "fluid" then
      return false
    end
  end
  return true
end

--- @param obj GenericObject
function util.is_hidden(obj)
  --- @type GenericPrototype
  local prototype = game[obj.type .. "_prototypes"][obj.name]
  if obj.type == "item" then
    return prototype.has_flag("hidden")
  elseif obj.type == "entity" then
    return false
  else
    return prototype.hidden
  end
end

util.refresh_guis_paused_event = script.generate_event_name()

--- @param player LuaPlayer
function util.schedule_gui_refresh(player)
  global.refresh_gui[player.index] = true
  if game.tick_paused then
    script.raise_event(util.refresh_guis_paused_event, {})
  end
end

return util
