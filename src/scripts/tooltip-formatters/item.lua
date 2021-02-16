local item = {}

local base_functions

item.init = function(functions)
    base_functions = functions
end

item.tooltip_formatter = function(obj_data, player_data, is_hidden, is_researched, is_label)
    -- locals
    local gui_translations = player_data.translations.gui

    -- object properties
    local stack_size = obj_data.stack_size

    -- build string
    local base_str = base_functions.get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
    -- stack size
    local stack_size_str = ""
    if stack_size then
      stack_size_str = "\n"..base_functions.build_rich_text("font", "default-semibold", gui_translations.stack_size).." "..stack_size
    end
    -- fuel category
    local fuel_category_str = ""
    if obj_data.fuel_category then
      fuel_category_str = (
        "\n"
        ..base_functions.build_rich_text("font", "default-semibold", gui_translations.fuel_category)
        .." "
        ..obj_data.fuel_category
      )
    end
    -- fuel value
    local fuel_value_str = ""
    if obj_data.fuel_value then
      fuel_value_str = (
        "\n"
        ..base_functions.build_rich_text("font", "default-semibold", gui_translations.fuel_value)
        .." "
        ..base_functions.fixed_format(obj_data.fuel_value, 3, "2")
        .."J"
      )
    end
    -- interaction help
    local interaction_help_str = ""
    if not is_label then
      interaction_help_str = "\n"..gui_translations.click_to_view
    end

    return base_str..stack_size_str..fuel_category_str..fuel_value_str..interaction_help_str
  end

return item