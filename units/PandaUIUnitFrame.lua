function PandaUIUnits:GetUnitInfo(unit)
  if not UnitExists(unit) then
    return {exists = false, classFile = ""}
  end

  local powerType, powerToken = UnitPowerType(unit)
  local name, realm = UnitName(unit)
  local className, classFile = UnitClass(unit)
  local info = {
    exists = true,
    name = name,
    realm = realm,
    class = className,
    classFile = classFile,
    maxHealth = UnitHealthMax(unit),
    health = UnitHealth(unit),
    connected = UnitIsConnected(unit),
    dead = UnitIsDead(unit),
    castingInfo = {UnitCastingInfo(unit)},
    channelingInfo = {UnitChannelInfo(unit)},
    incomingHeals = UnitGetIncomingHeals(unit),
    totalAbsorbs = UnitGetTotalAbsorbs(unit),
    totalHealAbsorbs = UnitGetTotalHealAbsorbs(unit),
    groupRole = UnitGroupRolesAssigned(unit),
    isGhost = UnitIsGhost(unit),
    level = UnitLevel(unit),
    powerType = powerType,
    powerToken = powerToken,
    maxPower = UnitPowerMax(unit),
    power = UnitPower(unit),
    isEnemy = UnitIsEnemy("player", unit),
    isFriend = UnitIsFriend("player", unit),
    classification = UnitClassification(unit)
  }

  return info
end

local ClassificationLabels = {
  worldboss = "W",
  rareelite = "RE",
  elite = "E",
  rare = "R",
  normal = "",
  trivial = "",
  minus = "C"
}

PandaUIUnits.BackgroundAlpha = .5
PandaUIUnits.InactiveColor = {r = .5, g = .5, b = .5}

local DefaultBackgroundColor = {
  r = .5,
  g = .5,
  b = .5,
  a = PandaUIUnits.BackgroundAlpha
}
local DefaultCastColor = {r = .8, g = .8, b = .8, a = .75}

local UnitFrameMixin = {}

function UnitFrameMixin:UpdateCastBars(frame)
  self.refs.cast:SetMinMaxValues(0, self.maxValue)
  self.refs.cast:SetValue(self.value)
end

function UnitFrameMixin:UpdateCast(frame)
  if not self.casting then
    return
  end

  self.value = GetTime() - (self.startTime / 1000)
  self:UpdateCastBars(self)
end

function UnitFrameMixin:EndCast(frame, unit)
  self.casting = false
  self.maxValue = 1
  self.value = 0
  self.refs.castIcon:Hide()
  self:UpdateCastBars(frame)
  self:SetScript("OnUpdate", nil)
end

function UnitFrameMixin:InitCastbars(frame, unit, infoFunc)
  local name,
    text,
    texture,
    startTime,
    endTime,
    isTradeSkill,
    castID,
    notInterruptible = infoFunc(self.props.unit)

  self.refs.castIcon:Show()
  self.refs.castIcon.texture:SetTexture(texture)

  if name then
    self:SetScript(
      "OnUpdate",
      function(self)
        self:UpdateCast(self)
      end
    )
    self.casting = true
    self.startTime = startTime
    self.maxValue = (endTime - startTime) / 1000
    self:UpdateCast(self)
  end
end

function UnitFrameMixin:InitCast(frame, unit)
  self:InitCastbars(self, unit, UnitCastingInfo)
end

function UnitFrameMixin:InitChannel(frame, unit)
  self:InitCastbars(self, unit, UnitChannelInfo)
end

function UnitFrameMixin:Setup(frame)
  local unit = self.props.unit
  local info = PandaUIUnits:GetUnitInfo(unit)

  self.refs.cast:SetValue(0)
  self:SetScript("OnUpdate", nil)
  -- Check for casting and channeling on new unit
  self:InitCast(self, unit)
  if not self.casting then
    self:InitChannel(self, unit)
  end

  self.refs.health:Update()

  self.refs.power.details.hidden = info.maxPower == 0
  self.refs.unitStatus:UpdateLayout()
  self.refs.power:Setup()

  -- still deciding between this or crosshairs
  --   self.refs.actions.texture:SetTexture(
  --     string.format("Interface\\ICONS\\ClassIcon_%s", info.classFile)
  --   )

  if not info.exists or info.dead then
    self.casting = false
    self.channeling = false
    self.refs.unitStatus:SetBackgroundColor(
      PandaUICore:FadeBy(
        PandaUIUnits.InactiveColor,
        PandaUIUnits.BackgroundAlpha
      )
    )
    self:SetAlpha(.5)
    self.refs.health:MakeInactive()
    self.refs.power:MakeInactive()
  else
    self:SetAlpha(1.0)
    self.refs.unitStatus:SetBackgroundColor(
      self.backgroundColor or DefaultBackgroundColor
    )
    self.refs.health:MakeActive()
    self.refs.power:MakeActive()
  end

  self:Update()
