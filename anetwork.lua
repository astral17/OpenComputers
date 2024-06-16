local computer = require("computer")
local component = require("component")
local gpu = component.gpu
local event = require("event")
local unicode = require("unicode")
local sere = require("serialization")
local modem = component.modem

local network = {}
local host_handlers = {}
local peer_handlers = {}
local room = {}
local room_meta = {__index = room}
local table_meta = {}

network.version = "0.0.4"
network.port = 125
network.defaultRoomPort = 126
network.timeout = 5

modem.open(network.port)

local Prefixes = {}

local ToAllEvents =
{
    PING = "ANET_PING",
    PONG = "ANET_PONG",
}

local RoomEvents =
{
    ROOM_JOIN_REQUEST = "ANET_ROOM_JOIN_REQUEST",
    ROOM_JOIN_RESPONSE = "ANET_ROOM_JOIN_RESPONSE",
    ROOM_LEFT = "ANET_ROOM_LEFT",
    ROOM_KICKED = "ANET_ROOM_KICKED",
    
    ROOM_TABLE_LIST_REQUEST = "ANET_ROOM_TABLE_LIST_REQUEST",
    ROOM_TABLE_LIST_RESPONSE = "ANET_ROOM_TABLE_LIST_RESPONSE",
    ROOM_USER_LIST_REQUEST = "ANET_ROOM_USER_LIST_REQUEST",
    ROOM_USER_LIST_RESPONSE = "ANET_ROOM_USER_LIST_REQUEST",
    -- ROOM_INFO = "ANET_ROOM_INFO",
}

local TableEvents =
{
    TABLE_LOAD_REQUEST = "ANET_TABLE_LOAD_REQUEST",
    TABLE_LOAD_RESPONSE = "ANET_TABLE_LOAD_RESPONSE",
    TABLE_UPDATE = "ANET_TABLE_UPDATE",
    TABLE_UPDATES_LIST = "ANET_TABLE_UPDATES_LIST",
}

for k, v in pairs(ToAllEvents) do
    Prefixes[k] = v
end
for k, v in pairs(RoomEvents) do
    Prefixes[k] = v
end
for k, v in pairs(TableEvents) do
    Prefixes[k] = v
end

local Convert = {} -- TODO: Rename
for k, v in pairs(Prefixes) do
    Convert[v] = k
end

network.Prefixes = Prefixes

-- local events = {}
-- local function RegisterEvent(EventName, EventHandler)
    -- if (type(events[EventName]) ~= "table")
        -- events[EventName] = {}
    -- end
    -- table.insert(events[EventName], EventHandler)
-- end

-------------------- Components --------------------
-- local NetworkComponents = {}
-- local function DisableNetworkComponent(self)
    -- self.Disabled = true
-- end

-- local function EnableNetworkComponent(self)
    -- self.Disabled = false
-- end

-- local component_modem =
-- {
    -- Enable = EnableNetworkComponent,
    -- Disable = DisableNetworkComponent,
-- }
-- NetworkComponents.modem = component_modem

-- function component_modem:Init()
    -- RegisterEvent("modem", self.OnEvent)
-- end

-- function component_modem.OnEvent(EventName, ...)

-- end

-- function component_modem:Send(addrs, port, ...)

-- end

-- function component_modem:Broadcast(port, ...)

-- end
----------------------- Room -----------------------
local ROOM_ACCESS =
{
    NONE = 0,
    READ_MESSAGE = 1,
    SEND_MESSAGE = 2,
    USER_LIST = 4,
    TABLE_LIST = 8,
    TABLE_JOIN = 16,
    TABLE_CREATE = 32,
    ALL = 63,
    
}

local JOIN_INFO =
{
    NONE = 0,
    FREE = 1,
    PASSWORD = 2,
}

local TABLE_ACCESS =
{
    READ = 1,
    WRITE = 2,
    DESTROY = 4,
    OWNER = 7,
}

-- local TABLE_BEHAVIOUR =
-- {
    -- WAIT_GET = 1,
    -- AUTO_GET = 2,
    -- FAST_GET = 1,
    -- MANUAL_GET = 2,
    -- REQUEST_GET = 3,
-- }

local function HasAccess(userRights, requiredRights)
    return bit32.band(userRights or 0, requiredRights) == requiredRights
