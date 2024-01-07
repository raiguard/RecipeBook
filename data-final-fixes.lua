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

-- data:extend({
--   {
--     type = "recipe",
--     name = "rb-properties-test-recipe",
--     ingredients = { { "uranium-fuel-cell", 420 }, { "pipe", 69 } },
--     enabled = false,
--     result = "spidertron",
--     recipe_book = {
--       alternative = "recipe/spidertron",
--     },
--   },
-- })

-- table.insert(
--   data.raw.technology["automation-3"].effects,
--   { type = "unlock-recipe", recipe = "rb-properties-test-recipe" }
-- )

--- @diagnostic disable: inject-field
data.raw["curved-rail"]["curved-rail"].recipe_book = { alternative = "entity/straight-rail" }
data.raw["fish"]["fish"].recipe_book = { group_with = "item/raw-fish" }
data.raw["straight-rail"]["straight-rail"].recipe_book = { group_with = "item/rail" }
--- @diagnostic enable: inject-field

--- @class RBPrototypeOverrides
--- @field hidden boolean? If true, the prototype will be hidden in recipe book even if it is not hidden otherwise.
--- @field hidden_from_search boolean? If true, the prototype will be hidden from search results, but will not be hidden in info pages.
--- @field exclude boolean? If true, the prototype will be entirely excluded from recipe book.
--- @field alternative string? If set, this prototype will reference the given alternative's page instead of having its own.
--- @field group_with SpritePath? If set, this prototype will be grouped with the given prototype instead of following the regular grouping logic.

--- @class PrototypeWithRBOverrides: data.PrototypeBase
--- @field recipe_book RBPrototypeOverrides

--- @type table<SpritePath, SpritePath>
local alternatives = {}
--- @type table<SpritePath, SpritePath>
local group_overrides = {}

--- @param prototype data.PrototypeBase
--- @return string
local function get_prototype_base_type(prototype)
  for name, tbl in pairs(defines.prototypes) do
    if tbl[prototype.type] then
      return name
    end
  end
  error("Failed to find prototype type of " .. prototype.type .. "/" .. prototype.name)
end

--- @param prototype PrototypeWithRBOverrides
local function add_overrides(prototype)
  -- TODO: Validation
  local overrides = prototype.recipe_book
  local path = get_prototype_base_type(prototype) .. "/" .. prototype.name
  if overrides.alternative then
    alternatives[path] = overrides.alternative
  end
  if overrides.group_with then
    group_overrides[path] = overrides.group_with
  end
  prototype.recipe_book = nil
end

for _, prototypes in pairs(data.raw) do
  for _, prototype in pairs(prototypes) do
    if prototype.recipe_book then
      add_overrides(prototype)
    end
  end
end

local bigpack = require("__big-data-string__.pack")
data:extend({
  bigpack("rb_alternatives", serpent.line(alternatives)),
  bigpack("rb_group_overrides", serpent.line(group_overrides)),
})

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
