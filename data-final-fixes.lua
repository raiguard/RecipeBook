require("prototypes.pack-overrides")
require("prototypes.pack-sprites")

for recipe_name, recipe in pairs(data.raw.recipe) do
  if string.find(recipe_name, "empty%-.*%-barrel") then
    recipe.unlock_results = false
  end
end
