local table = require("__flib__.table")

local util = require("scripts.util")

local equipment_proc = {}

function equipment_proc.build(recipe_book, dictionaries)
  for name, prototype in pairs(global.prototypes.equipment) do
    local fuel_categories
    local burner = prototype.burner_prototype
    if burner then
      fuel_categories = util.convert_categories(burner.fuel_categories, "fuel_category")
    end
    recipe_book.equipment[name] = {
      class = "equipment",
      compatible_fuels = {},
      fuel_categories = fuel_categories,
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

function equipment_proc.process_burned_in(recipe_book)
  for equipment_name, equipment_data in pairs(recipe_book.equipment) do
    -- Burned in
    local compatible_fuels = equipment_data.compatible_fuels
    for i, category_ident in pairs(equipment_data.fuel_categories or {}) do
      local category_data = recipe_book.fuel_category[category_ident.name]
      if category_data then
        -- Add fluids and items to the compatible fuels, and add the machine to the material's burned in table
        for _, objects in pairs{category_data.fluids, category_data.items} do
          for _, obj_ident in pairs(objects) do
            local obj_data = recipe_book[obj_ident.class][obj_ident.name]
            obj_data.burned_in[#obj_data.burned_in + 1] = {class = "equipment", name = equipment_name}
            compatible_fuels[#compatible_fuels + 1] = table.shallow_copy(obj_ident)
          end
        end
      else
        -- Remove this category from the machine
        table.remove(equipment_data.fuel_categories, i)
      end
    end
  end
end

-- When calling the module directly, call equipment_proc.build
setmetatable(equipment_proc, { __call = function(_, ...) return equipment_proc.build(...) end })

return equipment_proc

