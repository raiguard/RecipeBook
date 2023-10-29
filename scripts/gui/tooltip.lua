local database = require("__RecipeBook__/scripts/database")
local gui_util = require("__RecipeBook__/scripts/gui/util")

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
    tooltip[#tooltip + 1] = "\n────────────────────────\n"

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
  return tooltip
end

return gui_tooltip
