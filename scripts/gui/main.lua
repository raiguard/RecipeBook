local flib_gui = require("__flib__/gui-lite")
local mod_gui = require("__core__/lualib/mod-gui")

local gui_util = require("__RecipeBook__/scripts/gui/util")
local history = require("__RecipeBook__/scripts/gui/history")
local util = require("__RecipeBook__/scripts/util")

local list_box = require("__RecipeBook__/scripts/gui/list-box")
local info_pane = require("__RecipeBook__/scripts/gui/info-pane")
local search_pane = require("__RecipeBook__/scripts/gui/search-pane")

--- @param name string
--- @param sprite string
--- @param tooltip LocalisedString
--- @param handler fun(e: GuiEventData)
--- @param auto_toggle boolean
--- @return LuaGuiElement.add_param
local function frame_action_button(name, sprite, tooltip, handler, auto_toggle)
  return {
    type = "sprite-button",
    name = name,
    style = "frame_action_button",
    sprite = sprite .. "_white",
    hovered_sprite = sprite .. "_black",
    clicked_sprite = sprite .. "_black",
    tooltip = tooltip,
    mouse_button_filter = { "left" },
    tags = flib_gui.format_handlers({ [defines.events.on_gui_click] = handler }),
    auto_toggle = auto_toggle,
  }
end

--- @class MainGui
--- @field context MainGuiContext
--- @field window LuaGuiElement
--- @field header LuaGuiElement
--- @field search_pane SearchPane
--- @field info_pane InfoPane
--- @field history History
--- @field pinned boolean
local main_gui = {}
local mt = { __index = main_gui }
script.register_metatable("main_gui", mt)

--- @param player LuaPlayer
--- @return MainGui
function main_gui.build(player)
  main_gui.destroy(player.index)

  --- @type MainGuiContext
  local context = {
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
    tags = flib_gui.format_handlers({ [defines.events.on_gui_click] = main_gui.on_titlebar_click }),
  })
  header.add({
    type = "label",
    style = "frame_title",
    caption = { "mod-name.RecipeBook" },
    ignored_by_interaction = true,
  })
  header.add({ type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true })
  header.add(
    frame_action_button(
      "show_unresearched_button",
      "rb_show_unresearched",
      { "gui.rb-show-unresearched-instruction" },
      main_gui.on_show_unresearched_button_click,
      true
    )
  )
  header.add(
    frame_action_button(
      "show_hidden_button",
      "rb_show_hidden",
      { "gui.rb-show-hidden-instruction" },
      main_gui.on_show_hidden_button_click,
      true
    )
  )
  header.add(
    frame_action_button(
      "nav_backward_button",
      "flib_nav_backward",
      { "gui.rb-nav-backward-instruction" },
      main_gui.prev,
      false
    )
  )
  header.add(
    frame_action_button(
      "nav_forward_button",
      "flib_nav_forward",
      { "gui.rb-nav-forward-instruction" },
      main_gui.next,
      false
    )
  )
  header.add(
    frame_action_button("pin_button", "flib_pin", { "gui.rb-pin-instruction" }, main_gui.on_pin_button_click, true)
  )
  header.add(frame_action_button("close_button", "utility/close", { "gui.close-instruction" }, main_gui.hide, false))

  local main_flow = window.add({ type = "flow", style = "inset_frame_container_horizontal_flow" })
  local search_pane = search_pane.build(main_flow, context)
  local info_pane = info_pane.build(main_flow, context)

  -- Set initial button states
  gui_util.update_frame_action_button(header.nav_backward_button, "disabled")
  gui_util.update_frame_action_button(header.nav_forward_button, "disabled")
  gui_util.update_frame_action_button(header.show_unresearched_button, "selected")

  local self = {
    context = context,
    window = window,
    header = header,
    search_pane = search_pane,
    info_pane = info_pane,
    current_page = nil,
    history = history.new(),
    pinned = false,
  }
  setmetatable(self, mt)
  global.guis[player.index] = self

  return self
end

--- @param player_index uint
function main_gui.destroy(player_index)
  local self = global.guis[player_index]
  if not self then
    return
  end
  if self.window.valid then
    self.window.destroy()
  end
  global.guis[player_index] = nil
end

--- @param e EventData.on_gui_checked_state_changed
function main_gui:collapse_list_box(e)
  local state = e.element.state
  e.element.parent.parent.list_frame.style.height = state and 1 or 0
  -- TODO: Keep track of collapsed states
end

--- @param e EventData.on_gui_click
function main_gui:on_prototype_button_click(e)
  local path = e.element.sprite --[[@as string?]]
  if not path then
    return
  end
  local type, name = string.match(path, "(.*)/(.*)")
  if type == "technology" then
    -- TODO: Keep-open logic
    self.context.player.open_technology_gui(name)
    return
  end
  self.history:push(path)
  self:update()
end

--- @param e EventData.on_gui_click
function main_gui:on_pin_button_click(e)
  self.pinned = e.element.toggled
  if self.pinned then
    self.header.pin_button.sprite = "flib_pin_black"
    self.header.close_button.tooltip = { "gui.close" }
    self.search_pane.textfield.tooltip = { "gui.search" }
    if self.context.player.opened == self.window then
      self.context.player.opened = nil
    end
  else
    self.header.pin_button.sprite = "flib_pin_white"
    self.context.player.opened = self.window
    self.window.force_auto_center()
    self.header.close_button.tooltip = { "gui.close-instruction" }
    self.search_pane.textfield.tooltip = { "gui.flib-search-instruction" }
  end
end

--- @param e EventData.on_gui_click
function main_gui:on_show_hidden_button_click(e)
  self.context.show_hidden = e.element.toggled
  gui_util.update_frame_action_button(e.element, self.context.show_hidden and "selected" or "default")
  self.search_pane:update()
  self:update()
