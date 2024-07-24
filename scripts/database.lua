local constants = require("constants")

local util = require("scripts.util")

local beacon = require("scripts.database.beacon")
local burning = require("scripts.database.burning")
local crafter = require("scripts.database.crafter")
local entity = require("scripts.database.entity")
local entity_state = require("scripts.database.entity-state")
local entity_type = require("scripts.database.entity-type")
local equipment_category = require("scripts.database.equipment-category")
local equipment = require("scripts.database.equipment")
local fluid = require("scripts.database.fluid")
local fuel_category = require("scripts.database.fuel-category")
local generator = require("scripts.database.generator")
local group = require("scripts.database.group")
local item = require("scripts.database.item")
local item_type = require("scripts.database.item-type")
local lab = require("scripts.database.lab")
local mining_drill = require("scripts.database.mining-drill")
local offshore_pump = require("scripts.database.offshore-pump")
local recipe_category = require("scripts.database.recipe-category")
local recipe = require("scripts.database.recipe")
local resource_category = require("scripts.database.resource-category")
local resource = require("scripts.database.resource")
local science_pack = require("scripts.database.science-pack")
local technology = require("scripts.database.technology")

local database = {}
local mt = { __index = database }
script.register_metatable("database", mt)

function database.new()
  local self = setmetatable({}, mt)
  -- Create class tables
  for _, class in pairs(constants.classes) do
    self[class] = {}
  end

  -- Create dictionaries
  for _, class in pairs(constants.classes) do
    util.new_dictionary(class)
    util.new_dictionary(class .. "_description")
  end
  util.new_dictionary("gui", constants.gui_strings)

  -- Data that is needed for generation but will not be saved
  local metadata = {}

  entity_type(self)
  equipment_category(self)
  fuel_category(self)
  group(self)
  item_type(self)
  recipe_category(self)
  resource_category(self)
  science_pack(self)

  equipment(self)

  beacon(self, metadata)
  crafter(self, metadata)
  generator(self)
  entity(self, metadata)
  mining_drill(self)

  fluid(self, metadata)

  lab(self)
  offshore_pump(self) -- requires fluids

  item(self, metadata) -- requires all entities

  recipe(self, metadata)
  resource(self)
  technology(self, metadata)

  offshore_pump.check_enabled_at_start(self)
  fluid.process_temperatures(self, metadata)
  mining_drill.add_resources(self)
  fuel_category.check_fake_category(self)
  lab.process_researched_in(self)

  burning(self)
  entity_state(self)

  for _, force in pairs(game.forces) do
    if force.valid then
      self:check_force(force)
    end
  end

  return self
end

function database:check_force(force)
  for _, technology in pairs(force.technologies) do
    if technology.enabled and technology.researched then
      self:handle_research_updated(technology, true)
    end
  end
end

local function update_launch_products(launch_products, force_index, to_value)
  for _, launch_product in pairs(launch_products) do
    local product_data = database.item[launch_product.name]
    if product_data.researched_forces then
      product_data.researched_forces[force_index] = to_value
    end
    update_launch_products(product_data.rocket_launch_products, force_index, to_value)
  end
end

function database:handle_research_updated(technology, to_value)
  local force_index = technology.force.index
  -- Technology
  local technology_data = self.technology[technology.name]
  -- Other mods can update technologies during on_configuration_changed before RB gets a chance to config change
  if not technology_data then
    return
  end
  technology_data.researched_forces[force_index] = to_value

  for _, objects in pairs({
    technology_data.unlocks_equipment,
    technology_data.unlocks_fluids,
    technology_data.unlocks_items,
    technology_data.unlocks_entities,
    technology_data.unlocks_recipes,
  }) do
    for _, obj_ident in ipairs(objects) do
      local class = obj_ident.class
      local obj_data = self[class][obj_ident.name]

      -- Unlock this object
      if obj_data.researched_forces then
        obj_data.researched_forces[force_index] = to_value
      end

      if class == "fluid" and obj_data.temperature_ident then
        -- Unlock base fluid
        local base_fluid_data = self.fluid[obj_data.prototype_name]
        if base_fluid_data.researched_forces then
          base_fluid_data.researched_forces[force_index] = to_value
        end
      elseif class == "item" then
        -- Unlock rocket launch products
        update_launch_products(obj_data.rocket_launch_products, force_index, to_value)
      elseif class == "offshore_pump" then
        -- Unlock pumped fluid
        local fluid = obj_data.fluid
        local fluid_data = self.fluid[fluid.name]
        if fluid_data.researched_forces then
          fluid_data.researched_forces[force_index] = to_value
        end
      end
    end
  end
end

return database
