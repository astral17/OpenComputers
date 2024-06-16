local AGUI_VERSION = "0.6"
local component = require("component")
local success, gui
repeat
  success, gui = pcall(require, "AGUI")
  if not success then
    print(gui)
    io.write("For the application need a library AGUI (https://pastebin.com/s4UFSFwn).\n")
    if not component.isAvailable("internet") then
      os.exit()
    end
    io.write("Do you want to install?[Y/n] ")
    if not ((io.read() or "n").."y"):match("^%s*[Yy]") then
      os.exit()
    end
    loadfile("/bin/wget.lua")("https://pastebin.com/raw/s4UFSFwn", "/lib/AGUI.lua", "-f")
  end
until success

if gui.Version ~= AGUI_VERSION then
  io.write("Recommended version of AGUI library ("..AGUI_VERSION..") does not match installed ("..(gui.Version or "unknown")..")\n")
  io.write("Do you want to continue?[Y/n] ")
    if not ((io.read() or "n").."y"):match("^%s*[Yy]") then
      os.exit()
    end
end

local gpu = component.gpu
local event = require("event")

------SETTINGS-------
local cfg = {}
cfg.mapWidth = 10
cfg.mapHeight = 20
cfg.startX = gui.GetCenter(1, cfg.mapWidth, 1) - 1
cfg.drawShadow = true
cfg.shadowColor = 0x222222
cfg.tickDelay = 0.1
cfg.fallTickCnt = 3
cfg.fallLinesDelay = 0.3
cfg.backColor = 0x000000
--
function InRange(value, left, right)
  return left <= value and value <= right
end

function ValidateConfig()
  local MaxScreenWidth, MaxScreenHeight
  MaxScreenWidth, MaxScreenHeight = gpu.maxResolution()
  
  if not InRange(cfg.mapWidth * 2 + 12, 22, MaxScreenWidth) then
    return "MapWidthError", "out of bounds"
  end
  
  if not InRange(cfg.mapHeight, 15, MaxScreenHeight) then
    return "MapHeightError", "out of bounds"
  end
end

--UpdateScreenSettings()
local err, msg = ValidateConfig()
if err ~= nil then
  print(err, msg)
  os.exit()
end
--

linePoints = {[0] = 0, [1] = 10, [2] = 25, [3] = 50, [4] = 100}
---------------------
-- function centerText(x,y,w,text)
  -- gpu.set(x+math.floor(w/2-string.len(text)/2),y,text)
-- end

-- function messageBox(title,text,color)
  -- local x,y=cfg.mapWidth-9,math.floor(cfg.mapHeight/2)-3
  -- local len1,len2=string.len(title),string.len(text)
  -- local len3=math.max(len1,len2)+2
  -- gpu.setBackground(0xffffff)
  -- gpu.fill(x,y,len3,2+3," ")
  -- gpu.setForeground(color or 0xFF0000)
  -- centerText(x,y+1,len3,title)
  -- gpu.setForeground(0x000000)
  -- centerText(x,y+3,len3,text)
  -- gpu.setBackground(color or 0xFF0000)
  -- gpu.setForeground(0xffffff)
  -- gpu.fill(x,y+5,len3,3," ")
  -- centerText(x,y+6,len3,"OK!")
