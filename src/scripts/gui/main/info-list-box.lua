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

function info_list_box.update(tbl, int_class, list_box, player_data, options, direction_hint)
  options = options or {}

  local recipe_book = global.recipe_book[int_class]

  -- scroll pane
  local scroll = list_box.scroll_pane
  local add = scroll.add
  local children = scroll.children

  -- loop through input table
  local i = options.starting_index or 0
  for j = 1, #tbl do
    -- get object information
    local obj = tbl[j]
    local obj_data
    if int_class == "material" then
      obj_data = recipe_book[obj.type.."."..obj.name]
    -- if `blueprint_recipe` exists, this is on a recipe and is therefore a table
    elseif int_class == "crafter" and options.blueprint_recipe then
      obj_data = recipe_book[obj.name]
    elseif obj.name then
      obj_data = recipe_book[obj.name]
    else
      obj_data = recipe_book[obj]
    end

    local skip = false

    if options.fluid_temperature_key and obj.fluid_temperature_key and direction_aid then
      local min1, max1 = util.parse_fluid_temperature_key(options.fluid_temperature_key)
      local min2, max2 = util.parse_fluid_temperature_key(obj.fluid_temperature_key)
      
      if direction_hint == "in" and (min1 < min2 or max1 > max2) then
        skip = true
      elseif direction_hint == "out" and (min2 < min1 or max2 > max1) then
        skip = true
      end
    end

    if options.fluid_temperature_key and obj.fluid_temperature_keys and not skip then
      skip = true

      local min1, max1 = util.parse_fluid_temperature_key(options.fluid_temperature_key)
      for k = 1, #obj.fluid_temperature_keys do

        local min2, max2 = util.parse_fluid_temperature_key(obj.fluid_temperature_keys[k])

        if min1 >= min2 and max1 <= max2 then
          skip = false
          break
        end
      end

    end
    
    if not skip then
      local should_add, style, caption, tooltip, enabled = formatter(
        obj_data,
        player_data,
        {
          amount_string = obj.amount_string,
          fluid_temperature_string = obj.fluid_temperature_string,
          fluid_temperature_key = obj.fluid_temperature_key,
          always_show = options.always_show,
          blueprint_recipe = options.blueprint_recipe
        }
      )
      local context_data = {
        item_class = obj_data.sprite_class,
        item_name = obj_data.prototype_name,
        fluid_temperature_string = obj.fluid_temperature_string,
        fluid_temperature_key = obj.fluid_temperature_key,
      }

      if should_add then
        i = i + 1
        -- update or add item
        local child = children[i]
        if child then
          child.style = style
          child.caption = caption
          child.tooltip = tooltip
          child.enabled = enabled
          child.tags = {
            [script.mod_name] = {
              flib = {
                on_click = {gui = "main", action = "handle_list_box_item_click"}
              },
              context_data = context_data
            }
          }
        else
          add{
            type = "button",
            style = style,
            caption = caption,
            tooltip = tooltip,
            enabled = enabled,
            mouse_button_filter = {"left"},
            tags = {
              [script.mod_name] = {
                blueprint_recipe = options.blueprint_recipe,
                flib = {
                  on_click = {gui = "main", action = "handle_list_box_item_click"}
                },
                context_data = context_data
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
    if entry.int_class ~= "home" then
      local obj_data = recipe_book[entry.int_class][entry.int_name]

      local options = { fluid_temperature_key = entry.fluid_temperature_key, fluid_temperature_string = entry.fluid_temperature_string }

      local should_add, style, caption, tooltip = formatter(obj_data, player_data, options)
      local context_data = {
        item_class = obj_data.sprite_class,
        item_name = obj_data.prototype_name,
        fluid_temperature_string = entry.fluid_temperature_string,
        fluid_temperature_key = entry.fluid_temperature_key,
        fluid_temperature_force = true
      }

      if should_add then
        i = i + 1
        -- add or update item
        local child = children[i]
        if child then
          child.style = style
          child.caption = caption
          child.tooltip = tooltip
          child.tags = {
            [script.mod_name] = {
              flib = {
                on_click = {gui = "main", action = "handle_list_box_item_click"}
              },
              context_data = context_data
            }
          }
        else
          add{
            type = "button",
            style = style,
            caption = caption,
            tooltip = tooltip,
            tags = {
              [script.mod_name] = {
                flib = {
                  on_click = {gui = "main", action = "handle_list_box_item_click"}
                },
                context_data = context_data
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
  local listbox_item_data = e.element.tags[script.mod_name].context_data
  local class = listbox_item_data.item_class
  local name = listbox_item_data.item_name

  if e.shift and not listbox_item_data.fluid_temperature_force then
    listbox_item_data.fluid_temperature_key = nil
    listbox_item_data.fluid_temperature_string = nil
  end

  if class == "technology" then
    player_table.flags.technology_gui_open = true
    player.open_technology_gui(name)
  elseif class == "entity" then
    local crafter_data = global.recipe_book.crafter[name]
    if crafter_data then
      if e.control then
        if crafter_data.fixed_recipe then
          return { item_class = "recipe", item_name = crafter_data.fixed_recipe }
        end
      elseif e.shift then
        local blueprint_recipe = gui.get_tags(e.element).blueprint_recipe
        if blueprint_recipe then
          if crafter_data.blueprintable then
            local cursor_stack = player.cursor_stack
            player.clear_cursor()
            if cursor_stack and cursor_stack.valid then
              -- entities with an even number of tiles to a side need to be set at -0.5 instead of 0
              local width, height = area_dimensions(game.entity_prototypes[name].collision_box)
              cursor_stack.set_stack{name = "blueprint", count = 1}
              cursor_stack.set_blueprint_entities{
                {
                  entity_number = 1,
                  name = name,
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
        return listbox_item_data
      end
    else
      local resource_data = global.recipe_book.resource[name]
      if resource_data then
        local required_fluid = resource_data.required_fluid
        if required_fluid then
          return { item_class = "fluid", item_name = required_fluid.name }
        end
      end
    end
  else
    return listbox_item_data
  end
end

return info_list_box