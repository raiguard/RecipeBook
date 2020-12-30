local table = require("__flib__.table")

local util = {}

function util.append(tbl, name)
  local new_tbl = table.shallow_copy(tbl)
  new_tbl[#new_tbl+1] = name
  return new_tbl
end

return util

