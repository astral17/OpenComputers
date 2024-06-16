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

-- gui.Init()
-- gui.backend.MessageBox:Create("Game Over", "Draw!"):Modify{ButtonHandle = function() GameForm.Elements["Exit"]:OnElementClick() end}:Init():Paint()
-- gui.Destroy()
-- os.exit()

local gpu = component.gpu
local event = require("event")
----SETTINGS----
local cfg = {}
cfg.MapWidth = 9
cfg.MapHeight = 9
cfg.WinLine = 5
cfg.ReqAuth = true

function InRange(value, left, right)
  return left <= value and value <= right
end

function UpdateScreenSettings()
  cfg.ScreenWidth  = cfg.MapWidth  * 8 - 1
  cfg.ScreenHeight = cfg.MapHeight * 4 + 1
end

function ValidateConfig()
  local MaxScreenWidth, MaxScreenHeight
  MaxScreenWidth, MaxScreenHeight = gpu.maxResolution()
  UpdateScreenSettings()
  if not InRange(cfg.ScreenWidth, 1, MaxScreenWidth) then
    return "MapWidthError", "out of bounds"
  end
  
  if not InRange(cfg.ScreenHeight, 1, MaxScreenHeight) then
    return "MapHeightError", "out of bounds"
  end
end

--UpdateScreenSettings()
local err, msg = ValidateConfig()
if err ~= nil then
  print(err, msg)
  os.exit()
end

local map, players, FreeCells, canvas, curPlayer, isRunning

function fromXY(x, y)
  return (y - 1) * cfg.MapWidth + x
end

tex = {
  {
    "▄   ▄",
    " ▀▄▀ ",
    "▄▀ ▀▄",
  },
  {
    "  ▄  ",
    "▄▀ ▀▄",
    " ▀▄▀ "
  }
}

function DrawCell(canvas, x, y, id)
  if id == 1 then
    gpu.setForeground(0x0000ff)
  elseif id == 2 then
    gpu.setForeground(0xff0000)
  else
    return
  end
  for i = 1, 3 do
    canvas.set((x - 1) * 8 + 2, (y - 1) * 4 + i, tex[id][i])
  end
  gpu.setForeground(0xffffff)
end

function GameInit()
  map = {}
  curPlayer = 1
  isRunning = true
  FreeCells = cfg.MapWidth * cfg.MapHeight
  -- event.listen("touch", OnTouch)
end

local DIRS =
{
  { 1, 1},
  { 1, 0},
  { 0, 1},
  {-1, 1},
}

function MoveHandle(x, y)
  if map[fromXY(x, y)] then
    return false
  end
  map[fromXY(x, y)] = curPlayer
  
  local cnt
  local curX, curY
  for i = 1, 4 do
    cnt = 0
    local CUR = DIRS[i]
    curX, curY = x - CUR[1], y - CUR[2]
    while InRange(curX, 1, cfg.MapWidth) and InRange(curY, 1, cfg.MapHeight) and map[fromXY(curX, curY)] == curPlayer do
      cnt = cnt + 1
      curX, curY = curX - CUR[1], curY - CUR[2]
    end
    curX, curY = x, y
    while InRange(curX, 1, cfg.MapWidth) and InRange(curY, 1, cfg.MapHeight) and map[fromXY(curX, curY)] == curPlayer do
      cnt = cnt + 1
      curX, curY = curX + CUR[1], curY + CUR[2]
    end
    if cnt >= cfg.WinLine then
      curPlayer = 3 - curPlayer
      return 3 - curPlayer, 3 - curPlayer
    end
  end
  
  FreeCells = FreeCells - 1
  if FreeCells == 0 then
    -- print("GG")
    curPlayer = 3 - curPlayer
    return 3 - curPlayer, 0
  end
  
  curPlayer = 3 - curPlayer
  return 3 - curPlayer
end

function GameExit()
  -- event.ignore("touch", OnTouch)
end

