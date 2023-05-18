--- @type table<ContextKind, string>
local context_kind_filter = {
  usage = "has-ingredient-",
  recipes = "has-product-",
}

local list = {}

--- @param context Context
--- @param recipe string?
--- @return LuaRecipePrototype[]?, integer?
function list.get(context, recipe)
  local recipes = game.get_filtered_recipe_prototypes({
    {
      filter = context_kind_filter[context.kind] .. context.type,
      elem_filters = { { filter = "name", name = context.name } },
    },
  })
  local recipe_index = 1
  local recipes_array = {}
  local i = 0
  for recipe_name, recipe_prototype in pairs(recipes) do
    i = i + 1
    recipes_array[#recipes_array + 1] = recipe_prototype
    if recipe_name == recipe then
      recipe_index = i
    end
  end
  if not recipes_array[1] then
    return nil
  end
  return recipes_array, recipe_index
end

return list
