local util = require("scripts.util")

return function(recipe_book, dictionaries)
  for name, prototype in pairs(global.prototypes.resource) do
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
        -- Ten mining operations per amount consumed, so divide by 10 to get the actual number
        amount_ident = util.build_amount_ident{amount = mineable_properties.fluid_amount / 10}
      }
    else
      -- TODO: Validate that it's hand-mineable by checking character mineable categories
      -- NOTE: It doesn't appear to be possible to do ths in the current version of the game (1.1.37)
      -- Enable resource items that are hand-minable
      for _, product in ipairs(mineable_properties.products) do
        if product.type == "item" then
          local product_data = recipe_book[product.type][product.name]
          product_data.enabled_at_start = true
        end
      end
    end

    local products = {}
    for i, product in pairs(mineable_properties.products) do
      products[i] = {
        class = product.type,
        name = product.name,
        amount_ident = util.build_amount_ident(product)
      }
    end

    local compatible_mining_drills = {}
    local resource_category = prototype.resource_category
    for drill_name, drill_data in pairs(recipe_book.mining_drill) do
      if drill_data.resource_categories_lookup[resource_category]
        and (not required_fluid or drill_data.supports_fluid)
      then
        compatible_mining_drills[#compatible_mining_drills + 1] = {class = "mining_drill", name = drill_name}
      end
    end

    local resource_category_data = recipe_book.resource_category[resource_category]
    resource_category_data.resources[#resource_category_data.resources + 1] = {class = "resource", name = name}

    recipe_book.resource[name] = {
      class = "resource",
      compatible_mining_drills = compatible_mining_drills,
      mining_time = mineable_properties.mining_time,
      products = products,
      prototype_name = name,
      resource_category = {class = "resource_category", name = resource_category},
      required_fluid = required_fluid
    }
    dictionaries.resource:add(name, prototype.localised_name)
    dictionaries.resource_description:add(name, prototype.localised_description)
  end
end
