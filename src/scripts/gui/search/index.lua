local gui = require("__flib__.gui")
local table = require("__flib__.table")

local constants = require("constants")

local formatter = require("scripts.formatter")
local gui_util = require("scripts.gui.util")
local shared = require("scripts.shared")
local util = require("scripts.util")

local actions = require("actions")

-- GUI OBJECT

--- @class SearchGuiRefs
--- @field window LuaGuiElement
--- @field titlebar SearchGuiTitlebarRefs
--- @field tab_frame LuaGuiElement
--- @field tabbed_pane LuaGuiElement
--- @field search_textfield LuaGuiElement
--- @field search_results_pane LuaGuiElement
--- @field favorites_pane LuaGuiElement
--- @field delete_favorites_button LuaGuiElement
--- @field history_pane LuaGuiElement
--- @field delete_history_button LuaGuiElement

--- @class SearchGuiTitlebarRefs
--- @field flow LuaGuiElement
--- @field pin_button LuaGuiElement
--- @field settings_button LuaGuiElement
--- @field close_button LuaGuiElement

--- @class SearchGui
local Gui = {}

Gui.actions = actions

function Gui:destroy()
  self.refs.window.destroy()
  self.player_table.guis.search = nil
  self.player.set_shortcut_available("rb-search", false)
end

function Gui:open()
  local refs = self.refs
  refs.window.visible = true
  refs.window.bring_to_front()
  refs.tabbed_pane.selected_tab_index = 1
  refs.search_textfield.select_all()
  refs.search_textfield.focus()

  if not self.state.pinned then
    self.player.opened = refs.window
  end
  -- Workaround to prevent the search GUI from centering itself if the player doesn't manually recenter
  if self.player_table.settings.general.interface.search_gui_location ~= "center" then
    refs.window.auto_center = false
  end

  self.player.set_shortcut_toggled("rb-search", true)
end

function Gui:close()
  local window = self.player_table.guis.search.refs.window
  window.visible = false
  self.player.set_shortcut_toggled("rb-search", false)

  if self.player.opened == window then
    self.player.opened = nil
  end
end

function Gui:toggle()
  if self.refs.window.visible then
    self:close()
  else
    self:open()
  end
end

function Gui:dispatch(msg, e)
  local handler = self.actions[msg.action]
  if handler then
    handler(self, msg, e)
  end
end

function Gui:update_favorites()
  local refs = self.refs
  gui_util.update_list_box(
    refs.favorites_pane,
    self.player_table.favorites,
    formatter.build_player_data(self.player, self.player_table),
    pairs,
    { always_show = true }
  )
  refs.delete_favorites_button.enabled = table_size(self.player_table.favorites) > 0 and true or false
  -- REFACTOR:
  shared.update_all_favorite_buttons(self.player, self.player_table)
end

function Gui:update_history()
  local refs = self.refs
  gui_util.update_list_box(
    refs.history_pane,
    self.player_table.global_history,
    formatter.build_player_data(self.player, self.player_table),
    ipairs,
    { always_show = true }
  )
  refs.delete_history_button.enabled = table_size(self.player_table.global_history) > 0 and true or false
end

function Gui:update_width()
  local width = (constants.gui_sizes[self.player_table.language] or constants.gui_sizes.en).search_width

  self.refs.tab_frame.style.width = width
end

function Gui:bring_to_front()
  self.refs.window.bring_to_front()
end

-- CONSTRUCTOR

local index = {}

