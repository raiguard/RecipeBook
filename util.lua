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

--- @param num number
--- @return string
function util.format_number(num)
  return flib_format.number(flib_math.round(num, 0.01))
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

return util
