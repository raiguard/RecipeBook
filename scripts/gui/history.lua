local grouping = require("scripts.database.grouping")
local util = require("scripts.util")

--- @class History: {[integer]: GenericPrototype, index: integer}
local history = {}
local mt = { __index = history }
script.register_metatable("history", mt)

function history.new()
  return setmetatable({ index = 0 }, mt)
end

--- @param prototype GenericPrototype
--- @param resolve_grouping boolean
--- @return boolean
function history:push(prototype, resolve_grouping)
  if resolve_grouping then
    local base = grouping[util.get_path(prototype)]
    if base then
      prototype = base
    end
  end
  if self:current() == prototype then
    return false
  end
  for i = self.index + 1, #self do
    self[i] = nil
  end
  for i = self.index, 1, -1 do
    if self[i] == prototype then
      table.remove(self, i)
    end
  end
  self[#self + 1] = prototype
  self.index = #self
  return true
end

function history:prev()
  self.index = math.max(1, self.index - 1)
end

function history:next()
  self.index = math.min(#self, self.index + 1)
end

function history:current()
  return self[self.index]
end

function history:at_front()
  return self.index <= 1
end

function history:at_back()
  return self.index == #self
end

return history
