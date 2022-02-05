local gui = require("__flib__.gui")
local on_tick_n = require("__flib__.on-tick-n")

local constants = require("constants")
local formatter = require("scripts.formatter")
local recipe_book = require("scripts.recipe-book")

local actions = {}

--- @param Gui VisualSearchGui
--- @param msg table
function actions.change_group(Gui, msg)
  local last_group = Gui.state.active_group

  if not msg.ignore_last_button then
    Gui.refs.group_table[last_group].enabled = true
  end
  Gui.refs.objects_frame[last_group].visible = false

  local new_group = msg.group
  Gui.refs.group_table[new_group].enabled = false
  Gui.refs.objects_frame[new_group].visible = true

  Gui.state.active_group = msg.group
end

--- @param Gui VisualSearchGui
--- @param e on_gui_click
function actions.open_object(Gui, _, e)
  local context = gui.get_tags(e.element).context

  local list_name
  if e.button == defines.mouse_button_type.left then
    list_name = "product_of"
  elseif e.button == defines.mouse_button_type.right then
    list_name = "ingredient_in"
  end

  local list = recipe_book[context.class][context.name][list_name]
  if list and #list > 0 then
    local first_obj = list[1]
    OPEN_PAGE(Gui.player, Gui.player_table, {
      class = first_obj.class,
      name = first_obj.name,
      list = {
        context = context,
        index = 1,
        source = list_name,
      },
    })
  end
end

--- @param Gui SearchGui
--- @param e on_gui_text_changed
function actions.update_search_query(Gui, _, e)
  local player_table = Gui.player_table
  local state = Gui.state

  -- Remove results update action if there is one
  if state.update_results_ident then
    on_tick_n.remove(state.update_results_ident)
    state.update_results_ident = nil
  end
  local query = e.element.text
  if #query > 0 then
    -- Fuzzy search
    if player_table.settings.general.search.fuzzy_search then
      query = string.gsub(query, ".", "%1.*")
    end
    -- Input sanitization
    for pattern, replacement in pairs(constants.input_sanitizers) do
      query = string.gsub(query, pattern, replacement)
    end
    -- Save query
    state.search_query = query
    -- Update in a while
    state.update_results_ident = on_tick_n.add(
      game.tick + constants.search_timeout,
      { gui = "visual_search", action = "update_search_results", player_index = e.player_index }
    )
  else
    state.search_query = ""
    actions.update_search_results(Gui)
  end
end

--- @param Gui VisualSearchGui
function actions.update_search_results(Gui, _, _)
  local player = Gui.player
  local player_table = Gui.player_table
  local state = Gui.state

  -- Data
  local player_data = formatter.build_player_data(player, player_table)
  local show_fluid_temperatures = player_table.settings.general.search.show_fluid_temperatures
  local search_type = player_table.settings.general.search.search_type

  --- @type LuaGuiElement
  local query = state.search_query
  local group_table = Gui.refs.group_table

  for _, group_scroll in pairs(Gui.refs.objects_frame.children) do
    local group_has_results = false
    for _, subgroup_table in pairs(group_scroll.children) do
      local visible_count = 0
      for _, obj_button in pairs(subgroup_table.children) do
        local context = gui.get_tags(obj_button).context
        local translation = player_data.translations[context.class][context.name]
        -- Match against search string
        local matched
        if search_type == "both" then
          matched = string.find(string.lower(context.name), query) or string.find(string.lower(translation), query)
        elseif search_type == "internal" then
          matched = string.find(string.lower(context.name), query)
        elseif search_type == "localised" then
          matched = string.find(string.lower(translation), query)
        end

        -- Match fluid temperature
        if matched and context.class == "fluid" then
          local temperature_ident = recipe_book[context.class][context.name].temperature_ident
          if temperature_ident then
            local is_range = temperature_ident.min ~= temperature_ident.max
            if is_range then
              if show_fluid_temperatures ~= "all" then
                matched = false
              end
            else
              if show_fluid_temperatures == "off" then
                matched = false
              end
            end
          end
        end

        if matched then
          obj_button.visible = true
          visible_count = visible_count + 1
        else
          obj_button.visible = false
        end
      end

      if visible_count > 0 then
        group_has_results = true
        subgroup_table.visible = true
      else
        subgroup_table.visible = false
      end
    end

    local group_name = group_scroll.name
    local group_button = group_table[group_name]
    if group_has_results then
      group_button.style = "rb_filter_group_button_tab"
      group_button.enabled = state.active_group ~= group_scroll.name
    else
      group_button.style = "rb_disabled_filter_group_button_tab"
      group_button.enabled = false
      if state.active_group == group_name then
        local matched = false
        for _, group_button in pairs(group_table.children) do
          if group_button.enabled then
            matched = true
            actions.change_group(Gui, { group = group_button.name, ignore_last_button = true })
            break
          end
        end
        if not matched then
          game.print("NO RESULTS")
        end
      end
    end
  end
end

return actions
