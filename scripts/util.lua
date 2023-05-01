local flib_dictionary = require("__flib__/dictionary-lite")
local flib_format = require("__flib__/format")
local flib_math = require("__flib__/math")

local util = {}

--- @param obj Ingredient|Product
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

  -- TODO: Temperatures

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

--- @param player LuaPlayer
--- @param type string
--- @param name string
--- @return LocalisedString
function util.build_tooltip(player, type, name)
  --- @type GenericPrototype
  local prototype = game[type .. "_prototypes"][name]

  --- @type LocalisedString
  local prototype_history = { "" }
  -- XXX: get_prototype_history errors if there is no history, but we cannot tell that ahead of time,
  -- so a pcall is required for now
  -- FIXME: Prototype history is not working all the time
  local has_history, history = pcall(script.get_prototype_history, type, name)
  if
    has_history
    and history
    and (#history.changed > 0 or (history.created ~= "base" and history.created ~= "core"))
  then
    --- @type LocalisedString
    local items = { "", { "?", { "mod-name." .. history.created }, history.created } }
    for _, mod_name in pairs(history.changed) do
      items[#items + 1] = { "", " › ", { "?", { "mod-name." .. mod_name }, mod_name } }
    end
    prototype_history = { "", "\n", { "gui.rbl-info-color", items } }
  end

  --- @type LocalisedString
  local control_hints = { "" }
  if player.mod_settings["rbl-show-control-hints"].value then
    control_hints = { "", "\n", { "gui.rbl-left-click-instruction" }, "\n", { "gui.rbl-right-click-instruction" } }
  end

  --- @type LocalisedString
  local descriptions = { "?", prototype.localised_description }
  if type == "recipe" then
    local main_product = prototype.main_product
    if main_product then
      descriptions[#descriptions + 1] =
        game[main_product.type .. "_prototypes"][main_product.name].localised_description
    end
  end
  if type == "item" then
    local place_result = prototype.place_result
    if place_result then
      descriptions[#descriptions + 1] = place_result.localised_description
    end
    local place_as_equipment_result = prototype.place_as_equipment_result
    if place_as_equipment_result then
      descriptions[#descriptions + 1] = place_as_equipment_result.localised_description
    end
    local place_as_tile_result = prototype.place_as_tile_result
    if place_as_tile_result then
      descriptions[#descriptions + 1] = place_as_tile_result.result.localised_description
    end
  end

  return {
    "",
    { "gui.rbl-tooltip-title", prototype.localised_name, { "gui.rbl-" .. type } },
    prototype_history,
    { "?", { "", "\n", descriptions }, "" },
    control_hints,
  }
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
  local _, item = next(prototype.items_to_place_this)
  if item then
    return item.name
  end
end

--- @param recipe LuaRecipePrototype
--- @return boolean
function util.is_hand_craftable(recipe)
  -- TODO: Account for other characters and god controller?
  if not game.entity_prototypes["character"].crafting_categories[recipe.category] then
    return false
  end
  for _, ingredient in pairs(recipe.ingredients) do
    if ingredient.type == "fluid" then
      return false
    end
  end
  return true
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
