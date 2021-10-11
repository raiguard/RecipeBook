local table = require("__flib__.table")

local equipment_proc = {}

function equipment_proc.build(recipe_book, dictionaries)
  for name, prototype in pairs(global.prototypes.equipment) do
    recipe_book.equipment[name] = {
      class = "equipment",
      enabled = true,
      equipment_categories = table.map(prototype.equipment_categories, function(category)
        return {class = "equipment_category", name = category}
      end),
      hidden = false,
      placed_by = {},
      prototype_name = name,
      size = prototype.shape.width and prototype.shape or nil, -- Equipments can have irregular shapes
      take_result = prototype.take_result and {class = "item", name = prototype.take_result.name} or nil,
      unlocked_by = {}
    }
    dictionaries.equipment:add(name, prototype.localised_name)
    dictionaries.equipment_description:add(name, prototype.localised_description)
  end
end

-- When calling the module directly, call equipment_proc.build
setmetatable(equipment_proc, { __call = function(_, ...) return equipment_proc.build(...) end })

return equipment_proc

