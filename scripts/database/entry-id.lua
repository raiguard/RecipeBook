local core_util = require("__core__.lualib.util")
local flib_math = require("__flib__.math")

--- @alias EntryType
--- | "entity"
--- | "equipment"
--- | "fluid"
--- | "item"
--- | "recipe"
--- | "technology"
--- | "tile"

--- @class EntryID
--- @field database Database
--- @field type EntryType
--- @field name string
--- @field amount number?
--- @field amount_min number?
--- @field amount_max number?
--- @field probability number?
--- @field catalyst_amount number?
--- @field temperature number?
--- @field minimum_temperature number?
--- @field maximum_temperature number?
--- @field required_fluid EntryID?
local entry_id = {}
local mt = { __index = entry_id }
script.register_metatable("entry_id", mt)

--- @class GenericID
--- @field type "entity"|"equipment"|"fluid"|"item"|"recipe"|"technology"
--- @field name string

--- @param input GenericID|Ingredient.fluid|Product
--- @param database Database
--- @return EntryID?
function entry_id.new(input, database)
  local self = setmetatable({
    database = database,
    type = input.type,
    name = input.name,
    amount = input.amount,
    amount_min = input.amount_min,
    amount_max = input.amount_max,
    probability = input.probability,
    catalyst_amount = input.catalyst_amount,
    temperature = input.temperature,
    minimum_temperature = input.minimum_temperature,
    maximum_temperature = input.maximum_temperature,
  }, mt)

  if not database:get_entry(self) then
    -- TODO raiguard: Debug only / remove?
    log("Created an entry ID for a non-existent entry: " .. self:get_path())
    return
  end

  return self
end

--- @return Entry
function entry_id:get_entry()
  local entry = self.database:get_entry(self)
  assert(entry, "Entry ID points to nonexistent entry!")
  return entry
end

function entry_id:get_path()
  return self.type .. "/" .. self.name
end

--- @return LocalisedString
function entry_id:get_caption()
  --- @type LocalisedString
  local caption = { "" }
  if self.probability and self.probability < 1 then
    caption[#caption + 1] = {
      "",
      "[font=default-semibold]",
      { "format-percent", flib_math.round(self.probability * 100, 0.01) },
      "[/font] ",
    }
  end
  if self.amount then
    caption[#caption + 1] = {
      "",
      "[font=default-semibold]",
      core_util.format_number(self.amount, true),
      " ×[/font]  ",
    }
  elseif self.amount_min and self.amount_max then
    caption[#caption + 1] = {
      "",
      "[font=default-semibold]",
      core_util.format_number(self.amount_min, true),
      " - ",
      core_util.format_number(self.amount_max, true),
      " ×[/font]  ",
    }
  end

  caption[#caption + 1] = self:get_entry()[self.type].localised_name

  if self.temperature then
    caption[#caption + 1] = { "", "  (", { "format-degrees-c-compact", flib_math.round(self.temperature, 0.01) }, ")" }
  elseif self.minimum_temperature and self.maximum_temperature then
    local temperature_min = self.minimum_temperature --[[@as number]]
    local temperature_max = self.maximum_temperature --[[@as number]]
    local temperature_string
    if temperature_min == flib_math.min_double then
      temperature_string = "≤ " .. flib_math.round(temperature_max, 0.01)
    elseif temperature_max == flib_math.max_double then
      temperature_string = "≥ " .. flib_math.round(temperature_min, 0.01)
    else
      temperature_string = ""
        .. flib_math.round(temperature_min, 0.01)
        .. " - "
        .. flib_math.round(temperature_max, 0.01)
    end
    caption[#caption + 1] = { "", "  (", { "format-degrees-c-compact", temperature_string }, ")" }
  end

  return caption
end

--- @return string? bottom
--- @return string? top
function entry_id:get_temperature_strings()
  local temperature = self.temperature
  local temperature_min = self.minimum_temperature
  local temperature_max = self.maximum_temperature
  local bottom
  local top
  if temperature then
    bottom = core_util.format_number(temperature, true)
    temperature_min = temperature
    temperature_max = temperature
  elseif temperature_min and temperature_max then
    if temperature_min == flib_math.min_double then
      bottom = "≤" .. core_util.format_number(temperature_max, true)
    elseif temperature_max == flib_math.max_double then
      bottom = "≥" .. core_util.format_number(temperature_min, true)
    else
      bottom = core_util.format_number(temperature_min, true)
      top = core_util.format_number(temperature_max, true)
    end
  end

  return bottom, top
end

--- @return ElemID
function entry_id:strip()
  return { type = self.type, name = self.name }
end

return entry_id
