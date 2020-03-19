local util = require('__core__.lualib.util')

-- migrate conditional event table to new format
local new_data = {conditional_events={}, players={}}
for n,t in pairs(global.__lualib.event) do
  -- copy data
  local data = table.deepcopy(t)
  -- remove IDs - they are no longer stored here
  t.id = nil
  -- add to registry
  new_data.conditional_events[n] = data
  -- add player references
  for _,i in ipairs(data.players) do
    if new_data.players[i] then
      new_data.players[i][n] = true
    else
      new_data.players[i] = {[n]=true}
    end
  end
end

-- set new data
global.__lualib.event = new_data