--- @param player LuaPlayer
--- @param player_table PlayerTable
function index.build(player, player_table)
  local width = (constants.gui_sizes[player_table.language] or constants.gui_sizes.en).search_width
  --- @type SearchGuiRefs
  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      name = "rb_search_window",
      style = "invisible_frame",
      style_mods = { height = 596 },
      visible = false,
      ref = { "window" },
      actions = {
        on_closed = { gui = "search", action = "close" },
      },
      -- Search frame
      {
        type = "frame",
        direction = "vertical",
        {
          type = "flow",
          style = "flib_titlebar_flow",
          ref = { "titlebar", "flow" },
          actions = {
            on_click = { gui = "search", action = "reset_location" },
          },
          {
            type = "label",
            style = "frame_title",
            caption = { "gui.rb-search-title" },
            ignored_by_interaction = true,
          },
          { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
          util.frame_action_button(
            "rb_pin",
            { "gui.rb-pin-instruction" },
            { "titlebar", "pin_button" },
            { gui = "search", action = "toggle_pinned" }
          ),
          util.frame_action_button(
            "rb_settings",
            { "gui.rb-settings-instruction" },
            { "titlebar", "settings_button" },
            { gui = "search", action = "toggle_settings" }
          ),
          util.frame_action_button(
            "utility/close",
            { "gui.close" },
            { "titlebar", "close_button" },
            { gui = "search", action = "close" }
          ),
        },
        {
          type = "frame",
          style = "inside_deep_frame_for_tabs",
          style_mods = { width = width },
          direction = "vertical",
          ref = { "tab_frame" },
          {
            type = "tabbed-pane",
            style = "tabbed_pane_with_no_side_padding",
            style_mods = { height = 532 },
            ref = { "tabbed_pane" },
            {
              tab = { type = "tab", caption = { "gui.search" } },
              content = {
                type = "frame",
                style = "rb_inside_deep_frame_under_tabs",
                direction = "vertical",
                {
                  type = "frame",
                  style = "rb_subheader_frame",
                  direction = "vertical",
                  {
                    type = "textfield",
                    style = "flib_widthless_textfield",
                    style_mods = { horizontally_stretchable = true },
                    clear_and_focus_on_right_click = true,
                    ref = { "search_textfield" },
                    actions = {
                      on_text_changed = { gui = "search", action = "update_search_query" },
                    },
                  },
                },
                { type = "scroll-pane", style = "rb_search_results_scroll_pane", ref = { "search_results_pane" } },
              },
            },
            {
              tab = { type = "tab", caption = { "gui.rb-favorites" } },
              content = {
                type = "frame",
                style = "rb_inside_deep_frame_under_tabs",
                direction = "vertical",
                {
                  type = "frame",
                  style = "subheader_frame",
                  { type = "empty-widget", style = "flib_horizontal_pusher" },
                  {
                    type = "sprite-button",
                    style = "tool_button_red",
                    sprite = "utility/trash",
                    tooltip = { "gui.rb-delete-favorites" },
                    ref = { "delete_favorites_button" },
                    actions = {
                      on_click = { gui = "search", action = "delete_favorites" },
                    },
                  },
                },
                { type = "scroll-pane", style = "rb_search_results_scroll_pane", ref = { "favorites_pane" } },
              },
            },
            {
              tab = { type = "tab", caption = { "gui.rb-history" } },
              content = {
                type = "frame",
                style = "rb_inside_deep_frame_under_tabs",
                direction = "vertical",
                {
                  type = "frame",
                  style = "subheader_frame",
                  { type = "empty-widget", style = "flib_horizontal_pusher" },
                  {
                    type = "sprite-button",
                    style = "tool_button_red",
                    sprite = "utility/trash",
                    tooltip = { "gui.rb-delete-history" },
                    ref = { "delete_history_button" },
                    actions = {
                      on_click = { gui = "search", action = "delete_history" },
                    },
                  },
                },
                { type = "scroll-pane", style = "rb_search_results_scroll_pane", ref = { "history_pane" } },
              },
            },
          },
        },
      },
    },
  })

  refs.titlebar.flow.drag_target = refs.window

  if player_table.settings.general.interface.search_gui_location == "top_left" then
    refs.window.location = table.map(constants.search_gui_top_left_location, function(pos)
      return pos * player.display_scale
    end)
  else
    refs.window.force_auto_center()
  end

  --- @type SearchGui
  local self = {
    player = player,
    player_table = player_table,
    refs = refs,
    state = {
      ignore_closed = false,
      search_query = "",
      pinned = false,
    },
  }

  index.load(self)

  player_table.guis.search = self

  self:update_favorites()
  self:update_history()
end

function index.load(gui)
  setmetatable(gui, { __index = Gui })
end

return index
