local table = require("__flib__.table")

local util = require("scripts.util")

return function(recipe_book, strings, metadata)
  local rocket_launch_payloads = {}
  for name, prototype in pairs(game.item_prototypes) do
    -- rocket launch products
    local launch_products = {}
    for i, product in ipairs(prototype.rocket_launch_products or {}) do
      -- add to products table w/ amount string
      local amount_string = util.build_amount_string(product)
      launch_products[i] = {
        class = product.type,
        name = product.name,
        amount_string = amount_string
      }
      -- add to payloads table
      local product_payloads = rocket_launch_payloads[product.name]
      if product_payloads then
        product_payloads[#product_payloads + 1] = {class = product.type, name = product.name}
      else
        rocket_launch_payloads[product.name] = {{class = product.type, name = product.name}}
      end
    end
    local default_categories = (#launch_products > 0 and table.shallow_copy(metadata.rocket_silo_categories)) or {}

    recipe_book.item[name] = {
      available_to_forces = {},
      class = "item",
      fuel_value = prototype.fuel_value > 0 and prototype.fuel_value or nil,
      hidden = prototype.has_flag("hidden"),
      ingredient_in = {},
      mined_from = {},
      product_of = {},
      prototype_name = name,
      recipe_categories = default_categories,
      rocket_launch_payloads = {},
      rocket_launch_products = launch_products,
      stack_size = prototype.stack_size,
      type = "item",
      unlocked_by = util.unique_obj_array(),
      usable_in = {}
    }
    util.add_string(strings, {dictionary = "item", internal = name, localised = prototype.localised_name})
    util.add_string(strings, {dictionary = "item", internal = name, localised = prototype.localised_description})
  end
end
