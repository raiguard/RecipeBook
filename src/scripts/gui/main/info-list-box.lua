local area = require("__flib__.area")
local gui = require("__flib__.gui-beta")

local constants = require("constants")
local formatter = require("scripts.formatter")
local util = require("scripts.util")

local info_list_box = {}

function info_list_box.build(caption, rows, save_location, children)
  return (
    {type = "flow", direction = "vertical", ref = util.append(save_location, "flow"), children = {
      {
        type = "label",
        style = "rb_info_list_box_label",
        caption = caption,
        ref = util.append(save_location, "label")
      },
      {type = "frame", style = "deep_frame_in_shallow_frame", ref = util.append(save_location, "frame"),  children = {
        {
          type = "scroll-pane",
          style = "rb_list_box_scroll_pane",
          style_mods = {height = (rows * 28)},
          ref = util.append(save_location, "scroll_pane"),
          children = children
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

  local open_class = player_data.open_page_data.class
  local open_name = player_data.open_page_data.name

  local highlight_last_selected = player_data.settings.highlight_last_selected and not options.ignore_last_selected

  local iterator = options.use_pairs and pairs or ipairs
  for _, obj in iterator(tbl) do
    if obj.class ~= "home" then -- for the history listbox specifically
      -- get object information
      local obj_data = recipe_book[obj.class][obj.name]
      local data = formatter(
        obj_data,
        player_data,
        {
          always_show = options.always_show,
          amount_string = obj.amount_string,
          blueprint_recipe = options.blueprint_recipe
        }
      )

      if data then
        i = i + 1
        -- update or add item
        local style
        if
          highlight_last_selected
          and obj.class == open_class
          and (
            obj.name == open_name
            or obj_data.prototype_name == open_name
          )
        then
          style = "rb_last_selected_list_box_item"
        else
          style = data.is_researched and "rb_list_box_item" or "rb_unresearched_list_box_item"
        end
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
  end
  -- destroy extraneous items
  for j = i + 1, #children do
    children[j].destroy()
  end

  if not options.keep_listbox_properties then
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

  return i
end

-- if values are returned, the corresponding page is opened
function info_list_box.handle_click(e, player, player_table)
  local element = e.element
  local tags = gui.get_tags(element)
  local obj = tags.obj
  if player_table.settings.highlight_last_selected and tags.is_search_item and not (e.shift and obj.class == "technology") then
    local search_refs = player_table.guis.main.refs.search
    local last_selected = search_refs.last_selected_item
    if last_selected and last_selected.valid then
      local is_researched = gui.get_tags(last_selected).is_researched
      last_selected.style = is_researched and "rb_list_box_item" or "rb_unresearched_list_box_item"
    end
    element.style = "rb_last_selected_list_box_item"
    search_refs.last_selected_item = element
  end
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
              local CollisionBox = area.load(game.entity_prototypes[obj.name].collision_box)
              local height = CollisionBox:height()
              local width = CollisionBox:width()
              cursor_stack.set_stack{name = "blueprint", count = 1}
              cursor_stack.set_blueprint_entities{
                {
                  entity_number = 1,
                  name = obj.name,
                  position = {
                    -- entities with an even number of tiles to a side need to be set at -0.5 instead of 0
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
  elseif obj.class == "fluid" then
    local fluid_data = global.recipe_book.fluid[obj.name]
    if e.shift and fluid_data.temperature_data then
      return "fluid", fluid_data.prototype_name
    else
      return "fluid", obj.name
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
    if e.shift then
      player_table.flags.technology_gui_open = true
      player.open_technology_gui(obj.name)
    else
      return obj.class, obj.name
    end
  else
    return obj.class, obj.name
  end
end

return info_list_box
