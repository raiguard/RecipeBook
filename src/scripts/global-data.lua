local global_data = {}

local constants = require("scripts.constants")

local table_remove = table.remove

function global_data.init()
  global.players = {}
  global.searching_players = {}

  global_data.build_recipe_book()

  for _, force in pairs(game.forces) do
    global_data.check_force_recipes(force)
    global_data.check_force_technologies(force)
  end
end

function global_data.build_recipe_book()
  -- table skeletons
  local recipe_book = {
    crafter = {},
    material = {},
    recipe = {},
    technology = {}
  }
  local translation_data = {
    {dictionary="other", internal="character", localised={"entity-name.character"}}
  }

  -- forces
  local forces = {}
  for _, force in pairs(game.forces) do
    forces[force.index] = force.recipes
  end

  -- iterate crafters
  local crafter_prototypes = game.get_filtered_entity_prototypes{
    {filter="type", type="assembling-machine"},
    {filter="type", type="furnace"}
  }
  for name, prototype in pairs(crafter_prototypes) do
    recipe_book.crafter[name] = {
      available_to_forces = {},
      categories = prototype.crafting_categories,
      crafting_speed = prototype.crafting_speed,
      hidden = prototype.has_flag("hidden")
    }
    translation_data[#translation_data+1] = {dictionary="crafter", internal=name, localised=prototype.localised_name}
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
      recipe_book.material[class..","..name] = {
        available_to_forces = {},
        hidden = hidden,
        ingredient_in = {},
        mined_from = {},
        product_of = {},
        prototype_name = name,
        sprite_class = class,
        unlocked_by = {}
      }
      -- add to translation table
      translation_data[#translation_data+1] = {dictionary="material", internal=class..","..name, localised=prototype.localised_name}
    end
  end

  -- iterate recipes
  local recipe_prototypes = game.recipe_prototypes
  for name, prototype in pairs(recipe_prototypes) do
    if #prototype.ingredients > 0 and not constants.blacklisted_recipe_categories[prototype.category] then
      local data = {
        available_to_forces = {},
        energy = prototype.energy,
        hand_craftable = prototype.category == "crafting",
        hidden = prototype.hidden,
        made_in = {},
        prototype_name = name,
        sprite_class = "recipe",
        unlocked_by = {}
      }
      -- ingredients / products
      for _, mode in ipairs{"ingredients", "products"} do
        local materials = prototype[mode]
        for i=1,#materials do
          local material = materials[i]
          -- build amount string, to display probability, [min/max] amount - includes the "x"
          local amount = material.amount
          local amount_string = amount and (tostring(amount).."x") or (material.amount_min.."-"..material.amount_max.."x")
          local probability = material.probability
          if probability and probability < 1 then
            amount_string = tostring(probability * 100).."% "..amount_string
          end
          material.amount_string = amount_string
        end
        -- add to data
        data[mode] = materials
      end
      -- made in
      local category = prototype.category
      for crafter_name, crafter_data in pairs(recipe_book.crafter) do
        if crafter_data.categories[category] then
          data.made_in[#data.made_in+1] = crafter_name
        end
      end
      -- material: ingredient in
      local ingredients = prototype.ingredients
      for i=1,#ingredients do
        local ingredient = ingredients[i]
        local ingredient_data = recipe_book.material[ingredient.type..","..ingredient.name]
        if ingredient_data then
          ingredient_data.ingredient_in[#ingredient_data.ingredient_in+1] = name
        end
      end
      -- material: product of
      local products = prototype.products
      for i=1,#products do
        local product = products[i]
        local product_data = recipe_book.material[product.type..","..product.name]
        if product_data then
          product_data.product_of[#product_data.product_of+1] = name
        end
      end
      -- insert into recipe book
      recipe_book.recipe[name] = data
      -- translation data
      translation_data[#translation_data+1] = {dictionary="recipe", internal=name, localised=prototype.localised_name}
    end
  end

  -- iterate resources
  local resource_prototypes = game.get_filtered_entity_prototypes{{filter="type", type="resource"}}
  for name, prototype in pairs(resource_prototypes) do
    local products = prototype.mineable_properties.products
    if products then
      for _, product in ipairs(products) do
        local product_data = recipe_book.material[product.type..","..product.name]
        if product_data then
          product_data.mined_from[#product_data.mined_from+1] = name
        end
      end
    end
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
              local product_data = recipe_book.material[product_type..","..product_name]
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
        researched_forces = {}
      }
      translation_data[#translation_data+1] = {dictionary="technology", internal=prototype.name, localised=prototype.localised_name}
    end
  end

  -- remove all materials that aren't used in recipes
  do
    local materials = recipe_book.material
    local translations = translation_data
    for i = #translations, 1, -1 do
      local t = translations[i]
      if t.dictionary == "material" then
        local data = materials[t.internal]
        if #data.ingredient_in == 0 and #data.product_of == 0 then
          __dlog("Removing material ["..t.internal.."], which is not used in any recipes")
          materials[t.internal] = nil
          table_remove(translations, i)
        elseif #data.unlocked_by == 0 then
          -- set unlocked by default
          __dlog("Material ["..t.internal.."] has no technologies to unlock it, setting to unlocked by default")
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
    local product_data = recipe_book.material[product.type..","..product.name]
    if product_data and product_data.available_to_forces then
      product_data.available_to_forces[force_index] = true
    end
    -- crafter
    if product.type == "item" then
      local place_result = item_prototypes[product.name].place_result
      if place_result then
        local crafter_data = recipe_book.crafter[place_result.name]
        if crafter_data then
          crafter_data.available_to_forces[force_index] = true
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

return global_data