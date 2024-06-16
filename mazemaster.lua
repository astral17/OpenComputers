-- TODO
-- REMAKED system of group draw functions -- NEEDS BEAUTY
-- REMAKED WIN messageBox as AGUI object -- NEEDS BEAUTY
-- FIXED hunt&kill can make loops
-- CHANGED Recursive algorithm now start from rnd point
-- ADDED start and finish point setting
-- ADDED Validator maze size, start and finish points
-- REMAKED Config Menu
-- ADD TextBox check function (do not need anymore)
-- ADD When Disabled TextBox Painted have another color
-- ADD config saver and checker for correct data
-- ADD PathFinder for help -- IN PROGRESS (~70%)
-- ADD Color Points (mb 1-3 colors) -- IN PROGRESS (~75%)
-- ADD new algorithms for maze generator
-- ADD Mode where Camera move with character
-- ADD Braille draw mode (only draw, not playable)
-- FIX HalfSymbol mode if you stand above exit it is erased
-- ADD Kruskal algorithm
local AGUI_VERSION = "0.5"
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
local unicode = require("unicode")
--------------SETTINGS----------------
local cfg = {}
cfg.MapWidth = 159 --79
cfg.MapHeight = 97 --49
cfg.Algorithm = "recursive"--"hunt&kill" -- ("recursive"/"hunt&kill")
local WallColor = 0x666666
local FloorColor = 0x000000
local PlayerColor = 0xffff00
local ExitColor = 0x00ff00
local PathColor = 0x0000ff
local MarkerColor = 0xff0000 -- mb more colors
local Qualities = {DoubleSpace = 0, HalfSymbol = 1, Braille = 2} -- not optimal for speed but more beautiful
local Cells = {Empty = 0, Wall = 1, Exit = 2, Path = 3, Marker = 4}
local offsetY = 1
cfg.Quality = Qualities.HalfSymbol
-- cfg.Quality = Qualities.DoubleSpace
cfg.AllowPathFinder = true
cfg.AllowMarkers = true
cfg.StartX = 2
cfg.StartY = 2
cfg.FinishX = -1
cfg.FinishY = -1

function InRange(value, left, right)
  return left <= value and value <= right
end

function UpdateScreenSettings()
  if cfg.Quality == Qualities.HalfSymbol then
    cfg.ScreenWidth = cfg.MapWidth
    cfg.ScreenHeight = math.floor((cfg.MapHeight + 1) / 2) + offsetY
  else
    cfg.ScreenWidth = cfg.MapWidth * 2
    cfg.ScreenHeight = cfg.MapHeight + offsetY
  end
end

function ValidateConfig()
  local MaxScreenWidth, MaxScreenHeight
  MaxScreenWidth, MaxScreenHeight = gpu.maxResolution()
  UpdateScreenSettings()
  
  if not InRange(cfg.ScreenWidth, 8, MaxScreenWidth) then
    return "MapWidthError", "out of bounds"
  end
  if cfg.MapWidth % 2 == 0 then
    return "MapWidthError", "only odd value"
  end
  
  if not InRange(cfg.ScreenHeight, 5, MaxScreenHeight) then
    return "MapHeightError", "out of bounds"
  end
  if cfg.MapHeight % 2 == 0 then
    return "MapHeightError", "only odd value"
  end
  
  local x, y
  x, y = (cfg.StartX + cfg.MapWidth - 1) % cfg.MapWidth + 1, (cfg.StartY + cfg.MapHeight - 1) % cfg.MapHeight + 1
  if x % 2 == 1 then
    return "StartXError", "only even point"
  end
  if y % 2 == 1 then
    return "StartYError", "only even point"
  end
  
  x, y = (cfg.FinishX + cfg.MapWidth - 1) % cfg.MapWidth + 1, (cfg.FinishY + cfg.MapHeight - 1) % cfg.MapHeight + 1
  if not InRange(x, 1, cfg.MapWidth) then
    return "FinishXError", "out of bounds"
  end
  if x % 2 == 1 then
    return "FinishXError", "only even point"
  end
  if not InRange(y, 1, cfg.MapHeight) then
    return "FinishYError", "out of bounds"
  end
  if y % 2 == 1 then
    return "FinishYError", "only even point"
  end
