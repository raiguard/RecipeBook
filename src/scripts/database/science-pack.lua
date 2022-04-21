return function(database, dictionaries)
  for name, prototype in pairs(global.prototypes.item) do
    if prototype.type == "tool" then
      database.science_pack[name] = {
        class = "science_pack",
        prototype_name = name,
      }
      dictionaries.science_pack:add(name, prototype.localised_name)
      dictionaries.science_pack_description:add(name, prototype.localised_description)
    end
  end
end
