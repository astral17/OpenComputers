-- ДОБАВИТЬ ТАБЛУ РЕКОРДОВ ; ДОБАВИТЬ КНОПКИ СЛОЖНОСТИ И РЕСТАРТА
local event=require("event")
local unicode = require("unicode")
local component=require("component")
local gpu=component.gpu
-----------------SETTINGS-------------------------
local cfg = {}
cfg.mapWidth = 30
cfg.mapHeight = 16
cfg.Mines = 99
-- local size=30
-- local MINES=100
-----------------------------------------------------------------------------------------------------------------
local SAVEW,SAVEH=gpu.getResolution()
gpu.setResolution(cfg.mapWidth * 2, cfg.mapHeight + 2)
local timerID=-1
local timeC={year=2000,month=0,day=0,min=0,sec=0}
local timeS=os.time(timeC)
local time=timeS
local tir = false
function onTick()
  time=time+1
  drawTimer(size*2-4,1)
  if time-timeS == 59*61 then
    stopTimer()
  end
end

function startTimer()
  time=timeS
  timerID=event.timer(1,onTick,math.huge)
end

function stopTimer()
  event.cancel(timerID)
end

function drawTimer(x,y)
  gpu.setBackground(0x333333)
  gpu.set(x,y,os.date("%M:%S",time))
  gpu.setBackground(0x999999)
end

-----------------------------------------------------------------------------------------------------------------
function centerText(x,y,w,text)
  gpu.set(x+math.floor(w/2-string.len(text)/2),y,text)
end

function messageBox(title,text,color)
  local x,y=size-7,math.floor(size/2)-3
  local len1,len2=string.len(title),string.len(text)
  local len3=math.max(len1,len2)+2
  gpu.setBackground(0xffffff)
  gpu.fill(x,y,len3,2+3," ")
  gpu.setForeground(color or 0xFF0000)
  centerText(x,y+1,len3,title)
  gpu.setForeground(0x000000)
  centerText(x,y+3,len3,text)
  gpu.setBackground(color or 0xFF0000)
  gpu.setForeground(0xffffff)
  gpu.fill(x,y+5,len3,3," ")
  centerText(x,y+6,len3,"OK!")
end
-----------------------------------------------------------------------------------------------------------------
local sym = unicode.char(0x25D6)..unicode.char(0x25D7)
local cnum = {0x0000FF,0x00FF00,0xFF0000,0x000055,0x550000,0x005500,0xFF00FF,0x000000}

-----------------------------------------------------------------------------------------------------------------
--[[size = 10
  tmp = 1

  size = 30
  tmp = 10

  size = 40
  tmp = 15--]]
--end
if dif == "легко" then
    mines = size+math.floor(size/7)*tmp
elseif dif == "средне" then
  mines = 2*size+math.floor(size/6)*tmp
elseif dif == "сложно" then
  mines = 3*size+math.floor(size/5)*tmp
end--]]
mines=MINES
flags = mines
openfield = 0
--------------------------------------- генерирование поля -----------------------------------------------
gpu.setBackground(0x333333)
gpu.fill(1,1,size*2,2," ")
local field = {}
for i = 0,size+1 do
  field[i] = {}
  for j = 0,size+1 do
    field[i][j] = {}
    field[i][j][0] = 0  -- -1 - мина, 1-8 кол-во мин вокруг
    field[i][j][1] = 0  -- 0 - закрыто, 1 - открыто, 2 - флажок
  end
end
gpu.setBackground(0x666666)
gpu.fill(1,3,size*2,size," ")
for i = 1,mines do
  x = math.random(1,size)
  y = math.random(1,size)
  while field[x][y][0] == -1 do
    x = math.random(1,size)
    y = math.random(1,size)
  end
  field[x][y][0] = -1
--      gpu.set(x*2+1,y+2,"#")
end
local tmp = 0
for x = 1,size do
  for y = 1, size do
--      print(field[x][y][0])
    if field[x][y][0] ~= -1 then
      tmp = 0
      if field[x-1][y-1][0] == -1 then
        tmp = tmp + 1
      end
      if field[x-1][y][0] == -1 then
        tmp = tmp + 1
      end
      if field[x-1][y+1][0] == -1 then
        tmp = tmp + 1
      end
      if field[x][y-1][0] == -1 then
        tmp = tmp + 1
      end
      if field[x][y+1][0] == -1 then
        tmp = tmp + 1
      end
      if field[x+1][y-1][0] == -1 then
        tmp = tmp + 1
      end
      if field[x+1][y][0] == -1 then
        tmp = tmp + 1
      end
      if field[x+1][y+1][0] == -1 then
        tmp = tmp + 1
      end
      field[x][y][0] = tmp
      tmp2 = tostring(tmp)
--        gpu.set(x*2,2+y,tmp2)
--        gpu.set(1+x*2,2+y,tmp2)
--        os.sleep(0.1)
    end
  end
end
gpu.setBackground(0x999999)
gpu.setForeground(0xFFFFFF)
--------------------------------------- обработка событий ------------------------------------------------
function usecell(x,y,type)
  if gamestate==false then
    return
  end
  if type == 0 then
    if (field[x][y][0] == -1)and(field[x][y][1] ~= 2) then
      for i = 1,size do
        for j = 1,size do
          if field[i][j][0]==-1 then
            gpu.setBackground((field[i][j][1]==2 and 0xFFFF00)or 0x666666)
            gpu.setForeground(0xFF0000)
            gpu.set(i*2-1,2+j,sym)
          end
        end
      end
