local gpu = require("component").gpu
local event = require("event")
local unicode = require("unicode")

local IsInited = false
local gui = {}
local elements -- = {}
local timers -- = {}

gui.Version = "1.0.0pre1"

-- function gui.getVersion(requestVersion)
  -- if type(goodVersion) ~= "table" then
    -- return false
  -- end
  -- if V
-- end

--gui.Elements = elements

function gui.NewIsClicked(x1, y1, x2, y2)
  return function(x, y) return x1 <= x and x <= x2 and y1 <= y and y <= y2;end
end

function gui:IsClicked(x, y)
  return self.X <= x and x <= self.X + self.Width - 1 and self.Y <= y and y <= self.Y + self.Height - 1
end

function gui.GetCenterSegment(l, r, width)
  return math.floor((l + r - (width or 0) + 1) / 2)
end

function gui.GetCenter(sX, sWidth, width)
  return sX + math.floor((sWidth - (width or 0)) / 2)
  -- return gui.GetCenterSegment(sX, sX + sWidth - 1, width)
end

function gui.gc()
  for index, element in pairs(elements) do
    if type(element) == "table" and element.Garbage then
      elements[index] = nil
    end
  end
end

function gui.OnEvent(...)
    gui.gc()
    for index, element in pairs(elements) do
        if element and element.enabled then
            pcall(element.OnEvent, element, ...)
        end
    end
end

function gui.OnClick(_, _, x, y, button, name)
  gui.gc()
  for index, element in pairs(elements) do
    if type(element) == "table" and element.enabled and type(element.OnClick) == "function" then
      -- element:OnClick(x, y)
      pcall(element.OnClick, element, x, y, button, name)
    end
  end
  
  for index, element in pairs(elements) do
    if type(element) == "table" and element.enabled and type(element.IsClicked) == "function" and type(element.OnElementClick) == "function" and element:IsClicked(x, y) then
      -- element:OnElementClick(x - element.X + 1, y - element.Y + 1)
      pcall(element.OnElementClick, element, x - element.X + 1, y - element.Y + 1, button, name)
      break
    end
  end
end

function gui.OnKeyDown(_, _, key1, key2, name)
  gui.gc()
  for index, element in pairs(elements) do
    if type(element) == "table" and element.enabled and element.focused and type(element.OnKeyDown) == "function" then
      -- element:OnKeyDown(key1, key2, name)
      pcall(element.OnKeyDown, element, key1, key2, name)
    end
  end
end

function gui.OnKeyUp(_, _, key1, key2, name)
  gui.gc()
  for index, element in pairs(elements) do
    if type(element) == "table" and element.enabled and element.focused and type(element.OnKeyUp) == "function" then
      -- element:OnKeyDown(key1, key2, name)
      pcall(element.OnKeyUp, element, key1, key2, name)
    end
  end
end

-- OnScroll
-- OnDrag
-- OnDrop
-- OnClipboard
-- OnScreenResized

local OnEventID
function gui.Init()
    if IsInited then
        return false
    end
    IsInited = true
    elements = {}
    timers = {}
    OnEventID = event.register(nil, gui.OnEvent, math.huge, math.huge)
    event.listen("touch", gui.OnClick)
    event.listen("key_down", gui.OnKeyDown)
    event.listen("key_up", gui.OnKeyUp)
    return true
end

function gui.Destroy()
-- TODO DEPRECATE
    event.cancel(OnEventID)
  event.ignore("touch", gui.OnClick)
  event.ignore("key_down", gui.OnKeyDown)
  event.ignore("key_up", gui.OnKeyUp)
  IsInited = false
  for index, timer in pairs(timers) do
    event.cancel(timer)
  end
  timers = nil
  for index, element in pairs(elements) do
    if type(element) == "table" and type(element.Destroy) == "function" then
      -- element:Destroy()
      pcall(element.Destroy, element)
    end
  end
  elements = nil
end

local WorkSpace = {}

