local recipe = {}

local math = require("__flib__.math")

local base_functions

recipe.init = function(functions)
    base_functions = functions
end

local ingredients_products_keys = {ingredients = true, products = true}

recipe.tooltip_formatter = function(obj_data, player_data, is_hidden, is_researched, is_label)
    -- locals
    local recipe_book = global.recipe_book
    local gui_translations = player_data.translations.gui
    local player_settings = player_data.settings

    -- build string
    local base_str = base_functions.get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
    -- crafting_category
    local category_str = (
      "\n"
      ..base_functions.build_rich_text("font", "default-semibold", gui_translations.category)
      .." "
      ..obj_data.category
    )
    -- crafting time, ingredients and products
    local ip_str_arr = {}
    if player_settings.show_detailed_recipe_tooltips and not is_label then
      -- crafting time
      ip_str_arr[1] = (
        "\n"
        ..base_functions.build_rich_text("font", "default-semibold", gui_translations.crafting_time)
        .." "..math.round_to(obj_data.energy, 2)
        .." "
        ..gui_translations.seconds_standalone
      )
      -- ingredients and products
      for material_type in pairs(ingredients_products_keys) do
        local materials = obj_data[material_type]
        local materials_len = #materials
        if materials_len > 0 then
          ip_str_arr[#ip_str_arr+1] = (
            "\n"
            ..base_functions.build_rich_text("font", "default-semibold", gui_translations[material_type.."_tooltip"])
          )
          for i = 1, #materials do
            local material = materials[i]
            local material_data = recipe_book[material.class][material.name]
            if material_data then
              local data = base_functions.formatter(
                material_data,
                player_data,
                {amount_string = material.amount_string, always_show = true}
              )
              local label = data.caption
              if data.is_researched then
                ip_str_arr[#ip_str_arr+1] = "\n  "..label
              else
                ip_str_arr[#ip_str_arr+1] = "\n  "..base_functions.build_rich_text("color", "unresearched", label)
              end
            end
          end
        end
      end
    end
    local ip_str = base_functions.concat(ip_str_arr)
    -- interaction help
    local interaction_help_str = ""
    if not is_label then
      interaction_help_str = "\n"..gui_translations.click_to_view
    end

    return base_str..category_str..ip_str..interaction_help_str
end

return recipe