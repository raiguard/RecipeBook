local lab = {}

local math = require("__flib__.math")

local base_functions

lab.init = function(functions)
    base_functions = functions
end

lab.tooltip_formatter = function(obj_data, player_data, is_hidden, is_researched, _)
    local base_str = base_functions.get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
    -- researching speed
    local researching_speed_str = (
      "\n"
      ..base_functions.build_rich_text("font", "default-semibold", player_data.translations.gui.researching_speed)
      .." "
      ..math.round_to(obj_data.researching_speed, 2)
    )

    return base_str..researching_speed_str
end

return lab