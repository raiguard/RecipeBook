--- @type table<ContextKind, string>
local context_kind_filter = {
  usage = "has-ingredient-",
  recipes = "has-product-",
}

local list = {}

--- @param context Context
--- @return LuaRecipePrototype[]?
function list.get(context)
  local recipes = game.get_filtered_recipe_prototypes({
    {
      filter = context_kind_filter[context.kind] .. context.type,
      elem_filters = { { filter = "name", name = context.name } },
    },
  })
  local recipes_array = {}
  for _, recipe_prototype in pairs(recipes) do
    recipes_array[#recipes_array + 1] = recipe_prototype
  end
  if not recipes_array[1] then
    return nil
  end
  return recipes_array
end

return list
