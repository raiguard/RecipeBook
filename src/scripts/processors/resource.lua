local util = require("scripts.util")

return function(recipe_book, strings)
  for name, prototype in pairs(game.get_filtered_entity_prototypes{{filter = "type", type = "resource"}}) do
    local products = prototype.mineable_properties.products
    if products then
      for _, product in ipairs(products) do
        local product_data = recipe_book.item[product.name]
        if product_data then
          product_data.mined_from[#product_data.mined_from + 1] = {class = "resource", name = name}
        end
      end
    end
    local required_fluid
    local mineable_properties = prototype.mineable_properties
    if mineable_properties.required_fluid then
      required_fluid = {
        class = "fluid",
        name = mineable_properties.required_fluid,
        amount_string = util.build_amount_string{amount = mineable_properties.fluid_amount}
      }
    end

    recipe_book.resource[name] = {
      available_to_all_forces = true,
      class = "resource",
      prototype_name = name,
      required_fluid = required_fluid,
      type = "entity"
    }
    util.add_string(strings, {
      dictionary = "resource",
      internal = name,
      localised = prototype.localised_name
    })
    util.add_string(strings, {
      dictionary = "resource_description",
      internal = name,
      localised = prototype.localised_description
    })
  end
end
