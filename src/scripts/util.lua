local area = require("__flib__.area")
local gui = require("__flib__.gui-beta")
local math = require("__flib__.math")
local table = require("__flib__.table")

local formatter = require("scripts.formatter")

local util = {}

function util.append(tbl, name)
  local new_tbl = table.shallow_copy(tbl)
  new_tbl[#new_tbl + 1] = name
  return new_tbl
end

function util.build_amount_ident(input)
  return {
    amount = input.amount or false,
    amount_min = input.amount_min or false,
    amount_max = input.amount_max or false,
    probability = input.probability or false,
    format = input.format or "format_amount"
  }
end

function util.build_temperature_ident(fluid)
  local temperature = fluid.temperature
  local temperature_min = fluid.minimum_temperature
  local temperature_max = fluid.maximum_temperature
  local temperature_string
  if temperature then
    temperature_string = formatter.number(temperature)
    temperature_min = temperature
    temperature_max = temperature
  elseif temperature_min and temperature_max then
    if temperature_min == math.min_double then
      temperature_string = "≤"..formatter.number(temperature_max)
    elseif temperature_max == math.max_double then
      temperature_string = "≥"..formatter.number(temperature_min)
    else
      temperature_string = ""..formatter.number(temperature_min).."-"..formatter.number(temperature_max)
    end
  end

  if temperature_string then
    return {string = temperature_string, min = temperature_min, max = temperature_max}
  end
end

function util.convert_and_sort(tbl)
  for key in pairs(tbl) do
    tbl[#tbl + 1] = key
  end
  table.sort(tbl)
  return tbl
end

function util.add_string(strings, tbl)
  strings.__index = strings.__index + 1
  strings[strings.__index] = tbl
end

function util.unique_string_array(initial_tbl)
  initial_tbl = initial_tbl or {}
  local hash = {}
  for _, value in pairs(initial_tbl) do
    hash[value] = true
  end
  return setmetatable(initial_tbl, {
    __newindex = function(tbl, key, value)
      if not hash[value] then
        hash[value] = true
        rawset(tbl, key, value)
      end
    end
  })
end

function util.unique_obj_array(initial_tbl)
  local hash = {}
  return setmetatable(initial_tbl or {}, {
    __newindex = function(tbl, key, value)
      if not hash[value.name] then
        hash[value.name] = true
        rawset(tbl, key, value)
      end
    end
  })
end

function util.frame_action_button(sprite, tooltip, ref, action)
  return {
    type = "sprite-button",
    style = "frame_action_button",
    sprite = sprite.."_white",
    hovered_sprite = sprite.."_black",
    clicked_sprite = sprite.."_black",
    tooltip = tooltip,
    mouse_button_filter = {"left"},
    ref = ref,
    actions = {
      on_click = action
    }
  }
end

function util.process_placeable_by(prototype)
  local placeable_by = prototype.items_to_place_this
  if placeable_by then
    return table.map(placeable_by, function(item_stack)
      return {
        class = "item",
        name = item_stack.name,
        amount_ident = util.build_amount_ident{amount = item_stack.count}
      }
    end)
  end
end

function util.navigate_to(e)
  local player = game.get_player(e.player_index)

  local element = e.element
  local tags = gui.get_tags(element)
  local context = tags.context

  if context.class == "crafter" then
    local crafter_data = global.recipe_book.crafter[context.name]
    if crafter_data then
      if e.control then
        return crafter_data.fixed_recipe
      elseif e.shift then
        local blueprint_recipe = tags.blueprint_recipe
        if blueprint_recipe then
          if crafter_data.blueprintable then
            local cursor_stack = player.cursor_stack
            player.clear_cursor()
            if cursor_stack and cursor_stack.valid then
              local CollisionBox = area.load(game.entity_prototypes[context.name].collision_box)
              local height = CollisionBox:height()
              local width = CollisionBox:width()
              cursor_stack.set_stack{name = "blueprint", count = 1}
              cursor_stack.set_blueprint_entities{
                {
                  entity_number = 1,
                  name = context.name,
                  position = {
                    -- Entities with an even number of tiles to a side need to be set at -0.5 instead of 0
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
        return {class = context.class, name = context.name}
      end
    end
  elseif context.class == "fluid" then
    local fluid_data = global.recipe_book.fluid[context.name]
    if e.shift and fluid_data.temperature_data then
      return {class = "fluid", name = fluid_data.prototype_name}
    else
      return {class = "fluid", name = context.name}
    end
  elseif context.class == "resource" then
    local resource_data = global.recipe_book.resource[context.name]
    if resource_data then
      local required_fluid = resource_data.required_fluid
      if required_fluid then
        return {class = "fluid", name = required_fluid.name}
      end
    end
  elseif context.class == "technology" then
    if e.shift then
      player.open_technology_gui(context.name)
    else
      return {class = context.class, name = context.name}
    end
  else
    return {class = context.class, name = context.name}
  end
end

return util

