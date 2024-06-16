local computer = require("computer")
local component = require("component")
local env = {}

local function cloneTable(tbl, clone, used)
  if type(used) ~= "table" then
    used = {}
  end
  if type(tbl) ~= "table" then
    return tbl
  end
  if type(clone) ~= "table" then
    clone = {}
  end
  --local clone = {}
  
  local mt = getmetatable(tbl)
  for index, value in pairs(tbl) do
    --print(index, value)
    -- if index == "component" then
      -- print("OK")
    -- end
    if type(value) == "table" then
      if used[value] then
        clone[index] = used[value]
      else
        used[value] = {}
        clone[index] = cloneTable(value, used[value], used)
      end
    else
      clone[index] = cloneTable(value, nil, used)
    end
  end
  if type(mt) == "table" then
    setmetatable(clone, mt)
  end
  return clone
end

env._G = cloneTable(_G)
env.computer = cloneTable(computer)
env.component = cloneTable(component)

_G.custom = env