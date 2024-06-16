local component = require("component")
if not component.isAvailable("data") or not component.data.encrypt then
    print("Data card tier 2+ is required!")
    return
end
local data = component.data
local args = {...}
local password = data.md5(args[2] or data.random(16))
local iv = data.random(16)-- string.rep("0", 16)
if not args[1] then
    print("Usage: tpm.lua <file> [password]")
    return
end

local eeprom = [[local password = ]] .. string.format("%q", password) .. [[
local iv = ]] .. string.format("%q", iv) .. [[
local init
do
  local component_invoke = component.invoke
  local function boot_invoke(address, method, ...)
    local result = table.pack(pcall(component_invoke, address, method, ...))
    if not result[1] then
      return nil, result[2]
    else
      return table.unpack(result, 2, result.n)
    end
  end

  -- backwards compatibility, may remove later
  local eeprom = component.list("eeprom")()
  computer.getBootAddress = function()
    return boot_invoke(eeprom, "getData")
  end
  computer.setBootAddress = function(address)
    return boot_invoke(eeprom, "setData", address)
  end

  do
    local screen = component.list("screen")()
    local gpu = component.list("gpu")()
    if gpu and screen then
      boot_invoke(gpu, "bind", screen)
    end
  end
  local function tryLoadFrom(address)
    local handle, reason = boot_invoke(address, "open", "/init.lua")
    if not handle then
      return nil, reason
    end
    local buffer = ""
    repeat
      local data, reason = boot_invoke(address, "read", handle, math.huge)
      if not data and reason then
        return nil, reason
      end
      buffer = buffer .. (data or "")
    until not data
    boot_invoke(address, "close", handle)
    if component.list("data")() then
      local handle, reason = boot_invoke(address, "open", "/tpm.dat")
      if handle then
        local buffer = ""
        repeat
          local data, reason = boot_invoke(address, "read", handle, math.huge)
          if not data and reason then
            break
          end
          buffer = buffer .. (data or "")
        until not data
        boot_invoke(address, "close", handle)
        local run, reason = load(boot_invoke(component.list("data")(), "decrypt", buffer, password, iv) or "", "=init")
        if run then
          tpm = run()
        end
      end
    end
    return load(buffer, "=init")
  end
  local reason
  if computer.getBootAddress() then
    init, reason = tryLoadFrom(computer.getBootAddress())
  end
  if not init then
    computer.setBootAddress()
    for address in component.list("filesystem") do
      init, reason = tryLoadFrom(address)
      if init then
        computer.setBootAddress(address)
        break
      end
    end
  end
  if not init then
    error("no bootable medium found" .. (reason and (": " .. tostring(reason)) or ""), 0)
  end
  computer.beep(1000, 0.2)
end
init()
]]
local file = io.open(args[1], "r")
local text = file:read("*a")
file:close()
local file = io.open("/tpm.dat", "w")
file:write(data.encrypt(text, password, iv))
file:close()

component.eeprom.set(eeprom)
print("TPM install was successful")