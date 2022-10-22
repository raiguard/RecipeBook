-- TEMPORARY:
for _, recipe in pairs(data.raw["recipe"]) do
  if string.find(recipe.name, "empty%-.*%-barrel") then
    recipe.unlock_results = false
  end
end
data.raw["recipe"]["rocket-part"].hidden = false
data.raw["recipe"]["rocket-part"].hidden_from_player_crafting = true
data.raw["recipe"]["electric-energy-interface"].hidden = true