end

--UpdateScreenSettings()
local err, msg = ValidateConfig()
if err ~= nil then
  print(err, msg)
  os.exit()
end
--------------------------------------
local map = {}
local distMap = {}
local markerMap = {}
local size = 200 -- width map mas NEED CHANGE TO cfg.MapWidth

local isRunning = false
local quit = false
local plx, ply, finX, finY

local algorithms = {}
local Draw = {}
local DIR = {{x = 0, y = -1}, {x = -1, y = 0}, {x = 1, y = 0}, {x = 0, y = 1}}
-----------------------
-- DEPRECATED
-- function centerText(x, y, w, text)
  -- gpu.set(x+math.floor(w/2-string.len(text)/2),y,text)
-- end

-- function messageBox(title,text,color)
  -- local x,y=(cfg.MapWidth-6)/((cfg.Quality and 2)or 1),(math.floor(cfg.MapHeight/2)-3)/((cfg.Quality and 2)or 1)
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
  -- centerText(x,y+6,len3,"OK")
-- end
-----------------------

function toXY(num) -- its slow
  local y=math.floor((num-1)/size)+1
  return num-(y-1)*size,y
end
function fromXY(x,y)
  return (y-1)*size+x
end

function clearMap()
  for x=1,cfg.MapWidth+10 do
    for y=1,cfg.MapHeight+10 do
      if (x%2==0)and(y%2==0) then
        map[fromXY(x, y)] = nil
      else
        map[fromXY(x, y)] = Cells.Wall
      end
    end
  end
  markerMap = {}
  -- markerMap[fromXY(2,2)] = true
  -- markerMap[fromXY(2,3)] = true
end

--DoubleSpace
Draw[Qualities.DoubleSpace] = {}
Draw[Qualities.DoubleSpace].Map = function()
  gpu.setBackground(WallColor)
  gpu.fill(1, 1 + offsetY, cfg.MapWidth * 2, cfg.MapHeight, " ")
  gpu.setBackground(FloorColor)
  for x=1,cfg.MapWidth do
    for y=1,cfg.MapHeight do
      if map[fromXY(x,y)] ~= Cells.Wall then
        gpu.set(x * 2 - 1, y + offsetY, "  ")
        -- gpu.set(x * 2 - 1, y + offsetY, (distMap[fromXY(x, y)] < 10 and "0" or "")..tostring(distMap[fromXY(x, y)]))
      end
    end
  end
end

Draw[Qualities.DoubleSpace].Point = function(x, y, col)
  gpu.setBackground(col or (markerMap[fromXY(x, y)] and MarkerColor or FloorColor))
  gpu.set(x * 2 - 1, y + offsetY, "  ")
  gpu.setBackground(0x000000)
  -- gpu.setBackground(0xffff00)
  -- gpu.set(3,2 + offsetY,"  ")
  -- gpu.setBackground(0x00ff00)
  -- gpu.set((cfg.MapWidth-1)*2-1,cfg.MapHeight-1 + offsetY,"  ")
  -- gpu.setBackground(0x000000)
end

Draw[Qualities.DoubleSpace].Path = function(x, y)
  local point = Draw[Qualities.DoubleSpace].Point
  local b
  while distMap[fromXY(x, y)] ~= 0 do
    point(x, y, PathColor)
    b = true
    for dr = 1, 4 do
      if distMap[fromXY(x + DIR[dr].x, y + DIR[dr].y)] ~= nil and distMap[fromXY(x + DIR[dr].x, y + DIR[dr].y)] < distMap[fromXY(x, y)] then
        x, y = x + DIR[dr].x, y + DIR[dr].y
        b = false
        break
      end
    end
    if b then
      break
    end
  end
