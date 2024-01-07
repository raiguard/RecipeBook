--- @class History: {[integer]: Entry, index: integer}
local history = {}
local mt = { __index = history }
script.register_metatable("history", mt)

function history.new()
  return setmetatable({ index = 0 }, mt)
end

--- @param entry Entry
function history:push(entry)
  for i = self.index + 1, #self do
    self[i] = nil
  end
  for i = self.index, 1, -1 do
    if self[i] == entry then
      table.remove(self, i)
    end
  end
  self[#self + 1] = entry
  self.index = #self
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
