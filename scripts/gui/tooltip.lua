local database = require("__RecipeBook__/scripts/database")
local gui_util = require("__RecipeBook__/scripts/gui/util")

--- @param prototype LuaRecipePrototype
--- @return LocalisedString
local function recipe_details(prototype)
  --- @type LocalisedString
  local ingredients = { "", { "gui.rb-tooltip-title", { "", { "description.ingredients" }, ":" } }, "\n" }
  for _, ingredient in pairs(prototype.ingredients) do
    ingredients[#ingredients + 1] = { "", "    ", gui_util.build_caption(ingredient, true), "\n" }
  end
  ingredients[#ingredients + 1] = { "", "    ", gui_util.format_crafting_time(prototype.energy) }
  --- @type LocalisedString
  local products = { "", { "gui.rb-tooltip-title", { "", { "description.products" }, ":" } }, "\n" }
  for i, product in pairs(prototype.products) do
    if i > 1 then
      table.insert((products --[[@as table]])[i + 2], "\n")
    end
    products[#products + 1] = { "", "    ", gui_util.build_caption(product, true) }
  end

  return { "", "\n", ingredients, "\n", products }
end

--- @class GuiTooltip
local gui_tooltip = {}

--- @param member GenericObject
--- @return LocalisedString
function gui_tooltip.from_member(member)
  local entry = database.get_entry(member)
  if not entry then
    return ""
  end

  --- @type LocalisedString
  local tooltip = { "" }
  for _, key in pairs({ "recipe", "item", "fluid", "entity" }) do
    local prototype = entry[key] --[[@as GenericPrototype?]]
    if not prototype then
      goto continue
    end

    tooltip[#tooltip + 1] = gui_tooltip.from_prototype(prototype)
    tooltip[#tooltip + 1] = "\n─────────────────────────\n"

    ::continue::
  end

  if #tooltip > 2 then
    tooltip[#tooltip] = nil
  end

  return tooltip
end

--- @param prototype GenericPrototype
--- @return LocalisedString
function gui_tooltip.from_prototype(prototype)
  --- @type LocalisedString
  local tooltip = { "" }
  tooltip[#tooltip + 1] = {
    "gui.rb-tooltip-title",
    { "", prototype.localised_name, " (", gui_util.type_locale[prototype.object_name], ")" },
  }

  local type = gui_util.type_string[prototype.object_name]
  if not type then
    type = prototype.type
  end
  local history = script.get_prototype_history(type, prototype.name)
  if history and (#history.changed > 0 or (history.created ~= "base" and history.created ~= "core")) then
    --- @type LocalisedString
    local items = { "", { "?", { "mod-name." .. history.created }, history.created } }
    for _, mod_name in pairs(history.changed) do
      items[#items + 1] = { "", " › ", { "?", { "mod-name." .. mod_name }, mod_name } }
    end
    tooltip[#tooltip + 1] = { "", "\n[color=128, 206, 240]", items, "[/color]" }
  end

  tooltip[#tooltip + 1] = { "?", { "", "\n", prototype.localised_description }, "" }
  if prototype.object_name == "LuaRecipePrototype" then
    tooltip[#tooltip + 1] = recipe_details(prototype)
  end
  return tooltip
end

return gui_tooltip
