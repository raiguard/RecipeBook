local recipe_book_data = {}

local crafter_proc = require("scripts.processors.crafter")
local fluid_proc = require("scripts.processors.fluid")
local item_proc = require("scripts.processors.item")
local lab_proc = require("scripts.processors.lab")
local offshore_pump_proc = require("scripts.processors.offshore-pump")
local recipe_proc = require("scripts.processors.recipe")
local resource_proc = require("scripts.processors.resource")
local technology_proc = require("scripts.processors.technology")

function recipe_book_data.build()
  -- the data that will actually be saved and used
  local recipe_book = {
    crafter = {},
    fluid = {},
    item = {},
    lab = {},
    offshore_pump = {},
    recipe = {},
    resource = {},
    technology = {}
  }
  -- localised strings for translation
  local strings = {__index = 0}
  -- data that is needed for generation but will not be saved
  local metadata = {}

  -- CRAFTERS
  crafter_proc(recipe_book, strings, metadata)
  -- FLUIDS
  fluid_proc(recipe_book, strings)
  -- ITEMS
  item_proc(recipe_book, strings, metadata)
  -- LABS
  lab_proc(recipe_book, strings)
  -- OFFSHORE PUMPS
  offshore_pump_proc(recipe_book, strings)
  -- RECIPES
  recipe_proc(recipe_book, strings, metadata)
  -- RESOURCES
  resource_proc(recipe_book, strings)
  -- TECHNOLOGIES
  technology_proc(recipe_book, strings)

  strings.__index = nil
  global.recipe_book = recipe_book
  -- game.write_file("recipe_book_dump", serpent.block(recipe_book))
  global.strings = strings

  error("THOU FOOL!")
end

return recipe_book_data
