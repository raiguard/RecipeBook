local util = require("scripts.util")

local mining_drill_proc = {}

function mining_drill_proc.build(recipe_book, strings)
  for name, prototype in pairs(game.get_filtered_entity_prototypes{{filter = "type", type = "mining-drill"}}) do
    for category in pairs(prototype.resource_categories) do
      local category_data = recipe_book.resource_category[category]
      category_data.mining_drills[#category_data.mining_drills + 1] = {class = "mining_drill", name = name}
    end

    recipe_book.mining_drill[name] = {
      class = "mining_drill",
      placeable_by = util.process_placeable_by(prototype),
      prototype_name = name,
      resource_categories_lookup = prototype.resource_categories,
      resource_categories = util.convert_categories(prototype.resource_categories, "resource_category"),
      supports_fluid = #prototype.fluidbox_prototypes > 0,
      unlocked_by = {}
    }
    util.add_string(strings, {dictionary = "mining_drill", internal = name, localised = prototype.localised_name})
    util.add_string(strings, {
      dictionary = "mining_drill_description",
      internal = name,
      localised = prototype.localised_description
    })
  end
end

function mining_drill_proc.add_resources(recipe_book)
  for _, drill_data in pairs(recipe_book.mining_drill) do
    local compatible_resources = util.unique_obj_array()
    for category in pairs(drill_data.resource_categories_lookup) do
      local category_data = recipe_book.resource_category[category]
      for _, resource_ident in pairs(category_data.resources) do
        local resource_data = recipe_book.resource[resource_ident.name]
        if not resource_data.required_fluid or drill_data.supports_fluid then
          -- TODO: Shallow copy?
          compatible_resources[#compatible_resources + 1] = resource_ident
        end
      end
    end
    drill_data.compatible_resources = compatible_resources
  end
end

-- When calling the module directly, call fluid_proc.build
setmetatable(mining_drill_proc, { __call = function(_, ...) return mining_drill_proc.build(...) end })

return mining_drill_proc
