local data_util = require("prototypes.util")

--- Recipe Book data overrides API. Overrides are:
--- - **alternative**: `string?` - If set, this prototype will reference the given alternative's page instead of having its own.
--- - **exclude**: `boolean?` - If true, the prototype will be entirely excluded from recipe book.
--- - **group_with**: `SpritePath?` - If set, this prototype will be grouped with the given prototype instead of following the regular grouping logic.
--- - **hidden**: `boolean?` - If true, the prototype will be hidden in recipe book even if it is not hidden otherwise.
--- - **hidden_from_search**: `boolean?` - If true, the prototype will be hidden from search results, but will not be hidden in info pages.
--- - **unlocks_results**: `boolean?` - If true, unlocking this recipe will not mark the recipe products as unlocked.
--- @class RecipeBookDataAPI
--- @field private alternatives table<SpritePath, data.PrototypeBase>
--- @field private exclude table<SpritePath, boolean>
--- @field private group_with table<SpritePath, data.PrototypeBase>
--- @field private hidden table<SpritePath, boolean>
--- @field private hidden_from_search table<SpritePath, boolean>
--- @field private unlocks_results table<SpritePath, boolean>
recipe_book = {
  alternatives = {},
  exclude = {},
  group_with = {},
  hidden = {},
  hidden_from_search = {},
  unlocks_results = {},
}

--- @param prototype data.PrototypeBase
--- @return data.PrototypeBase?
function recipe_book.get_alternative(prototype)
  data_util.assert_is_prototype(prototype, "prototype")
  return recipe_book.alternatives[data_util.get_sprite_path(prototype)]
end

--- @param prototype data.PrototypeBase
--- @param alternative data.PrototypeBase
function recipe_book.set_alternative(prototype, alternative)
  data_util.assert_is_prototype(prototype, "prototype")
  data_util.assert_is_prototype(alternative, "alternative")
  recipe_book.alternatives[data_util.get_sprite_path(prototype)] = alternative
end

--- @param prototype data.PrototypeBase
--- @return boolean
function recipe_book.get_exclude(prototype)
  data_util.assert_is_prototype(prototype, "prototype")
  return recipe_book.exclude[data_util.get_sprite_path(prototype)] or false
end

--- @param prototype data.PrototypeBase
--- @param exclude boolean
function recipe_book.set_exclude(prototype, exclude)
  data_util.assert_is_prototype(prototype, "prototype")
  data_util.assert_is_boolean(exclude, "exclude")
  recipe_book.exclude[data_util.get_sprite_path(prototype)] = exclude
end

--- @param prototype data.PrototypeBase
--- @return data.PrototypeBase?
function recipe_book.get_group_with(prototype)
  data_util.assert_is_prototype(prototype, "prototype")
  return recipe_book.group_with[data_util.get_sprite_path(prototype)]
end

--- @param prototype data.PrototypeBase
--- @param group_with data.PrototypeBase
function recipe_book.set_group_with(prototype, group_with)
  data_util.assert_is_prototype(prototype, "prototype")
  data_util.assert_is_prototype(group_with, "group_with")
  recipe_book.group_with[data_util.get_sprite_path(prototype)] = group_with
end

--- @param prototype data.PrototypeBase
--- @return boolean
function recipe_book.get_hidden(prototype)
  data_util.assert_is_prototype(prototype, "prototype")
  return recipe_book.hidden[data_util.get_sprite_path(prototype)] or false
end

--- @param prototype data.PrototypeBase
--- @param hidden boolean
function recipe_book.set_hidden(prototype, hidden)
  data_util.assert_is_prototype(prototype, "prototype")
  data_util.assert_is_boolean(hidden, "hidden")
  recipe_book.hidden[data_util.get_sprite_path(prototype)] = hidden
end

--- @param prototype data.PrototypeBase
--- @return boolean
function recipe_book.get_hidden_from_search(prototype)
  data_util.assert_is_prototype(prototype, "prototype")
  return recipe_book.hidden_from_search[data_util.get_sprite_path(prototype)] or false
end

--- @param prototype data.PrototypeBase
--- @param hidden_from_search boolean
function recipe_book.set_hidden_from_search(prototype, hidden_from_search)
  data_util.assert_is_prototype(prototype, "prototype")
  data_util.assert_is_boolean(hidden_from_search, "hidden_from_search")
  recipe_book.hidden_from_search[data_util.get_sprite_path(prototype)] = hidden_from_search
end

--- @param prototype data.PrototypeBase
--- @return boolean
function recipe_book.get_unlocks_results(prototype)
  data_util.assert_is_prototype(prototype, "prototype")
  return recipe_book.unlocks_results[data_util.get_sprite_path(prototype)] or false
end

--- @param prototype data.PrototypeBase
function recipe_book.set_unlocks_results(prototype, unlocks_results)
  data_util.assert_is_prototype(prototype, "prototype")
  data_util.assert_is_boolean(unlocks_results, "hidden")
  recipe_book.unlocks_results[data_util.get_sprite_path(prototype)] = unlocks_results
end
