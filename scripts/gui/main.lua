local flib_gui = require("__flib__.gui")

local gui_util = require("scripts.gui.util")
local history = require("scripts.gui.history")
local info_pane = require("scripts.gui.info-pane")
local search_pane = require("scripts.gui.search-pane")

--- @param name string
--- @param sprite string
--- @param tooltip LocalisedString
--- @param handler flib.GuiElemHandler
--- @param auto_toggle boolean
--- @return LuaGuiElement.add_param
local function frame_action_button(name, sprite, tooltip, handler, auto_toggle)
  return {
    type = "sprite-button",
    name = name,
    style = "frame_action_button",
    sprite = sprite,
    tooltip = tooltip,
    mouse_button_filter = { "left" },
    tags = flib_gui.format_handlers({ [defines.events.on_gui_click] = handler }),
    auto_toggle = auto_toggle,
  }
end

--- @class MainGuiContext
--- @field grouping_mode GroupingMode
--- @field show_hidden boolean
--- @field show_unresearched boolean
--- @field player LuaPlayer

--- @class MainGui
--- @field context MainGuiContext
--- @field window LuaGuiElement
--- @field header LuaGuiElement
--- @field search_pane SearchPane
--- @field info_pane InfoPane
--- @field history History
--- @field pinned boolean
--- @field opening_technology_gui boolean
local main_gui = {}
local mt = { __index = main_gui }
script.register_metatable("main_gui", mt)

--- @param player LuaPlayer
--- @return MainGui
function main_gui.build(player)
  main_gui.destroy(player.index)

  --- @type MainGuiContext
  local context = {
    grouping_mode = player.mod_settings["rb-grouping-mode"].value --[[@as string]],
    show_hidden = false,
    show_unresearched = true,
    player = player,
  }

  local window = player.gui.screen.add({
    type = "frame",
    name = "rb_main_window",
    direction = "vertical",
    visible = false,
    tags = flib_gui.format_handlers({ [defines.events.on_gui_closed] = main_gui.on_window_closed }),
  })
  window.auto_center = true

  local header = window.add({
    type = "flow",
    style = "flib_titlebar_flow",
    tags = flib_gui.format_handlers({ [defines.events.on_gui_click] = main_gui.on_titlebar_clicked }),
  })
  header.drag_target = window
  header.add({
    type = "label",
    style = "flib_frame_title",
    caption = { "gui.rb-title" },
    ignored_by_interaction = true,
  })
  header.add({ type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true })
  header.add(
    frame_action_button(
      "show_unresearched_button",
      "rb_show_unresearched_white",
      { "gui.rb-show-unresearched-instruction" },
      main_gui.on_show_unresearched_button_clicked,
      true
    )
  )
  header.add(
    frame_action_button(
      "show_hidden_button",
      "rb_show_hidden_white",
      { "gui.rb-show-hidden-instruction" },
      main_gui.on_show_hidden_button_clicked,
      true
    )
  )
  header.add(
    frame_action_button(
      "nav_backward_button",
      "flib_nav_backward_white",
      { "gui.rb-nav-backward-instruction" },
      main_gui.prev,
      false
    )
  )
  header.add(
    frame_action_button(
      "nav_forward_button",
      "flib_nav_forward_white",
      { "gui.rb-nav-forward-instruction" },
      main_gui.next,
      false
    )
  )
  header.add(
    frame_action_button(
      "pin_button",
      "flib_pin_white",
      { "gui.rb-pin-instruction" },
      main_gui.on_pin_button_clicked,
      true
    )
  )
  header.add(frame_action_button("close_button", "utility/close", { "gui.close-instruction" }, main_gui.hide, false))

  gui_util.update_frame_action_button(header.nav_backward_button, "disabled")
  gui_util.update_frame_action_button(header.nav_forward_button, "disabled")
  gui_util.update_frame_action_button(header.show_unresearched_button, "selected")

  local main_flow = window.add({ type = "flow", style = "inset_frame_container_horizontal_flow" })

  --- @type MainGui
  local self = {
    context = context,
    window = window,
    header = header,
    search_pane = search_pane.build(main_flow, context),
    info_pane = info_pane.build(main_flow, context),
    history = history.new(),
    pinned = false,
    opening_technology_gui = false,
  }
  setmetatable(self, mt)
  storage.guis[player.index] = self

  return self
end

--- @param player_index uint
function main_gui.destroy(player_index)
  local self = storage.guis[player_index]
  if not self then
    return
  end
  if self.window.valid then
    self.window.destroy()
  end
  storage.guis[player_index] = nil
end

function main_gui:hide()
  self.window.visible = false
  if self.context.player.opened == self.window then
    self.context.player.opened = nil
  end