end

--HalfSymbol
Draw[Qualities.HalfSymbol] = {}
local PIX={[0]=" ",[1]="▀",[2]="▄",[3]="█"}

Draw[Qualities.HalfSymbol].Map = function()
  gpu.setBackground(FloorColor)
  gpu.setForeground(WallColor)
  local s,tmp="none",0
  for y=2,cfg.MapHeight+1,2 do
--      s=""
    s = {}
    for x=1,cfg.MapWidth do
      tmp=0
      if map[fromXY(x,y-1)] == Cells.Wall then
        tmp=tmp+1
      end
      if (map[fromXY(x,y)] == Cells.Wall)and(y~=cfg.MapHeight+1) then
        tmp=tmp+2
      end
--        s=s..PIX[tmp]
      table.insert(s, PIX[tmp])
    end
    -- if y==52 then
     -- print("1"..s.."1")
    -- end
    s = table.concat(s)
    gpu.set(1, math.floor(y / 2) + offsetY, s)
  end
  gpu.setForeground(0xffffff)
  gpu.setBackground(0x000000)
end

Draw[Qualities.HalfSymbol].Point = function(x, y, color, full)
  local TopColor, BottomColor
  if full then
    TopColor    = color
    BottomColor = color
  else
    if y%2 == 0 then
      TopColor    = map[fromXY(x, y - 1)] == Cells.Wall and WallColor or (markerMap[fromXY(x, y - 1)] and MarkerColor or FloorColor)
      BottomColor = color or (markerMap[fromXY(x, y)] and MarkerColor or FloorColor)
    else
      TopColor    = color or (markerMap[fromXY(x, y)] and MarkerColor or FloorColor)
      BottomColor = map[fromXY(x, y + 1)] == Cells.Wall and WallColor or (markerMap[fromXY(x, y + 1)] and MarkerColor or FloorColor)
    end
  end
  
  gpu.setForeground(TopColor)
  gpu.setBackground(BottomColor)
  gpu.set(x, math.floor((y + 1) / 2) + offsetY, PIX[1])
  gpu.setBackground(0x000000)
  gpu.setForeground(0xffffff)
end

Draw[Qualities.HalfSymbol].Path = function(x, y)
  local point = Draw[Qualities.HalfSymbol].Point
  local nY
  local fullDraw = false
  for dr = 1, 4 do
    if distMap[fromXY(x + DIR[dr].x, y + DIR[dr].y)] ~= nil and distMap[fromXY(x + DIR[dr].x, y + DIR[dr].y)] < distMap[fromXY(x, y)] then
      x, y = x + DIR[dr].x, y + DIR[dr].y
      break
    end
  end
  while distMap[fromXY(x, y)] ~= 0 do
    point(x, y, PathColor, fullDraw)
    fullDraw = false
    nY = nil
    for dr = 1, 4 do
      if distMap[fromXY(x + DIR[dr].x, y + DIR[dr].y)] ~= nil and distMap[fromXY(x + DIR[dr].x, y + DIR[dr].y)] < distMap[fromXY(x, y)] then
        x, nY = x + DIR[dr].x, y + DIR[dr].y
        break
      end
    end
    if nY == nil then
      break
    end
    if math.floor((nY + 1) / 2) == math.floor((y + 1) / 2) and nY ~= y then
      fullDraw = true
    end
    y = nY
  end
end

-- Draw[Qualities.HalfSymbol].Point = function(x, y, col)
  -- local tmp=0
  -- if y%2==0 then
    -- if map[fromXY(x,y-1)]==false then
      -- gpu.setBackground(0x000000)
    -- else
      -- gpu.setBackground(0x666666)
    -- end
    -- gpu.setForeground(col or 0xffff00)
    -- tmp=2
  -- elseif (x==cfg.MapWidth-1)and(y==cfg.MapHeight-2) then
    -- gpu.setBackground(0x00ff00)
    -- gpu.setForeground(col or 0xffff00)
    -- tmp=1
  -- else
    -- if map[fromXY(x,y+1)]==false then
      -- gpu.setBackground(0x000000)
    -- else
      -- gpu.setBackground(0x666666)
    -- end
    -- gpu.setForeground(col or 0xffff00)
    -- tmp=1
  -- end
  -- gpu.set(x, math.floor((y-1)/2) + 1 + offsetY, PIX[tmp])
