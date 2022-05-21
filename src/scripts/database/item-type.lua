return function(database, dictionaries)
  for name, prototype in pairs(global.prototypes.item) do
    if prototype.type ~= "mining-tool" then
      local type = prototype.type
      local type_data = database.item_type[type]
      if not type_data then
        type_data = {
          class = "item_type",
          items = {},
          prototype_name = type,
        }
        database.item_type[type] = type_data
        dictionaries.item_type:add(type, { "item-type." .. type })
        dictionaries.item_type_description:add(type, { "item-type-description." .. type })
      end

      table.insert(type_data.items, { class = "item", name = name })
    end
  end
end
