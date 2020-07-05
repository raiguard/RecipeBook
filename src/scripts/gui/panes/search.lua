local search_pane = {}

local gui = require("__flib__.gui")

local constants = require("constants")

local string = string

gui.add_handlers{
  search = {
    textfield = {
      on_gui_text_changed = function(e)
        local player = game.get_player(e.player_index)
        local force_index = player.force.index
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.main.search
        local query = string.lower(e.element.text)

        -- -- fuzzy search
        -- if player_table.settings.use_fuzzy_search then
        --   query = string.gsub(query, ".", "%1.*")
        -- end

        -- input sanitization
        for pattern, replacement in pairs(constants.input_sanitisers) do
          query = string.gsub(query, pattern, replacement)
        end

        gui_data.query = query

        --! ---------------------------------------------------------------------------
        --! TODO: This is catastrophically bad. Don't do this. I need to fix this.

        local category = gui_data.category
        local translations = player_table.translations[gui_data.category]
        local scroll = gui_data.results_scroll_pane
        local rb_data = global.recipe_book[category]

        -- hide limit frame, show it again later if there's more than 50 results
        local limit_frame = gui_data.limit_frame
        limit_frame.visible = false

        -- don't show anything if there are zero or one letters in the query
        if string.len(query) < 2 then
          scroll.clear()
          return
        end

        -- TODO: settings
        local show_hidden = false
        local show_unavailable = false

        -- match queries and add or modify children
        local children = scroll.children
        local add = scroll.add
        local i = 0
        for internal, translation in pairs(translations) do
          if string.find(string.lower(translation), query) then
            -- check hidden status
            local result_data = rb_data[internal]
            local is_hidden = result_data.hidden
            local is_available = result_data.available_to_forces[force_index]
            if (show_hidden or not is_hidden) and (show_unavailable or is_available) then
              -- increment index, break if more than 50 results
              i = i + 1
              if i == 51 then
                limit_frame.visible = true
                break
              end

              -- assemble element components
              local style = is_available and "rb_list_box_item" or "rb_unavailable_list_box_item"
              local caption = "["..category.."="..internal.."]  "..translation
              local tooltip = internal

              if is_hidden then caption = "[H]  "..caption end

              -- create or modify element
              local child = children[i]
              if child then
                child.style = style
                child.caption = caption
                child.tooltip = tooltip
              else
                add{type="button", style=style, caption=caption, tooltip=tooltip}
              end
            end
          end
        end

        -- remove extraneous children, if any
        if i < 50 then
          for j = i + 1, #scroll.children do
            children[j].destroy()
          end
        end
      end

      --! ---------------------------------------------------------------------------
    }
  }
}

search_pane.base_template = {type="frame", style="inside_shallow_frame", direction="vertical", children={
  {type="frame", style="subheader_frame", children={
    {type="label", style="subheader_caption_label", caption={"rb-gui.search-by"}},
    {template="pushers.horizontal"},
    {type="drop-down", items=constants.search_categories, selected_index=2, save_as="search.category_drop_down"}
  }},
  {type="flow", style_mods={padding=12, top_padding=8, right_padding=0, vertical_spacing=10}, direction="vertical", children={
    {type="textfield", style_mods={width=250, right_margin=12}, handlers="search.textfield", save_as="search.textfield"},
    {type="frame", style="deep_frame_in_shallow_frame", style_mods={width=250, height=392}, direction="vertical", children={
      {type="frame", style="rb_search_results_subheader_frame", elem_mods={visible=false},
        save_as="search.limit_frame", children={
          {type="label", style="info_label", caption={"", "[img=info] ", {"rb-gui.results-limited"}}},
        }
      },
      {type="scroll-pane", style="rb_list_box_scroll_pane", style_mods={horizontally_stretchable=true, vertically_stretchable=true},
        save_as="search.results_scroll_pane"}
    }}
  }}
}}

return search_pane