function WorkSpace:WaitTilExit(timeout)
    while true do
        local tbl = {event.pull(timeout)}
    end
end

function WorkSpace:Destroy()
    local gpu = self.gpu
    gpu.setResolution(self.screenWidth, self.screenHeight)
    gpu.setViewport(self.viewWidth, self.viewHeight)
    gpu.setBackground(self.backColor, self.isBackPalette)
    gpu.setForeground(self.foreColor, self.isForePalette)
    gpu.setDepth(self.depth)
end

local WorkSpaceMeta = {__index = WorkSpace}

function gui.CreateWorkSpace(GPU)
    -- self:Init()
    local gpu = GPU or gpu
    local screenWidth, screenHeight = gpu.getResolution()
    local viewWidth, viewHeight = gpu.getViewport()
    local backColor, isBackPalette = gpu.getBackground()
    local foreColor, isForePalette = gpu.getForeground()
    local depth = gpu.getDepth()
    return setmetatable(
    {
        gpu = gpu,
        screenWidth = screenWidth,
        screenHeight = screenHeight,
        viewWidth = viewWidth,
        viewHeight = viewHeight,
        backColor = backColor,
        isBackPalette = isBackPalette,
        foreColor = foreColor,
        isForePalette = isForePalette,
        depth = depth,
        forms = {},
    }, WorkSpaceMeta)
end

--[[
 Standard methods:
    Init
    Destroy
    Enable
    Disable
    PushEvent
    [Paint]
 Standard arguments:
    X
    Y
    Width
    Height
    Elements
 Standard events:
    
--]]

-- local function CreateEventHandler(eventName, eventHandler)
    
-- end

-- local function CreateComponent(methods, arguments, events)
    -- local nc = {}
    -- setmetatable(nc,
    -- {
        -- __index = {}
    -- })
    -- return nc
-- end

local Element =
{
    X = 1,
    Y = 1,
    OffsetX = 0,
    OffsetY = 0,
    Width = 1,
    Height = 1,
    enabled = false,
    focused = false, -- TODO: Remove
}
Element.__element = Element

function Element:Init()
    if self.OnInit then
        self:OnInit()
    end
    return self
end

function Element:Destroy()
    if self.OnDestroy then
        pcall(self.OnDestroy, self)
    end
    self.Garbage = true
    return self
end

function Element:Enable()
    if self.OnEnable then
        self:OnEnable()
    end
    self.enabled = true
    return self
end

function Element:Disable()
    if self.OnDisable then
        self:OnDisable()
    end
    self.enabled = false
    return self
end

function Element:Paint()
    if self.OnPaint then
        self:OnPaint()
    end
    return self
end

function Element:Modify(tbl)
    for index, element in pairs(tbl) do
        self[index] = element
    end
    return self
end

local ElementMeta = {__index = Element}

function gui.Create(element, meta)
    element = setmetatable(element or {}, meta or ElementMeta)
    table.insert(elements, element)
    return element
end

-- Group --

local Group =
{
    X = 1,
    Y = 1,
    OffsetX = 0,
    OffsetY = 0,
    Width = 1,
    Height = 1,
    enabled = false,
}
Group.__group = Group

function Group:AddChild(child)
    table.insert(self.Elements, child)
    return self
end

function Group:Init()
    if self.OnInit then
        self:OnInit()
    end
    for index, element in pairs(self.Elements) do
        if type(element) == "table" and type(element.Init) == "function" then
            element.OffsetX = self.OffsetX + self.X - 1
            element.OffsetY = self.OffsetY + self.Y - 1
            element.Parent = self
            element:Init()
        end
    end
    return self
end

function Group:Destroy()
    if self.OnDestroy then
        pcall(self.OnDestroy, self)
    end
    for index, element in pairs(self.Elements) do
        if type(element) == "table" and type(element.Destroy) == "function" then
            pcall(element.Destroy, element)
        end
    end
    self.Garbage = true
end

