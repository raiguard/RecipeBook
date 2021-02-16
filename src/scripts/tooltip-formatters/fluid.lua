local fluid = {}

local base_functions

fluid.init = function(functions)
    base_functions = functions
end

fluid.tooltip_formatter = function(obj_data, player_data, is_hidden, is_researched, is_label)
    -- locals
    local gui_translations = player_data.translations.gui

    -- build string
    local base_str = base_functions.get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
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
        if obj_data.temperature_data then
        interaction_help_str = interaction_help_str.."\n"..gui_translations.shift_click_to_view_base_fluid
        end
    end

    return base_str..fuel_value_str..interaction_help_str
end

return fluid