end

--- @param e EventData.on_gui_click
function main_gui:on_show_unresearched_button_click(e)
  self.context.show_unresearched = e.element.toggled
  gui_util.update_frame_action_button(e.element, self.context.show_unresearched and "selected" or "default")
  self.search_pane:update()
  self:update()
end

--- @param e EventData.on_gui_click?
function main_gui:on_titlebar_click(e)
  if not e or e.button == defines.mouse_button_type.middle then
    self.window.force_auto_center()
  end
end

function main_gui:on_window_closed()
  if self.pinned then
    return
  end
  main_gui.hide(self)
end

-- Methods

function main_gui:hide()
  self.window.visible = false
  if self.context.player.opened == self.window then
    self.context.player.opened = nil
  end
  self.context.player.set_shortcut_toggled("rb-toggle", false)
end

function main_gui:prev()
  self.history:prev()
  self:update()
end

function main_gui:next()
  self.history:next()
  self:update()
end

function main_gui:show()
  self.window.visible = true
  self.window.bring_to_front()
  if not self.pinned then
    self.context.player.opened = self.window
    self.window.force_auto_center()
  end
  self.context.player.set_shortcut_toggled("rb-toggle", true)
end

function main_gui:toggle()
  if self.window.visible then
    main_gui.hide(self)
  else
    main_gui.show(self)
  end
end

function main_gui:update()
  gui_util.update_frame_action_button(
    self.header.nav_backward_button,
    self.history:at_front() and "disabled" or "default"
  )
  gui_util.update_frame_action_button(
    self.header.nav_forward_button,
    self.history:at_back() and "disabled" or "default"
  )

  self.search_pane:select_result(self.history:current())
  self.info_pane:show(self.history:current())
end

--- @param player LuaPlayer
function main_gui.refresh_overhead_button(player)
  local button_flow = mod_gui.get_button_flow(player)
  if button_flow.rb_toggle then
    button_flow.rb_toggle.destroy()
  end
  if player.mod_settings["rb-show-overhead-button"].value then
    flib_gui.add(button_flow, {
      type = "sprite-button",
      name = "rb_toggle",
      style = mod_gui.button_style,
      tooltip = { "", { "shortcut-name.rb-toggle" }, " (", { "gui.rb-toggle-instruction" }, ")" },
      sprite = "rb_logo",
      handler = { [defines.events.on_gui_click] = main_gui.toggle },
    })
  end
end

--- Get the player's GUI or create it if it does not exist
--- @param player_index uint
--- @return MainGui?
function main_gui.get(player_index)
  local self = global.guis[player_index]
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

--- @param force LuaForce
local function update_force_guis(force)
  for _, player in pairs(force.players) do
    local player_gui = main_gui.get(player.index)
    if player_gui then
      player_gui.search_pane:update()
      player_gui.info_pane:show(player_gui.history[player_gui.history.__index])
    end
  end
end

-- Events

local function on_runtime_mod_setting_changed(e)
  if e.setting ~= "rb-show-overhead-button" then
    return
  end
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  main_gui.refresh_overhead_button(player)
end

local function on_tick()
  for force_index in pairs(global.update_force_guis) do
    local force = game.forces[force_index]
    if force then
      update_force_guis(force)
    end
  end
  global.update_force_guis = {}
end

--- @param e EventData.CustomInputEvent
local function on_open_selected(e)
  local selected_prototype = e.selected_prototype
  if not selected_prototype then
    return
  end
  local player_gui = main_gui.get(e.player_index)
  if not player_gui then
    return
  end
  local updated = player_gui.info_pane:show(selected_prototype.base_type .. "/" .. selected_prototype.name)
  if not updated then
    util.flying_text(player_gui.context.player, { "message.rb-no-info" })
    return
  end
  main_gui.show(player_gui)
end

--- @param e EventData.CustomInputEvent
local function on_toggle(e)
  local self = main_gui.get(e.player_index)
  if self then
    main_gui.toggle(self)
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
  local self = global.guis[e.player_index]
  if self and self.window.valid and not self.pinned then
    self.search_pane:focus_search()
  end
end

function main_gui.on_init()
  --- @type table<uint, MainGui>
  global.guis = {}
  --- @type table<uint, boolean>
  global.update_force_guis = {} --
end

function main_gui.on_configuration_changed()
  for _, player in pairs(game.players) do
    main_gui.build(player)
    main_gui.refresh_overhead_button(player)
  end
end

main_gui.events = {
  [defines.events.on_lua_shortcut] = on_lua_shortcut,
  [defines.events.on_runtime_mod_setting_changed] = on_runtime_mod_setting_changed,
  [defines.events.on_tick] = on_tick,
  ["rb-linked-focus-search"] = on_focus_search,
  ["rb-next"] = on_next,
  ["rb-open-selected"] = on_open_selected,
  ["rb-previous"] = on_previous,
  ["rb-toggle"] = on_toggle,
}

function main_gui.add_remote_interface()
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
      local player_gui = main_gui.get(player_index)
      if player_gui then
        main_gui.history:push(path)
        main_gui:update()
      end
      return true
    end,
    --- The current interface version.
    version = function()
      return 4
    end,
  })
end

flib_gui.add_handlers(main_gui, function(e, handler)
  local pgui = main_gui.get(e.player_index)
  if pgui then
    handler(pgui, e)
  end
end, "main")

-- TODO: This sucks
info_pane.on_result_clicked = main_gui.on_prototype_button_click
list_box.on_result_clicked = main_gui.on_prototype_button_click
search_pane.on_result_clicked = main_gui.on_prototype_button_click

return main_gui
