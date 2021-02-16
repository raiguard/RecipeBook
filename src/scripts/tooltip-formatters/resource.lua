local resource = {}

local base_functions

resource.init = function(functions)
    base_functions = functions
end

resource.tooltip_formatter = function(obj_data, player_data, is_hidden, is_researched, _)
    local base_str = base_functions.get_base_tooltip(obj_data, player_data, is_hidden, is_researched)
    local required_fluid_str = ""
    local interaction_help_str = ""
    local required_fluid = obj_data.required_fluid
    if required_fluid then
      local fluid_data = global.recipe_book.fluid[required_fluid.name]
      if fluid_data then
        local data = base_functions.formatter(fluid_data, player_data, {amount_string = required_fluid.amount_string})
        local label = data.caption
        -- remove glyph from caption, since it's implied
        if player_data.settings.show_glyphs then
          label = string.gsub(label, "^.-nt%]  ", "")
        end
        if not data.is_researched then
          label = base_functions.build_rich_text("color", "unresearched", label)
        end
        required_fluid_str = (
          "\n"
          ..base_functions.build_rich_text("font", "default-semibold", player_data.translations.gui.required_fluid)
          .."  "
          ..label
        )
        interaction_help_str = "\n"..player_data.translations.gui.click_to_view_required_fluid
      end
    end
    return base_str..required_fluid_str..interaction_help_str
  end


return resource