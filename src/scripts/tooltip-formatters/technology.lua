local technology = {}

local base_functions

technology.init = function(functions)
    base_functions = functions
end

technology.tooltip_formatter = function( obj_data, player_data, is_hidden, is_researched, is_label)
    local base_str = base_functions.get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
    local gui_translations = player_data.translations.gui
    local player_settings = player_data.settings
    local recipe_book = global.recipe_book

    -- units count, ingredients
    local tech_str_arr = {}
    if player_settings.show_detailed_recipe_tooltips and not is_label then
      -- units count
      local unit_count = obj_data.research_unit_count or game.evaluate_expression(
        obj_data.research_unit_count_formula,
        {L = obj_data.min_level, l = obj_data.min_level}
      )

      tech_str_arr[1] = (
        "\n"
        ..base_functions.build_rich_text("font", "default-semibold", gui_translations.research_units_tooltip)
        .." "..unit_count
      )
      tech_str_arr[#tech_str_arr+1] = (
        "\n"
        ..base_functions.build_rich_text("font", "default-semibold", gui_translations.research_ingredients_per_unit_tooltip)
      )

      -- time ingredient
      if obj_data.research_unit_energy then
        local time_item_prefix = player_data.settings.show_glyphs and "[font=RecipeBook]Z[/font]   " or ""
        tech_str_arr[#tech_str_arr+1] = "\n  ".. time_item_prefix.."[img=quantity-time]   "
        ..obj_data.research_unit_energy.." "..gui_translations.seconds_standalone
                  
      end
      -- ingredients
      local ingredients = obj_data.research_ingredients_per_unit
      for i = 1, #ingredients do
        local ingredient = ingredients[i]
        local ingredient_data = recipe_book[ingredient.class][ingredient.name]
        if ingredient_data then
          local data = base_functions.formatter(
            ingredient_data,
            player_data,
            {amount_string = ingredient.amount_string, always_show = true}
          )
          local label = data.caption
          if data.is_researched then
            tech_str_arr[#tech_str_arr+1] = "\n  "..label
          else
            tech_str_arr[#tech_str_arr+1] = "\n  "..base_functions.build_rich_text("color", "unresearched", label)
          end
        end
      end
    end

    local tech_str = base_functions.concat(tech_str_arr)
    -- interaction help
    local interaction_help_str = ""
    if not is_label then
      interaction_help_str = "\n"..gui_translations.click_to_view
      interaction_help_str = interaction_help_str.."\n"..player_data.translations.gui.shift_click_to_view_technology
    end

    return base_str..tech_str..interaction_help_str
end

return technology