end

function UnitFrameMixin:Update(frame)
  local info = PandaUIUnits:GetUnitInfo(self.props.unit)

  -- set description text
  local classification =
    ClassificationLabels[info.classification or ""] or ""

  -- allow level to be specified by creator of frame
  local level = self.level or info.level or -1
  if level == -1 then
    level = "??"
  end
  if classification ~= "" then
    level = level .. " "
  end

  local description = string.format("(%s%s)", level, classification)

  self.refs.description.text:SetText(description)

  self.refs.debuffs:Update()
  self.refs.buffs:Update()
end

-- Move to settings eventually
local LeftPanelWidth = 25
local RightPanelWidth = 85
local TopPanelHeight = 15
local BottomPanelHeight = TopPanelHeight
local MiddlePanelHeight = 50
local StatusPadding = 10
local TotalWidth = LeftPanelWidth + RightPanelWidth
local TotalHeight =
  BottomPanelHeight + TopPanelHeight + MiddlePanelHeight
local ControlButtonSize = 15
local ControlButtonSpacing = 5
local ControlPanelHeight =
  ControlButtonSize * 2 + ControlButtonSpacing
local ControlPanelWidth = ControlButtonSize
local AuraSize = 15
local AuraPadding = 2.5
local MaxAuraCount = 5

local BuffGridMixin = {}

function BuffGridMixin:Update()
  local frame = self
  local maxCount = self.props.maxCount
  local index = 1
  AuraUtil.ForEachAura(
    self.props.unit,
    self.props.filter,
    maxCount,
    function(...)
      local name,
        buffTexture,
        count,
        debuffType,
        duration,
        expirationTime,
        _,
        _,
        _,
        _,
        _,
        _,
        _,
        _,
        timeMod = ...

      local buffFrame = frame.childFrames[index]
      --   buffFrame.expirationTime = aura.expirationTime
      buffFrame.details.hidden = false
      buffFrame.auraIndex = index

      buffFrame.texture:SetTexture(buffTexture)
      buffFrame.details.texture.file = buffTexture

      --   local timeText = buffFrame.refs.timeText.details.text
      --   local stackText = buffFrame.refs.stackText.details.text

      --   if aura.duration > 0 and aura.expirationTime then
      --     timeText.hidden = false
      --     buffFrame:SetScript("OnUpdate", UpdateAura)
      --     UpdateAura(buffFrame)
      --   else
      --     timeText.hidden = true
      --   end

      --   stackText.hidden = not aura.count or aura.count == 0
      --   stackText.text = aura.count or ""

      --   buffFrame.refs.timeText:UpdateStyles()
      --   buffFrame.refs.stackText:UpdateStyles()
      buffFrame:UpdateStyles()

      index = index + 1
      return index > maxCount
    end
  )

  -- hide remaining frames
  for i = index, maxCount do
    frame.childFrames[i].details.hidden = true
    frame.childFrames[i]:UpdateStyles()
    frame.childFrames[i]:SetScript("OnUpdate", nil)
  end
end

local function MakeAuraGrid(unit, name, anchor, filter, maxCount)
  local children = {}
  for i = 1, maxCount do
    table.insert(
      children,
      {
        name = "Buff" .. i,
        -- backgroundColor = {g = 1},
        hidden = true,
        texture = {}
      }
    )
  end

  return {
    name = name,
    ref = string.lower(name),
    mixin = BuffGridMixin,
    props = {
      unit = unit,
      filter = filter,
      maxCount = maxCount
    },
    height = PandaUICore:val(10),
    anchor = PandaUICore:anchor(anchor),
    width = PandaUICore:val(RightPanelWidth - 10),
    childLayout = {
      type = "grid",
      rows = 1,
      cellWidth = AuraSize,
      cellHeight = AuraSize,
      cellPadding = 2.5
    },
    children = children,
    unit = {
      name = unit,
      events = {
        UNIT_AURA = function(frame, unit)
          frame:Update()
        end
      }
    }
  }
end

