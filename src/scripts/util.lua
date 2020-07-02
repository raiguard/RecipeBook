local util = require("__core__.lualib.util")

function util.shallow_copy(tbl)
  local new_t = {}
  for k, v in pairs(tbl) do
    new_t[k] = v
  end
  return new_t
end

return util