-------------------- GUI --------------------
gui.Init()

AuthForm = gui.backend.Form:Create(21, 9,
  {
    gui.backend.Text:Create(1, 1, 21, "Auth plz..."),
    
    player1 = gui.backend.Button:Create(1, 3, 10, 3, "", function(self, x, y, b, name)
      if self.Text ~= "" then
        return
      end
      self:Modify{BackColor = 0x009900, Text = name}:Paint()
      if self.Parent.Elements["player1"].Text ~= "" and self.Parent.Elements["player2"].Text ~= "" then
        players[1] = self.Parent.Elements["player1"].Text
        players[2] = self.Parent.Elements["player2"].Text
        AuthForm:Disable(true)
        GameForm:Enable():Paint()
      end
    end),
    player2 = gui.backend.Button:Create(12, 3, 10, 3, "", function(self, x, y, b, name)
      if self.Text ~= "" then
        return
      end
      self:Modify{BackColor = 0x009900, Text = name}:Paint()
      if self.Parent.Elements["player1"].Text ~= "" and self.Parent.Elements["player2"].Text ~= "" then
        players[1] = self.Parent.Elements["player1"].Text
        players[2] = self.Parent.Elements["player2"].Text
        AuthForm:Disable(true)
        GameForm:Enable():Paint()
      end
    end),
    
    gui.backend.Button:Create(1, 7, 21, 3, "Back", function()
      AuthForm:Disable(true)
      MainForm:Enable():Paint()
    end),
  }
):Modify
{
  OnEnable = function(self)
    self.Elements["player1"]:Modify{Text = "", BackColor = 0x666666}
    self.Elements["player2"]:Modify{Text = "", BackColor = 0x666666}
    players = {}
  end,
}:Init()

GameForm = gui.backend.Form:Create(cfg.ScreenWidth, cfg.ScreenHeight,
  {
    Exit = gui.backend.Button:Create(1, 1, 8, 1, "[Return]", function()
      GameExit()
      GameForm:Disable(true)
      MainForm:Enable():Paint()
    end),
    
    -- status = gui.ba
    
    canvas = gui.backend.Canvas:Create(1, 2, cfg.ScreenWidth, cfg.ScreenHeight - 1):Modify
    {
      OnElementClick = function(self, x, y, b, name)
        if not isRunning then
          return false
        end
        if cfg.ReqAuth and players[curPlayer] ~= name then
          return false
        end
        x, y = math.floor((x - 1) / 8) + 1, math.floor((y - 1) / 4) + 1
        -- print(x, y)
        local moved, ended = MoveHandle(x, y)
        if moved then
          DrawCell(self, x, y, moved)
        end
        
        if ended ~= nil then
          isRunning = false
          if ended == 0 then
            gui.backend.MessageBox:Create("Game Over", "Draw!"):Modify{ButtonHandle = function() GameForm.Elements["Exit"]:OnElementClick() end}:Init():Paint()
          else
            gui.backend.MessageBox:Create("Game Over", "Winner: "..players[ended]):Modify{ButtonHandle = function() GameForm.Elements["Exit"]:OnElementClick() end}:Init():Paint()
          end
        end
      end,
      OnPaint = function(self)
        -- for x = 1, cfg.MapWidth do
          -- for y = 1, cfg.MapHeight do
            -- DrawCell(self, x, y, 1)
          -- end
        -- end
        
        for y = 1, cfg.MapHeight - 1 do
          self.set(1, y * 4, string.rep("▄",8 * cfg.MapWidth - 1))
          -- for x = 1, cfg.mapWidth do
            -- draw(map[fromXY(x, y)], (x - 1) * 8 + 2, (y - 1) * 4 + 1)
          -- end
        end
        for x = 1, cfg.MapWidth - 1 do
            self.set(x * 8, 1, string.rep("█", 4 * cfg.MapHeight - 1).."▀", true)
        end
      end,
    },
    
    -- algo = gui.backend.Text:Create(10, 1, nil, cfg.Algorithm),
  }
):Modify
{
  OnPaint = function(self)
    self.Width  = cfg.ScreenWidth
    self.Height = cfg.ScreenHeight
    self.Elements["canvas"].Width  = cfg.ScreenWidth
    self.Elements["canvas"].Height = cfg.ScreenHeight - 1
  end,
  OnEnable = function(self)
    if not cfg.ReqAuth then
      players = {"x", "o"}
    end
    GameInit()
  end,
}:Init()

