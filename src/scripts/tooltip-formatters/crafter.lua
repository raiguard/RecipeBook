local crafter = {}

local math = require("__flib__.math")

local base_functions

crafter.init = function(functions)
    base_functions = functions
end

crafter.tooltip_formatter =function(obj_data, player_data, is_hidden, is_researched, is_label, blueprint_recipe)
    -- locals
    local translations = player_data.translations
    local gui_translations = translations.gui

    -- object properties
    local categories = obj_data.categories
    local rocket_parts_required = obj_data.rocket_parts_required
    local fixed_recipe = obj_data.fixed_recipe

    -- build string
    local base_str = base_functions.get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
    -- rocket parts
    local rocket_parts_str = ""
    if rocket_parts_required then
      rocket_parts_str = (
        "\n"
        ..base_functions.build_rich_text("font", "default-semibold", gui_translations.rocket_parts_required)
        .." "
        ..rocket_parts_required
      )
    end
    -- fixed recipe
    local fixed_recipe_str = ""
    local fixed_recipe_help_str = ""
    if fixed_recipe then
      -- get fixed recipe data
      local fixed_recipe_data = global.recipe_book.recipe[obj_data.fixed_recipe]
      if fixed_recipe_data then
        local title_str = ("\n"..base_functions.build_rich_text("font", "default-semibold", gui_translations.fixed_recipe).."  ")
        -- fixed recipe
        local data = base_functions.formatter(fixed_recipe_data, player_data, {always_show = true})
        local label = data.caption
        -- remove glyph from caption, since it's implied
        if player_data.settings.show_glyphs then
          label = string.gsub(label, "^.-nt%]  ", "")
        end
        if data.is_researched then
          fixed_recipe_str = title_str..label
        else
          fixed_recipe_str = title_str..base_functions.build_rich_text("color", "unresearched", label)
        end
        -- help text
        if not is_label then
          fixed_recipe_help_str = "\n"..gui_translations.control_click_to_view_fixed_recipe
        end
      end
    end
    -- crafting speed
    local crafting_speed_str = (
      "\n"
      ..base_functions.build_rich_text("font", "default-semibold", gui_translations.crafting_speed)
      .." "
      ..math.round_to(obj_data.crafting_speed, 2)
    )
    -- crafting categories
    local crafting_categories_str_arr = {
      "\n"
      ..base_functions.build_rich_text("font", "default-semibold", gui_translations.crafting_categories)
    }
    for i = 1, #categories do
      crafting_categories_str_arr[#crafting_categories_str_arr+1] = "\n  "..categories[i]
    end
    local crafting_categories_str = base_functions.concat(crafting_categories_str_arr)
    -- fuel categories
    local fuel_categories_str_arr = {}
    local fuel_categories = obj_data.fuel_categories
    if fuel_categories then
      fuel_categories_str_arr[1] = "\n"..base_functions.build_rich_text("font", "default-semibold", gui_translations.fuel_categories)
      for i = 1, #fuel_categories do
        fuel_categories_str_arr[#fuel_categories_str_arr+1] = "\n  "..fuel_categories[i]
      end
    end
    local fuel_categories_str = base_functions.concat(fuel_categories_str_arr)
    local open_page_help_str = ""
    local blueprintable_str = ""
    if not is_label then
      -- open page help
      open_page_help_str = "\n"..gui_translations.click_to_view
      -- blueprintable
      if blueprint_recipe then
        if obj_data.blueprintable then
          blueprintable_str = "\n"..gui_translations.shift_click_to_get_blueprint
        else
          blueprintable_str = "\n"..base_functions.build_rich_text("color", "error", gui_translations.blueprint_not_available)
        end
      end
    end

    return (
      base_str
      ..rocket_parts_str
      ..fixed_recipe_str
      ..crafting_speed_str
      ..crafting_categories_str
      ..fuel_categories_str
      ..open_page_help_str
      ..blueprintable_str
      ..fixed_recipe_help_str
    )
end

return crafter