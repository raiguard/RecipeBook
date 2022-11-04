-- Make unbarreling recipes not unlock their corresponding fluids
for _, recipe in pairs(data.raw["recipe"]) do
  if string.find(recipe.name, "empty%-.*%-barrel") then
    recipe.unlock_results = false
  end
end
-- Make rocket part visible in RB
data.raw["recipe"]["rocket-part"].hidden = false
data.raw["recipe"]["rocket-part"].hide_from_player_crafting = true
-- Hide EEE from RB
data.raw["recipe"]["electric-energy-interface"].hidden = true

-- Testing recipe
local recipe = table.deepcopy(data.raw["recipe"]["advanced-oil-processing"])
recipe.name = "rb-test-recipe"
recipe.ingredients[1].temperature = 130
recipe.ingredients[2].minimum_temperature = 10
recipe.ingredients[2].maximum_temperature = 1000
recipe.ingredients[3] = {
  type = "fluid",
  name = "petroleum-gas",
  minimum_temperature = 69,
  amount = 10000,
}
recipe.ingredients[4] = {
  type = "fluid",
  name = "sulfuric-acid",
  maximum_temperature = 420,
  amount = 1,
}
recipe.results[2].temperature = 25
recipe.results[4] = {
  type = "item",
  name = "space-science-pack",
  amount_min = 1,
  amount_max = 65535,
  probability = 0.6666666666666666666667,
}
data:extend({ recipe })