function Group:Enable()
    if self.OnEnable then
        self:OnEnable()
    end
    for index, element in pairs(self.Elements) do
        if type(element) == "table" and type(element.Enable) == "function" then
            element:Enable()
        end
    end
    self.enabled = true
    return self
end

function Group:Disable()
    if self.OnDisable then
        self:OnDisable()
    end
    for index, element in pairs(self.Elements) do
        if type(element) == "table" and type(element.Disable) == "function" then
            element:Disable()
        end
    end
    self.enabled = false
    return self
end

function Group:Paint()
    if self.OnPaint then
        self:OnPaint()
    end
    for index, element in pairs(self.Elements) do
        if type(element) == "table" and type(element.Paint) == "function" then
            element:Paint()
        end
    end
    return self
end

local GroupMeta = {__index = Group}

function gui.CreateGroup(group, elements, meta)
    group = group or {}
    -- group.X = x
    -- group.Y = y
    -- group.Width = width
    -- group.Height = height
    group.Elements = elements or {}
    return setmetatable(group, meta or GroupMeta)
end

--~Group~--

gui.backend = {} -- TODO: Remove
-- Text --
-- gui.backend.Text = {}
local Text =
{
    Width = 0,
    Text = "text",
    PaintedTextLen = 0,
    BackColor = 0x000000,
    TextColor = 0xffffff,
}
Text.__base = Text

function Text:Paint()
    gpu.setBackground(self.BackColor)
    gpu.setForeground(self.TextColor)
    if self.Width > 0 then
        -- gpu.set(self.X + math.floor(self.Width / 2) - math.ceil(unicode.len(self.Text) / 2), self.Y, self.Text)
        gpu.set(self.X + math.floor((self.Width - self.PaintedTextLen) / 2), self.Y, string.rep(" ", self.PaintedTextLen))
        gpu.set(self.X + math.floor((self.Width - unicode.len(self.Text)) / 2), self.Y, self.Text)
    else
        gpu.set(self.X, self.Y, string.rep(" ", self.PaintedTextLen))
        gpu.set(self.X, self.Y, self.Text)
    end
    self.PaintedTextLen = unicode.len(self.Text)
    return self
end

-- function Text:Create(x, y, width, text)
  -- return gui.Create{
    -- X = x,
    -- Y = y,
    -- Width = width or 0,
    -- Paint = self.Paint,
    -- Text = text,
    -- PaintedTextLen = 0,
    -- BackColor = 0x000000,
    -- TextColor = 0xffffff,
  -- }
-- end

local TextMeta = {__index = setmetatable(Text, ElementMeta)}

function gui.CreateText(element)
    return gui.Create(element, TextMeta)
end

-- Button --
-- gui.backend.Button = {}
local Button =
{
    -- OnElementClick = onclick,
    IsClicked = gui.IsClicked,
    Text = "button",
    BackColor = 0x666666,
    TextColor = 0xffffff,
}
Button.__base = Button

function Button:Paint(pressed)
    gpu.setBackground(self.BackColor)
    gpu.setForeground(self.TextColor)
    gpu.fill(self.X, self.Y, self.Width, self.Height, " ")
    gpu.set(self.X + math.floor(self.Width / 2) - math.ceil(unicode.len(self.Text) / 2), self.Y + math.floor(self.Height / 2), self.Text)
    return self
end

-- function Button:Create(x, y, width, height, text, onclick)
  -- return gui.Create{
    -- OnElementClick = onclick,
    -- Paint = self.Paint,
    -- IsClicked = gui.IsClicked,
    -- Text = text,
    -- X = x,
    -- Y = y,
    -- Width = width,
    -- Height = height,
    -- BackColor = 0x666666,
    -- TextColor = 0xffffff,
  -- }
-- end

local ButtonMeta = {__index = setmetatable(Button, ElementMeta)}

function gui.CreateButton(element)
    return gui.Create(element, ButtonMeta)
end

