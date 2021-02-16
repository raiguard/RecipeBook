local info_list_box = require("scripts.gui.main.info-list-box")

local technology_page = {}

function technology_page.build()
  local elems =  {
    info_list_box.build(
      {"rb-gui.research-units"},
      1,
      {"technology", "research_units"},
      {
        {
          type = "button",
          style = "rb_list_box_item",
          tooltip = {"rb-gui.units-research-tooltip"},
          enabled = false,
          ref = {"technology", "research_units", "unit_item"}
        }
      }
    ),
    info_list_box.build(
      {"rb-gui.research-ingredients-per-unit"},
      1,
      {"technology", "research_ingredients_per_unit"},
      {
        {
          type = "button",
          style = "rb_list_box_item",
          tooltip = {"rb-gui.seconds-research-tooltip"},
          enabled = false,
          ref = {"technology", "research_ingredients_per_unit", "time_item"}
        }
      }
    ),
    info_list_box.build({"rb-gui.unlocks-fluids"}, 1, {"technology", "associated_fluids"}),
    info_list_box.build({"rb-gui.unlocks-items"}, 1, {"technology", "associated_items"}),
    info_list_box.build({"rb-gui.unlocks-recipes"}, 1, {"technology", "associated_recipes"}),
    info_list_box.build({"rb-gui.prerequisites"}, 1, {"technology", "prerequisites"}),
    info_list_box.build({"rb-gui.prerequisite-of"}, 1, {"technology", "prerequisite_of"}),
  }

  return elems
end

function technology_page.update(int_name, gui_data, player_data)
  local state = gui_data.state
  local refs = gui_data.refs

  local obj_data = global.recipe_book.technology[int_name]

  -- set units item
  local units_item_prefix = player_data.settings.show_glyphs and "[font=RecipeBook]Z[/font]   " or ""
  local units_item = refs.technology.research_units.unit_item
  local unit_count = obj_data.research_unit_count or game.evaluate_expression(
    obj_data.research_unit_count_formula,
    {L = state.tech_level, l = state.tech_level}
  )
  units_item.caption = {
    "",
    units_item_prefix.."[img=quantity-multiplier]   [font=default-bold]",
    unit_count,
    "[/font]"
  }

  -- set time item
  local time_item_prefix = player_data.settings.show_glyphs and "[font=RecipeBook]Z[/font]   " or ""
  local time_item = refs.technology.research_ingredients_per_unit.time_item
  time_item.caption = {
    "",
    time_item_prefix.."[img=quantity-time]   [font=default-bold]",
    {"rb-gui.seconds", obj_data.research_unit_energy},
    "[/font]"
  }

  return
    info_list_box.update(
      obj_data.research_ingredients_per_unit,
      refs.technology.research_ingredients_per_unit,
      player_data,
      {always_show = true, starting_index = 1}
    )
    + info_list_box.update(obj_data.associated_fluids, refs.technology.associated_fluids, player_data)
    + info_list_box.update(obj_data.associated_items, refs.technology.associated_items, player_data)
    + info_list_box.update(obj_data.associated_recipes, refs.technology.associated_recipes, player_data)
    + info_list_box.update(obj_data.prerequisites, refs.technology.prerequisites, player_data)
    + info_list_box.update(obj_data.prerequisite_of, refs.technology.prerequisite_of, player_data)
 end

function technology_page.update_unit_count(obj_data, refs, state, settings)
  -- set units item
  local units_item_prefix = settings.show_glyphs and "[font=RecipeBook]Z[/font]   " or ""
  local units_item = refs.technology.research_units.unit_item
  local unit_count = obj_data.research_unit_count or game.evaluate_expression(
    obj_data.research_unit_count_formula,
    {L = state.tech_level, l = state.tech_level}
  )
  units_item.caption = {
    "",
    units_item_prefix.."[img=quantity-multiplier]   [font=default-bold]",
    unit_count,
    "[/font]"
  }
end

return technology_page