-- end
----------------------------------------------------------------
StockBlocks = { { start_position = { x = 1, y = 1 },
                  color = 0xFFFF00,
                  symbol = "T",
                  transformations = { { { x = -1, y = 0 },
                                        { x = 0, y = 0 },
                                        { x = 1, y = 0 },
                                        { x = 0, y = -1 } },
                                      { { x = 0, y = 0 },
                                        { x = 0, y = -1 },
                                        { x = 0, y = 1 },
                                        { x = -1, y = 0 } },
                                      { { x = -1, y = 0 },
                                        { x = 0, y = 0 },
                                        { x = 1, y = 0 },
                                        { x = 0, y = 1 } },
                                      { { x = 0, y = 0 },
                                        { x = 0, y = -1 },
                                        { x = 0, y = 1 },
                                        { x = 1, y = 0 } } } },
                                        
                { start_position = { x = 1, y = 1 },
                  color = 0x00FF00,
                  symbol = "Z",
                  transformations = { { { x = -1, y = 0 },
                                        { x = 0, y = 0 },
                                        { x = 0, y = -1 },
                                        { x = 1, y = -1 } },
                                      { { x = 0, y = -1 },
                                        { x = 0, y = 0 },
                                        { x = 1, y = 0 },
                                        { x = 1, y = 1 } } } },
                { start_position = { x = 1, y = 1 }, 
                  color = 0x9999CC,
                  symbol = "S",
                  transformations = { { { x = 1, y = 0 },
                                        { x = 0, y = 0 },
                                        { x = 0, y = -1 },
                                        { x = -1, y = -1 } },
                                      { { x = 0, y = 1 },
                                        { x = 0, y = 0 },
                                        { x = 1, y = 0 },
                                        { x = 1, y = -1 } } } },
                { start_position = { x = 1, y = 0 }, 
                  color = 0xFFFF99,
                  symbol = "J",
                  transformations = { { { x = -1, y = 0 },
                                        { x = 0, y = 0 },
                                        { x = 1, y = 0 },
                                        { x = -1, y = 1 } },
                                      { { x = 0, y = -1 },
                                        { x = 0, y = 0 },
                                        { x = 0, y = 1 },
                                        { x = 1, y = 1 } },
                                      { { x = -1, y = 0 },
                                        { x = 0, y = 0 },
                                        { x = 1, y = 0 },
                                        { x = 1, y = -1 } },
                                      { { x = 0, y = -1 },
                                        { x = 0, y = 0 },
                                        { x = 0, y = 1 },
                                        { x = -1, y = -1 } } } },
                { start_position = { x = 1, y = 0 },
                  color = 0xFF00FF,
                  symbol = "L",
                  transformations = { { { x = -1, y = 0 },
                                        { x = 0, y = 0 },
                                        { x = 1, y = 0 },
                                        { x = 1, y = 1 } },
                                      { { x = 0, y = -1 },
                                        { x = 0, y = 0 },
                                        { x = 0, y = 1 },
                                        { x = 1, y = -1 } },
                                      { { x = -1, y = 0 },
                                        { x = 0, y = 0 },
                                        { x = 1, y = 0 },
                                        { x = -1, y = -1 } },
                                      { { x = 0, y = -1 },
                                        { x = 0, y = 0 },
                                        { x = 0, y = 1 },
                                        { x = -1, y = 1 } } } },
                { start_position = { x = 1, y = 0 },
                  color = 0xFF0000,
                  symbol = "I",
                  transformations = { { { x = -1, y = 0 },
                                        { x = 0, y = 0 },
                                        { x = 1, y = 0 },
                                        { x = 2, y = 0 } },
                                      { { x = 0, y = -1 },
                                        { x = 0, y = 0 },
                                        { x = 0, y = 1 },
                                        { x = 0, y = 2 } } } },
                { start_position = { x = 1, y = 0 },
                  color = 0x0000FF,
                  symbol = "[]",
                  transformations = { { { x = 0, y = 0 },
                                        { x = 0, y = 1 },
                                        { x = 1, y = 0 },
                                        { x = 1, y = 1 } } } }
             }

local width = cfg.mapWidth + 10 --width of map NOT field
local score -- = 0
local map -- = {}
local control
local tick
local isRunning = false
local isInited = false

function toXY(num,wid)
  wid=wid or width
  y=math.floor((num-1)/wid)+1
  return num-(y-1)*width,y
end
function fromXY(x,y,wid)
  wid = wid or width
  return (y-1)*wid+x
end

-- TODO DELETE
-- for i=-1000,2500 do
  -- map[i]=0
-- end
--print(StockBlocks[1].transformations[1][1].y)
--[[f=7
tr=1
for i=1,4 do
  gpu.set(StockBlocks[f].transformations[tr][i].x+5,StockBlocks[f].transformations[tr][i].y+5,"!")
end]]--
local fObj, nextObj, sObj
local gCanvas, pCanvas

local scoreObj
function GetScore()
  return tonumber(scoreObj.Text)
end

function SetScore(value)
  scoreObj:Modify{Text = tostring(value)}:Paint()
end

function IncreaseScore(amount)
  SetScore(GetScore() + amount)
end

function randomID()
  -- return 6
  return math.random(1, 7)
end

function createObject(id, x, y)
  id = id or randomID()
  local obj = {}
  obj.id = id
  obj.x, obj.y = StockBlocks[id].start_position.x + (x or cfg.startX), StockBlocks[id].start_position.y + (y or 0)
  obj.color = StockBlocks[id].color
  obj.rotate = 1
  return obj
end

