local table = require("__flib__.table")

local constants = require("constants")

return function(recipe_book)
  for _, class in pairs(constants.burner_classes) do
    for name, data in pairs(recipe_book[class]) do
      -- Burned in
      local compatible_fuels = data.compatible_fuels
      for i, category_ident in pairs(data.fuel_categories or {}) do
        local category_data = recipe_book.fuel_category[category_ident.name]
        if category_data then
          -- Add fluids and items to the compatible fuels, and add the object to the material's burned in table
          for _, objects in pairs{category_data.fluids, category_data.items} do
            for _, obj_ident in pairs(objects) do
              local obj_data = recipe_book[obj_ident.class][obj_ident.name]
              obj_data.burned_in[#obj_data.burned_in + 1] = {class = class, name = name}
              compatible_fuels[#compatible_fuels + 1] = table.shallow_copy(obj_ident)
            end
          end
        else
          -- Remove this category from the machine
          table.remove(data.fuel_categories, i)
        end
      end
    end
  end

  -- Burnt results
  for item_name, item_data in pairs(recipe_book.item) do
    local burnt_result = item_data.burnt_result
    if burnt_result then
      local result_data = recipe_book.item[burnt_result.name]
      result_data.burnt_result_of[#result_data.burnt_result_of + 1] = {class = "item", name = item_name}
    end
  end
end
