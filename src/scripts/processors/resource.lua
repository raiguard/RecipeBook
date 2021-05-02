local translation = require("__flib__.translation-new")

local util = require("scripts.util")

return function(recipe_book, strings)
  for name, prototype in pairs(game.get_filtered_entity_prototypes{{filter = "type", type = "resource"}}) do
    local products = prototype.mineable_properties.products
    if products then
      for _, product in ipairs(products) do
        local product_data = recipe_book[product.type][product.name]
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
    else
      -- enable resource items that are hand-minable
      for _, product in ipairs(mineable_properties.products) do
        if product.type == "item" then
          local product_data = recipe_book[product.type][product.name]
          product_data.enabled_at_start = true
        end
      end
    end

    recipe_book.resource[name] = {
      class = "resource",
      prototype_name = name,
      required_fluid = required_fluid
    }
    translation.add(strings.resource, name, prototype.localised_name)
    translation.add(strings.resource_description, name, prototype.localised_description)
  end
end
