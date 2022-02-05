local gui = require("__flib__.gui")

--- @class DockGuiRefs
--- @field window LuaGuiElement

--- @class DockGui
local Gui = {}

function Gui:destroy()
  self.refs.window.destroy()
end

local index = {}

--- @param player LuaPlayer
--- @param player_table PlayerTable
function index.build(player, player_table)
  local refs = gui.build(player.gui.left, {
    {
      type = "frame",
      style = "quick_bar_window_frame",
      direction = "vertical",
      ref = { "window" },
      {
        type = "frame",
        style = "inside_deep_frame",
        {
          type = "button",
          style_mods = { height = 40, minimal_width = 50, horizontally_stretchable = true },
          caption = "RB",
        },
      },
      {
        type = "frame",
        style = "inside_deep_frame",
        style_mods = { top_margin = 4 },
        {
          type = "table",
          style = "slot_table",
          column_count = 2,
          {
            type = "sprite-button",
            style = "flib_slot_button_default",
            style_mods = { size = 32 },
            sprite = "item/iron-plate",
          },
          {
            type = "sprite-button",
            style = "flib_slot_button_default",
            style_mods = { size = 32 },
            sprite = "item/copper-plate",
          },
          {
            type = "sprite-button",
            style = "flib_slot_button_default",
            style_mods = { size = 32 },
            sprite = "item/steel-plate",
          },
          { type = "sprite", sprite = "rb_favorite_slot" },
          { type = "sprite", sprite = "rb_favorite_slot" },
          { type = "sprite", sprite = "rb_favorite_slot" },
        },
      },
      {
        type = "frame",
        style = "inside_deep_frame",
        style_mods = { top_margin = 4 },
        {
          type = "table",
          style = "slot_table",
          column_count = 2,
          {
            type = "sprite-button",
            style = "flib_slot_button_default",
            style_mods = { size = 32 },
            sprite = "item/iron-plate",
          },
          {
            type = "sprite-button",
            style = "flib_slot_button_default",
            style_mods = { size = 32 },
            sprite = "item/copper-plate",
          },
          {
            type = "sprite-button",
            style = "flib_slot_button_default",
            style_mods = { size = 32 },
            sprite = "item/steel-plate",
          },
          { type = "sprite", sprite = "rb_favorite_slot" },
          { type = "sprite", sprite = "rb_favorite_slot" },
          { type = "sprite", sprite = "rb_favorite_slot" },
          { type = "sprite", sprite = "rb_favorite_slot" },
          { type = "sprite", sprite = "rb_favorite_slot" },
          { type = "sprite", sprite = "rb_favorite_slot" },
          { type = "sprite", sprite = "rb_favorite_slot" },
        },
      },
    },
  })

  --- @type DockGui
  local self = {
    player = player,
    player_table = player_table,
    refs = refs,
  }
  index.load(self)
  player_table.guis.dock = self
end

function index.load(self)
  setmetatable(self, { __index = Gui })
end

return index
