local player_data = {}

function player_data.init(player_index)
  local data = {
    flags = {
      can_open_gui = false,
      gui_open = false,
      translate_on_join = false,
      tried_to_open_gui = false
    },
    gui = {},
    translations = {}
  }
  global.players[player_index] = data
end

function player_data.request_translations(player_index)
  -- TODO
end

function player_data.refresh(player_index)
  -- TODO
end

function player_data.remove(player_index)
  -- TODO
end

return player_data