-- end

--[[
function drawMap()
  if cfg.Quality then
    gpu.setBackground(0x000000)
    gpu.setForeground(0x666666)
    local s,tmp="none",0
    for y=2,cfg.MapHeight+1,2 do
     -- s=""
      s = {}
      for x=1,cfg.MapWidth do
        tmp=0
        if map[fromXY(x,y-1)] then
          tmp=tmp+1
        end
        if (map[fromXY(x,y)])and(y~=cfg.MapHeight+1) then
          tmp=tmp+2
        end
       -- s=s..PIX[tmp]
        table.insert(s, PIX[tmp])
      end
      -- if y==52 then
       -- print("1"..s.."1")
      -- end
      s = table.concat(s)
      gpu.set(1, math.floor(y / 2) + offsetY, s)
    end
    gpu.setForeground(0xffffff)
  else
    gpu.setBackground(0x666666)
    gpu.fill(1, 1 + offsetY, cfg.MapWidth * 2, cfg.MapHeight, " ")
    gpu.setBackground(0x000000)
    for x=1,cfg.MapWidth do
      for y=1,cfg.MapHeight do
        if not map[fromXY(x,y)] then
          gpu.set(x * 2 - 1, y + offsetY, "  ")
        end
      end
    end
  end
  gpu.setBackground(0x000000)
end
--]]

algorithms["recursive"] = function()
  local stack={}
  local stklen,step=1,0
  local posx, posy = math.random(1, math.floor(cfg.MapWidth / 2)) * 2,math.random(1, math.floor(cfg.MapHeight / 2)) * 2
  stack[1]={x=posx,y=posy}
  while stklen>0 do
--    step=(step+1)%1000
--    os.sleep(0)
    map[fromXY(stack[stklen].x,stack[stklen].y)] = Cells.Empty
--    drawMap()
    local bool,tmp=true,true
    while bool do
      tmp=false
      local rnd=math.random(0,3)
      if (map[fromXY(stack[stklen].x-2,stack[stklen].y)]==nil)and(stack[stklen].x-1~=1) then
        tmp=true
        if rnd==0 then
          map[fromXY(stack[stklen].x-1,stack[stklen].y)] = Cells.Empty
          stklen=stklen+1
          stack[stklen]={x=stack[stklen-1].x-2,y=stack[stklen-1].y}
          break
        end
      end
      if (map[fromXY(stack[stklen].x+2,stack[stklen].y)]==nil)and(stack[stklen].x+1~=cfg.MapWidth) then
        tmp=true
        if rnd==1 then
          map[fromXY(stack[stklen].x+1,stack[stklen].y)] = Cells.Empty
          stklen=stklen+1
          stack[stklen]={x=stack[stklen-1].x+2,y=stack[stklen-1].y}
          break
        end
      end
      if (map[fromXY(stack[stklen].x,stack[stklen].y-2)]==nil)and(stack[stklen].y-1~=1) then
        tmp=true
        if rnd==2 then
          map[fromXY(stack[stklen].x,stack[stklen].y-1)] = Cells.Empty
          stklen=stklen+1
          stack[stklen]={x=stack[stklen-1].x,y=stack[stklen-1].y-2}
          break
        end
      end
      if (map[fromXY(stack[stklen].x,stack[stklen].y+2)]==nil)and(stack[stklen].y+1~=cfg.MapHeight) then
        tmp=true
        if rnd==3 then
          map[fromXY(stack[stklen].x,stack[stklen].y+1)] = Cells.Empty
          stklen=stklen+1
          stack[stklen]={x=stack[stklen-1].x,y=stack[stklen-1].y+2}
          break
        end
      end
      bool=tmp
    end
    if not tmp then
      stklen=stklen-1
    end
  end
