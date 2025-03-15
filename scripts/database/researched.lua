local flib_table = require("__flib__.table")
local util = require("scripts.util")

--- @type table<uint, table<SpritePath, boolean>>
local entries = {}

--- @param prototype GenericPrototype
--- @param force_index uint
local function research(prototype, force_index)
  assert(prototype, "Prototype was nil")
  local path = util.get_path(prototype)
  local researched = flib_table.get_or_insert(entries, force_index, {})

  if researched[path] then
    return
  end
  researched[path] = true

  if prototype.object_name == "LuaRecipePrototype" and not prototype.unlock_results then
    return
  end

  if prototype.object_name == "LuaTechnologyPrototype" then
    for _, effect in pairs(prototype.effects) do
      if effect.type == "unlock-recipe" then
        research(prototypes.recipe[effect.recipe], force_index)
      end
    end
  elseif prototype.object_name == "LuaRecipePrototype" then
    for _, product in pairs(prototype.products) do
      if product.type ~= "research-progress" then
        research(prototypes[product.type][product.name], force_index)
      end
    end
  elseif prototype.object_name == "LuaItemPrototype" then
    for _, product in pairs(prototype.rocket_launch_products) do
      if product.type ~= "research-progress" then
        research(prototypes[product.type][product.name], force_index)
      end
    end
    local burnt_result = prototype.burnt_result
    if burnt_result then
      research(burnt_result, force_index)
    end
    local place_result = prototype.place_result
    if place_result then
      research(place_result, force_index)
    end
    local place_as_tile_result = prototype.place_as_tile_result
    if place_as_tile_result then
      research(place_as_tile_result.result, force_index)
    end
    local place_as_equipment_result = prototype.place_as_equipment_result
    if place_as_equipment_result then
      research(place_as_equipment_result, force_index)
    end
  elseif prototype.object_name == "LuaEntityPrototype" then
    local mineable_properties = prototype.mineable_properties
    if mineable_properties then
      for _, product in pairs(mineable_properties.products or {}) do
        if product.type ~= "research-progress" then
          research(prototypes[product.type][product.name], force_index)
        end
      end
    end
    if prototype.type == "boiler" then
      for _, fluidbox in pairs(prototype.fluidbox_prototypes) do
        -- TODO: Are multiple outputs possible?
        if fluidbox.production_type == "output" and fluidbox.filter then
          research(fluidbox.filter, force_index)
        end
      end
    end
    if prototype.type == "mining-drill" then
      --- @type string|boolean?
      local filter
      for _, fluidbox_prototype in pairs(prototype.fluidbox_prototypes) do
        local production_type = fluidbox_prototype.production_type
        if production_type == "input" or production_type == "input-output" then
          filter = fluidbox_prototype.filter and fluidbox_prototype.filter.name or true
          break
        end
      end
      local resource_categories = prototype.resource_categories or {}
      for _, resource in pairs(prototypes.get_entity_filtered({ { filter = "type", type = "resource" } })) do
        local mineable = resource.mineable_properties
        local required_fluid = mineable.required_fluid
        if
          resource_categories[resource.resource_category]
          and (not required_fluid or filter == true or filter == required_fluid)
        then
          research(resource, force_index)
        end
      end
    end
    if prototype.type == "offshore-pump" then
      for _, tile in pairs(prototypes.tile) do
        if tile.fluid and researched[util.get_path(tile)] then
          research(tile.fluid, force_index)
        end
      end
    end
  elseif prototype.object_name == "LuaTilePrototype" then
    local fluid = prototype.fluid
    if fluid then
      for _, offshore_pump in pairs(prototypes.get_entity_filtered({ { filter = "type", type = "offshore-pump" } })) do
        if researched[util.get_path(offshore_pump)] then
          research(fluid, force_index)
          break
        end
      end
    end
  end
end

--- @param e EventData.on_research_finished
local function on_research_finished(e)
  research(e.research.prototype, e.research.force.index)
end