function PandaUIUnits:UnitFrame(
  unit,
  dropDownMenu,
  buffFilter,
  debuffFilter)
  return {
    name = "UnitFrame",
    mixin = UnitFrameMixin,
    props = {
      unit = unit
    },
    height = PandaUICore:val(TotalHeight),
    width = PandaUICore:val(TotalWidth),
    childLayout = {
      type = "align",
      direction = "horizontal"
    },
    children = {
      {
        name = "Left",
        width = PandaUICore:val(LeftPanelWidth),
        -- backgroundColor = {r = 1},
        children = {
          {
            childLayout = {type = "align", direction = "vertical"},
            width = PandaUICore:val(ControlPanelWidth),
            height = PandaUICore:val(ControlPanelHeight),
            anchor = PandaUICore:anchor("CENTER"),
            children = {
              {
                name = "CastIcon",
                ref = "castIcon",
                height = PandaUICore:val(ControlButtonSize),
                width = PandaUICore:val(ControlButtonSize),
                -- backgroundColor = {g = 1},
                texture = {},
                hidden = true
              },
              {
                height = PandaUICore:val(ControlButtonSpacing)
              },
              {
                name = "Target",
                ref = "actions",
                height = PandaUICore:val(ControlButtonSize),
                width = PandaUICore:val(ControlButtonSize),
                -- backgroundColor = {r = 0, g = 0, b = 0},
                texture = {
                  file = "Interface\\CURSOR\\Crosshairs"
                },
                init = function(frame)
                  local button =
                    CreateFrame(
                    "Button",
                    frame:GetName() .. "UnitButton",
                    frame,
                    "SecureUnitButtonTemplate"
                  )
                  button:SetSize(frame:GetWidth(), frame:GetHeight())
                  button:RegisterForClicks("AnyUp")
                  button:SetPoint("CENTER")
                  SecureUnitButton_OnLoad(button, unit, dropDownMenu)
                  -- button:SetAttribute("*type1", "target");
                  -- button:SetAttribute("shift-type2", "target");
                  -- button:SetAttribute("unit", unit);
                end
              }
            }
          }
        }
      },
      {
        width = PandaUICore:val(RightPanelWidth),
        childLayout = {
          type = "align",
          direction = "vertical"
        },
        children = {
          {
            name = "Bottom",
            height = PandaUICore:val(TopPanelHeight),
            -- backgroundColor = {b = 1},
            children = {
              MakeAuraGrid(
                unit,
                "Debuffs",
                "BOTTOMLEFT",
                debuffFilter,
                MaxAuraCount
              )
            }
          },
          {
            name = "Middle",
            backgroundColor = DefaultBackgroundColor,
            height = PandaUICore:val(MiddlePanelHeight),
            children = {
              PandaUICore:StatusBar(
                {
                  name = "CastBar",
                  ref = "cast",
                  statusBar = {color = DefaultCastColor}
                }
              ),
              {
                name = "Status",
                ref = "unitStatus",
                childLayout = {direction = "vertical"},
                height = PandaUICore:val(
                  MiddlePanelHeight - StatusPadding
                ),
                width = PandaUICore:val(
                  RightPanelWidth - StatusPadding
                ),
                anchor = PandaUICore:anchor("CENTER"),
                children = {
                  PandaUICore:Merge(
                    PandaUIUnits:UnitHealthFrame(unit),
                    {
                      ref = "health",
                      layout = {parts = 9}
                    }
                  ),
                  PandaUICore:Merge(
                    PandaUIUnits:UnitPowerFrame(unit),
                    {
                      ref = "power"
                    }
                  )
                },
                scripts = {
                  OnEnter = function(frame)
                    GameTooltip:SetOwner(frame, "ANCHOR_BOTTOMRIGHT")
                    GameTooltip:SetUnit(unit, true)
                    GameTooltip:Show()
                  end,
                  OnLeave = function(frame)
                    GameTooltip:Hide()
                  end
                }
              },
              {
                name = "Description",
                ref = "description",
                text = {
                  font = "PandaUI_GameFontNormalMed",
                  -- text = "Test Value",
                  anchor = PandaUICore:anchor("CENTER")
                },
                frameLevel = 100
              }
            }
          },
          {
            name = "Top",
            height = PandaUICore:val(BottomPanelHeight),
            -- backgroundColor = {b = 1}
            children = {
              MakeAuraGrid(
                unit,
                "Buffs",
                "TOPLEFT",
                buffFilter,
                MaxAuraCount
              )
            }
          }
        }
      }
    },
    unit = {
      name = unit,
      events = {
        UNIT_HEALTH = "Update",
        UNIT_POWER_FREQUENT = "Update",
        UNIT_SPELLCAST_START = "InitCast",
        UNIT_SPELLCAST_DELAYED = "InitCast",
        UNIT_SPELLCAST_STOP = "EndCast",
        UNIT_SPELLCAST_FAILED = "EndCast",
        UNIT_SPELLCAST_INTERRUPTED = "EndCast",
        UNIT_SPELLCAST_CHANNEL_START = "InitChannel",
        UNIT_SPELLCAST_CHANNEL_UPDATE = "InitChannel",
        UNIT_SPELLCAST_CHANNEL_STOP = "EndCast",
        UNIT_LEVEL = "Update"
      }
    },
    events = {},
    scripts = {
      OnShow = "Setup"
    }
  }
