local gui = require("__flib__.gui-beta")

local constants = require("constants")
local formatter = require("scripts.formatter")
local util = require("scripts.util")

local info_list_box = {}

function info_list_box.build(caption, rows, save_location, tooltip)
  return (
    {type = "flow", direction = "vertical", ref = util.append(save_location, "flow"), children = {
      {
        type = "label",
        style = "rb_info_list_box_label",
        caption = caption,
        tooltip = tooltip,
        ref = util.append(save_location, "label")
      },
      {type = "frame", style = "deep_frame_in_shallow_frame", ref = util.append(save_location, "frame"),  children = {
        {
          type = "scroll-pane",
          style = "rb_list_box_scroll_pane",
          style_mods = {height = (rows * 28)},
          ref = util.append(save_location, "scroll_pane")
        }
      }}
    }}
  )
end

function info_list_box.update(tbl, list_box, player_data, options)
  tbl = tbl or {}
  options = options or {}

  local recipe_book = global.recipe_book

  -- scroll pane
  local scroll = list_box.scroll_pane
  local add = scroll.add
  local children = scroll.children

  -- loop through input table
  local i = options.starting_index or 0
  for j = 1, #tbl do
    -- get object information
    local obj = tbl[j]
    local obj_data = recipe_book[obj.class][obj.name]
    local data = formatter(
      obj_data,
      player_data,
      {
        amount_string = obj.amount_string,
        always_show = options.always_show,
        blueprint_recipe = options.blueprint_recipe
      }
    )

    if data then
      i = i + 1
      -- update or add item
      local style = data.is_researched and "rb_list_box_item" or "rb_unresearched_list_box_item"
      local item = children[i]
      if item then
        item.style = style
        item.caption = data.caption
        item.tooltip = data.tooltip
        item.enabled = data.is_enabled
        gui.update_tags(item, {obj = {class = obj.class, name = obj.name}})
      else
        add{
          type = "button",
          style = style,
          caption = data.caption,
          tooltip = data.tooltip,
          enabled = data.is_enabled,
          mouse_button_filter = {"left"},
          tags = {
            [script.mod_name] = {
              blueprint_recipe = options.blueprint_recipe,
              flib = {
                on_click = {gui = "main", action = "handle_list_box_item_click"}
              },
              obj = {class = obj.class, name = obj.name}
            }
          }
        }
      end
    end
  end
  -- destroy extraneous items
  for j = i + 1, #children do
    children[j].destroy()
  end

  -- set listbox properties
  if i == 0 then
    list_box.flow.visible = false
  else
    list_box.flow.visible = true
    scroll.style.height = math.min((28 * i), 28 * (options.max_listbox_height or constants.max_listbox_height))

    local caption = list_box.label.caption
    caption[2] = i - (options.starting_index or 0)
    list_box.label.caption = caption
  end
end


-- only used on the home screen
function info_list_box.update_home(tbl_name, gui_data, player_data, home_data)
  local recipe_book = global.recipe_book
  local tbl = home_data[tbl_name]

  -- list box
  local list_box = gui_data.refs.home[tbl_name]
  local scroll = list_box.scroll_pane
  local add = scroll.add
  local children = scroll.children

  -- loop through input table
  local i = 0
  for j = 1, #tbl do
    -- get object information
    local entry = tbl[j]
    if entry.class ~= "home" then
      local obj_data = recipe_book[entry.class][entry.name]
      local data = formatter(obj_data, player_data)

      if data then
        i = i + 1
        -- add or update item
        local style = data.is_researched and "rb_list_box_item" or "rb_unresearched_list_box_item"
        local item = children[i]
        if item then
          item.style = style
          item.caption = data.caption
          item.tooltip = data.tooltip
          gui.update_tags(item, {class = entry.class, name = entry.name})
        else
          add{
            type = "button",
            style = style,
            caption = data.caption,
            tooltip = data.tooltip,
            mouse_button_filter = {"left"},
            tags = {
              [script.mod_name] = {
                flib = {
                  on_click = {gui = "main", action = "handle_list_box_item_click"}
                },
                obj = {class = entry.class, name = entry.name}
              }
            }
          }
        end
      end
    end
  end

  -- destroy extraneous items
  for j = i + 1, #children do
    children[j].destroy()
  end
end

-- TODO: move this to flib
-- get the width and height of an area
local function area_dimensions(area)
  local width = math.abs(area.left_top.x - area.right_bottom.x)
  local height = math.abs(area.left_top.y - area.right_bottom.y)
  return width, height
end

-- if values are returned, the corresponding page is opened
function info_list_box.handle_click(e, player, player_table)
  local obj = gui.get_tags(e.element).obj
  if obj.class == "crafter" then
    local crafter_data = global.recipe_book.crafter[obj.name]
    if crafter_data then
      if e.control then
        if crafter_data.fixed_recipe then
          return "recipe", crafter_data.fixed_recipe
        end
      elseif e.shift then
        local blueprint_recipe = gui.get_tags(e.element).blueprint_recipe
        if blueprint_recipe then
          if crafter_data.blueprintable then
            local cursor_stack = player.cursor_stack
            player.clear_cursor()
            if cursor_stack and cursor_stack.valid then
              -- entities with an even number of tiles to a side need to be set at -0.5 instead of 0
              local width, height = area_dimensions(game.entity_prototypes[obj.name].collision_box)
              cursor_stack.set_stack{name = "blueprint", count = 1}
              cursor_stack.set_blueprint_entities{
                {
                  entity_number = 1,
                  name = obj.name,
                  position = {
                    math.ceil(width) % 2 == 0 and -0.5 or 0,
                    math.ceil(height) % 2 == 0 and -0.5 or 0
                  },
                  recipe = blueprint_recipe
                }
              }
              player.add_to_clipboard(cursor_stack)
              player.activate_paste()
            end
          else
            player.create_local_flying_text{
              text = {"rb-message.cannot-create-blueprint"},
              create_at_cursor = true
            }
            player.play_sound{path = "utility/cannot_build"}
          end
        end
      else
        return obj.class, obj.name
      end
    end
  elseif obj.class == "resource" then
    local resource_data = global.recipe_book.resource[obj.name]
    if resource_data then
      local required_fluid = resource_data.required_fluid
      if required_fluid then
        return "fluid", required_fluid.name
      end
    end
  elseif obj.class == "technology" then
    player_table.flags.technology_gui_open = true
    player.open_technology_gui(obj.name)
  else
    return obj.class, obj.name
  end
end

return info_list_box
