local global_data = {}

local constants = require("scripts.constants")

local table_remove = table.remove

function global_data.init()
  global.players = {}

  global_data.build_recipe_book()
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

  -- iterate crafters
  for name, prototype in pairs(game.get_filtered_entity_prototypes{
    {filter="type", type="assembling-machine"},
    {filter="type", type="furnace"}
  })
  do
    recipe_book.crafter[name] = {
      crafting_speed = prototype.crafting_speed,
      hidden = prototype.has_flag("hidden"),
      categories = prototype.crafting_categories,
      recipes = {},
      sprite_class = "entity",
      prototype_name = name
    }
    translation_data[#translation_data+1] = {dictionary="crafter", internal=name, localised=prototype.localised_name}
  end

  -- iterate materials
  for class, t in pairs{fluid=game.fluid_prototypes, item=game.item_prototypes} do
    for name, prototype in pairs(t) do
      local hidden
      if class == "fluid" then
        hidden = prototype.hidden
      else
        hidden = prototype.has_flag("hidden")
      end
      recipe_book.material[class..","..name] = {
        hidden = hidden,
        ingredient_in = {},
        product_of = {},
        unlocked_by = {},
        sprite_class = class,
        prototype_name = name
      }
      -- add to translation table
      translation_data[#translation_data+1] = {dictionary="material", internal=class..","..name, localised=prototype.localised_name}
    end
  end

  -- iterate recipes
  for name, prototype in pairs(game.recipe_prototypes) do
    if constants.blacklisted_recipe_categories[prototype.category] then
      goto continue
    end
    local data = {
      energy = prototype.energy,
      hand_craftable = prototype.category == "crafting",
      hidden = prototype.hidden,
      made_in = {},
      unlocked_by = {},
      sprite_class = "recipe",
      prototype_name = name
    }
    -- ingredients / products
    local material_book = recipe_book.material
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
        -- add hidden flag to table
        material.hidden = material_book[material.type..","..material.name].hidden
      end
      -- add to data
      data[mode] = materials
    end
    -- made in
    local category = prototype.category
    for crafter_name, crafter_data in pairs(recipe_book.crafter) do
      if crafter_data.categories[category] then
        data.made_in[#data.made_in+1] = crafter_name
        crafter_data.recipes[#crafter_data.recipes+1] = {name=name, hidden=prototype.hidden}
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
    ::continue::
  end

  -- iterate technologies
  for name, prototype in pairs(game.technology_prototypes) do
    for _, modifier in ipairs(prototype.effects) do
      if modifier.type == "unlock-recipe" then
        -- add to recipe data
        local recipe = recipe_book.recipe[modifier.recipe]
        recipe.unlocked_by[#recipe.unlocked_by+1] = name
      end
    end
    recipe_book.technology[name] = {hidden=prototype.hidden}
    translation_data[#translation_data+1] = {dictionary="technology", internal=prototype.name, localised=prototype.localised_name}
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
          log("Removing material ["..t.internal.."], which is not used in any recipes")
          materials[t.internal] = nil
          table_remove(translations, i)
        end
      end
    end
  end

  -- apply to global
  global.recipe_book = recipe_book
  global.translation_data = translation_data
end

return global_data