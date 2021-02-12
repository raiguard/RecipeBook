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
    info_list_box.build({"rb-gui.unlocks-recipes"}, 1, {"technology", "associated_recipes"}),
    info_list_box.build({"rb-gui.prerequisites"}, 1, {"technology", "prerequisites"}),
    info_list_box.build({"rb-gui.prerequisite-of"}, 1, {"technology", "prerequisite_of"}),
  }

  return elems
end

function technology_page.update(int_name, gui_data, player_data)
  local refs = gui_data.refs

  local obj_data = global.recipe_book.technology[int_name]

  -- set units item
  local units_item_prefix = player_data.settings.show_glyphs and "[font=RecipeBook]Z[/font]   " or ""
  local units_item = refs.technology.research_units.unit_item
  units_item.caption = {
    "",
    units_item_prefix.."[img=quantity-multiplier]   [font=default-bold]",
    obj_data.research_unit_amount,
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

  info_list_box.update(obj_data.research_ingredients_per_unit, refs.technology.research_ingredients_per_unit, player_data, {always_show = true, starting_index = 1})
  info_list_box.update(obj_data.associated_recipes, refs.technology.associated_recipes, player_data)
  info_list_box.update(obj_data.prerequisites, refs.technology.prerequisites, player_data)
  info_list_box.update(obj_data.prerequisite_of, refs.technology.prerequisite_of, player_data)
end

return technology_page
