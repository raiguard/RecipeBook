-- documentation: https://github.com/raiguard/Factorio-RecipeBook/wiki/Remote-Interface-Documentation
local interface = {}

local event = require("__flib__.control.event")

local constants = require("scripts.constants")

remote.add_interface("RecipeBook", {
  open_gui = function(player_index, gui_type, object, source_data)
    -- error checking
    if not object then error("Must provide an object!") end
    if source_data and (not source_data.mod_name or not source_data.gui_name) then
      error("Incomplete source_data table!")
    end
    -- raise internal mod event
    event.raise(constants.open_gui_event, {player_index=player_index, gui_type=gui_type, object=object, source_data=source_data})
  end,
  reopen_source_event = function() return constants.reopen_source_event end,
  version = function() return 2 end -- increment when backward-incompatible changes are made
})

return interface