--- @param surface LuaSurface
local function research_surface(surface)
  local autoplace_settings = surface.map_gen_settings.autoplace_settings
  -- TODO: Iterate natural entities
  -- for entity_name in pairs(autoplace_settings.entity.settings) do
  --   local entity_entry = self:get_entry({ type = "entity", name = entity_name })
  --   if entity_entry then
  --     for _, force in pairs(game.forces) do
  --       entity_entry:research(force.index)
  --     end
  --   end
  -- end
  local tile_settings = autoplace_settings.tile
  if tile_settings then
    for tile_name in pairs(tile_settings.settings) do
      local tile = prototypes.tile[tile_name]
      if tile then
        for _, force in pairs(storage.forces) do
          research(tile, force.index)
        end
      end
    end
  end
end

--- @param e EventData.on_surface_created
local function on_surface_created(e)
  local surface = game.get_surface(e.surface_index)
  if not surface then
    return
  end
  research_surface(surface)
end

--- @param force LuaForce
local function rebuild_force(force)
  local force_index = force.index
  -- Gather-able items
  for _, entity in
    pairs(prototypes.get_entity_filtered({
      --- @diagnostic disable-next-line unused-fields
      { filter = "type", type = "simple-entity" },
      --- @diagnostic disable-next-line unused-fields
      { filter = "type", type = "tree" },
      --- @diagnostic disable-next-line unused-fields
      { filter = "type", type = "fish" },
    }))
  do
    if entity.type ~= "simple-entity" or entity.count_as_rock_for_filtered_deconstruction then
      research(entity, force_index)
    end
  end
  -- Technologies
  for _, technology in pairs(force.technologies) do
    if technology.researched then
      research(technology.prototype, force_index)
    end
  end
  -- Recipes (some may be enabled without technologies)
  for _, recipe in pairs(force.recipes) do
    -- Some recipes will be enabled from the start, but will only be craftable in machines
    if recipe.enabled and not (recipe.prototype.enabled and recipe.prototype.hidden_from_player_crafting) then
      research(recipe.prototype, force_index)
    end
  end
  -- Characters
  --- @diagnostic disable-next-line unused-fields
  for _, character in pairs(prototypes.get_entity_filtered({ { filter = "type", type = "character" } })) do
    research(character, force_index)
  end
end

local function rebuild()
  if not storage.forces or not storage.surfaces then
    return
  end
  for _, surface in pairs(storage.surfaces) do
    if surface.valid then
      research_surface(surface)
    end
  end
  for _, force in pairs(storage.forces or {}) do
    if force.valid then
      rebuild_force(force)
    end
  end
end

--- @param e EventData.on_force_created
local function on_force_created(e)
  if not storage.forces then
    return
  end
  storage.forces[e.force.index] = e.force
  rebuild_force(e.force)
end

local function setup_cache()
  storage.forces = {}
  for _, force in pairs(game.forces) do
    storage.forces[force.index] = force
  end
  storage.surfaces = {}
  for _, surface in pairs(game.surfaces) do
    storage.surfaces[surface.index] = surface
  end
end

--- @class Researched
local M = {}

function M.on_init()
  setup_cache()
  rebuild()
end

M.on_load = rebuild

function M.on_configuration_changed()
  setup_cache()
  rebuild()
end

M.events = {
  [defines.events.on_force_created] = on_force_created,
  -- [defines.events.on_forces_merged] = on_forces_merged, -- TODO:
  [defines.events.on_research_finished] = on_research_finished,
  [defines.events.on_surface_created] = on_surface_created,
  -- [defines.events.on_surface_deleted] = on_surface_destroyed, -- TODO:
}

--- @param prototype GenericPrototype
--- @param force_index uint
--- @return boolean
function M.is(prototype, force_index)
  local force_entries = entries[force_index]
  if not force_entries then
    return false
  end
  return force_entries[util.get_path(prototype)] or false
end

return M

--[[
  Database topology
  - Build per-player search tree depending on their preferences
  - Track researched objects with a simple map<SpritePath, boolean>
  - Memoize results as they are browsed
  - Consider pregenerating expensive lists - or maybe just pregen everything like in RB3?
]]
--