function cloneObject(obj, x, y, r)
  local nObj = {}
  for index, value in pairs(obj) do
    nObj[index] = value
  end
  nObj.x = nObj.x + (x or 0)
  nObj.y = nObj.y + (y or 0)
  nObj.rotate = (nObj.rotate - 1 + (r or 0) + #StockBlocks[obj.id].transformations) % (#StockBlocks[obj.id].transformations) + 1
  return nObj
end

function createShadow(obj)
  local sObj = cloneObject(obj)
  while check(sObj) do
    sObj.y = sObj.y + 1
  end
  sObj.y = sObj.y - 1
  return sObj
end

function drawBlock(canvas, x, y, color)
  canvas.set(x * 2 - 1, y, "  ")
end

function drawObject(canvas, obj, color)
  gpu.setBackground(color or obj.color)
  for i = 1, 4 do
    drawBlock(canvas, StockBlocks[obj.id].transformations[obj.rotate][i].x + obj.x,StockBlocks[obj.id].transformations[obj.rotate][i].y + obj.y)
  end
  gpu.setBackground(0x000000)
end

function drawPredict(obj)
  gpu.setBackground(cfg.backColor)
  pCanvas.fill(1, 1, 8, 4, " ")
  drawObject(pCanvas, obj)
end

function checkLine(line)
  for x = 1, cfg.mapWidth do
    if not map[fromXY(x, line)] then
      return false
    end
  end
  return true
end

function fallBlocks(line)
  for i = line, 1, -1 do
    for j = 1, cfg.mapWidth do
      map[fromXY(j,i)] = map[fromXY(j,i-1)]
    end
  end
end

function clearLines()
  local cnt, offset = 0, 0
  -- for i = cfg.mapHeight, 1, -1 do
    -- if checkLine(i) then
      -- cnt = cnt + 1
      -- offset = offset + 1
      -- gpu.set(1, i - offset, string.rep(" ", cfg.mapWidth * 2))
      -- os.sleep(cfg.fallLinesDelay)
      -- gpu.copy(1, i - cfg.mapHeight, cfg.mapWidth * 2, cfg.mapHeight, 0, 1)
    -- end
    -- if offset > 0 then
      -- for j = 1, cfg.mapWidth do
        -- map[fromXY(j, i - offset)] = map[fromXY(j, i)]
      -- end
    -- end
  -- end
  for i = 1, cfg.mapHeight do
    if checkLine(i) then
      cnt = cnt + 1
      fallBlocks(i) -- ... TODO SPEEDUP
      gpu.set(1, i, string.rep(" ", cfg.mapWidth * 2))
      os.sleep(cfg.fallLinesDelay)
      gpu.copy(1, i - cfg.mapHeight, cfg.mapWidth * 2, cfg.mapHeight, 0, 1)
    end
  end
  return cnt
end

function check(obj)
  for i = 1, 4 do
    local x, y = StockBlocks[obj.id].transformations[obj.rotate][i].x + obj.x, StockBlocks[obj.id].transformations[obj.rotate][i].y + obj.y
    if (y == cfg.mapHeight + 1) or (map[fromXY(x,y)]) or (x > cfg.mapWidth) or (x < 1) then
      return false
    end
  end
  return true
end

function putInMap(obj)
  for j = 1, 4 do
    map[fromXY(StockBlocks[obj.id].transformations[obj.rotate][j].x + obj.x, StockBlocks[obj.id].transformations[obj.rotate][j].y + obj.y)] = 1
  end
end

function GameInit()
  map = {}
  control = {}
  SetScore(0)
  fObj = createObject()
  sObj = createShadow(fObj)
  nextObj = createObject(nil, 1, 2)
  tick = 0
end

function DrawMap()
  -- gpu.setBackground(0x222222)
  -- require("term").clear()
  gpu.setBackground(cfg.backColor)
  gCanvas:Paint()
  -- gpu.fill(1, 1, cfg.mapWidth * 2, cfg.mapHeight, " ")
  drawPredict(nextObj)
  if cfg.drawShadow then
    drawObject(gCanvas, sObj, cfg.shadowColor)
  end
end

function GameHandle()
  local dX = 0
  local dY = 0
  local dR = 0
  if control.l then
    dX = dX - 1
  end
  if control.r then
    dX = dX + 1
  end
  if control.d then
    dY = 1
  end
  if control.u then
    dR = -1
    control.u = false
  end
  -- control = {}

  tick = (tick + 1) % cfg.fallTickCnt
  
  local moved = false
  local shadowMoved = false
  local tObj = cloneObject(fObj)
  
  if dX ~= 0 then
    fObj.x = fObj.x + dX
    if not check(fObj) then
      fObj.x = fObj.x - dX
    else
      moved = true
      shadowMoved = true
    end
  end
  if dR ~= 0 then
    fObj.rotate = (fObj.rotate - 1 + dR + #StockBlocks[fObj.id].transformations) % (#StockBlocks[fObj.id].transformations) + 1
    if not check(fObj) then
      fObj.rotate = (fObj.rotate - 1 - dR + #StockBlocks[fObj.id].transformations) % (#StockBlocks[fObj.id].transformations) + 1
    else
      moved = true
      shadowMoved = true
    end
  end
  
  local freeze = false
  if dY ~= 0 then
    tick = 0
    fObj.y = fObj.y + dY
    if not check(fObj) then
      freeze = true
      fObj.y = fObj.y - dY
    else
      moved = true
    end
  elseif tick == 0 then
    fObj.y = fObj.y + 1
    if not check(fObj) then
      freeze = true
      fObj.y = fObj.y - 1
    else
      moved = true
    end
  end
  
  if cfg.drawShadow and shadowMoved then
    drawObject(gCanvas, sObj, cfg.backColor)
    sObj = createShadow(fObj)
    drawObject(gCanvas, sObj, cfg.shadowColor)
  end
  if moved then
    drawObject(gCanvas, tObj, cfg.backColor)
    drawObject(gCanvas, fObj)
  end
  if freeze then
    putInMap(fObj)
    IncreaseScore(linePoints[clearLines()])
    fObj = nextObj
    fObj.x, fObj.y = StockBlocks[fObj.id].start_position.x + cfg.startX, StockBlocks[fObj.id].start_position.y
    if not check(fObj) then
      gui.backend.MessageBox:Create("GAME OVER", "Your score: "..GetScore()):Modify{ScreenWidth = cfg.mapWidth * 2, ScreenHeight = cfg.mapHeight}:Init():Paint()
      -- messageBox("GAME OVER","Your score: "..GetScore())
      -- gpu.setForeground(0xffffff)
      isRunning = false
    else
      clearLines()
    end
    if cfg.drawShadow then
      sObj = createShadow(fObj)
      drawObject(gCanvas, sObj, cfg.shadowColor)
    end
    drawObject(gCanvas, fObj)
    nextObj = createObject(nil, 1, 2)
    drawPredict(nextObj)
  end
  
  os.sleep(cfg.tickDelay)
end

function onKeyDown(ev, _, code1, code2, player)
  if (code1==113)and(code2==16) then
    isRunning = false -- TODO REMOVE
  elseif (code1==0) then
    if code2 == 203 then--left
      control.l = true
    elseif code2==200 then--up
      control.u = true
    elseif code2==205 then--right
      control.r = true
    elseif code2==208 then--down
      control.d = true
    end
  end
end

function onKeyUp(ev, _, code1, code2, player)
  if code2 == 203 then--left
    control.l = false
  elseif code2==200 then--up
    -- control.u = false
  elseif code2==205 then--right
    control.r = false
  elseif code2==208 then--down
    control.d = false
  end
end
-------------------- GUI --------------------
local quit = false
gui.Init()

GameForm = gui.backend.Form:Create(cfg.mapWidth * 2 + 12, cfg.mapHeight,
  {
    canvas = gui.backend.Canvas:Create(1, 1, cfg.mapWidth * 2, cfg.mapHeight),
    panel = gui.CreateGroup(
    {
      OnPaint = function(self)
        gpu.setBackground(0x222222)
        gpu.fill(self.X, 1, self.Width, cfg.mapHeight, " ")
      end
    },
    {
      canvas = gui.backend.Canvas:Create(3, 1, 8, 4),
      gui.backend.Text:Create(1, 6, 12, "Score:"):Modify{BackColor = 0x222222},
      score = gui.backend.Text:Create(1, 7, 12, "0"):Modify{BackColor = 0x222222},
      -- gui.backend.CheckBox:Create(1, 9, 12, "Shadow", true):Modify{BackColor = 0x222222},
      gui.backend.Button:Create(1, 9, 12, 1, "New Game", function(self)
        -- if isRunning then
          -- self.Text = "Start"
        -- else
          -- self.Text = "Restart"
        -- end
        -- self:Paint()
        -- gpu.set(1, 1, self.Parent.Elements["pause"].X .. " " .. self.Parent.Elements["pause"].Y)os.sleep(1)
        self.Parent.Elements["pause"]:Modify{Text = "Pause"}:Paint()
        GameInit()
        DrawMap()
        isInited = true
        isRunning = true
      end),
      pause = gui.backend.Button:Create(1, 11, 12, 1, "Pause", function(self)
        if not isInited then
          return
        end
        if isRunning then
          self.Text = "Resume"
        else
          self.Text = "Pause"
        end
        -- isRunning = false
        isRunning = not isRunning
        self:Paint()
      end),
      gui.backend.Button:Create(1, 13, 12, 1, "Settings", function(self)
        -- self.Parent.Elements["pause"]:OnElementClick()
        isRunning = false
        isInited = false
        self.Parent.Elements["pause"].Text = "Pause"
        GameForm:Disable(true)
        SettingsForm:Enable():Paint()
      end),
      gui.backend.Button:Create(1, 15, 12, 1, "Exit", function() quit = true end),
    }, cfg.mapWidth * 2 + 1, gui.GetCenter(1, cfg.mapHeight, 15), 12, cfg.mapHeight),
  }
):Init()

SettingsForm = gui.backend.Form:Create(20, 13,
  {
    gui.backend.Text:Create(1, 1, 20, "Settings"),
    
    gui.backend.Text:Create(1, 3, nil, "Width"),
    MapWidth = gui.backend.TextBox:Create(1, 4, 20, cfg.mapWidth .. "", "0123456789"),
    MapWidthError = gui.backend.Text:Create(1, 5, nil, ""):Modify{TextColor = 0xff0000},
    
    gui.backend.Text:Create(1, 6, nil, "Height"),
    MapHeight = gui.backend.TextBox:Create(1, 7, 20, cfg.mapHeight .. "", "0123456789"),
    MapHeightError = gui.backend.Text:Create(1, 8, nil, ""):Modify{TextColor = 0xff0000},
    
    DrawShadow = gui.backend.CheckBox:Create(1, 9, 0, "Draw Shadow", cfg.drawShadow),
    
    gui.backend.Button:Create(1, 11, 20, 3, "Back", function()
      cfg.mapWidth = SettingsForm.Elements["MapWidth"].Text + 0
      cfg.startX = gui.GetCenter(1, cfg.mapWidth, 1) - 1
      width = cfg.mapWidth + 10
      cfg.mapHeight = SettingsForm.Elements["MapHeight"].Text + 0
      cfg.drawShadow = SettingsForm.Elements["DrawShadow"].Checked
      SettingsForm.Elements["MapWidthError"]:Modify{Text = ""}:Paint()
      SettingsForm.Elements["MapWidth"]:Modify{TextColor = 0xffffff}:Paint()
      SettingsForm.Elements["MapHeightError"]:Modify{Text = ""}:Paint()
      SettingsForm.Elements["MapHeight"]:Modify{TextColor = 0xffffff}:Paint()
      
      local err, msg = ValidateConfig()
      if err ~= nil then
        SettingsForm.Elements[err]:Modify{Text = msg}:Paint()
        SettingsForm.Elements[unicode.sub(err, 1, -6)]:Modify{TextColor = 0xff0000}:Paint()
        return false
      end
      
      GameForm.Width = cfg.mapWidth * 2 + 12
      local offsetX = cfg.mapWidth * 2 + 1 - GameForm.Elements["panel"].X
      local offsetY = gui.GetCenter(1, cfg.mapHeight, 15) - GameForm.Elements["panel"].Y
      -- GameForm.Elements["panel"].X = cfg.mapWidth * 2 + 1
      for index, element in pairs(GameForm.Elements["panel"].Elements) do
        element.X = element.X + offsetX
        element.Y = element.Y + offsetY
      end
      GameForm.Elements["panel"].Elements["canvas"]:Init() -- kostil need fix
      GameForm.Elements["panel"].X = GameForm.Elements["panel"].X + offsetX
      GameForm.Elements["panel"].Y = GameForm.Elements["panel"].Y + offsetY
      GameForm.Height = cfg.mapHeight
      SettingsForm:Disable(true)
      GameForm:Enable():Paint()
    end),
  }
):Init()

GameForm:Enable():Paint()

gCanvas = GameForm.Elements["canvas"]
pCanvas = GameForm.Elements["panel"].Elements["canvas"]
scoreObj = GameForm.Elements["panel"].Elements["score"]


-- GameInit()
-- DrawMap()
event.ignore("key_down", onKeyDown)
event.listen("key_down", onKeyDown)
event.ignore("key_up", onKeyUp)
event.listen("key_up", onKeyUp)

local suc, err = pcall(function()
  while not quit do
    if isRunning then
      GameHandle()
    else
      event.pull()
    end
  end
end)

if not suc then
  print(err)
  os.sleep(3)
end

gui.Destroy()
event.ignore("key_down", onKeyDown)
event.ignore("key_up", onKeyUp)
gpu.setBackground(0x000000)
gpu.setForeground(0xffffff)