end

algorithms["hunt&kill"] = function()
  local function testField()
    for j=2,cfg.MapHeight,2 do
      for i=2,cfg.MapWidth,2 do
        if map[fromXY(i,j)]==nil then
          for dr=1,4 do
            if map[fromXY(i+DIR[dr].x*2,j+DIR[dr].y*2)] == Cells.Empty then
              map[fromXY(i,j)] = Cells.Empty
              map[fromXY(i+DIR[dr].x,j+DIR[dr].y)] = Cells.Empty
              return i,j
            end
          end
        end
      end
    end
    return false
  end
  local isRunning,tmp=true,true
  local posx,posy,rnd=math.random(1,math.floor(cfg.MapWidth/2))*2,math.random(1,math.floor(cfg.MapHeight/2))*2,0
  while isRunning do
    tmp=true
    map[fromXY(posx, posy)] = Cells.Empty
    while tmp do
      tmp=false
      rnd=math.random(1,4)
      for dr=1,4 do
        if (map[fromXY(posx+DIR[dr].x*2,posy+DIR[dr].y*2)]==nil)and(posx+DIR[dr].x~=1)and(posx+DIR[dr].x~=cfg.MapWidth)and(posy+DIR[dr].y~=1)and(posy+DIR[dr].y~=cfg.MapHeight) then
          tmp=true
          if rnd==dr then
            map[fromXY(posx+DIR[dr].x,posy+DIR[dr].y)] = Cells.Empty
            map[fromXY(posx+DIR[dr].x*2,posy+DIR[dr].y*2)] = Cells.Empty
            posx,posy=posx+DIR[dr].x*2,posy+DIR[dr].y*2
            break
          end
        end
      end
    end
    -- Draw[cfg.Quality].Map();os.sleep(0)
    posx,posy=testField()
    if posx==false then
      isRunning=false
    end
  end
end

-- function drawPoint(x,y,col)
  -- local tmp=0
  -- if y%2==0 then
    -- if map[fromXY(x,y-1)]==false then
      -- gpu.setBackground(0x000000)
    -- else
      -- gpu.setBackground(0x666666)
    -- end
    -- gpu.setForeground(col or 0xffff00)
    -- tmp=2
  -- elseif (x==cfg.MapWidth-1)and(y==cfg.MapHeight-2) then
    -- gpu.setBackground(0x00ff00)
    -- gpu.setForeground(col or 0xffff00)
    -- tmp=1
  -- else
    -- if map[fromXY(x,y+1)]==false then
      -- gpu.setBackground(0x000000)
    -- else
      -- gpu.setBackground(0x666666)
    -- end
    -- gpu.setForeground(col or 0xffff00)
    -- tmp=1
  -- end
  -- gpu.set(x, math.floor((y-1)/2) + 1 + offsetY, PIX[tmp])
-- end

function onKeyDown(_, _, ch1, ch2)
  if ch1 == 112 and cfg.AllowPathFinder then
    -- isRunning=false
    Draw[cfg.Quality].Path(plx, ply)
  end
  if ch1 == 32 and cfg.AllowMarkers then
    markerMap[fromXY(plx, ply)] = not markerMap[fromXY(plx, ply)]
  end
  if ch1==0 then
--    print(ch2)
    if ch2==203 then
      lP=true
    elseif ch2==200 then
      uP=true
    elseif ch2==205 then
      rP=true
    elseif ch2==208 then
      dP=true
    end
  end
end

function onKeyUp(_,_,ch1,ch2)
  if ch1==0 then
    if ch2==203 then
      lP=false
    elseif ch2==200 then
      uP=false
    elseif ch2==205 then
      rP=false
    elseif ch2==208 then
      dP=false
    end
  end
