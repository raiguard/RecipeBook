local constants = require("constants")

return function(database)
  for _, machine_class in pairs(constants.machine_classes) do
    for _, machine_data in pairs(database[machine_class]) do
      -- Hidden / disabled for machines
      if not machine_data.is_character then
        local placed_by_len = #(machine_data.placed_by or {})
        if placed_by_len == 0 then
          machine_data.enabled = false
        elseif placed_by_len == 1 then
          local item_ident = machine_data.placed_by[1]
          local item_data = database.item[item_ident.name]
          if item_data.hidden then
            machine_data.hidden = true
          end
        end
      end
    end
  end
end
