local event = require("__flib__.event")
local dictionary = require("__flib__.dictionary")

local database = require("__RecipeBook__.database")
local gui = require("__RecipeBook__.gui")
local migration = require("__RecipeBook__.migration")

gui.handle_events()

event.on_init(function()
  migration.init()
end)

event.on_load(function()
  dictionary.load()
end)

event.on_configuration_changed(migration.on_configuration_changed)

event.on_player_created(function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  migration.init_player(player)
end)

event.on_player_joined_game(function(e)
  local player_table = global.players[e.player_index]
  if player_table and not player_table.search_strings then
    local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
    dictionary.translate(player)
  end
end)

event.on_player_left_game(function(e)
  dictionary.cancel_translation(e.player_index)
end)

event.register("rb-linked-focus-search", function(e)
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

event.register("rb-open-selected", function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  local selected_prototype = e.selected_prototype
  if not selected_prototype then
    return
  end
  local path = selected_prototype.base_type .. "/" .. selected_prototype.name
  if global.database[path] then
    local pgui = gui.get(player)
    if pgui and pgui:update_page(path) then
      return
    end
  end
  player.create_local_flying_text({
    text = { "message.rb-no-info" },
    create_at_cursor = true,
  })
  player.play_sound({ path = "utility/cannot_build" })
end)

event.register("rb-toggle", function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  local pgui = gui.get(player)
  if pgui then
    pgui:toggle()
  end
end)

event.on_research_finished(function(e)
  local profiler = game.create_profiler()
  local technology = e.research
  database.on_technology_researched(technology, technology.force.index)
  profiler.stop()
  log({ "", "Unlock Tech ", profiler })
  -- Update on the next tick in case multiple researches are done at once
  global.update_force_guis[technology.force.index] = true
end)

event.on_tick(function()
  dictionary.check_skipped()
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

event.on_lua_shortcut(function(e)
  if e.prototype_name == "RecipeBook" then
    local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
    local pgui = gui.get(player)
    if pgui then
      pgui:toggle()
    end
  end
end)

event.on_runtime_mod_setting_changed(function(e)
  if e.setting == "rb-show-overhead-button" then
    local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
    gui.refresh_overhead_button(player)
  end
end)

event.on_string_translated(function(e)
  local result = dictionary.process_translation(e)
  if result then
    for _, player_index in pairs(result.players) do
      local player_table = global.players[player_index]
      if player_table then
        player_table.search_strings = result.dictionaries.search
        if player_table.gui and player_table.gui.elems.rb_main_window.valid then
          player_table.gui:update_translation_warning()
        end
      end
    end
  end
end)