end

function FindPath()
  local queue = {fromXY(finX, finY)}
  local queueFront = 1
  local x, y, cell, nextCell, dist
  distMap = {}
  distMap[ queue[1] ] = 0
  while queue[queueFront] ~= nil do
    cell = queue[queueFront]
    queueFront = queueFront + 1
    x, y = toXY(cell)
    dist = distMap[cell] + 1
    for dr = 1, 4 do
      if InRange(x + DIR[dr].x, 1, cfg.MapWidth) and InRange(y + DIR[dr].y, 1, cfg.MapHeight) then
        nextCell = fromXY(x + DIR[dr].x, y + DIR[dr].y)
        if distMap[nextCell] == nil and map[nextCell] ~= Cells.Wall then
          distMap[nextCell] = dist
          table.insert(queue, nextCell)
        end
      end
    end
  end
end

function GameInit()
  clearMap()
  plx, ply   = (cfg.StartX  + cfg.MapWidth - 1) % cfg.MapWidth + 1, (cfg.StartY  + cfg.MapHeight - 1) % cfg.MapHeight + 1
  finX, finY = (cfg.FinishX + cfg.MapWidth - 1) % cfg.MapWidth + 1, (cfg.FinishY + cfg.MapHeight - 1) % cfg.MapHeight + 1
  algorithms[cfg.Algorithm]()
  -- if cfg.Algorithm == "recursive" then
    -- generateMaze(cfg.StartX, cfg.StartY)
  -- elseif cfg.Algorithm == "hunt&kill" then
    -- generateMaze2()
  -- end
  FindPath()
  --os.sleep(2)
  -- drawMap()
  Draw[cfg.Quality].Map()
  
  -- Draw[cfg.Quality].Path(2, 2)
  Draw[cfg.Quality].Point(plx, ply, PlayerColor)
  Draw[cfg.Quality].Point(finX, finY, ExitColor)
  -- if cfg.Quality == Qualities.HalfSymbol then
    -- drawPoint(2,2)
    -- drawPoint(cfg.MapWidth-1,cfg.MapHeight-1,0x00ff00)
  -- else
    -- gpu.setBackground(0xffff00)
    -- gpu.set(3,2 + offsetY,"  ")
    -- gpu.setBackground(0x00ff00)
    -- gpu.set((cfg.MapWidth-1)*2-1,cfg.MapHeight-1 + offsetY,"  ")
    -- gpu.setBackground(0x000000)
  -- end
  lP, rP, uP, dP = false, false, false, false
  --
  event.listen("key_down",onKeyDown)
  event.listen("key_up",onKeyUp)
  isRunning = true
end

function GameHandle()
-- while isRunning do
  local plxb,plyb=plx,ply
  if (lP)and(map[fromXY(plx-1,ply)] ~= Cells.Wall) then--left
    plx=plx-1
  elseif (uP)and(map[fromXY(plx,ply-1)] ~= Cells.Wall) then--up
    ply=ply-1
  elseif (rP)and(map[fromXY(plx+1,ply)] ~= Cells.Wall) then--right
    plx=plx+1
  elseif (dP)and(map[fromXY(plx,ply+1)] ~= Cells.Wall) then--down
    ply=ply+1
  end
  if (plx~=plxb)or(ply~=plyb) then
    Draw[cfg.Quality].Point(plxb, plyb)
    Draw[cfg.Quality].Point(plx, ply, PlayerColor)
    
    -- if cfg.Quality then
      -- drawPoint(plxb,plyb,0x000000)
      -- drawPoint(plx,ply)
    -- else
      -- gpu.setBackground(0x000000)
      -- gpu.set(plxb*2-1,plyb + offsetY,"  ")
      -- gpu.setBackground(0xffff00)
      -- gpu.set(plx*2-1,ply + offsetY,"  ")
    -- end
    if (plx == finX) and (ply == finY) then
      isRunning = false
      --messageBox("congratulation","You Win!")
      gui.backend.MessageBox:Create("congratulation", "You Win!"):Modify{ButtonHandle = function() GameForm.Elements["Exit"]:OnElementClick() end}:Init():Paint()
    end
  end
  os.sleep(0.1)
