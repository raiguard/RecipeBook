recipe_book.set_alternative(data.raw["curved-rail"]["curved-rail"], data.raw["straight-rail"]["straight-rail"])

recipe_book.set_hidden(data.raw["recipe"]["electric-energy-interface"], true)
recipe_book.set_hidden(data.raw["item"]["electric-energy-interface"], true)
recipe_book.set_hidden(data.raw["electric-energy-interface"]["electric-energy-interface"], true)

recipe_book.set_group_with(data.raw["fish"]["fish"], data.raw["capsule"]["raw-fish"])
recipe_book.set_group_with(data.raw["straight-rail"]["straight-rail"], data.raw["rail-planner"]["rail"])

recipe_book.set_hidden(data.raw["item"]["rocket-part"], false)
recipe_book.set_hidden(data.raw["recipe"]["rocket-part"], false)

for _, recipe in pairs(data.raw["recipe"]) do
  if string.match(recipe.name, "^empty%-.*%-barrel$") then
    recipe_book.set_unlocks_results(recipe, false)
  end
end

local tree_01 = data.raw.tree["tree-01"]
for name, tree in pairs(data.raw.tree) do
  if name == "tree-01" then
    goto continue
  end

  recipe_book.set_alternative(tree, tree_01)

  ::continue::
end