end

local rooms = {}
function OnModemMessage(_, _, sender, port, _, eventName, arg1, ...)
    local rEventName = Convert[eventName] -- TODO: REMAKE
    if not Prefixes[rEventName] then
        return
    end
    if RoomEvents[rEventName] or TableEvents[rEventName] then
        local handler = rooms[arg1].eventHandlers[eventName]
        if handler then
            handler(rooms[arg1], sender, port, ...) -- mb check type and pcall
        end
    end
    if ToAllEvents[rEventName] then
        for name, room in pairs(rooms) do
            local handler = room.eventHandlers[eventName]
            if handler then
                handler(room, sender, port, arg1, ...) -- mb check type and pcall
            end
        end
    end
end
event.listen("modem_message", OnModemMessage)

----------------------- API ------------------------
network.SendToAll = modem.broadcast

network.SendMessage = modem.send
function network.GetMessage(...) -- [timeout], sender, port, ...
    local args = {...}
    local timeout, sender, port, from
    if type(args[1]) == "number" then
        timeout = args[1]
        sender = args[2]
        port = args[3]
        from = 4
    else
        sender = args[1]
        port = args[2]
        from = 3
    end
    return event.pull(timeout or network.timeout, "modem_message", nil, sender, port, nil, table.unpack(args, from))
end

function network.GetRooms(timeout, limit)
    timeout = timeout or network.timeout
    limit = limit or math.huge
    local list = {}
    network.SendToAll(network.port, Prefixes.PING)
    local deadline = computer.uptime() + timeout
    repeat
        local ok, _, address, _, _, _, name, port, info = network.GetMessage(deadline - computer.uptime(), nil, network.port, Prefixes.PONG)
        if not ok then
            break
        end
        table.insert(list, {address = address, name = name, port = port, info = info})
        limit = limit - 1
    until computer.uptime() >= deadline or limit <= 0
    return list
end

function network.CreateRoom(name, port, password)
    port = port or network.defaultRoomPort
    modem.open(port)
    if rooms[name] then
        return false
    end
    rooms[name] = setmetatable(
    {
        port = port,
        name = name,
        password = password,
        host = true,
        eventHandlers = setmetatable({}, {__index = host_handlers}),
        users = {},
        tables = {},
        joinInfo = 1,
    }, room_meta)
    return rooms[name]
end

function network.JoinRoom(room, password)
    modem.open(room.port)
    network.SendMessage(room.address, room.port, Prefixes.ROOM_JOIN_REQUEST, room.name, password)
    local ok, _, _, _, _, _, _, result, reason = network.GetMessage(room.address, room.port, Prefixes.ROOM_JOIN_RESPONSE, room.name)
    if not ok then
        return false, "no response"
    end
    if not result or result == 0 then
        return false, reason or "unknown"
    end
    return true, setmetatable(
    {
        port = port,
        host = room.address,
        eventHandlers = setmetatable({}, {__index = peer_handlers}),
    }, room_meta)
end


function room:IsHost()
    return self.host == true
end

function room:Kick(address)    
    if self:IsHost() and self.users[address] then
        self.users[address] = nil
        network.SendMessage(address, self.port, RoomEvents.ROOM_KICKED)
    end
end

-- function room:RegisterListener(name, callback)
    -- table.insert(self.listeners, {name, callback})
    -- return event.listen(name, callback)
-- end

function room:GetRights()
    return ROOM_ACCESS.ALL
end

function room:SendToAll(...)
    for address, _ in pairs(room.users) do
        network.SendMessage(address, room.port, ...)
    end
end

function room:SendToHost(...)
    return network.SendMessage(self.host, self.port, ...)
end

function room:GetHostMessage(...)
    return network.GetMessage(self.host, self.port, ...)
end

-- function room:SendEvent(event, ...)
    -- network.SendEvent(event, ...)
-- end

-- function room:GetEvent(event, ...)

-- end

function room:CreateTable(name) -- check is host?
    self.tables[name] = {}
    return setmetatable({},
    {
        __index = table_meta.__index,
        __newindex = table_meta.__newindex,
        info = {room = self, name = name, host = true},
        data = {},
    })
end

