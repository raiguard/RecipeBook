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