-- end
end

-- event.ignore("key_down",onKeyDown)
-- event.ignore("key_up",onKeyUp)
-- map=nil
-- gpu.setBackground(0x000000)
-- gpu.setForeground(0xffffff)
--event.pull("key_down")

-------------------- GUI --------------------
gui.Init()

GameForm = gui.backend.Form:Create(cfg.ScreenWidth, cfg.ScreenHeight,
  {
    Exit = gui.backend.Button:Create(1, 1, 8, 1, "[Return]", function()
      event.ignore("key_down",onKeyDown)
      event.ignore("key_up",onKeyUp)
      isRunning = false
      GameForm:Disable(true)
      MainForm:Enable():Paint()
    end),
    
    algo = gui.backend.Text:Create(10, 1, nil, cfg.Algorithm),
  }
):Init()

SettingsForm = gui.backend.Form:Create(32, 15,
  {
    gui.backend.Text:Create(1, 1, 32, "Settings"),
    
    gui.backend.Text:Create(1, 3, 7, "Width"),
    MapWidth = gui.backend.TextBox:Create(1, 4, 7, cfg.MapWidth .. "", "0123456789"),
    MapWidthError = gui.backend.Text:Create(1, 5, nil, ""):Modify{TextColor = 0xff0000},
    
    gui.backend.Text:Create(9, 3, 7, "Height"),
    MapHeight = gui.backend.TextBox:Create(9, 4, 7, cfg.MapHeight .. "", "0123456789"),
    MapHeightError = gui.backend.Text:Create(1, 5, nil, ""):Modify{TextColor = 0xff0000},
    
    -- Quality = gui.backend.CheckBox:Create(1, 6, 20, "Super Quality", cfg.Quality == Qualities.HalfSymbol),
    gui.backend.Text:Create(1, 6, nil, "Graphic Mode"),
    Quality = gui.backend.RadioGroup:Create(
    {
      [Qualities.DoubleSpace] = gui.backend.RadioButton:Create(1, 7, 15, "DoubleSpace"),
      [Qualities.HalfSymbol]  = gui.backend.RadioButton:Create(1, 8, 15, "Half Symbol"),
    }, cfg.Quality),
    
    gui.backend.Text:Create(1, 10, nil, "Algorithm"),
    Algorithm = gui.backend.RadioGroup:Create(
    {
      ["recursive"] = gui.backend.RadioButton:Create(1, 11, 15, "Recursive"),
      ["hunt&kill"] = gui.backend.RadioButton:Create(1, 12, 15, "Hunt&Kill"),
    }, cfg.Algorithm),
    
    gui.backend.Text:Create(18, 3, 15, "Start Position"),
    StartX = gui.backend.TextBox:Create(18, 4, 7, cfg.StartX .. "", "0123456789"),
    StartXError = gui.backend.Text:Create(18, 5, nil, ""):Modify{TextColor = 0xff0000},
    StartY = gui.backend.TextBox:Create(26, 4, 7, cfg.StartY .. "", "0123456789"),
    StartYError = gui.backend.Text:Create(18, 5, nil, ""):Modify{TextColor = 0xff0000},
    
    gui.backend.Text:Create(18, 6, 15, "Finish Position"),
    FinishX = gui.backend.TextBox:Create(18, 7, 7, cfg.FinishX .. "", "0123456789"),
    FinishXError = gui.backend.Text:Create(18, 8, nil, ""):Modify{TextColor = 0xff0000},
    FinishY = gui.backend.TextBox:Create(26, 7, 7, cfg.FinishY .. "", "0123456789"),
    FinishYError = gui.backend.Text:Create(18, 8, nil, ""):Modify{TextColor = 0xff0000},
    
    gui.backend.Text:Create(18, 9, nil, "Another"),
    AllowMarkers = gui.backend.CheckBox:Create(18, 10, 15, "Markers", cfg.AllowMarkers),
    AllowPathFinder = gui.backend.CheckBox:Create(18, 11, 15, "PathFinder", cfg.AllowPathFinder),
    
    gui.backend.Button:Create(1, 13, 32, 3, "Back", function()
      cfg.MapWidth = SettingsForm.Elements["MapWidth"].Text + 0
      cfg.MapHeight = SettingsForm.Elements["MapHeight"].Text + 0
      cfg.StartX = SettingsForm.Elements["StartX"].Text + 0
      cfg.StartY = SettingsForm.Elements["StartY"].Text + 0
      cfg.FinishX = SettingsForm.Elements["FinishX"].Text + 0
      cfg.FinishY = SettingsForm.Elements["FinishY"].Text + 0
      cfg.Quality = SettingsForm.Elements["Quality"].Checked
      cfg.Algorithm = SettingsForm.Elements["Algorithm"].Checked
      cfg.AllowPathFinder = SettingsForm.Elements["AllowPathFinder"].Checked
      cfg.AllowMarkers = SettingsForm.Elements["AllowMarkers"].Checked
      -- UpdateScreenSettings()
      SettingsForm.Elements["MapWidthError"]:Modify{Text = ""}:Paint()
      SettingsForm.Elements["MapWidth"]:Modify{TextColor = 0xffffff}:Paint()
      SettingsForm.Elements["MapHeightError"]:Modify{Text = ""}:Paint()
      SettingsForm.Elements["MapHeight"]:Modify{TextColor = 0xffffff}:Paint()
      SettingsForm.Elements["StartXError"]:Modify{Text = ""}:Paint()
      SettingsForm.Elements["StartX"]:Modify{TextColor = 0xffffff}:Paint()
      SettingsForm.Elements["StartYError"]:Modify{Text = ""}:Paint()
      SettingsForm.Elements["StartY"]:Modify{TextColor = 0xffffff}:Paint()
      SettingsForm.Elements["FinishXError"]:Modify{Text = ""}:Paint()
      SettingsForm.Elements["FinishX"]:Modify{TextColor = 0xffffff}:Paint()
      SettingsForm.Elements["FinishYError"]:Modify{Text = ""}:Paint()
      SettingsForm.Elements["FinishY"]:Modify{TextColor = 0xffffff}:Paint()
      local err, msg = ValidateConfig()
      if err ~= nil then
        SettingsForm.Elements[err]:Modify{Text = msg}:Paint()
        SettingsForm.Elements[unicode.sub(err, 1, -6)]:Modify{TextColor = 0xff0000}:Paint()
        return false
      end
      GameForm.Width = cfg.ScreenWidth
      GameForm.Height = cfg.ScreenHeight
      GameForm.Elements["algo"].Text = cfg.Algorithm
      SettingsForm:Disable(true)
      MainForm:Enable():Paint()
    end),
  }
):Init()

MainForm = gui.backend.Form:Create(20, 11,
  {
    gui.backend.Button:Create(1, 1, 20, 3, "Start", function()
      MainForm:Disable(true)
      GameForm:Enable():Paint()
      GameInit()
    end),
    gui.backend.Button:Create(1, 5, 20, 3, "Settings", function() MainForm:Disable(true) SettingsForm:Enable():Paint() end),
    gui.backend.Button:Create(1, 9, 20, 3, "Exit", function() quit = true end),
  }
)

MainForm:Init():Enable():Paint()

quit = false
pcall(function()
  while not quit do
    if isRunning then
      GameHandle()
    else
      event.pull()
    end
  end
end)

gui.Destroy()
event.ignore("key_down",onKeyDown)
event.ignore("key_up",onKeyUp)

gpu.setBackground(0x000000)
gpu.setForeground(0xffffff)