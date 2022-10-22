local libgui = require("__flib__.gui")
local libmath = require("__flib__.math")
local libtable = require("__flib__.table")

local templates = require("__RecipeBook__.gui.templates")

local crafting_machine = {
  ["assembling-machine"] = true,
  ["furnace"] = true,
  ["rocket-silo"] = true,
}

local page = {}

--- @param self Gui
function page.update(self, prototype_path)
  -- TODO: This currently redraws a page if you click a grouped item, then its recipe, etc
  -- Proper grouping of prototypes will fix this
  if self.state.current_page == prototype_path then
    return
  end

  log("Updating page to " .. prototype_path)
  local group = global.database[prototype_path]
  if not group then
    log("Page was not found")
    return
  end

  local profiler = game.create_profiler()

  local sprite, localised_name
  -- TODO: Assemble info, THEN build the GUI
  local components = {}

  -- This will be common across all kinds of objects
  local unlocked_by = {}

  local types = {}

  local recipe = group.recipe
  if recipe then
    sprite = "recipe/" .. recipe.name
    localised_name = recipe.localised_name
    table.insert(types, "Recipe")

    table.insert(
      components,
      templates.list_box(
        "Ingredients",
        libtable.map(recipe.ingredients, function(v)
          v.amount = { "", "[font=default-semibold]", v.amount, " ×[/font]  " }
          return v
        end),
        {
          "",
          "[img=quantity-time] [font=default-semibold]",
          { "time-symbol-seconds", libmath.round(recipe.energy, 0.1) },
          "[/font] ",
          { "description.crafting-time" },
        }
      )
    )
    table.insert(
      components,
      templates.list_box(
        "Products",
        libtable.map(recipe.products, function(v)
          v.amount = { "", "[font=default-semibold]", v.amount, " ×[/font]  " }
          return v
        end)
      )
    )

    local made_in = {}
    for _, crafter in
      pairs(game.get_filtered_entity_prototypes({
        { filter = "crafting-category", crafting_category = recipe.category },
      }))
    do
      if crafter.ingredient_count == 0 or crafter.ingredient_count >= #recipe.ingredients then
        table.insert(made_in, {
          type = "entity",
          name = crafter.name,
          remark = {
            "",
            "[img=quantity-time] ",
            { "time-symbol-seconds", libmath.round(recipe.energy / crafter.crafting_speed, 0.01) },
            " ",
          },
        })
      end
    end
    table.insert(components, templates.list_box("Made in", made_in))

    for _, technology in
      pairs(game.get_filtered_technology_prototypes({ { filter = "enabled" }, { filter = "has-effects" } }))
    do
      for _, effect in pairs(technology.effects) do
        if effect.type == "unlock-recipe" and effect.recipe == recipe.name then
          table.insert(unlocked_by, { type = "technology", name = technology.name })
        end
      end
    end
  end

  local fluid = group.fluid
  if fluid then
    sprite = sprite or ("fluid/" .. fluid.name)
    localised_name = localised_name or fluid.localised_name
    libtable.insert(types, "Fluid")

    local ingredient_in = {}
    for _, recipe in
      pairs(game.get_filtered_recipe_prototypes({
        { filter = "has-ingredient-fluid", elem_filters = { { filter = "name", name = fluid.name } } },
      }))
    do
      libtable.insert(ingredient_in, { type = "recipe", name = recipe.name })
    end
    libtable.insert(components, templates.list_box("Ingredient in", ingredient_in))

    local product_of = {}
    for _, recipe in
      pairs(game.get_filtered_recipe_prototypes({
        { filter = "has-product-fluid", elem_filters = { { filter = "name", name = fluid.name } } },
      }))
    do
      libtable.insert(product_of, { type = "recipe", name = recipe.name })
    end
    libtable.insert(components, templates.list_box("Product of", product_of))
  end

  local item = group.item
  if item then
    sprite = sprite or ("item/" .. item.name)
    localised_name = localised_name or item.localised_name
    libtable.insert(types, "Item")

    local ingredient_in = {}
    for _, recipe in
      pairs(game.get_filtered_recipe_prototypes({
        { filter = "has-ingredient-item", elem_filters = { { filter = "name", name = item.name } } },
      }))
    do
      libtable.insert(ingredient_in, { type = "recipe", name = recipe.name })
    end
    libtable.insert(components, templates.list_box("Ingredient in", ingredient_in))

    local product_of = {}
    for _, recipe in
      pairs(game.get_filtered_recipe_prototypes({
        { filter = "has-product-item", elem_filters = { { filter = "name", name = item.name } } },
      }))
    do
      libtable.insert(product_of, { type = "recipe", name = recipe.name })
    end
    if #product_of > 1 or not recipe then
      libtable.insert(components, templates.list_box("Product of", product_of))
    end
  end

  local entity = group.entity
  if entity then
    sprite = sprite or ("entity/" .. entity.name)
    localised_name = localised_name or entity.localised_name
    libtable.insert(types, "Entity")

    if crafting_machine[entity.type] then
      local filters = {}
      for category in pairs(entity.crafting_categories) do
        libtable.insert(filters, { filter = "category", category = category })
        libtable.insert(filters, { mode = "and", filter = "hidden-from-player-crafting", invert = true })
      end
      local can_craft = {}
      for _, recipe in pairs(game.get_filtered_recipe_prototypes(filters)) do
        if entity.ingredient_count == 0 or entity.ingredient_count >= #recipe.ingredients then
          libtable.insert(can_craft, { type = "recipe", name = recipe.name })
        end
      end
      libtable.insert(components, templates.list_box("Can craft", can_craft))
    elseif entity.type == "resource" then
      local required_fluid_str
      local required_fluid = entity.mineable_properties.required_fluid
      if required_fluid then
        required_fluid_str = {
          "",
          "Requires:  ",
          "[img=fluid/" .. required_fluid .. "] ",
          game.fluid_prototypes[required_fluid].localised_name,
        }
      end
      local resource_category = entity.resource_category
      local mined_by = {}
      for _, entity in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "mining-drill" } })) do
        if entity.resource_categories[resource_category] and (not required_fluid or entity.fluidbox_prototypes[1]) then
          libtable.insert(mined_by, { type = "entity", name = entity.name })
        end
      end
      libtable.insert(components, templates.list_box("Mined by", mined_by, required_fluid_str))
    elseif entity.type == "mining-drill" then
      local categories = entity.resource_categories --[[@as table<string, _>]]
      -- TODO: Fluid filters?
      local supports_fluid = entity.fluidbox_prototypes[1] and true or false
      local can_mine = {}
      for _, resource in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "resource" } })) do
        if
          categories[resource.resource_category] and (supports_fluid or not resource.mineable_properties.required_fluid)
        then
          table.insert(can_mine, { type = "entity", name = resource.name })
        end
      end
      table.insert(components, templates.list_box("Can mine", can_mine))
    end
  end

  if #unlocked_by > 0 then
    libtable.insert(components, templates.list_box("Unlocked by", unlocked_by))
  end

  profiler.stop()
  log({ "", "Build Info ", profiler })
  profiler.reset()

  self.refs.page_header_icon.sprite = sprite
  self.refs.page_header_label.caption = localised_name
  self.refs.page_header_type_label.caption = libtable.concat(types, "/")

  local page_scroll = self.refs.page_scroll
  page_scroll.clear()
  libgui.build(page_scroll, components)

  profiler.stop()
  log({ "", "Build GUI ", profiler })

  self.state.current_page = prototype_path
end

return page
