local global_data = {}

function global_data.init()
  global.flags = {}
  global.players = {}

  global_data.build_recipe_book()
end

function global_data.build_recipe_book()
  local recipe_book = {
    machine = {},
    material = {},
    recipe = {},
    technology = {}
  }
  local translation_data = {}
end

return global_data