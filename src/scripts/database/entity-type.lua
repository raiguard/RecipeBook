local constants = require("constants")

return function(database, dictionaries)
  for class in pairs(constants.prototypes.filtered_entities) do
    for name, prototype in pairs(global.prototypes[class]) do
      local type = prototype.type
      local type_data = database.entity_type[type]
      if not type_data then
        type_data = {
          class = "entity_type",
          entities = {},
          prototype_name = type,
        }
        database.entity_type[type] = type_data
        dictionaries.entity_type:add(type, { "entity-type." .. type })
        dictionaries.entity_type_description:add(type, { "entity-type-description." .. type })
      end

      table.insert(type_data.entities, { class = "entity", name = name })
    end
  end
end
