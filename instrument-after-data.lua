--- @param type string
--- @param name string
--- @param new_name string
--- @return table?
local function make_copy(type, name, new_name)
  local original = data.raw[type][name]
  if not original then
    return
  end
  local new = table.deepcopy(original)
  new.name = new_name
  data:extend({ new })
  return new
end

local wacky_silo = make_copy("rocket-silo", "rocket-silo", "wacky-silo")
wacky_silo.crafting_categories = { "crafting" }
wacky_silo.fixed_recipe = nil
