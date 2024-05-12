local function on_toggle_entity_selection(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  local gvs = player.game_view_settings
  gvs.update_entity_selection = not gvs.update_entity_selection
  player.game_view_settings = gvs
  player.create_local_flying_text({ text = gvs.update_entity_selection, create_at_cursor = true })
end

local M = {}

M.events = {
  ["rb-debug-toggle-entity-selection"] = on_toggle_entity_selection,
  ["rb-debug-reload-mods"] = function(e)
    game.reload_mods()
    game.get_player(e.player_index).create_local_flying_text({ text = "Reloaded mods", create_at_cursor = true })
  end,
}

return M
