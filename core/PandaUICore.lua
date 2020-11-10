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
  rootFrame = nil,
  modules = {}
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

function PandaUICore:Split(s)
  chunks = {}
  for substring in s:gmatch("%S+") do
    table.insert(chunks, substring)
  end
  return chunks
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

function PandaUICore:RegisterModule(module)
  table.insert(self.modules, module)
end