--[[      ecs.universalWindow("auto","auto",30,0xDDDDDD,true,
        {"EmptyLine"},
        {"CenterText",0x111111,"вы проиграли"},
        {"EmptyLine"},
        {"button",{ecs.colors.red,0xFFFFFF,"OK"}}
      )--]]
--      print("you lose")
      messageBox("GAME OVER","You lose")
      gamestate = false
    elseif field[x][y][1] == 0 then
      if field[x][y][0] == 0 then
        if (x~=0)and(x~=size+1)and(y~=0)and(y~=size+1) then
          field[x][y][1] = 1
          openfield = openfield + 1
          usecell(x-1,y-1,0)
          usecell(x-1,y,0)
          usecell(x-1,y+1,0)
          usecell(x,y-1,0)
          usecell(x,y+1,0)
          usecell(x+1,y-1,0)
          usecell(x+1,y,0)
          usecell(x+1,y+1,0)
          gpu.set(x*2-1,2+y,"  ")
        end
      else
        gpu.setForeground(cnum[field[x][y][0]])
        gpu.set(x*2-1,2+y,tostring("."..field[x][y][0]))
        gpu.setForeground(0xFFFFFF)
        field[x][y][1] = 1
        openfield = openfield + 1
      end
    end
  elseif type == 1 then
    if field[x][y][1] == 0 then
      if (flags > 0) then
        gpu.setBackground(0xFFFF00)
        flags = flags - 1
        field[x][y][1] = 2
        gpu.set(x*2-1,2+y,"  ")
        gpu.setBackground(0x999999)
      end
    elseif field[x][y][1] == 1 then
      tmp = 0
      if field[x-1][y-1][1] == 2 then
        tmp = tmp + 1
      end
      if field[x-1][y][1] == 2 then
        tmp = tmp + 1
      end
      if field[x-1][y+1][1] == 2 then
        tmp = tmp + 1
      end
      if field[x][y-1][1] == 2 then
        tmp = tmp + 1
      end
      if field[x][y+1][1] == 2 then
        tmp = tmp + 1
      end
      if field[x+1][y-1][1] == 2 then
        tmp = tmp + 1
      end
      if field[x+1][y][1] == 2 then
        tmp = tmp + 1
      end
      if field[x+1][y+1][1] == 2 then
        tmp = tmp + 1
      end
      if tmp == field[x][y][0] then
----
        if field[x-1][y-1][1] == 0 then
          usecell(x-1,y-1,0)
        end
        if field[x-1][y][1] == 0 then
          usecell(x-1,y,0)
        end
        if field[x-1][y+1][1] == 0 then
          usecell(x-1,y+1,0)
        end
        if field[x][y-1][1] == 0 then
          usecell(x,y-1,0)
        end
        if field[x][y+1][1] == 0 then
          usecell(x,y+1,0)
        end
        if field[x+1][y-1][1] == 0 then
          usecell(x+1,y-1,0)
        end
        if field[x+1][y][1] == 0 then
          usecell(x+1,y,0)
        end
        if field[x+1][y+1][1] == 0 then
          usecell(x+1,y+1,0)
        end
----
      end
    else
      gpu.setBackground(0x666666)
--      gpu.setBack
      flags = flags + 1
      field[x][y][1] = 0
      gpu.set(x*2-1,2+y,"  ")
      gpu.setBackground(0x999999)
    end
  end
end
gpu.setBackground(0x333333) -- Парочка костылей
gpu.set(size*2-4,1,"00:00")
gpu.set(1,1,((flags<100 and "0")or "")..((flags<10 and "0")or "")..flags..sym)
gamestate = true
while gamestate do
  _,_,x,y,type = event.pull("touch")
  if not tir then
    startTimer()
    tir=true
  end
  x = math.floor((x+1)/2)
  y = y-2
  if (x>0)and(x<size+1)and(y>0)and(y<size+1) then
    gpu.setBackground(0x999999)
    usecell(x,y,type)
  end
  win = false
  if openfield >= size*size-mines then
    win = true
  end
  if flags == 0 then
    win = true
    for i = 1,size do
      for j = 1,size do
        if ((field[i][j][0] == -1)and(field[i][j][1]==2))or((field[i][j][0] ~= -1)and(field[i][j][1]==1)) then
        else
          win = false
        end
      end
    end
  end
  if win then
    gamestate = false
    messageBox("congratulation","you win",0x00CC00)
  end
  gpu.setBackground(0x333333)
  gpu.setForeground(0xffffff)
  gpu.set(1,1,((flags<100 and "0")or "")..((flags<10 and "0")or "")..flags..sym)
end
stopTimer()
gpu.setBackground(0x000000)
gpu.setForeground(0xffffff)
gpu.setResolution(SAVEW,SAVEH)

os.exit()

function gameInit()

end

function gameHandle()

end

function gameExit()

end

-------------------- GUI --------------------
gui.Init()

GameForm = gui.backend.Form:Create(cfg.mapWidth * 2, cfg.mapHeight + 1,
  {
    gui.backend.Button:Create(1, 1, 8, 1, "[Return]", function()
      gameExit()
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

gameExit()
gpu.setBackground(0x000000)
gpu.setForeground(0xffffff)