-- Mark unbarreling recipes as not unlocking their products
for name, recipe in pairs(data.raw.recipe) do
  if string.match(name, "^empty%-.*%-barrel$") then
    recipe.unlock_results = false
  end
end
