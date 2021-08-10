local actions = require("scripts.gui.search.actions")
local root = require("scripts.gui.search.root")

local function handle_action(msg, e)
  local data = actions.get_action_data(msg, e)

  if data then
    if type(msg) == "string" then
      actions[msg](data)
    else
      actions[msg.action](data)
    end
  end
end

return {
  actions = actions,
  handle_action = handle_action,
  root = root,
}