end

function main_gui:prev()
  if not self.window.visible then
    return
  end
  self.history:prev()
  self:update_info()
end

function main_gui:next()
  if not self.window.visible then
    return
  end
  self.history:next()
  self:update_info()
end

function main_gui:show()
  self.window.visible = true
  self.window.bring_to_front()
  if not self.pinned then
    self.context.player.opened = self.window
    self.window.force_auto_center()
  end
  if self.context.player.mod_settings["rb-auto-focus-search"].value then
    self.search_pane:focus_search()
  end
end

function main_gui:toggle()
  if self.window.visible then
    main_gui.hide(self)
  else
    main_gui.show(self)
  end
end

function main_gui:update_info()
  gui_util.update_frame_action_button(
    self.header.nav_backward_button,
    self.history:at_front() and "disabled" or "default"
  )
  gui_util.update_frame_action_button(
    self.header.nav_forward_button,
    self.history:at_back() and "disabled" or "default"
  )

  local prototype = self.history:current()
  if not prototype then
    return
  end
  self.search_pane:select_result(prototype)
  self.info_pane:show(prototype)
end

function main_gui:update()
  self.search_pane:update()
  self:update_info()
end

--- Get the player's GUI or create it if it does not exist
--- @param player_index uint
--- @return MainGui?
function main_gui.get(player_index)
  local self = storage.guis[player_index]
  if not self or not self.window.valid then
    local player = game.get_player(player_index)
    if not player then
      return
    end
    if self then
      player.print({ "message.rb-recreated-gui" })
    end
    self = main_gui.build(player)
  end
  return self
end

--- @param e EventData.on_gui_click
function main_gui:on_pin_button_clicked(e)
  self.pinned = e.element.toggled
  if self.pinned then
    self.header.close_button.tooltip = { "gui.close" }
    self.search_pane.textfield.tooltip = { "gui.search" }
    if self.context.player.opened == self.window then
      self.context.player.opened = nil
    end
  else
    self.context.player.opened = self.window
    self.window.force_auto_center()
    self.header.close_button.tooltip = { "gui.close-instruction" }
    self.search_pane.textfield.tooltip = { "gui.flib-search-instruction" }
  end
end

--- @param e EventData.on_gui_click
function main_gui:on_show_hidden_button_clicked(e)
  self.context.show_hidden = e.element.toggled
  gui_util.update_frame_action_button(e.element, self.context.show_hidden and "selected" or "default")
  self:update()
end

--- @param e EventData.on_gui_click
function main_gui:on_show_unresearched_button_clicked(e)
  self.context.show_unresearched = e.element.toggled
  gui_util.update_frame_action_button(e.element, self.context.show_unresearched and "selected" or "default")
  self:update()
end

--- @param e EventData.on_gui_click?
function main_gui:on_titlebar_clicked(e)
  if not e or e.button == defines.mouse_button_type.middle then
    self.window.force_auto_center()
  end
end

--- @param e EventData.on_gui_click
function main_gui:on_result_clicked(e)
  local id = e.element.tags.id --[[@as DatabaseID?]]
  if not id then
    return
  end
  if id.type == "technology" and e.shift then
    if not self.pinned then
      self.opening_technology_gui = true
      self:hide()
    end
    self.context.player.open_technology_gui(id.name)
    return
  end
  local prototype = prototypes[id.type][id.name]
  assert(prototype, "Prototype was nil")
  self.history:push(prototype, self.context.grouping_mode)
  self:update_info()
end

function main_gui:on_window_closed()
  if self.pinned then
    return
  end
  self:hide()
end

-- Events

--- @param force LuaForce
local function update_force_guis(force)
  for _, player in pairs(force.players) do
    local player_gui = main_gui.get(player.index)
    if player_gui then
      player_gui:update()
    end
  end
end

local function on_tick()
  if not next(storage.update_force_guis or {}) then
    return
  end
  for force_index in pairs(storage.update_force_guis) do
    local force = game.forces[force_index]
    if force then
      update_force_guis(force)
    end
  end
  storage.update_force_guis = {}
end

--- @param e EventData.on_runtime_mod_setting_changed
local function on_runtime_mod_setting_changed(e)
  if not storage.guis or e.setting ~= "rb-grouping-mode" then
    return
  end

  if storage.guis[e.player_index] then
    main_gui.destroy(e.player_index)
    local player = game.get_player(e.player_index)
    --- @cast player -?
    main_gui.build(player)
  end
end

--- @param e EventData.on_research_finished|EventData.on_research_reversed
local function on_research_updated(e)
  if storage.update_force_guis then
    storage.update_force_guis[e.research.force.index] = true
  end
