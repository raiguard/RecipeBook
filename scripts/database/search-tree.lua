--- Each top-level prototype sorted into groups and subgroups for the search panel.
--- @class SearchTree
--- @field groups table<string, table<string, Entry[]>> Group name -> subgroup name -> members
--- @field order table<Entry, integer>
local search_tree = {}
local mt = { __index = search_tree }
script.register_metatable("search_tree", mt)

--- @return SearchTree
function search_tree.new()
  --- @type SearchTree
  local self = {
    groups = {},
    order = {},
  }

  for group_name, group_prototype in pairs(prototypes.item_group) do
    local subgroups = {}
    for _, subgroup_prototype in pairs(group_prototype.subgroups) do
      subgroups[subgroup_prototype.name] = {}
    end
    self.groups[group_name] = subgroups
  end

  setmetatable(self, mt)
  return self
end

--- Prune empty groups and sort all subgroups.
function search_tree:finalize()
  local order = 0
  for group_name, group in pairs(self.groups) do
    for subgroup_name, subgroup in pairs(group) do
      if #subgroup == 0 then
        group[subgroup_name] = nil
        goto continue
      end

      table.sort(subgroup, function(a, b)
        local a_order, b_order = a:get_order(), b:get_order()
        if a_order == b_order then
          return a:get_name() < b:get_name()
        end
        return a_order < b_order
      end)

      for i = 1, #subgroup do
        order = order + 1
        self.order[subgroup[i]] = order
      end

      ::continue::
    end
    if not next(group) then
      search_tree[group_name] = nil
    end
  end
end

--- @param entry Entry
function search_tree:add(entry)
  local subgroup = self.groups[entry:get_group().name][entry:get_subgroup().name]
  assert(subgroup, "Subgroup was nil.")
  subgroup[#subgroup + 1] = entry
end

return search_tree