end

local function SetMovable(details, default, vars, saveVar)
  local point = vars[saveVar] or default
  details.anchor =
    PandaUICore:anchor(
    point.point,
    point.relativePoint,
    point.xOfs,
    point.yOfs
  )
  details.movable = true
  details.scripts.OnMouseDown = function(frame)
    frame:StartMoving()
  end
  details.scripts.OnMouseUp = function(frame)
    frame:StopMovingOrSizing()
    local point, relativeTo, relativePoint, xOfs, yOfs =
      frame:GetPoint(1)
    vars[saveVar] = {
      point = point,
      relativeTo = relativeTo,
      relativePoint = relativePoint,
      xOfs = xOfs,
      yOfs = yOfs
    }

    frame.details.anchor =
      PandaUICore:anchor(point, relativePoint, xOfs, yOfs)
  end
end

function PandaUIUnits:TargetFrame(vars)
  local dropdown = TargetFrameDropDown
  local menuFunc = TargetFrameDropDown_Initialize
  UIDropDownMenu_SetInitializeFunction(dropdown, menuFunc)
  UIDropDownMenu_SetDisplayMode(dropdown, "MENU")

  local showmenu = function()
    ToggleDropDownMenu(1, nil, dropdown, "cursor", 0, 0)
  end
  local details =
    self:UnitFrame("target", showmenu, "HELPFUL", "HARMFUL PLAYER")
  details.hidden = true

  local function SetupTarget(frame)
    local info = PandaUIUnits:GetUnitInfo("target")
    local playerInCombat = InCombatLockdown()

    if info.exists then
      if not playerInCombat then
        frame:Show()
      end

      if info.isFriend then
        frame.backgroundColor = {r = 0, g = .5, b = 0, a = .4}
      elseif info.isEnemy then
        frame.backgroundColor = {r = .5, g = 0, b = 0, a = .4}
      else
        -- let frame use its default
        frame.backgroundColor = nil
      end
    elseif not playerInCombat then
      frame.details.hidden = true
      frame:Hide()
    end

    frame:Setup()
  end

  details.events.PLAYER_ENTERING_WORLD = SetupTarget
  details.events.PLAYER_TARGET_CHANGED = SetupTarget
  details.events.PLAYER_REGEN_DISABLED = function(frame)
    -- try to catch before combat and show target frame
    if not UnitExists("target") and not InCombatLockdown() then
      frame.details.hidden = false
      frame:UpdateStyles()
    end
  end

  details.events.PLAYER_REGEN_ENABLED = function(frame)
    if not UnitExists("target") and not InCombatLockdown() then
      frame.details.hidden = true
      frame:UpdateStyles()
    end
  end

  SetMovable(
    details,
    {
      point = "CENTER",
      relativePoint = "CENTER",
      xOfs = 0,
      yOfs = 200
    },
    vars.Target,
    "position"
  )

  return details
end

function PandaUIUnits:PlayerFrame(vars)
  local menuFunc = function()
    ToggleDropDownMenu(1, nil, PlayerFrameDropDown, "cursor", 0, 0)
  end
  local details =
    self:UnitFrame("player", menuFunc, "HELPFUL RAID", "HARMFUL RAID")
  details.anchor = point
  SetMovable(
    details,
    {
      point = "CENTER",
      relativePoint = "CENTER",
      xOfs = 0,
      yOfs = -200
    },
    vars.Player,
    "position"
  )

  details.events.PLAYER_LEVEL_UP = function(frame, level)
    frame.level = level
    frame:Update()
  end
  details.events.PLAYER_LEVEL_CHANGED = function(
    frame,
    oldLevel,
    newLevel)
    frame.level = newLevel
    frame:Update()
  end

  return details
end