-- TextBox --
-- gui.backend.TextBox = {}
local TextBox =
{
    IsClicked = gui.IsClicked,
    Text = "",
    -- AvailableChars = nil,
    CursorPosition = 0,
    BackColor = 0x333333,
    TextColor  = 0xffffff,
}
TextBox.__base = TextBox

function TextBox:Init()
    self.Timer = event.timer(0.5, function()
        if self.Enable and self.focused then
            self.Blink = not self.Blink
            self:Paint()
        end
    end, math.huge)
    table.insert(timers, self.Timer)
end

function TextBox:Destroy()
    event.cancel(self.Timer)
    self.__element:Destroy()
end

function TextBox:OnClick(x, y)
    self.focused = false
    self.Blink = false
    self:Paint()
end

function TextBox:OnElementClick(x, y)
    self.focused = true
    if self.focused then
        self.CursorPosition = math.min(math.max(1, x), unicode.len(self.Text) + 1)
        self:Paint()
    end
    return self
end

function TextBox:OnKeyDown(key1, key2)
    if key1 == 8 then -- BackSpace
        if self.CursorPosition > 1 then
            self.Text = unicode.sub(self.Text, 1, self.CursorPosition - 2) .. unicode.sub(self.Text, self.CursorPosition, unicode.len(self.Text))
            self.CursorPosition = self.CursorPosition - 1
        end
    elseif key2 == 211 then -- Delete
        if self.CursorPosition <= unicode.len(self.Text) then
            self.Text = unicode.sub(self.Text, 1, self.CursorPosition - 1) .. unicode.sub(self.Text, self.CursorPosition + 1, unicode.len(self.Text))
        end
    elseif key2 == 199 then -- Home
        self.CursorPosition = 1
    elseif key2 == 207 then -- End
        self.CursorPosition = unicode.len(self.Text) + 1
    elseif key2 == 203 then -- Left
        self.CursorPosition = math.max(self.CursorPosition - 1, 1)
    elseif key2 == 205 then -- Right
        self.CursorPosition = math.min(self.CursorPosition + 1, unicode.len(self.Text) + 1)
    elseif key1 ~= 0 and (not self.AvailableChars or self.AvailableChars:find(unicode.char(key1))) then
        self.Text = unicode.sub(self.Text, 1, self.CursorPosition - 1) .. unicode.char(key1) .. unicode.sub(self.Text, self.CursorPosition, unicode.len(self.Text))
        self.CursorPosition = self.CursorPosition + 1
    end
    self:Paint()
end

