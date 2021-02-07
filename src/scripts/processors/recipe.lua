local util = require("scripts.util")

local fluid_proc = require("scripts.processors.fluid")

return function(recipe_book, strings, metadata)
  for name, prototype in pairs(game.recipe_prototypes) do
    local data = {
      available_to_forces = {},
      category = prototype.category,
      class = "recipe",
      energy = prototype.energy,
      hidden = prototype.hidden,
      made_in = {},
      prototype_name = name,
      type = "recipe",
      unlocked_by = {},
      used_as_fixed_recipe = metadata.fixed_recipes[name]
    }

    -- ingredients / products
    for lookup_type, io_type in pairs{ingredient_in = "ingredients", product_of = "products"} do
      local output = {}
      for i, material in ipairs(prototype[io_type]) do
        local amount_string, avg_amount_string = util.build_amount_string(material)
        -- TODO: find better name
        local to_save = {
          class = material.type,
          name = material.name,
          amount_string = amount_string,
          avg_amount_string = avg_amount_string
        }
        local lookup_table = recipe_book[material.type][material.name][lookup_type]
        lookup_table[#lookup_table + 1] = {class = "recipe", name = name}
        output[i] = to_save
      end
      data[io_type] = output
    end

    recipe_book.recipe[name] = data
    util.add_string(strings, {
      dictionary = "recipe",
      internal = name,
      localised = prototype.localised_name
    })
    util.add_string(strings, {
      dictionary = "recipe",
      internal = name,
      localised = prototype.localised_description
    })
  end
end
