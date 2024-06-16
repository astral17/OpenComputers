local gui = require("AGUI") -- pastebin get s4UFSFwn /lib/AGUI.lua


----------SETTINGS----------
local cfg = {}
cfg.mapWidth = 80
cfg.mapHeight = 49
--local SUPERQUALITY = true
--local GENERATORMODE = 0 -- 0 - absolute random; 1 - specific random
local startX = 1
local startY = 2
local colors = {0xff0000, 0x00ff00, 0x0000ff}--, 0xffffff}
colors[0] = 0x000000

function scoreFormula(blocks)
  if blocks < 1 then
    return 0
  end
  return (blocks - 1) * (blocks - 1)
end

----------------------------

local event = require("event")
local gpu = require("component").gpu
local term = require("term")

local score = 0
local map = {}

function drawBlock(x, y)
  gpu.setBackground(colors[ map[y][x] ])
  gpu.set((startX + x - 1) * 2 - 1, startY + y - 1, "  ")
end

function fillBlocks(x, y, w, h)
  gpu.setBackground(0x000000)
  gpu.fill((startX + x - 1) * 2 - 1, startY + y - 1, w * 2, h, " ")
end

function drawScore(score)
  gpu.setBackground(0x000000)
  gpu.setForeground(0xffffff)
  gpu.set(10, 1, "score: " .. tostring(score))
end

function drawMap(startX, startY)
  drawScore(score)
  if startX == nil then
    startX = 1
  end
  if startY == nil then
    startY = 1
  end
--  term.clear()
  for y = 1, cfg.mapHeight do
    for x = 1, cfg.mapWidth do
      gpu.setBackground(colors[ map[y][x] ])
      gpu.set((startX + x - 1) * 2 - 1, startY + y - 1, "  ")
    end
  end
end

compressXCount = {}

function compressXPrecalc(noCheat) -- cheat if generator no create empty cell
  if noCheat == nil then
    for x = 1, cfg.mapWidth do
      compressXCount[x] = cfg.mapHeight
    end
  else
    for x = 1, cfg.mapWidth do
      for y = 1, cfg.mapHeight do
        if map[y][x] ~= 0 then
          compressXCount[x] = compressXCount[x] + 1
        end
      end
    end
  end
end