function TextBox:Paint()
    gpu.setBackground(self.BackColor)
    gpu.setForeground(self.TextColor)
    gpu.set(self.X, self.Y, string.rep(" ", self.Width))
    gpu.set(self.X, self.Y, unicode.sub(self.Text, 1, self.Width)) -- TODO normal cut
    if self.Blink and self.CursorPosition <= self.Width then
        gpu.setBackground(self.TextColor)
        gpu.setForeground(self.BackColor)
        gpu.set(self.X + self.CursorPosition - 1, self.Y, self.CursorPosition <= #self.Text and unicode.sub(self.Text, self.CursorPosition, self.CursorPosition) or " ")
    end
    return self
end

local TextBoxMeta = {__index = setmetatable(TextBox, ElementMeta)}
function gui.CreateTextBox(element)
    return gui.Create(element, TextBoxMeta)
end
-- function TextBox:Create(x, y, width, text, availableChars)
  
  -- return gui.Create{
    -- Init = self.Init,
    -- Destroy = self.Destroy,
    -- OnClick = self.OnClick,
    -- OnElementClick = self.OnElementClick,
    -- OnKeyDown = self.OnKeyDown,
    -- Paint = self.Paint,
    -- IsClicked = gui.IsClicked,
    -- Text = text,
    -- AvailableChars = availableChars,
    -- CursorPosition = 0,
    -- BackColor = 0x333333,
    -- TextColor  = 0xffffff,
    -- X = x,
    -- Y = y,
    -- Width = width,
    -- Height = 1,
  -- }
-- end

-- CheckBox --

-- gui.backend.CheckBox = {}
local CheckBox = 
{
    StrUnChecked = "[ ] ",
    StrChecked   = "[X] ",
    Checked = false,
    Width = 0,
    Text = "text",
    BackColor = 0x000000, -- 0x333333,
    TextColor  = 0xffffff,
}
CheckBox.__base = CheckBox

function CheckBox:Init() -- TODO: Think
    if self.Width == 0 then
        self.Width = 4 + unicode.len(self.Text)
    end
end

function CheckBox:Paint()
    gpu.setBackground(self.BackColor)
    gpu.setForeground(self.TextColor)

    local box = "[ ] "
    if self.Checked then
        box = "[X] "
    end
    gpu.set(self.X, self.Y, unicode.sub(box .. self.Text, 1, self.Width) .. string.rep(" ", self.Width - box:len() - self.Text:len()))
    return self
end

function CheckBox:OnElementClick(x, y)
    self.Checked = not self.Checked
    if type(self.OnCheckedChanged) == "function" then
        pcall(self.OnCheckedChanged, self)
    end
    self:Paint()
end

local CheckBoxMeta = {__index = setmetatable(CheckBox, ElementMeta)}
function gui.CreateCheckBox(element)
    return gui.Create(element, CheckBoxMeta)
end
-- function CheckBox:Create(x, y, width, text, checked)
  -- return gui.Create{
    -- Init = self.Init,
    -- IsClicked = gui.IsClicked,
    -- OnElementClick = self.OnElementClick,
    -- -- OnCheckedChanged
    -- Paint = self.Paint,
    -- X = x,
    -- Y = y,
    -- Width = width,
    -- Text = text,
    -- BackColor = 0x000000, -- 0x333333,
    -- TextColor  = 0xffffff,
    -- Checked = checked or false,
  -- }
-- end

-- RadioButton --

-- gui.backend.RadioButton = {}
local RadioButton =
{
    IsClicked = gui.IsClicked,
    Text = "text",
    BackColor = 0x000000, -- 0x333333,
    TextColor  = 0xffffff,
    Checked = false,
}
RadioButton.__base = RadioButton

function RadioButton:Paint()
    gpu.setBackground(self.BackColor)
    gpu.setForeground(self.TextColor)

    local box = "( ) "
    if self.Checked then
        box = "(X) "
    end
    gpu.set(self.X, self.Y, unicode.sub(box .. self.Text, 1, self.Width) .. string.rep(" ", self.Width - box:len() - self.Text:len()))
    return self
end

function RadioButton:OnAnotherChecked()
    self.Checked = false
end

function RadioButton:OnElementClick(x, y)
    self.Checked = true
    if type(self.Parent) == "table" then
        self.Parent:OnChecked(self.Name)
    else
        self:Paint()
    end
end

local RadioButtonMeta = {__index = setmetatable(RadioButton, ElementMeta)}
function gui.CreateRadioButton(element)
    return gui.Create(element, RadioButtonMeta)
end
-- function RadioButton:Create(x, y, width, text)
  -- return gui.Create{
    -- IsClicked = gui.IsClicked,
    -- OnElementClick = self.OnElementClick,
    -- OnAnotherChecked = self.OnAnotherChecked,
    -- Paint = self.Paint,
    -- X = x,
    -- Y = y,
    -- Width = width,
    -- Text = text,
    -- BackColor = 0x000000, -- 0x333333,
    -- TextColor  = 0xffffff,
    -- Checked = true,
  -- }
-- end

-- RadioGroup --

local RadioGroup =
{
}
RadioGroup.__base = RadioGroup

function RadioGroup:Init()
  -- if self.Checked == nil then
    -- self.Checked = next(self.Elements)
  -- end
  for index, element in pairs(self.Elements) do
    element.Parent = self
    element.Name = index
    if self.Checked == nil and element.Checked or self.Checked == index then
      element.Checked = true
      self.Checked = index
    end
    element:Init()
  end
  return self
end

function RadioGroup:OnChecked(name)
  self.Checked = name
  for index, element in pairs(self.Elements) do
    if type(element) == "table" then
      if index ~= name then
        element:OnAnotherChecked()
      end
      element:Paint()
    end
  end
end

local RadioGroupMeta = {__index = setmetatable(RadioGroup, GroupMeta)}
function gui.CreateRadioGroup(group, elements)
    return gui.CreateGroup(group, elements, RadioGroupMeta)
end
-- function RadioGroup:Create(elements, checked)
  -- return gui.CreateGroup({
    -- Init = self.Init,
    -- OnChecked = self.OnChecked,
    -- Checked = checked,
  -- }, elements)
-- end

-- MessageBox --
gui.backend.MessageBox = {}
local msgbox = gui.backend.MessageBox

function msgbox:Init()
  local widthScreen, heightScreen = gpu.getResolution()
  widthScreen  = self.ScreenWidth  or widthScreen
  heightScreen = self.ScreenHeight or heightScreen
  self.Width = math.max(self.Width, unicode.len(self.Title) + 2, unicode.len(self.Text) + 2)
  self.X = gui.GetCenter(1, widthScreen , self.Width)
  self.Y = gui.GetCenter(1, heightScreen, self.Height)
  -- self.X = math.floor((widthScreen  - self.Width ) / 2) + 1
  -- self.Y = math.floor((heightScreen - self.Height) / 2) + 1
  self.Elements = gui.CreateGroup(nil,
  {
    Title = gui.backend.Text:Create(self.X, self.Y + 1, self.Width, self.Title):Modify{TextColor = self.TitleColor, BackColor = self.BackColor},
    Text = gui.backend.Text:Create(self.X, self.Y + 3, self.Width, self.Text):Modify{TextColor = self.TextColor, BackColor = self.BackColor},
    Button = gui.backend.Button:Create(self.X, self.Y + 5, self.Width, 3, "OK", function()
      if type(self.ButtonHandle) == "function" then
        self:ButtonHandle()
      end
      self:Destroy()
    end):Modify{BackColor = self.ButtonColor},
  }):Init():Enable()
  return self
end

function msgbox:Destroy()
  self.Elements:Destroy()
  self.Garbage = true
end

function msgbox:Paint()
  gpu.setBackground(self.BackColor)
  gpu.fill(self.X, self.Y, self.Width, 5, " ")
  self.Elements:Paint()
  return self
 
end

function msgbox:Create(title, text, buttonText)
  return gui.Create{
    Init = self.Init,
    Destroy = self.Destroy,
    Paint = self.Paint,
    X = 0,
    Y = 0,
    Width = 10,
    Height = 8,
    Title = title or "Error",
    Text = text or "oops...",
    ButtonText = buttonText or "OK",
    TitleColor = 0xff0000,
    TextColor = 0x000000,
    BackColor = 0xffffff,
    ButtonColor = 0xff0000,
    -- ButtonHandle
  }
end

function gui.Error(text, handle)
  return gui.backend.MessageBox:Create(nil, text):Modify{ButtonHandle = handle}:Init():Paint()
end

-- Canvas --
gui.backend.Canvas = {}
local canvas = gui.backend.Canvas

function canvas.GetOffsetFunction(func, ...)
  local offset = {...}
  return function(...)
    local args = {...}
    for index, value in pairs(offset) do
      args[index] = args[index] + value
    end
    return func(table.unpack(args))
  end
end

-- local gpuOffset = {}

-- function gpuOffset:get(x, y)
    -- return gpu.get(x + self.offsetX, y + self.offsetY)
-- end
-- function gpuOffset:set(x, y, value, vertical)
    -- return gpu.set(x + self.offsetX, y + self.offsetY, value, vertical)
-- end

-- function gpuOffset:fill(x, y, width, height, char)
    -- return gpu.fill(x + self.offsetX, y + self.offsetY, width, height, char)
-- end

-- function gpuOffset:copy(x, y, width, height, tx, ty)
    -- return gpu.copy(x + self.offsetX, y + self.offsetY, width, height, tx, ty)
-- end

function canvas:Init()
  self.get = canvas.GetOffsetFunction(gpu.get, self.X - 1, self.Y - 1)
  self.set = canvas.GetOffsetFunction(gpu.set, self.X - 1, self.Y - 1)
  self.fill = canvas.GetOffsetFunction(gpu.fill, self.X - 1, self.Y - 1)
  self.copy = canvas.GetOffsetFunction(gpu.copy, self.X - 1, self.Y - 1)
end

function canvas:Paint()
  gpu.setBackground(self.BackColor)
  self.fill(1, 1, self.Width, self.Height, " ")
  if type(self.OnPaint) == "function" then
    self:OnPaint()
  end
end

function canvas:Create(x, y, width, height)
  return gui.Create{
    Paint = self.Paint,
    Init = self.Init,
    IsClicked = gui.IsClicked,
    X = x,
    Y = y,
    Width = width,
    Height = height,
    BackColor = 0x000000,
  }
end

-- Snapshot --

gui.backend.Snapshot = {}
local snapshot = gui.backend.Snapshot

function snapshot:Create()

end

-- Form --
local Form =
{
    BackColor = 0x000000,
    TextColor = 0xffffff,
}
Form.__base = Form

-- function Form:Init()
    -- for _, element in pairs(self.Elements) do
        -- -- element.OffsetX = 0
        -- -- element.OffsetY = 0
        -- element.Parent = self
        -- element:Init()
    -- end
    -- return self
-- end

function Form:Paint(NoClear)
    if type(self.OnPaint) == "function" then
        self:OnPaint()
    end
    if not NoClear then
        gpu.setBackground(self.BackColor)
        gpu.setForeground(self.TextColor)
        width, height = gpu.getResolution()
        gpu.fill(1, 1, width, height, " ")
    end
    pcall(gpu.setResolution, self.Width, self.Height)
    for index, element in pairs(self.Elements) do
        element:Paint()
    end
    return self
end

-- function Form:SwapTo(other)

-- function Form:Enable()
  -- if type(self.OnEnable) == "function" then
    -- pcall(self.OnEnable, self)
  -- end
  -- for index, element in pairs(self.Elements) do
    -- element:Enable()
  -- end
  -- self.enabled = true
  -- return self
-- end

-- function Form:Disable(NoClear)
  -- if type(self.OnDisable) == "function" then
    -- pcall(self.OnDisable, self)
  -- end
  -- for _, element in pairs(self.Elements) do
    -- element:Disable()
  -- end
  -- if not NoClear then
    -- gpu.setResolution(gpu.maxResolution())
    -- gpu.setBackground(0x000000)
    -- gpu.setForeground(0xffffff)
    -- width, height = gpu.getResolution()
    -- gpu.fill(1, 1, width, height, " ")
  -- end
  -- self.enabled = false
  -- return self
-- end

-- function Form:Destroy()
  -- self:Disable()
  -- for _, element in pairs(self.Elements) do
    -- if type(element) == "table" and type(element.Destroy) == "function" then
      -- element:Destroy()
    -- end
  -- end
  -- self.Garbage = true
-- end

local FormMeta = {__index = setmetatable(Form, GroupMeta)}
function gui.CreateForm(form, elements)
    return gui.CreateGroup(form, elements, FormMeta)
end

-- function Form:Create(width, height, elements)
  -- return gui.Create{
    -- Enable = self.Show,
    -- Disable = self.Hide,
    -- Destroy = self.Destroy,
    -- Paint = self.Paint,
    -- Init = self.Init,
    -- Width = width,
    -- Height = height,
    -- BackColor = 0x000000,
    -- TextColor = 0xffffff,
    -- Elements = elements,
  -- }
-- end

return gui --[[
---------------------------------------------------------
local gui = require("AGUI"):CreateWorkSpace()

ScoresForm = gui.CreateForm({Width = 20, Height = 20},
    {
        gui.CreateTextBox{X = 1, Y = 1, Width = 10, Text = "YourфText"},
        gui.CreateCheckBox{X = 1, Y = 3, Width = 20, Text = "всё ок?"},

        TMP = gui.CreateRadioGroup(nil,
        {
            qm = gui.CreateRadioButton{X = 1, Y = 5, Width = 20, Text = "QWERTYмэн"},
            q2 = gui.CreateRadioButton{X = 2, Y = 6, Width = 10, Text = "Qмэн", Checked = true},
        }),

        gui.CreateButton{X = 1, Y = 18, Width = 20, Height = 3, Text = "Back",
        OnElementClick = function()
            -- print(ScoresForm.Elements["TMP"].Checked) os.sleep(1)
            ScoresForm:Disable()
            MainForm:Enable():Paint()
        end},
    }
):Init()

SettingsForm = gui.backend.Form:Create(20, 17,
  {
    gui.CreateText{X = 1, Y = 1, Width = 20, Text = "Settings"},
    
    gui.CreateText{X = 1, Y = 3, Text = "Width"},
    Width  = gui.CreateTextBox{X = 1, Y = 4, Width = 20, Text = "0", AvailableChars = "0123456789"},
    
    gui.CreateText{X = 1, Y = 6, Text = "Height"},
    Height = gui.CreateTextBox{X = 1, Y = 7, Width = 20, Text = "0", AvailableChars = "0123456789"},
    
    SQ     = gui.CreateCheckBox{X = 1, Y = 9, Width = 20, Text = "Super Quality"},
    
    gui.CreateText{X = 1, Y = 11, Text = "Map Generation Mode"},
    Mode = gui.CreateRadioGroup(nil,
    {
        gui.CreateRadioButton{X = 1, Y = 12, Width = 20, Text = "Recursive"},
        gui.CreateRadioButton{X = 1, Y = 13, Width = 20, Text = "Hunt&Kill"},
    }),
    
    gui.CreateButton{X = 1, Y = 15, Width = 20, Height = 3, Text = "Back",
        OnElementClick = function()
          -- print(SettingsForm.Elements["Mode"].Checked) os.sleep(1)
          -- print(SettingsForm.Elements["SQ"].Checked) os.sleep(1)
          -- print(SettingsForm.Elements["Width"].Text) os.sleep(1)
            SettingsForm:Disable()
            MainForm:Enable():Paint()
        end),
    }
):Init()

MainForm = gui.backend.Form:Create(20, 15,
  {
    gui.backend.Button:Create(1, 1, 20, 3, "New Game", function() MainForm:Disable(true) quit = true end),
    gui.backend.Button:Create(1, 5, 20, 3, "High Scores", function()
      MainForm:Disable(true)
      ScoresForm:Enable():Paint()
    end),
    gui.backend.Button:Create(1, 9, 20, 3, "Settings", function()
      MainForm:Disable(true)
      SettingsForm:Enable():Paint()
    end),
    gui.backend.Button:Create(1, 13, 20, 3, "Exit", function() quit = true end),
  }
):Init():Enable():Paint()
Err = gui.backend.MessageBox:Create():Init():Paint()
gui.Error("GG!")
-- gui.backend.MessageBox:Create("congratulation","You Win!"):Modify{ButtonHandle = function() print("HANDLED")  end}:Init():Paint()

eoe = event.onError
event.onError = function(...) 
  quit = true
  print("event error") os.sleep(1)
  return eoe(...)
end

quit = false
pcall(function()
  while not quit do
    event.pull()
  end
end)

event.onError = eoe
-- print(SettingsForm.Elements["Width"].Text, SettingsForm.Elements["Height"].Text) os.sleep(1)

gui.Destroy()
--]]