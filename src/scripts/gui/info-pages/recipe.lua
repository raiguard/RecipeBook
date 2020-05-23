local recipe_gui = {}

local event = require("__flib__.event")
local gui = require("__flib__.gui")

local constants = require("scripts.constants")
local lookup_tables = require("scripts.lookup-tables")

local math_max = math.max
local math_min = math.min

-- because Lua doesn't have a math.round...
-- from http://lua-users.org/wiki/SimpleRound
local function math_round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

gui.add_handlers{recipe={
  material_listboxes = {
    on_gui_selection_state_changed = gui.handlers.common.open_material_from_listbox
  },
  crafters_listbox = {
    on_gui_selection_state_changed = gui.handlers.common.do_nothing_listbox
  },
  quick_reference_button = {
    on_gui_click = function(e)
      event.raise(constants.open_gui_event, {player_index=e.player_index, gui_type="recipe_quick_reference", object=global.players[e.player_index].gui.info.name})
    end
  },
  technologies_listbox = {
    on_gui_selection_state_changed = gui.handlers.common.open_technology_from_listbox
  }
}}

function recipe_gui.create(player, player_table, content_container, name)
  local gui_data = gui.build(content_container, {
    {type="flow", style_mods={horizontal_spacing=8}, direction="horizontal", children={
      gui.templates.listbox_with_label("ingredients"),
      gui.templates.listbox_with_label("products")
    }},
    {type="flow", style_mods={horizontal_spacing=8}, direction="horizontal", children={
      gui.templates.listbox_with_label("crafters"),
      gui.templates.listbox_with_label("technologies")
    }},
    {type="button", style_mods={horizontally_stretchable=true}, caption={"rb-gui.open-quick-reference"}, mouse_button_filter={"left"},
      handlers="recipe.quick_reference_button"}
  })

  -- get data
  local force_index = player.force.index
  local recipe_book = global.recipe_book
  local recipe_data = recipe_book.recipe[name]
  local crafters = recipe_book.crafter
  local materials = recipe_book.material
  local technologies = recipe_book.technology
  local dictionary = lookup_tables[player.index]
  local crafter_translations = dictionary.crafter.translations
  local material_translations = dictionary.material.translations
  local technology_translations = dictionary.technology.translations
  local show_hidden = player_table.settings.show_hidden
  local rows = 0
  local show_unavailable = player_table.settings.show_unavailable

  -- populate ingredients and products
  for _,mode in ipairs{"ingredients", "products"} do
    local label = gui_data[mode.."_label"]
    local listbox = gui_data[mode.."_listbox"]
    local materials_list = recipe_data[mode]
    local items = {}
    local items_index = 0
    if mode == "ingredients" then
      items[1] = " [img=quantity-time]  "..recipe_data.energy.." seconds"
      items_index = 1
    end
    for ri=1,#materials_list do
      local material = materials_list[ri]
      local material_name = material.name
      local material_data = materials[material.type..","..material_name]
      if show_hidden or not material_data.hidden then
        if material_data.available_to_all_forces or material_data.available_to_forces[force_index] then
          items_index = items_index + 1
          items[items_index] = "[img="..material_data.sprite_class.."/"..material_name.."]  [font=default-semibold]"..material.amount_string.."[/font] "
            ..(material_data.hidden and "[H] " or "")..material_translations[material.type..","..material_name]
        elseif show_unavailable then
          items_index = items_index + 1
          items[items_index] = "[color="..constants.unavailable_font_color.."][img="..material_data.sprite_class.."/"..material_name
            .."]  [font=default-semibold]"..material.amount_string.."[/font] "..(material_data.hidden and "[H] " or "")
            ..material_translations[material.type..","..material_name].."[/color]"
        end
      end
    end
    listbox.items = items
    label.caption = {"rb-gui."..mode, items_index}
    rows = math_max(rows, math_min(6, items_index))
  end

  -- set material listbox heights
  local height = rows * 28
  gui_data.ingredients_frame.style.height = height
  gui_data.products_frame.style.height = height

  -- populate crafters
  rows = 0
  do
    local label = gui_data["crafters_label"]
    local listbox = gui_data["crafters_listbox"]
    local crafters_list = recipe_data.made_in
    local items = {}
    local items_index = 0
    if recipe_data.hand_craftable then
      items[1] = "[img=entity/character]  [font=default-semibold]("..recipe_data.energy.."s)[/font] "..dictionary.other.translations.character
      items_index = 1
    end
    for ri=1,#crafters_list do
      local crafter_name = crafters_list[ri]
      local crafter_data = crafters[crafter_name]
      if show_hidden or not crafter_data.hidden then
        if crafter_data.available_to_all_forces or crafter_data.available_to_forces[force_index] then
          items_index = items_index + 1
          items[items_index] = "[img=entity/"..crafter_name.."]  "..(crafter_data.hidden and "[H] " or "").."[font=default-semibold]("
            ..math_round(recipe_data.energy/crafter_data.crafting_speed,2).."s)[/font] "..crafter_translations[crafter_name]
        elseif show_unavailable then
          items_index = items_index + 1
          items[items_index] = "[color="..constants.unavailable_font_color.."][img=entity/"..crafter_name.."]  "..(crafter_data.hidden and "[H] " or "")
            .."[font=default-semibold](" ..math_round(recipe_data.energy/crafter_data.crafting_speed,2).."s)[/font] "..crafter_translations[crafter_name]
            .."[/color]"
        end
      end
    end
    listbox.items = items
    label.caption = {"rb-gui.made-in", items_index}
    rows = math_max(rows, math_min(6, items_index))
  end

  -- populate technologies
  do
    local label = gui_data["technologies_label"]
    local listbox = gui_data["technologies_listbox"]
    local technologies_list = recipe_data.unlocked_by
    local items = {}
    local items_index = 0
    for ri=1,#technologies_list do
      local technology_name = technologies_list[ri]
      local technology_data = technologies[technology_name]
      if technology_data.researched_forces[force_index] then
        items_index = items_index + 1
        items[items_index] = "[img=technology/"..technology_name.."]  "..(technology_translations[technology_name])
      else
        items_index = items_index + 1
        items[items_index] = "[color="..constants.unavailable_font_color.."][img=technology/"..technology_name.."]  "
          ..(technology_translations[technology_name]).."[/color]"
      end
    end
    listbox.items = items
    label.caption = {"rb-gui.unlocked-by", items_index}
    rows = math_max(rows, math_min(6, items_index))
  end

  -- set listbox heights
  height = rows * 28
  gui_data.crafters_frame.style.height = height
  gui_data.technologies_frame.style.height = height

  -- register handlers for listboxes
  gui.update_filters("recipe.material_listboxes", player.index, {gui_data.ingredients_listbox.index, gui_data.products_listbox.index}, "add")
  gui.update_filters("recipe.crafters_listbox", player.index, {gui_data.crafters_listbox.index}, "add")
  gui.update_filters("recipe.technologies_listbox", player.index, {gui_data.technologies_listbox.index}, "add")

  return gui_data
end

function recipe_gui.destroy(player, content_container)
  gui.update_filters("recipe", player.index, nil, "remove")
  content_container.clear()
end

return recipe_gui