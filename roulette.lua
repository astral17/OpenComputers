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







-------------------- GUI --------------------
local quit = false
gui.Init()

GameForm = gui.backend.Form:Create(100, 50,
  {
    gui.backend:Create(1,1, 5, 5, "exit", function() quit = true end)
  }
):Modify
{
  OnPaint = function(self)
    -- self.Width  = cfg.ScreenWidth
    -- self.Height = cfg.ScreenHeight
    -- self.Elements["canvas"].Width  = cfg.ScreenWidth
    -- self.Elements["canvas"].Height = cfg.ScreenHeight - 1
  end,
  OnEnable = function(self)
    -- if not cfg.ReqAuth then
      -- players = {"x", "o"}
    -- end
    -- GameInit()
  end,
}:Init()

GameForm:Enable():Paint()

-- gCanvas = GameForm.Elements["canvas"]
-- pCanvas = GameForm.Elements["panel"].Elements["canvas"]
-- scoreObj = GameForm.Elements["panel"].Elements["score"]


-- GameInit()
-- DrawMap()
-- event.ignore("key_down", onKeyDown)
-- event.listen("key_down", onKeyDown)
-- event.ignore("key_up", onKeyUp)
-- event.listen("key_up", onKeyUp)

local suc, err = pcall(function()
  while not quit do
    if isRunning then
      -- GameHandle()
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