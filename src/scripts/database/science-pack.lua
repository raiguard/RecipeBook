return function(database, dictionaries)
  --- @type table<string, LuaItemPrototype>
  local prototypes = global.prototypes.item
  for name, prototype in pairs(prototypes) do
    if prototype.type == "tool" then
      database.science_pack[name] = {
        class = "science_pack",
        order = prototype.order,
        prototype_name = name,
      }
      dictionaries.science_pack:add(name, prototype.localised_name)
      dictionaries.science_pack_description:add(name, prototype.localised_description)
    end
  end
end