end

--- @param e EventData.CustomInputEvent
local function on_open_selected(e)
  local selected_prototype = e.selected_prototype
  if not selected_prototype or selected_prototype.base_type == "technology" then
    return
  end
  local player_gui = main_gui.get(e.player_index)
  if not player_gui then
    return
  end
  if
    selected_prototype.base_type == "entity"
    and (selected_prototype.derived_type == "entity-ghost" or selected_prototype.derived_type == "tile-ghost")
  then
    local selected = player_gui.context.player.selected
    if selected and (selected.type == "entity-ghost" or selected.type == "tile-ghost") then
      selected_prototype.base_type = selected.type == "entity-ghost" and "entity" or "tile"
      selected_prototype.derived_type = selected.ghost_type
      selected_prototype.name = selected.ghost_name
    end
  end
  local prototype = prototypes[selected_prototype.base_type][selected_prototype.name]
  if player_gui.history:push(prototype, player_gui.context.grouping_mode) then
    player_gui:update_info()
  end
  player_gui:show()
end

--- @param e EventData.CustomInputEvent
local function on_toggle(e)
  local self = main_gui.get(e.player_index)
  if self then
    main_gui.toggle(self)
  end
end

--- @param e EventData.on_gui_closed
local function on_gui_closed(e)
  if e.gui_type ~= defines.gui_type.research then
    return
  end
  local self = storage.guis[e.player_index]
  if self and self.window.valid and self.opening_technology_gui then
    self.opening_technology_gui = false
    self:show()
  end
end

--- @param e EventData.on_lua_shortcut
local function on_lua_shortcut(e)
  if e.prototype_name ~= "rb-toggle" then
    return
  end
  local self = main_gui.get(e.player_index)
  if self then
    main_gui.toggle(self)
  end
end

--- @param e EventData.CustomInputEvent
local function on_next(e)
  local self = main_gui.get(e.player_index)
  if self then
    self:next()
  end
end

--- @param e EventData.CustomInputEvent
local function on_previous(e)
  local self = main_gui.get(e.player_index)
  if self then
    self:prev()
  end
end

--- @param e EventData.CustomInputEvent
local function on_focus_search(e)
  local self = storage.guis[e.player_index]
  if self and self.window.valid and not self.pinned and self.window.visible then
    self.search_pane:focus_search()
  end
end

function main_gui.on_init()
  --- @type table<uint, MainGui>
  storage.guis = {}
  --- @type table<uint, boolean>
  storage.update_force_guis = {} --
end

function main_gui.on_configuration_changed()
  if not storage.guis then
    return
  end
  for _, player in pairs(game.players) do
    main_gui.build(player)
  end
end

main_gui.events = {
  [defines.events.on_gui_closed] = on_gui_closed,
  [defines.events.on_lua_shortcut] = on_lua_shortcut,
  [defines.events.on_research_finished] = on_research_updated,
  [defines.events.on_research_reversed] = on_research_updated,
  [defines.events.on_runtime_mod_setting_changed] = on_runtime_mod_setting_changed,
  [defines.events.on_tick] = on_tick,
  ["rb-linked-focus-search"] = on_focus_search,
  ["rb-next"] = on_next,
  ["rb-open-selected"] = on_open_selected,
  ["rb-previous"] = on_previous,
  ["rb-toggle"] = on_toggle,
}

flib_gui.add_handlers(main_gui, function(e, handler)
  local pgui = main_gui.get(e.player_index)
  if pgui then
    handler(pgui, e)
  end
end, "main")

-- TODO: Perhaps pass these as function parameters when building
info_pane.on_result_clicked = main_gui.on_result_clicked
search_pane.on_result_clicked = main_gui.on_result_clicked

-- commands.add_command("rb-test-info", "- Tests showing every possible Recipe Book info page", function(e)
--   local gui = main_gui.get(e.player_index)
--   if not gui then
--     return
--   end
--   log("<< TESTING ALL INFO PAGES >>")
--   local tested = {}
--   local tested_count = 0
--   local profiler = game.create_profiler()
--   for _, entry in pairs(storage.database.entries) do
--     local base_path = entry:get_path()
--     if not tested[base_path] and not string.find(base_path, "technology/") then
--       tested[base_path] = true
--       tested_count = tested_count + 1
--       gui.history:push(entry, gui.context.use_groups)
--       gui:update_info()
--     end
--   end
--   profiler.stop()
--   log({ "", "Overall test ", profiler })
--   log("Number of pages: " .. tested_count)
--   profiler.divide(tested_count)
--   log({ "", "Average test ", profiler })
--   log("<< TEST COMPLETE >>")
-- end)

return main_gui
