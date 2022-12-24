local dictionary = require("__flib__/dictionary-lite")

local database = require("__RecipeBook__/database")
local gui = require("__RecipeBook__/gui")
local migrations = require("__RecipeBook__/migrations")

-- Interface

remote.add_interface("RecipeBook", {
  --- Open the given page in Recipe Book.
  --- @param player_index uint
  --- @param class string
  --- @param name string
  --- @return boolean success
  open_page = function(player_index, class, name)
    local path = class .. "/" .. name
    local entry = global.database[path]
    if not entry or not entry.base then
      return false
    end
    local player_gui = gui.get(player_index)
    if player_gui then
      gui.update_page(player_gui, path)
      gui.show(player_gui)
    end
    return true
  end,
})

-- Lifecycle

script.on_init(migrations.on_init)
script.on_configuration_changed(migrations.on_configuration_changed)

script.on_event(defines.events.on_player_created, function(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  migrations.migrate_player(player)
end)

-- Dictionary

dictionary.handle_events()

script.on_event(dictionary.on_player_dictionaries_ready, function(e)
  local player_gui = gui.get(e.player_index)
  if player_gui then
    gui.update_translation_warning(player_gui)
  end
end)

-- Gui

gui.handle_events()

script.on_event("rb-linked-focus-search", function(e)
  local player_gui = gui.get(e.player_index)
  if player_gui and not player_gui.state.pinned and player_gui.elems.rb_main_window.visible then
    if player_gui.state.search_open then
      gui.focus_search(player_gui)
    else
      gui.toggle_search(player_gui)
    end
  end
end)

script.on_event("rb-open-selected", function(e)
  local selected_prototype = e.selected_prototype
  if not selected_prototype then
    return
  end
  local player_gui = gui.get(e.player_index)
  if player_gui then
    gui.update_page(player_gui, selected_prototype.base_type .. "/" .. selected_prototype.name)
    gui.show(player_gui)
  end
end)

script.on_event("rb-toggle", function(e)
  local player_gui = gui.get(e.player_index)
  if player_gui then
    gui.toggle(player_gui)
  end
end)

script.on_event(defines.events.on_lua_shortcut, function(e)
  if e.prototype_name ~= "RecipeBook" then
    return
  end
  local player_gui = gui.get(e.player_index)
  if player_gui then
    gui.toggle(player_gui)
  end
end)

-- Triggers

script.on_event(defines.events.on_research_finished, function(e)
  local profiler = game.create_profiler()
  local technology = e.research
  database.on_technology_researched(technology, technology.force.index)
  profiler.stop()
  log({ "", "Unlock Tech ", profiler })
  if global.update_force_guis then
    -- Update on the next tick in case multiple researches are done at once
    global.update_force_guis[technology.force.index] = true
  end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(e)
  if e.setting == "rb-show-overhead-button" then
    local player = game.get_player(e.player_index)
    if not player then
      return
    end
    gui.refresh_overhead_button(player)
  end
end)

script.on_event(defines.events.on_tick, function()
  dictionary.on_tick()

  for force_index in pairs(global.update_force_guis) do
    local force = game.forces[force_index]
    if force then
      gui.update_force(force)
    end
  end
  global.update_force_guis = {}
end)
