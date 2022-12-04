local dictionary = require("__flib__/dictionary-lite")

local database = require("__RecipeBook__/database")
local gui = require("__RecipeBook__/gui")
local migrations = require("__RecipeBook__/migrations")

dictionary.handle_events()
gui.handle_events()

script.on_init(migrations.on_init)
script.on_configuration_changed(migrations.on_configuration_changed)

script.on_event(defines.events.on_player_created, function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  migrations.init_player(player)
end)

script.on_event("rb-linked-focus-search", function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  local pgui = gui.get(player)
  if pgui and not pgui.state.pinned and pgui.elems.rb_main_window.visible then
    if pgui.state.search_open then
      pgui:focus_search()
    else
      pgui:toggle_search()
    end
  end
end)

script.on_event("rb-open-selected", function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  local selected_prototype = e.selected_prototype
  if not selected_prototype then
    return
  end
  local pgui = gui.get(player)
  if pgui then
    pgui:update_page(selected_prototype.base_type .. "/" .. selected_prototype.name)
  end
end)

script.on_event("rb-toggle", function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  local pgui = gui.get(player)
  if pgui then
    pgui:toggle()
  end
end)

script.on_event(defines.events.on_research_finished, function(e)
  local profiler = game.create_profiler()
  local technology = e.research
  database.on_technology_researched(technology, technology.force.index)
  profiler.stop()
  log({ "", "Unlock Tech ", profiler })
  -- Update on the next tick in case multiple researches are done at once
  global.update_force_guis[technology.force.index] = true
end)

script.on_event(defines.events.on_tick, function()
  dictionary.on_tick()
  if next(global.update_force_guis) then
    for force_index in pairs(global.update_force_guis) do
      local force = game.forces[force_index]
      if force then
        for _, player in pairs(force.players) do
          local pgui = gui.get(player)
          if pgui then
            pgui:update_filter_panel()
          end
        end
      end
    end
    global.update_force_guis = {}
  end
end)

script.on_event(defines.events.on_lua_shortcut, function(e)
  if e.prototype_name == "RecipeBook" then
    local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
    local pgui = gui.get(player)
    if pgui then
      pgui:toggle()
    end
  end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(e)
  if e.setting == "rb-show-overhead-button" then
    local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
    gui.refresh_overhead_button(player)
  end
end)

script.on_event(dictionary.on_player_dictionaries_ready, function(e)
  local player_table = global.players[e.player_index]
  if player_table then
    if player_table.gui and player_table.gui.elems.rb_main_window.valid then
      player_table.gui:update_translation_warning()
    end
  end
end)
