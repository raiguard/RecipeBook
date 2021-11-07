local equipment_category_proc = {}

function equipment_category_proc.build(recipe_book, dictionaries)
  for name, prototype in pairs(global.prototypes.equipment_category) do
    recipe_book.equipment_category[name] = {
      class = "equipment_category",
      enabled_at_start = true,
      equipment = {},
      prototype_name = name,
    }
    dictionaries.equipment_category:add(name, prototype.localised_name)
    dictionaries.equipment_category_description:add(name, prototype.localised_description)
  end
end

-- When calling the module directly, call equipment_category_proc.build
setmetatable(equipment_category_proc, {
  __call = function(_, ...)
    return equipment_category_proc.build(...)
  end,
})

return equipment_category_proc
