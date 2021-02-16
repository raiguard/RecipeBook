local offshore_pump = {}

local math = require("__flib__.math")

local base_functions

offshore_pump.init = function(functions)
    base_functions = functions
end

offshore_pump.tooltip_formatter = function(obj_data, player_data, is_hidden, is_researched, _)
    -- locals
    local gui_translations = player_data.translations.gui

    -- build string
    local base_str = base_functions.get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
    -- pumping speed
    local pumping_speed_str = (
      "\n"
      ..base_functions.build_rich_text("font", "default-semibold", gui_translations.pumping_speed)
      .." "
      ..math.round_to(obj_data.pumping_speed * 60, 0)
      ..gui_translations.per_second
    )

    return base_str..pumping_speed_str
end

return offshore_pump