local global_data = {}

local table = require("__flib__.table")

local constants = require("constants")

local function unique_array(initial_value)
  local hash = {}
  if initial_value then
    for i = 1, #initial_value do
      hash[initial_value[i]] = true
    end
  end
  return setmetatable(initial_value or {}, {__newindex = function(tbl, key, value)
    if not hash[value] then
      hash[value] = true
      rawset(tbl, key, value)
    end
  end})
end

-- from http://lua-users.org/wiki/SimpleRound
local function round(num, decimals)
  local mult = 10^(decimals or 0)
  return math.floor(num * mult + 0.5) / mult
end

function global_data.init()
  global.flags = {}
  global.players = {}

  global_data.build_recipe_book()
  global_data.check_forces()
end

-- build amount string, to display probability, [min/max] amount - includes the "x"
local function build_amount_string(material)
  local amount = material.amount
  local amount_string = amount and (tostring(amount).."x") or (material.amount_min.."-"..material.amount_max.."x")
  local probability = material.probability
  if probability and probability < 1 then
    amount_string = tostring(probability * 100).."% "..amount_string
  end
  return amount_string, amount == nil and ((material.amount_min + material.amount_max) / 2) or nil
end

function global_data.build_recipe_book()
  -- character prototype
  local character_prototype = game.entity_prototypes["character"]
  local recipe_book = {
    crafter = {
      -- manually insert character as first entry
      character = {
        available_to_all_forces = true,
        blueprintable = false,
        categories = character_prototype.crafting_categories,
        crafting_speed = 1,
        hidden = false,
        internal_class = "crafter",
        prototype_name = character_prototype.name,
        sprite_class = "entity"
      }
    },
    material = {},
    offshore_pump = {},
    recipe = {},
    resource = {},
    rocket_launch_product = {},
    technology = {}
  }
  local translation_data = {
    -- internal classes
    {dictionary="gui", internal="fluid", localised={"rb-gui.fluid"}},
    {dictionary="gui", internal="item", localised={"rb-gui.item"}},
    {dictionary="gui", internal="crafter", localised={"rb-gui.crafter"}},
    {dictionary="gui", internal="material", localised={"rb-gui.material"}},
    {dictionary="gui", internal="offshore_pump", localised={"rb-gui.offshore-pump"}},
    {dictionary="gui", internal="recipe", localised={"rb-gui.recipe"}},
    {dictionary="gui", internal="resource", localised={"rb-gui.resource"}},
    {dictionary="gui", internal="technology", localised={"rb-gui.technology"}},
    -- captions
    {dictionary="gui", internal="hidden_abbrev", localised={"rb-gui.hidden-abbrev"}},
    -- tooltips
    {dictionary="gui", internal="blueprint_not_available", localised={"rb-gui.blueprint-not-available"}},
    {dictionary="gui", internal="click_to_get_blueprint", localised={"rb-gui.click-to-get-blueprint"}},
    {dictionary="gui", internal="click_to_view_technology", localised={"rb-gui.click-to-view-technology"}},
    {dictionary="gui", internal="click_to_view", localised={"rb-gui.click-to-view"}},
    {dictionary="gui", internal="fixed_recipe", localised={"rb-gui.fixed-recipe"}},
    {dictionary="gui", internal="hidden", localised={"rb-gui.hidden"}},
    {dictionary="gui", internal="per_second", localised={"rb-gui.per-second"}},
    {dictionary="gui", internal="pumping_speed", localised={"rb-gui.pumping-speed"}},
    {dictionary="gui", internal="rocket_parts_required", localised={"rb-gui.rocket-parts-required"}},
    {dictionary="gui", internal="shift_click_to_view_fixed_recipe", localised={"rb-gui.shift-click-to-view-fixed-recipe"}},
    {dictionary="gui", internal="stack_size", localised={"rb-gui.stack-size"}},
    {dictionary="gui", internal="unresearched", localised={"rb-gui.unresearched"}},
    -- character crafter
    {dictionary="crafter", internal="character", localised={"entity-name.character"}}
  }

  -- forces
  local forces = {}
  for _, force in pairs(game.forces) do
    forces[force.index] = force.recipes
  end

  -- iterate crafters
  local crafter_prototypes = game.get_filtered_entity_prototypes{
    {filter="type", type="assembling-machine"},
    {filter="type", type="furnace"},
    {filter="type", type="rocket-silo"}
  }
  local fixed_recipes = {}
  local rocket_silo_categories = {}
  for name, prototype in pairs(crafter_prototypes) do
    local is_hidden = prototype.has_flag("hidden")
    recipe_book.crafter[name] = {
      available_to_forces = {},
      blueprintable = not is_hidden and not prototype.has_flag("not-blueprintable"),
      categories = prototype.crafting_categories,
      crafting_speed = prototype.crafting_speed,
      -- TODO show this in the tooltip and make it open-able
      fixed_recipe = prototype.fixed_recipe,
      hidden = is_hidden,
      internal_class = "crafter",
      prototype_name = name,
      -- TODO show this in the item
      rocket_parts_required = prototype.rocket_parts_required,
      sprite_class = "entity"
    }
    -- add fixed recipe to list
    if prototype.fixed_recipe then
      fixed_recipes[prototype.fixed_recipe] = true
    end
    -- add categories to rocket silo list
    if prototype.rocket_parts_required then
      for category in pairs(prototype.crafting_categories) do
        rocket_silo_categories[category] = true
      end
    end
    -- add to translations table
    translation_data[#translation_data+1] = {dictionary="crafter", internal=name, localised=prototype.localised_name}
  end

  -- iterate materials
  local fluid_prototypes = game.fluid_prototypes
  local item_prototypes = game.item_prototypes
  local rocket_launch_payloads = {}
  for class, t in pairs{fluid=fluid_prototypes, item=item_prototypes} do
    for name, prototype in pairs(t) do
      local hidden
      if class == "fluid" then
        hidden = prototype.hidden
      else
        hidden = prototype.has_flag("hidden")
      end
      local launch_products = class == "item" and prototype.rocket_launch_products or {}
      local default_categories = (#launch_products > 0 and table.shallow_copy(rocket_silo_categories)) or {}
      -- process rocket launch products
      if launch_products then
        for i = 1, #launch_products do
          local product = launch_products[i]
          -- add amount strings
          local amount_string = build_amount_string(product)
          launch_products[i] = {
            type = product.type,
            name = product.name,
            amount_string = amount_string
          }
          -- add to rocket launch payloads table
          local product_key = product.type.."."..product.name
          local product_payloads = rocket_launch_payloads[product_key]
          if product_payloads then
            product_payloads[#product_payloads+1] = {type=class, name=name}
          else
            rocket_launch_payloads[product_key] = {{type=class, name=name}}
          end
        end
      end
      -- add to recipe book
      recipe_book.material[class.."."..name] = {
        available_to_forces = {},
        hidden = hidden,
        ingredient_in = {},
        internal_class = "material",
        mined_from = {},
        product_of = {},
        prototype_name = name,
        pumped_by = {},
        recipe_categories = default_categories,
        rocket_launch_payloads = {},
        rocket_launch_products = launch_products,
        sprite_class = class,
        stack_size = class == "item" and prototype.stack_size or nil,
        unlocked_by = unique_array()
      }
      -- add to translation table
      translation_data[#translation_data+1] = {dictionary="material", internal=class.."."..name, localised=prototype.localised_name}
    end
  end

  -- iterate offshore pumps
  local offshore_pump_prototypes = game.get_filtered_entity_prototypes{
    {filter="type", type="offshore-pump"}
  }
  for name, prototype in pairs(offshore_pump_prototypes) do
    -- add to material
    local fluid = prototype.fluid
    local fluid_data = recipe_book.material["fluid."..fluid.name]
    if fluid_data then
      fluid_data.pumped_by[#fluid_data.pumped_by+1] = name
    end
    -- add to recipe book
    recipe_book.offshore_pump[name] = {
      available_to_all_forces = true,
      fluid = prototype.fluid.name,
      internal_class = "offshore_pump",
      prototype_name = name,
      pumping_speed = prototype.pumping_speed,
      sprite_class = "entity"
    }
    -- add to translations table
    translation_data[#translation_data+1] = {dictionary="offshore_pump", internal=name, localised=prototype.localised_name}
  end

  -- iterate recipes
  local recipe_prototypes = game.recipe_prototypes
  for name, prototype in pairs(recipe_prototypes) do
    local data = {
      available_to_forces = {},
      category = prototype.category,
      energy = prototype.energy,
      hidden = prototype.hidden,
      internal_class = "recipe",
      made_in = {},
      prototype_name = name,
      sprite_class = "recipe",
      unlocked_by = {},
      used_as_fixed_recipe = fixed_recipes[name]
    }
    -- ingredients / products
    for _, mode in ipairs{"ingredients", "products"} do
      local materials = prototype[mode]
      local output = {}
      for i = 1, #materials do
        local material = materials[i]
        local amount_string, avg_amount_string = build_amount_string(material)
        -- save only the essentials
        output[i] = {
          type = material.type,
          name = material.name,
          amount_string = amount_string,
          avg_amount_string = avg_amount_string
        }
      end
      -- add to data
      data[mode] = output
    end
    -- made in
    local category = prototype.category
    for crafter_name, crafter_data in pairs(recipe_book.crafter) do
      if crafter_data.categories[category] then
        data.made_in[#data.made_in+1] = {
          name = crafter_name,
          amount_string = "("..round(prototype.energy / crafter_data.crafting_speed, 2).."s)"
        }
      end
    end
    -- material: ingredient in
    local ingredients = prototype.ingredients
    for i=1,#ingredients do
      local ingredient = ingredients[i]
      local ingredient_data = recipe_book.material[ingredient.type.."."..ingredient.name]
      if ingredient_data then
        ingredient_data.recipe_categories[data.category] = true
        ingredient_data.ingredient_in[#ingredient_data.ingredient_in+1] = name
      end
    end
    -- material: product of
    local products = prototype.products
    for i=1,#products do
      local product = products[i]
      local product_data = recipe_book.material[product.type.."."..product.name]
      if product_data then
        product_data.recipe_categories[data.category] = true
        product_data.product_of[#product_data.product_of+1] = name
      end
    end
    -- insert into recipe book
    recipe_book.recipe[name] = data
    -- translation data
    translation_data[#translation_data+1] = {dictionary="recipe", internal=name, localised=prototype.localised_name}
  end

  -- iterate resources
  local resource_prototypes = game.get_filtered_entity_prototypes{{filter="type", type="resource"}}
  for name, prototype in pairs(resource_prototypes) do
    local products = prototype.mineable_properties.products
    if products then
      for _, product in ipairs(products) do
        local product_data = recipe_book.material[product.type.."."..product.name]
        if product_data then
          product_data.mined_from[#product_data.mined_from+1] = name
        end
      end
    end
    recipe_book.resource[name] = {
      available_to_all_forces = true,
      internal_class = "resource",
      prototype_name = name,
      sprite_class = "entity"
    }
    translation_data[#translation_data+1] = {dictionary="resource", internal=name, localised=prototype.localised_name}
  end

  -- iterate technologies
  for name, prototype in pairs(game.technology_prototypes) do
    if prototype.enabled then
      for _, modifier in ipairs(prototype.effects) do
        if modifier.type == "unlock-recipe" then
          local recipe_data = recipe_book.recipe[modifier.recipe]
          if recipe_data then
            recipe_data.unlocked_by[#recipe_data.unlocked_by+1] = name

            for _, product in pairs(recipe_data.products) do
              local product_name = product.name
              local product_type = product.type
              -- product
              local product_data = recipe_book.material[product_type.."."..product_name]
              if product_data then
                -- check if we've already been added here
                local add = true
                for _, technology in ipairs(product_data.unlocked_by) do
                  if technology == name then
                    add = false
                    break
                  end
                end
                if add then
                  product_data.unlocked_by[#product_data.unlocked_by+1] = name
                end
              end
            end
          end
        end
      end
      recipe_book.technology[name] = {
        hidden = prototype.hidden,
        internal_class = "technology",
        prototype_name = name,
        researched_forces = {},
        sprite_class = "technology"
      }
      translation_data[#translation_data+1] = {dictionary="technology", internal=prototype.name, localised=prototype.localised_name}
    end
  end

  -- add rocket launch payloads to their material tables
  for product, payloads in pairs(rocket_launch_payloads) do
    local product_data = recipe_book.material[product]
    product_data.rocket_launch_payloads = table.array_copy(payloads)
    for i = 1, #payloads do
      local payload = payloads[i]
      local payload_data = recipe_book.material[payload.type.."."..payload.name]
      local payload_unlocked_by = payload_data.unlocked_by
      for j = 1, #payload_unlocked_by do
        product_data.unlocked_by[#product_data.unlocked_by+1] = payload_unlocked_by[j]
      end
    end
  end

  -- remove all materials that aren't used in recipes or rockets
  do
    local materials = recipe_book.material
    local translations = translation_data
    for i = #translations, 1, -1 do
      local t = translations[i]
      if t.dictionary == "material" then
        local data = materials[t.internal]
        if
          #data.ingredient_in == 0
          and #data.product_of == 0
          and #data.rocket_launch_products == 0
          and #data.rocket_launch_payloads == 0
        then
          materials[t.internal] = nil
          table.remove(translations, i)
        elseif #data.unlocked_by == 0 then
          -- set unlocked by default
          data.available_to_forces = nil
          data.available_to_all_forces = true
        end
      end
    end
  end

  -- apply to global
  global.recipe_book = recipe_book
  global.translation_data = translation_data
end

local function unlock_launch_products(force_index, launch_products, recipe_book)
  for _, launch_product in ipairs(launch_products) do
    local launch_product_data = recipe_book.material[launch_product.type.."."..launch_product.name]
    if launch_product_data and launch_product_data.available_to_forces then
      launch_product_data.available_to_forces[force_index] = true
    end
    unlock_launch_products(force_index, launch_product_data.rocket_launch_products, recipe_book)
  end
end

local function set_recipe_available(force_index, recipe_data, recipe_book, item_prototypes)
  -- check if the category should be ignored for recipe availability
  local disabled = constants.disabled_recipe_categories[recipe_data.category]
  if disabled and disabled == 0 then return end
  recipe_data.available_to_forces[force_index] = true
  for _, product in ipairs(recipe_data.products) do
    -- product
    local product_data = recipe_book.material[product.type.."."..product.name]
    if product_data and product_data.available_to_forces then
      product_data.available_to_forces[force_index] = true
    end
    -- crafter
    if product.type == "item" then
      local place_result = item_prototypes[product.name].place_result
      if place_result then
        local crafter_data = recipe_book.crafter[place_result.name]
        if crafter_data and crafter_data.available_to_forces then
          crafter_data.available_to_forces[force_index] = true
        end
      end
    end
    -- rocket launch products
    unlock_launch_products(force_index, product_data.rocket_launch_products, recipe_book)
  end
end

function global_data.update_available_objects(technology)
  local force_index = technology.force.index
  local item_prototypes = game.item_prototypes
  local recipe_book = global.recipe_book
  -- technology
  local technology_data = recipe_book.technology[technology.name]
  if technology_data then
    technology_data.researched_forces[force_index] = true
  end
  -- recipes
  for _, effect in ipairs(technology.effects) do
    if effect.type == "unlock-recipe" then
      local recipe_data = recipe_book.recipe[effect.recipe]
      if recipe_data and not recipe_data.available_to_forces[force_index] then
        set_recipe_available(force_index, recipe_data, recipe_book, item_prototypes)
      end
    end
  end
end

function global_data.check_force_recipes(force)
  local item_prototypes = game.item_prototypes
  local recipe_book = global.recipe_book
  local force_index = force.index
  for name, recipe in pairs(force.recipes) do
    if recipe.enabled then
      local recipe_data = recipe_book.recipe[name]
      if recipe_data then
        set_recipe_available(force_index, recipe_data, recipe_book, item_prototypes)
      end
    end
  end
end

function global_data.check_force_technologies(force)
  local force_index = force.index
  local technologies = global.recipe_book.technology
  for name, technology in pairs(force.technologies) do
    if technology.enabled and technology.researched then
      local technology_data = technologies[name]
      if technology_data then
        technology_data.researched_forces[force_index] = true
      end
    end
  end
end

function global_data.check_forces()
  for _, force in pairs(game.forces) do
    global_data.check_force_recipes(force)
    global_data.check_force_technologies(force)
  end
end

return global_data