local translation = require("__flib__.translation-new")

local table = require("__flib__.table")

local util = require("scripts.util")

return function(recipe_book, strings)
  for name, prototype in pairs(game.get_filtered_entity_prototypes{{filter = "type", type = "lab"}}) do
    -- add to items
    for _, item_name in ipairs(prototype.lab_inputs) do
      local item_data = recipe_book.item[item_name]
      if item_data then
        item_data.usable_in[#item_data.usable_in + 1] = {class = "lab", name = name}
      end
    end

    recipe_book.lab[name] = {
      class = "lab",
      hidden = prototype.has_flag("hidden"),
      inputs = table.map(prototype.lab_inputs, function(v) return {class = "item", name = v} end),
      placeable_by = {},
      prototype_name = name,
      researching_speed = prototype.researching_speed,
      unlocked_by = {}
    }
    translation.add(strings.lab, name, prototype.localised_name)
    translation.add(strings.lab_description, name, prototype.localised_description)
  end
end
