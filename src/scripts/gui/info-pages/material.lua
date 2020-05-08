local material_gui = {}

local gui = require("__flib__.control.gui")

local lookup_tables = require("scripts.lookup-tables")

local math_max = math.max
local math_min = math.min
local string_gsub = string.gsub

gui.add_handlers{material={
  generic_listbox = {
    on_gui_selection_state_changed = gui.handlers.common.generic_open_from_listbox
  },
  technology_listbox = {
    on_gui_selection_state_changed = gui.handlers.common.open_technology_from_listbox
  }
}}

function material_gui.create(player, player_table, content_container, name)
  local gui_data = gui.build(content_container, {
    {type="flow", style_mods={horizontal_spacing=8}, direction="horizontal", children={
      gui.templates.listbox_with_label("ingredient_in"),
      gui.templates.listbox_with_label("product_of"),
    }},
    {type="flow", style_mods={horizontal_spacing=8}, direction="horizontal", save_as="lower_flow", children={
      gui.templates.listbox_with_label("mined_from"),
      gui.templates.listbox_with_label("unlocked_by")
    }}
  })

  -- set up data
  local material_data = global.recipe_book.material[name]
  local player_lookup_tables = lookup_tables[player.index]
  local recipe_translations = player_lookup_tables.recipe.translations
  local recipes = global.recipe_book.recipe
  local resource_translations = player_lookup_tables.resource.translations
  local show_hidden = player_table.settings.show_hidden
  local technology_translations = player_lookup_tables.technology.translations
  local rows = 0

  -- recipe tables
  for _, mode in ipairs{"ingredient_in", "product_of"} do
    local label = gui_data[mode.."_label"]
    local listbox = gui_data[mode.."_listbox"]
    local recipe_list = material_data[mode]
    local items = {}
    local items_index = 0
    for ri=1,#recipe_list do
      local recipe_name = recipe_list[ri]
      local recipe = recipes[recipe_name]
      if show_hidden or not recipe.hidden then
        items_index = items_index + 1
        items[items_index] = "[img=recipe/"..recipe_name.."]  "..(recipe_translations[recipe_name])
      end
    end
    listbox.items = items
    label.caption = {"rb-gui."..string_gsub(mode, "_", "-"), items_index}
    rows = math_max(rows, math_min(6, items_index))
  end

  -- set table heights
  local height = rows * 28
  gui_data.ingredient_in_frame.style.height = height
  gui_data.product_of_frame.style.height = height

  gui.update_filters("material.generic_listbox", player.index, {gui_data.ingredient_in_listbox.index, gui_data.product_of_listbox.index}, "add")

  rows = 0

  if #material_data.mined_from > 0 or #material_data.unlocked_by > 0 then
    -- mined from
    do
      local label = gui_data.mined_from_label
      local listbox = gui_data.mined_from_listbox
      local resources_list = material_data.mined_from
      local items = {}
      local items_index = 0
      for ri=1,#resources_list do
        local resource_name = resources_list[ri]
        items_index = items_index + 1
        items[items_index] = "[img=entity/"..resource_name.."]  "..(resource_translations[resource_name])
      end
      listbox.items = items
      listbox.ignored_by_interaction = true -- no actions when clicking resources
      label.caption = {"rb-gui.mined-from", items_index}
      rows = math_max(rows, math_min(6, items_index))
    end

    -- unlocked by
    do
      local label = gui_data.unlocked_by_label
      local listbox = gui_data.unlocked_by_listbox
      local technologies_list = material_data.unlocked_by
      local items = {}
      local items_index = 0
      for ri=1,#technologies_list do
        local technology_name = technologies_list[ri]
        items_index = items_index + 1
        items[items_index] = "[img=technology/"..technology_name.."]  "..(technology_translations[technology_name])
      end
      listbox.items = items
      label.caption = {"rb-gui.unlocked-by", items_index}
      rows = math_max(rows, math_min(6, items_index))
    end

    -- set table heights
    height = rows * 28
    gui_data.mined_from_frame.style.height = height
    gui_data.unlocked_by_frame.style.height = height

    gui.update_filters("material.technology_listbox", player.index, {gui_data.unlocked_by_listbox.index}, "add")
  else
    gui_data.lower_flow.destroy()
  end

  return gui_data
end

function material_gui.destroy(player, content_container)
  gui.update_filters("material", player.index, nil, "remove")
  content_container.clear()
end

return material_gui