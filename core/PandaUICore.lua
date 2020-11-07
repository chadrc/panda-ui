PowerTokenByLabel = {
  MANA = Enum.PowerType.Mana,
  RAGE = Enum.PowerType.Rage,
  FOCUS = Enum.PowerType.Focus,
  ENERGY = Enum.PowerType.Energy,
  COMBO_POINTS = Enum.PowerType.ComboPoints,
  RUNES = Enum.PowerType.Runes,
  RUNIC_POWER = Enum.PowerType.RunicPower,
  SOUL_SHARDS = Enum.PowerType.SoulShards,
  LUNAR_POWER = Enum.PowerType.LunarPower,
  HOLY_POWER = Enum.PowerType.HolyPower,
  ALTERNATE = Enum.PowerType.Alternate,
  MAELSTROM = Enum.PowerType.Maelstrom,
  CHI = Enum.PowerType.Chi,
  ARCANE_CHARGES = Enum.PowerType.ArcaneCharges,
  FURY = Enum.PowerType.Fury,
  PAIN = Enum.PowerType.Pain,
  INSANITY = Enum.PowerType.Insanity
}

PandaUICore = {
  hider = CreateFrame("Frame"),
  showingBlizzardUI = true,
  rootFrame = nil
}

-- no-ops to prevent errors
function PandaUICore.hider:OnStatusBarsUpdated()
end

local framesToHide = {
  PlayerFrame = {},
  StatusTrackingBarManager = {},
  TargetFrame = {
    shouldShow = function()
      return UnitExists("target")
    end
  },
  FocusFrame = {
    shouldShow = function()
      return UnitExists("focus")
    end
  },
  --   MinimapCluster = {},
  MainMenuBarArtFrame = {},
  MicroButtonAndBagsBar = {},
  MultiBarRight = {},
  MultiBarLeft = {},
  --   ObjectiveTrackerFrame = {},
  BuffFrame = {},
  DurabilityFrame = {},
  CastingBarFrame = {},
  StanceBarFrame = {}
}

function PandaUICore:Print(t)
  if type(t) ~= "table" then
    print(t)
    return
  end

  local strs = {}
  for k, v in pairs(t) do
    table.insert(
      strs,
      string.format("%s = %s", tostring(k), tostring(v))
    )
  end
  print(table.concat(strs, ", "))
end

function PandaUICore:ApplyMixin(to, mixin)
  local m = PandaUICore:Clone(mixin or {})
  for k, v in pairs(m) do
    to[k] = v
  end
end

function PandaUICore:Merge(left, right)
  PandaUICore:ApplyMixin(left, right)
  return left
end

function PandaUICore:Clone(t)
  local n = {}
  for k, v in pairs(t) do
    n[k] = v
  end
  return n
end

function PandaUICore:FadeBy(clr, by)
  local new = PandaUICore:Clone(clr)
  new.a = new.a or 1.0
  new.a = new.a * by
  return new
end

function PandaUICore:ToggleUI()
  if InCombatLockdown() then
    return
  end
  if self.showingBlizzardUI then
    self:HideBlizzardUI()
    self:ShowPandaUI()
  else
    self:ShowBlizzardUI()
    self:HidePandaUI()
  end
end

function PandaUICore:HidePandaUI()
  self.rootFrame:Hide()
end

function PandaUICore:ShowPandaUI()
  self.rootFrame:Show()
end

function PandaUICore:TogglePandaUI()
  if InCombatLockdown() then
    return
  end
  if self.rootFrame:IsShown() then
    PandaUICore:HidePandaUI()
  else
    PandaUICore:ShowPandaUI()
  end
end

function PandaUICore:HideBlizzardUI(options)
  self.hider:Hide()

  for name, details in pairs(framesToHide) do
    details.parent = _G[name]:GetParent()
    _G[name]:SetParent(self.hider)
    _G[name]:Hide()
  end

  -- HidePartyFrame();

  self.showingBlizzardUI = false
end

function PandaUICore:ShowBlizzardUI(options)
  for name, details in pairs(framesToHide) do
    _G[name]:SetParent(details.parent)
    if not details.shouldShow or details.shouldShow() then
      _G[name]:Show()
    end
  end

  -- ShowPartyFrame();

  self.showingBlizzardUI = true
end

function PandaUICore:ToggleBlizzardUI()
  if self.showingBlizzardUI then
    self:HideBlizzardUI()
  else
    self:ShowBlizzardUI()
  end
end

function PandaUICore:Initialize()
  self.rootFrame =
    CreateFrame(
    "Frame",
    "PandaUIRootFrame",
    UIParent,
    BackdropTemplateMixin and "BackdropTemplate"
  )
  self.rootFrame:SetSize(
    self.rootFrame:GetParent():GetWidth(),
    self.rootFrame:GetParent():GetHeight()
  )
  self.rootFrame:SetBackdrop(
    {
      bgFile = "Interface\\Buttons\\WHITE8X8",
      tile = true
    }
  )
  self.rootFrame:SetBackdropColor(0, 0, 0, 0)
  self.rootFrame:SetPoint("BOTTOMLEFT")