SettingsForm = gui.backend.Form:Create(20, 16,
  {
    gui.backend.Text:Create(1, 1, 20, "Settings"),
    
    gui.backend.Text:Create(1, 3, nil, "Width"),
    MapWidth = gui.backend.TextBox:Create(1, 4, 20, cfg.MapWidth .. "", "0123456789"),
    MapWidthError = gui.backend.Text:Create(1, 5, nil, ""):Modify{TextColor = 0xff0000},
    
    gui.backend.Text:Create(1, 6, nil, "Height"),
    MapHeight = gui.backend.TextBox:Create(1, 7, 20, cfg.MapHeight .. "", "0123456789"),
    MapHeightError = gui.backend.Text:Create(1, 8, nil, ""):Modify{TextColor = 0xff0000},
    
    gui.backend.Text:Create(1, 9, nil, "WinLine"),
    WinLine = gui.backend.TextBox:Create(1, 10, 20, cfg.WinLine .. "", "0123456789"),
    WinLineError = gui.backend.Text:Create(1, 11, nil, ""):Modify{TextColor = 0xff0000},
    
    ReqAuth = gui.backend.CheckBox:Create(1, 12, 0, "Require Auth", cfg.ReqAuth),
    
    gui.backend.Button:Create(1, 14, 20, 3, "Back", function()
      cfg.MapWidth = SettingsForm.Elements["MapWidth"].Text + 0
      cfg.MapHeight = SettingsForm.Elements["MapHeight"].Text + 0
      cfg.WinLine = SettingsForm.Elements["WinLine"].Text + 0
      cfg.ReqAuth = SettingsForm.Elements["ReqAuth"].Checked
      SettingsForm.Elements["MapWidthError"]:Modify{Text = ""}:Paint()
      SettingsForm.Elements["MapWidth"]:Modify{TextColor = 0xffffff}:Paint()
      SettingsForm.Elements["MapHeightError"]:Modify{Text = ""}:Paint()
      SettingsForm.Elements["MapHeight"]:Modify{TextColor = 0xffffff}:Paint()
      SettingsForm.Elements["WinLineError"]:Modify{Text = ""}:Paint()
      SettingsForm.Elements["WinLine"]:Modify{TextColor = 0xffffff}:Paint()
      
      local err, msg = ValidateConfig()
      if err ~= nil then
        SettingsForm.Elements[err]:Modify{Text = msg}:Paint()
        SettingsForm.Elements[unicode.sub(err, 1, -6)]:Modify{TextColor = 0xff0000}:Paint()
        return false
      end
      SettingsForm:Disable(true)
      MainForm:Enable():Paint()
    end),
  }
):Init()

MainForm = gui.backend.Form:Create(20, 11,
  {
    gui.backend.Button:Create(1, 1, 20, 3, "Start", function()
      MainForm:Disable(true)
      if cfg.ReqAuth then
        AuthForm:Enable():Paint()
      else
        GameForm:Enable():Paint()
      end
    end),
    gui.backend.Button:Create(1, 5, 20, 3, "Settings", function() MainForm:Disable(true) SettingsForm:Enable():Paint() end),
    gui.backend.Button:Create(1, 9, 20, 3, "Exit", function() quit = true end),
  }
):Init():Enable():Paint()

canvas = GameForm.Elements["canvas"]
quit = false
pcall(function()
  while not quit do
    event.pull()
  end
end)

-- event.ignore("touch", OnTouch)
gui.Destroy()