function mapGenerate()
  map = {}
  for i = 1, cfg.mapHeight do
    table.insert(map,{})
  end
  for y = 1, cfg.mapHeight do
    for x = 1, cfg.mapWidth do
      map[y][x] = math.random(1,#colors)
    end
  end
  compressXPrecalc()
  compressYQueue = {}
end

function convertX(x)
  return math.floor((x - 1) / 2) + 2 - startX
end

function convertY(y)
  return y - startY + 1
end

function canDestroy(x, y)
  if x > 1 then
    if map[y][x - 1] == map[y][x] then
      return true
    end
  end
  if x < cfg.mapWidth then
    if map[y][x + 1] == map[y][x] then
      return true
    end
  end
  if y > 1 then
    if map[y - 1][x] == map[y][x] then
      return true
    end
  end
  if y < cfg.mapHeight then
    if map[y + 1][x] == map[y][x] then
      return true
    end
  end
  return false
end

--compressXQueue = {}
compressYQueue = {}

function destroy(x, y, draw)
--  print(x, y)
  if map[y][x] == 0 then
    return 0
  end
  compressXCount[x] = compressXCount[x] - 1
--  if compressXCount[x] == 0 then
--    table.insert(compressXQueue, x)
--  end
  compressYQueue[x] = true
  local count = 1
  local saved = map[y][x]
  map[y][x] = 0
  if draw == true then
    drawBlock(x, y)
  end
  if x > 1 then
    if map[y][x - 1] == saved then
      count = count + destroy(x - 1, y)
    end
  end
  if x < cfg.mapWidth then
    if map[y][x + 1] == saved then
      count = count + destroy(x + 1, y)
    end
  end
  if y > 1 then
    if map[y - 1][x] == saved then
      count = count + destroy(x, y - 1)
    end
  end
  if y < cfg.mapHeight then
    if map[y + 1][x] == saved then
      count = count + destroy(x, y + 1)
    end
  end
  return count
end

function compressX()
  offset = 0
  for x = 1, cfg.mapWidth do
--  for _, x in pairs(compressXQueue) do
    b = (compressXCount[x] == 0)
--[[
    for y = 1, cfg.mapHeight do
      if map[y][x] ~= 0 then
        b = false
        break
      end
    end--]]
    if b then
      gpu.copy((startX + x - offset) * 2 - 1, startY, cfg.mapWidth * 2, cfg.mapHeight, -2, 0)
      offset = offset + 1
    elseif offset > 0 then
      for y = 1, cfg.mapHeight do
        map[y][x - offset] = map[y][x]
        map[y][x] = 0
      end
      compressXCount[x - offset] = compressXCount[x]
    end
  end
  compressXQueue = {}
  fillBlocks(cfg.mapWidth - offset + 1, 1, offset, cfg.mapHeight)
end

function compressY()
--  for x = 1, cfg.mapWidth do
  for x in pairs(compressYQueue) do
    offset = 0
    for y = cfg.mapHeight, 1, -1 do
      if map[y][x] == 0 then
--        drawBlock(x, y)
        offset = offset + 1
      elseif offset > 0 then
        map[y + offset][x] = map[y][x]
        map[y][x] = 0
        drawBlock(x, y + offset)
        drawBlock(x, y)
      end
    end
    fillBlocks(x, 1, 1, offset)
--[[
    for y = 1, offset do
      drawBlock(x, y)
    end--]]
  end
  compressYQueue = {}
end

function onTouch(_, _, x, y, _, name)
--  print(x,y,name)
  x = convertX(x)
  y = convertY(y)
--  print(x,y,canDestroy(x,y))
  if canDestroy(x, y) then
    score = score + scoreFormula(destroy(x, y))
    --print("DESTROYED")
    compressY()
    compressX()
    drawScore(score)
--    drawMap(startX, startY)
  end
end

-------------------- GUI --------------------
gui.Init()

GameForm = gui.backend.Form:Create(cfg.mapWidth * 2, cfg.mapHeight + 1,
  {
    gui.backend.Button:Create(1, 1, 8, 1, "[Return]", function()
      event.ignore("touch", onTouch)
      GameForm:Disable(true)
      MainForm:Enable():Paint()
    end),
  }
):Init()

SettingsForm = gui.backend.Form:Create(20, 11,
  {
    gui.backend.Text:Create(1, 1, 20, "Settings"),
    
    gui.backend.Text:Create(1, 3, nil, "Width"),
    Width = gui.backend.TextBox:Create(1, 4, 20, cfg.mapWidth .. "", "0123456789"),
    
    gui.backend.Text:Create(1, 6, nil, "Height"),
    Height = gui.backend.TextBox:Create(1, 7, 20, cfg.mapHeight .. "", "0123456789"),
    
    gui.backend.Button:Create(1, 9, 20, 3, "Back", function()
      cfg.mapWidth = SettingsForm.Elements["Width"].Text + 0
      cfg.mapHeight = SettingsForm.Elements["Height"].Text + 0
      GameForm.Width = cfg.mapWidth * 2
      GameForm.Height = cfg.mapHeight + 1
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
      mapGenerate()
      score = 0
      drawMap(startX, startY)
      -- event.ignore("touch", onTouch)
      event.listen("touch", onTouch)
    end),
    gui.backend.Button:Create(1, 5, 20, 3, "Settings", function() MainForm:Disable(true) SettingsForm:Enable():Paint() end),
    gui.backend.Button:Create(1, 9, 20, 3, "Exit", function() quit = true end),
  }
)

MainForm:Init():Enable():Paint()

quit = false
pcall(function()
  while not quit do
    event.pull()
  end
end)

-- gpu.setBackground(0x000000)
-- term.clear()
-- mapGenerate()
-- drawMap(startX, startY)

-- event.pull("key_down")
gui.Destroy()
event.ignore("touch",onTouch)
--]]
--drawMap(startX, startY)
gpu.setBackground(0x000000)
gpu.setForeground(0xffffff)