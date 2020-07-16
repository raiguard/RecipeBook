local global_data = {}

local constants = require("constants")

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

function global_data.build_recipe_book()
  local recipe_book = {
    machine = {},
    material = {},
    recipe = {},
    resource = {},
    technology = {}
  }
  local translation_data = {
    -- internal classes
    {dictionary="gui", internal="fluid", localised={"rb-gui.fluid"}},
    {dictionary="gui", internal="item", localised={"rb-gui.item"}},
    {dictionary="gui", internal="machine", localised={"rb-gui.machine"}},
    {dictionary="gui", internal="material", localised={"rb-gui.material"}},
    {dictionary="gui", internal="recipe", localised={"rb-gui.recipe"}},
    {dictionary="gui", internal="resource", localised={"rb-gui.resource"}},
    {dictionary="gui", internal="technology", localised={"rb-gui.technology"}},
    -- misc
    {dictionary="gui", internal="character", localised={"entity-name.character"}},
    {dictionary="gui", internal="hidden", localised={"rb-gui.hidden"}},
    {dictionary="gui", internal="hidden_abbrev", localised={"rb-gui.hidden-abbrev"}},
    {dictionary="gui", internal="unavailable", localised={"rb-gui.unavailable"}}
  }

  -- forces
  local forces = {}
  for _, force in pairs(game.forces) do
    forces[force.index] = force.recipes
  end

  -- iterate machines
  local machine_prototypes = game.get_filtered_entity_prototypes{
    {filter="type", type="assembling-machine"},
    {filter="type", type="furnace"}
  }
  for name, prototype in pairs(machine_prototypes) do
    recipe_book.machine[name] = {
      available_to_forces = {},
      categories = prototype.crafting_categories,
      crafting_speed = prototype.crafting_speed,
      hidden = prototype.has_flag("hidden"),
      internal_class = "machine",
      prototype_name = name,
      sprite_class = "entity"
    }
    translation_data[#translation_data+1] = {dictionary="machine", internal=name, localised=prototype.localised_name}
  end

  -- iterate materials
  local fluid_prototypes = game.fluid_prototypes
  local item_prototypes = game.item_prototypes
  for class, t in pairs{fluid=fluid_prototypes, item=item_prototypes} do
    for name, prototype in pairs(t) do
      local hidden
      if class == "fluid" then
        hidden = prototype.hidden
      else
        hidden = prototype.has_flag("hidden")
      end
      recipe_book.material[class.."."..name] = {
        available_to_forces = {},
        hidden = hidden,
        ingredient_in = {},
        internal_class = "material",
        mined_from = {},
        product_of = {},
        prototype_name = name,
        sprite_class = class,
        unlocked_by = {}
      }
      -- add to translation table
      translation_data[#translation_data+1] = {dictionary="material", internal=class.."."..name, localised=prototype.localised_name}
    end
  end

  -- TODO this is slow
  -- iterate recipes
  local recipe_prototypes = game.recipe_prototypes
  for name, prototype in pairs(recipe_prototypes) do
    local data = {
      available_to_forces = {},
      energy = prototype.energy,
      hand_craftable = prototype.category == "crafting",
      hidden = prototype.hidden,
      internal_class = "recipe",
      made_in = {},
      prototype_name = name,
      sprite_class = "recipe",
      unlocked_by = {}
    }
    -- ingredients / products
    for _, mode in ipairs{"ingredients", "products"} do
      local materials = prototype[mode]
      local output = {}
      for i = 1, #materials do
        local material = materials[i]
        -- build amount string, to display probability, [min/max] amount - includes the "x"
        local amount = material.amount
        local amount_string = amount and (tostring(amount).."x") or (material.amount_min.."-"..material.amount_max.."x")
        local probability = material.probability
        if probability and probability < 1 then
          amount_string = tostring(probability * 100).."% "..amount_string
        end
        -- save only the essentials
        output[i] = {
          type = material.type,
          name = material.name,
          amount_string = amount_string,
          avg_amount_string = amount == nil and ((material.amount_min + material.amount_max) / 2) or nil
        }
      end
      -- add to data
      data[mode] = output
    end
    -- made in
    local category = prototype.category
    for machine_name, machine_data in pairs(recipe_book.machine) do
      if machine_data.categories[category] then
        data.made_in[#data.made_in+1] = {
          name = machine_name,
          amount_string = "("..round(prototype.energy / machine_data.crafting_speed, 2).."s)"
        }
      end
    end
    -- material: ingredient in
    local ingredients = prototype.ingredients
    for i=1,#ingredients do
      local ingredient = ingredients[i]
      local ingredient_data = recipe_book.material[ingredient.type.."."..ingredient.name]
      if ingredient_data then
        ingredient_data.ingredient_in[#ingredient_data.ingredient_in+1] = name
      end
    end
    -- material: product of
    local products = prototype.products
    for i=1,#products do
      local product = products[i]
      local product_data = recipe_book.material[product.type.."."..product.name]
      if product_data then
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

  -- remove all materials that aren't used in recipes
  -- TODO flag materials whose recipes are all hidden
  do
    local materials = recipe_book.material
    local translations = translation_data
    for i = #translations, 1, -1 do
      local t = translations[i]
      if t.dictionary == "material" then
        local data = materials[t.internal]
        if #data.ingredient_in == 0 and #data.product_of == 0 then
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

local function set_recipe_available(force_index, recipe_data, recipe_book, item_prototypes)
  recipe_data.available_to_forces[force_index] = true
  for _, product in ipairs(recipe_data.products) do
    -- product
    local product_data = recipe_book.material[product.type.."."..product.name]
    if product_data and product_data.available_to_forces then
      product_data.available_to_forces[force_index] = true
    end
    -- machine
    if product.type == "item" then
      local place_result = item_prototypes[product.name].place_result
      if place_result then
        local machine_data = recipe_book.machine[place_result.name]
        if machine_data then
          machine_data.available_to_forces[force_index] = true
        end
      end
    end
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