local AGUI_VERSION = "0.7"
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


local MainForm

function redraw()
  MainForm:Paint(true)
end

function berr()
  local r = math.random(1, 3)
  local str
  redraw()
  if r == 1 then
    str = "Вы на баланс смотрели?"
  elseif r == 2 then
    str = "Вы уверены, что у вас есть деньги?"
  elseif r == 3 then
    str = "Бедным деньги не даю!"
  end
  gui.Error(str, redraw)
end

function errfill()
  redraw()
  gui.Error("Функция временно недоступна)", redraw)
end

-------------------- GUI --------------------
gui.Init()

MainForm = gui.backend.Form:Create(80, 25,
  {
    gui.backend.Text:Create(1, 1, 80, "Вас приветствует кривой банк v1.0"),
    gui.CreateGroup(
    {
      OnPaint = function(self)
        gpu.setBackground(0x222222)
        gpu.fill(self.X, self.Y, self.Width, self.Height, " ")
      end
    },
    {
      gui.backend.Button:Create(1, 1, 30, 7, "Снять", berr),
      gui.backend.Button:Create(40, 1, 30, 7, "Пополнить", errfill),
      gui.backend.Button:Create(1, 10, 30, 7, "Перевести", berr),
      gui.backend.Button:Create(40, 10, 30, 7, "Оплатить", berr),
    }, gui.GetCenter(1, 80, 69), 2, 69, 16),
  }
):Init():Enable():Paint()

--[[
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

MainForm:Init():Enable():Paint()--]]

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