end

function PandaUICore:CreateFrame(name, details, children)
  local d = details or {}
  local tmp = d.template
  local t = d.type or "Frame"
  local root = self.rootFrame
  d.parent = d.parent or root
  local n = name

  if n then
    n = d.parent:GetName() .. n
  else
    n =
      d.parent:GetName() ..
      "_ChildFrame_" .. tostring(d.parent:GetNumChildren() + 1)
  end

  local templates = {}
  if BackdropTemplateMixin then
    table.insert(templates, "BackdropTemplate")
  end
  if tmp then
    table.insert(templates, tmp)
  end

  local frame =
    CreateFrame(t, n, d.parent, table.concat(templates, ","))
  PandaUICore:ApplyFrameMixin(frame)
  PandaUICore:ApplyMixin(frame, d.mixin)

  frame:SetBackdrop(
    {bgFile = "Interface\\Buttons\\WHITE8X8", tile = true}
  )

  frame.details = d
  frame.refs = {}
  if d.movable then
    frame:RegisterForDrag("LeftButton")
    frame:SetMovable(d.movable)
  end

  -- Probably won't need to set this more than once
  -- only set here to avoid it being set in combat
  if d.frameLevel then
    frame:SetFrameLevel(d.frameLevel)
  end

  if d.attributes then
    for k, v in pairs(d.attributes) do
      -- print('attr: ', k, " = ", v);
      frame:SetAttribute(k, v)
    end
  end

  local childFrames = {}
  if children then
    for i, child in ipairs(children) do
      child.parent = frame

      local childFrame =
        PandaUICore:CreateFrame(child.name, child, child.children)
      table.insert(childFrames, childFrame)

      for k, v in pairs(childFrame.refs) do
        frame.refs[k] = v
      end
      if child.ref then
        frame.refs[child.ref] = childFrame
      end
    end
  end
  frame.childFrames = childFrames

  if d.onEnter then
    frame:SetScript("OnEnter", d.onEnter)
  end
  if d.onLeave then
    frame:SetScript("OnLeave", d.onLeave)
  end

  if d.scripts then
    for h, s in pairs(d.scripts) do
      local f = s
      if type(s) == "string" then
        f = frame[s]
      end
      frame:SetScript(h, f)
    end
  end

  if d.clicks then
    frame:RegisterForClicks(unpack(d.clicks))
  end
  if t == "Button" and d.onClick then
    frame:SetScript("OnClick", d.onClick)
  end

  local allEvents = {}
  for name, h in pairs(d.events or {}) do
    frame:RegisterEvent(name)
    local f = h
    if type(f) == "string" then
      f = frame[h]
    end
    allEvents[name] = f
  end

  if d.unit then
    for name, h in pairs(d.unit.events or {}) do
      frame:RegisterUnitEvent(name, d.unit.name)
      local f = h
      if type(f) == "string" then
        f = frame[h]
      end
      allEvents[name] = f
    end
  end

  if table.getn(allEvents) then
    frame:SetScript(
      "OnEvent",
      function(self, event, ...)
        if allEvents[event] then
          allEvents[event](self, ...)
        end
      end
    )
  end

  frame.events = d.events
  frame.props = d.props

  return frame
end

-- Convenience Utilities

function PandaUICore:anchor(base, relative, offsetX, offsetY)
  return {
    base = base or "BOTTOMLEFT",
    relative = relative or base or "BOTTOMLEFT",
    offsetX = offsetX or 0,
    offsetY = offsetY or 0
  }
end
function PandaUICore:auto()
  return {type = "auto"}
end
function PandaUICore:val(v)
  return {type = "value", value = v}
end
function PandaUICore:pct(p)
  return {type = "percentage", value = p}
end
function PandaUICore:calc(f)
  return {type = "calc", func = f}
end
function PandaUICore:StatusBar(details)
  local orgInit = details.init
  local statusDetails = details.statusBar or {}

  local d = {}
  for k, v in pairs(details) do
    d[k] = v
  end

  d.name = d.name or "StatusBar"
  d.type = "StatusBar"
  d.init = function(frame)
    local texture =
      frame:CreateTexture(frame:GetName() .. "Texture", "BACKGROUND")
    texture:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.statusBarTexture = texture
    frame:SetStatusBarTexture(texture)
    frame:SetMinMaxValues(0, 1)
    frame:SetValue(0)
    frame:SetReverseFill(statusDetails.reverse or false)

    function frame:SetStatusColor(color)
      local clr = color or {r = 1.0, g = 1.0, b = 1.0, a = 1.0}
      texture:SetColorTexture(clr.r, clr.g, clr.b, clr.a)
    end
    frame:SetStatusColor(statusDetails.color)

    if orgInit then
      orgInit(frame)
    end
  end

  return d
end