function room:Leave()
    if self.IsHost() then
        for user, rights in pairs(self.users) do
            self:Kick(user)
        end
    else
        network.SendMessage(self.host, self.port, RoomEvents.ROOM_LEFT)
    end
    self:Destroy()
end

function room:Destroy()
    -- remove room from global list
    rooms[room.name] = nil
end


host_handlers[ToAllEvents.PING] = function(room, address, port)
    if room.joinInfo ~= JOIN_INFO.NONE then
        network.SendMessage(address, port, ToAllEvents.PONG, room.name, room.port, room.joinInfo)
    end
end

host_handlers[RoomEvents.ROOM_JOIN_REQUEST] = function(room, address, port, password)
    local rights, reason = room:GetRights(password)
    if rights ~= 0 then
        room.users[address] = rights
    end
    network.SendMessage(address, port, RoomEvents.ROOM_JOIN_RESPONSE, room.name, rights, reason)
end

host_handlers[RoomEvents.ROOM_LEFT] = function(room, address, port)
    room.users[address] = nil
end

peer_handlers[RoomEvents.ROOM_KICKED] = function(room, address, port)
    if address == room.host then
        room:Destroy()
    end
end

host_handlers[RoomEvents.ROOM_USER_LIST_REQUEST] = function(room, address, port)
    if HasAccess(room.users[address], ROOM_ACCESS.USER_LIST) then
        network.SendMessage(address, port, RoomEvents.ROOM_USER_LIST_RESPONSE, room.name, sere.serialize(room.users))
    end
end

host_handlers[RoomEvents.ROOM_TABLE_LIST_REQUEST] = function(room, address, port)
    if HasAccess(room.users[address], ROOM_ACCESS.TABLE_LIST) then
        local last = 0
        local tables = {}
        for tableName, _ in pairs(room.tables) do
            last = last + 1
            tables[last] = tableName
        end
    
        network.SendMessage(address, port, RoomEvents.ROOM_TABLE_LIST_RESPONSE, room.name, sere.serialize(tables))
    end
end


host_handlers[TableEvents.TABLE_LOAD_REQUEST] = function(room, address, port, tableName, key)
    if HasAccess(room.users[address], ROOM_ACCESS.TABLE_JOIN) and tableName ~= nil and room.tables[tableName] then
        if key ~= nil then
            network.SendMessage(address, port, RoomEvents.TABLE_LOAD_RESPONSE, room.name, room.tables[tableName][key])
        else
            network.SendMessage(address, port, RoomEvents.TABLE_LOAD_RESPONSE, room.name, sere.serialize(room.tables[tableName]))
        end
    end
end

host_handlers[TableEvents.TABLE_UPDATE] = function(room, address, port, tableName, key, value)
    if HasAccess(room.users[address], ROOM_ACCESS.TABLE_JOIN) and tableName ~= nil and room.tables[tableName] and key ~= nil then
        room.tables[tableName][key] = value
    end
end

-- peer_handlers[TableEvents.TABLE_UPDATE] = function(room, address, port, tableName, key, value)
    -- if address == room.host then
        -- room.tables[tableName][key] = value
    -- end
-- end

    -- TABLE_LOAD_RESPONSE = "ANET_TABLE_LOAD_RESPONSE",
    -- TABLE_UPDATE = "ANET_TABLE_UPDATE",
    -- TABLE_UPDATES_LIST = "ANET_TABLE_UPDATES_LIST",


function table_meta.__index(self, key)
    local meta = getmetatable(self)
    if meta.info.host == true then
        return meta.data[key]
    end
    -- LOAD FROM WEB
    local room = meta.info.room
    room:SendToHost(Prefixes.TABLE_LOAD_REQUEST, room.name, meta.info.name, key, value)
    -- local room = meta.room
    -- network.SendMessage(room.host, room.port, Prefixes.TABLE_LOAD_REQUEST, meta.info.room.id, meta.info.name, key, value)
    
    return meta.data[key]
end

function table_meta.__newindex(self, key, value)
    local meta = getmetatable(self)
    if meta.info.readonly and not meta.info.host then
        return
    end
    -- meta.room:SendEvent(Prefixes.TABLE_UPDATE, meta.info.room.id, meta.info.name, key, value)
    meta.room:SendEvent(Prefixes.TABLE_UPDATE, meta.info.room.id, meta.info.name, key, value)
    meta.data[key] = value
end


return network