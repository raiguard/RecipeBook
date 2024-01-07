local flib_table = require("__flib__.table")

-- Make unbarreling recipes not unlock their corresponding fluids
for _, recipe in pairs(data.raw["recipe"]) do
  if string.find(recipe.name, "empty%-.*%-barrel") then
    recipe.unlock_results = false
  end
end
-- Make rocket part visible in RB
data.raw["recipe"]["rocket-part"].hidden = false
data.raw["recipe"]["rocket-part"].hide_from_player_crafting = true
local flags = data.raw["item"]["rocket-part"].flags --[[@as data.ItemPrototypeFlags]]
local index = flib_table.find(flags, "hidden")
if index then
  table.remove(flags, index)
end
-- Hide EEE from RB
data.raw["recipe"]["electric-energy-interface"].hidden = true
table.insert(data.raw["item"]["electric-energy-interface"].flags, "hidden")

-- Potential properties layout:
-- {
--   type = "item",
--   name = "foo",
--   recipe_book = {
--     hidden = true, -- Will show as "hidden" even if it's really not. Clicking "show hidden" will still make this appear.
--     hidden_from_search = true, -- Will not show up in search results by default, but will show in info panes.
--     exclude = true, -- Will not show up in recipe book whatsoever.
--     alternative = "item/bar", -- Alt+clicking this recipe will open the bar item's page instead.
--     group_with = "recipe/bar-smelting", -- Force a grouping even if internal names don't match.
--   }
-- }

-- -- Testing recipe
-- local recipe = table.deepcopy(data.raw["recipe"]["advanced-oil-processing"])
-- if not recipe.ingredients then
--   return
-- end
-- recipe.name = "rb-test-recipe"
-- recipe.ingredients[1].temperature = 130
-- recipe.ingredients[2].minimum_temperature = 10
-- recipe.ingredients[2].maximum_temperature = 1000
-- recipe.ingredients[3] = {
--   type = "fluid",
--   name = "petroleum-gas",
--   minimum_temperature = 69,
--   amount = 10000,
-- }
-- recipe.ingredients[4] = {
--   type = "fluid",
--   name = "sulfuric-acid",
--   maximum_temperature = 420,
--   amount = 0.5,
-- }
-- recipe.results[2].temperature = 25
-- recipe.results[4] = {
--   type = "item",
--   name = "space-science-pack",
--   amount_min = 1,
--   amount_max = 65535,
--   probability = 0.6666666666666666666667,
-- }
-- data:extend({ recipe })

--- Some compatibility things for later
-- local excluded_categories = {
--   ["big-turbine"] = true,
--   ["condenser-turbine"] = true,
--   ["delivery-cannon"] = true,
--   ["ee-testing-tool"] = true,
--   ["fuel-depot"] = true,
--   ["scrapping"] = true,
--   ["spaceship-antimatter-engine"] = true,
--   ["spaceship-ion-engine"] = true,
--   ["spaceship-rocket-engine"] = true,
--   ["transport-drone-request"] = true,
--   ["transport-fluid-request"] = true,
--   ["void-crushing"] = true,
-- }
-- local group_overrides = {
--   ["entity/straight-rail"] = "item/rail",
--   ["entity/character"] = "item/nullius-android-1",
--   ["entity/coal"] = "item/nullius-coal",
--   ["entity/red-inserter"] = "item/long-handed-inserter",
--   ["item/express-transport-belt"] = "recipe/nullius-conveyor-belt-3",
--   ["item/fast-transport-belt"] = "recipe/nullius-conveyor-belt-2",
--   ["item/iron-chest"] = "recipe/nullius-small-chest-2",
--   ["item/logistic-chest-active-provider"] = "recipe/nullius-small-dispatch-chest-2",
--   ["item/logistic-chest-buffer"] = "recipe/nullius-small-buffer-chest-2",
--   ["item/logistic-chest-passive-provider"] = "recipe/nullius-small-supply-chest-2",
--   ["item/logistic-chest-requester"] = "recipe/nullius-small-demand-chest-2",
--   ["item/logistic-chest-storage"] = "recipe/nullius-small-storage-chest-2",
--   ["item/pipe-to-ground"] = "recipe/nullius-underground-pipe-1",
--   ["item/rail"] = "recipe/nullius-rail",
--   ["item/steel-chest"] = "recipe/nullius-small-chest-3",
--   ["item/transport-belt"] = "recipe/nullius-conveyor-belt-1",
--   ["item/ultimate-transport-belt"] = "recipe/nullius-conveyor-belt-4",
--   ["item/wooden-chest"] = "recipe/nullius-small-chest-1",
--   ["entity/nullius-turbine-open-standard-1"] = "item/nullius-turbine-open-1",
--   ["entity/nullius-turbine-open-standard-2"] = "item/nullius-turbine-open-2",
--   ["entity/nullius-turbine-open-standard-3"] = "item/nullius-turbine-open-3",
-- }
-- local alternatives = {
--   ["entity/nullius-turbine-open-backup-2"] = "entity/nullius-turbine-open-standard-2",
--   ["entity/nullius-turbine-open-exhaust-2"] = "entity/nullius-turbine-open-standard-2",
--   ["entity/curved-rail"] = "entity/straight-rail",
-- }
-- if mods["nullius"] then
--   data.raw["resource"]["nullius-fumarole"].subgroup = "raw-resource"
-- end
