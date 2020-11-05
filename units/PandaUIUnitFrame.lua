function PandaUIUnits:GetUnitInfo(unit)
  if not UnitExists(unit) then
    return {exists = false}
  end

  local powerType, powerToken = UnitPowerType(unit)
  local name, realm = UnitName(unit)
  local info = {
    exists = true,
    name = name,
    realm = realm,
    class = UnitClass(unit),
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

local DefaultBackgroundColor = {r = .5, g = .5, b = .5, a = PandaUIUnits.BackgroundAlpha}
local DefaultCastColor = {r = .8, g = .8, b = .8, a = .75}

function PandaUIUnits:UnitFrame(unit, dropDownMenu)
  local function UpdateCastBars(frame)
    frame.refs.cast:SetMinMaxValues(0, frame.maxValue)
    frame.refs.cast:SetValue(frame.value)
  end

  local function UpdateCast(frame)
    if not frame.casting then
      return
    end

    frame.value = GetTime() - (frame.startTime / 1000)
    UpdateCastBars(frame)
  end

  local function EndCast(frame, unit)
    frame.casting = false
    frame.maxValue = 1
    frame.value = 0
    UpdateCastBars(frame)
    frame:SetScript("OnUpdate", nil)
  end

  local function InitCastbars(frame, unit, infoFunc)
    local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = infoFunc(unit)

    if name then
      frame:SetScript(
        "OnUpdate",
        function(frame)
          UpdateCast(frame)
        end
      )
      frame.casting = true
      frame.startTime = startTime
      frame.maxValue = (endTime - startTime) / 1000
      UpdateCast(frame)
    end
  end

  local InitCast = function(frame, unit)
    InitCastbars(frame, unit, UnitCastingInfo)
  end

  local InitChannel = function(frame, unit)
    InitCastbars(frame, unit, UnitChannelInfo)
  end

  local function Setup(frame)
    local info = PandaUIUnits:GetUnitInfo(unit)

    frame.refs.cast:SetValue(0)
    frame:SetScript("OnUpdate", nil)
    -- Check for casting and channeling on new unit
    InitCast(frame, unit)
    if not frame.casting then
      InitChannel(frame, unit)
    end

    frame.refs.health:Update()

    frame.refs.power.details.hidden = info.maxPower == 0
    frame.refs.unitStatus:UpdateLayout()
    frame.refs.power:Setup()

    if not info.exists or info.dead then
      frame.casting = false
      frame.channeling = false
      frame:SetBackgroundColor(PandaUICore:FadeBy(PandaUIUnits.InactiveColor, PandaUIUnits.BackgroundAlpha))
      frame:SetAlpha(.5)
      frame.refs.health:MakeInactive()
      frame.refs.power:MakeInactive()
    else
      frame:SetAlpha(1.0)
      frame:SetBackgroundColor(frame.backgroundColor or DefaultBackgroundColor)
      frame.refs.health:MakeActive()
      frame.refs.power:MakeActive()
    end

    frame:UpdateUnit()
  end

  local function Update(frame)
    local info = PandaUIUnits:GetUnitInfo(unit)

    -- set description text
    local classification = ClassificationLabels[info.classification or ""] or ""

    -- allow level to be specified by creator of frame
    local level = frame.level or info.level or -1
    if level == -1 then
      level = "??"
    end
    if classification ~= "" then
      level = level .. " "
    end

    local description = string.format("(%s%s) %s", level, classification, info.name or "")

    -- Compare size to frame size
    if string.len(description) > 10 then
      description = string.sub(description, 0, 14) .. "..."
    end

    frame.refs.description.text:SetText(description)
  end

  return {
    name = "UnitFrame",
    height = PandaUICore:val(50 + 15 * 2),
    width = PandaUICore:val(30 + 150),
    childLayout = {
      type = "align",
      direction = "horizontal"
    },
    children = {
      {
        name = "Left",
        width = PandaUICore:val(30),
        backgroundColor = {r = 1}
      },
      {
        width = PandaUICore:val(150),
        childLayout = {
          type = "align",
          direction = "vertical"
        },
        children = {
          {
            name = "Top",
            height = PandaUICore:val(15),
            backgroundColor = {b = 1}
          },
          {
            name = "Middle",
            backgroundColor = DefaultBackgroundColor,
            height = PandaUICore:val(50),
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
                height = PandaUICore:val(40),
                width = PandaUICore:val(140),
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
                init = function(frame)
                  local button =
                    CreateFrame("Button", frame:GetName() .. "UnitButton", frame, "SecureUnitButtonTemplate")
                  button:SetSize(frame:GetWidth(), frame:GetHeight())
                  button:RegisterForClicks("AnyUp")
                  button:SetPoint("CENTER")
                  SecureUnitButton_OnLoad(button, unit, dropDownMenu)
                  -- button:SetAttribute("*type1", "target");
                  -- button:SetAttribute("shift-type2", "target");
                  -- button:SetAttribute("unit", unit);
                  button:SetScript(
                    "OnEnter",
                    function(frame)
                      GameTooltip:SetOwner(frame, "ANCHOR_BOTTOM")
                      GameTooltip:SetUnit(unit, true)
                      GameTooltip:Show()
                    end
                  )
                  button:SetScript(
                    "OnLeave",
                    function(frame)
                      GameTooltip:Hide()
                    end
                  )
                end
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
            name = "Bottom",
            height = PandaUICore:val(15),
            backgroundColor = {b = 1}
          }
        }
      }
    },
    unit = {
      name = unit,
      events = {
        UNIT_HEALTH = Update,
        UNIT_POWER_FREQUENT = Update,
        UNIT_SPELLCAST_START = InitCast,
        UNIT_SPELLCAST_DELAYED = InitCast,
        UNIT_SPELLCAST_STOP = EndCast,
        UNIT_SPELLCAST_FAILED = EndCast,
        UNIT_SPELLCAST_INTERRUPTED = EndCast,
        UNIT_SPELLCAST_CHANNEL_START = InitChannel,
        UNIT_SPELLCAST_CHANNEL_UPDATE = InitChannel,
        UNIT_SPELLCAST_CHANNEL_STOP = EndCast,
        UNIT_LEVEL = Update
      }
    },
    events = {},
    scripts = {
      OnShow = function(frame)
        frame:SetupUnit()
      end
    },
    init = function(frame)
      function frame:UpdateUnit()
        Update(frame)
      end
      function frame:SetupUnit()
        Setup(frame)
      end
    end
  }
end

local function SetMovable(details, default, vars, saveVar)
  local point = vars[saveVar] or default
  details.anchor = PandaUICore:anchor(point.point, point.relativePoint, point.xOfs, point.yOfs)
  details.movable = true
  details.scripts.OnMouseDown = function(frame)
    frame:StartMoving()
  end
  details.scripts.OnMouseUp = function(frame)
    frame:StopMovingOrSizing()
    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(1)
    vars[saveVar] = {
      point = point,
      relativeTo = relativeTo,
      relativePoint = relativePoint,
      xOfs = xOfs,
      yOfs = yOfs
    }

    frame.details.anchor = PandaUICore:anchor(point, relativePoint, xOfs, yOfs)
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
  local details = self:UnitFrame("target", showmenu)
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

    frame:SetupUnit()
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
  local details = self:UnitFrame("player", menuFunc)
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
    frame:UpdateUnit()
  end
  details.events.PLAYER_LEVEL_CHANGED = function(frame, oldLevel, newLevel)
    frame.level = newLevel
    frame:UpdateUnit()
  end

  return details
end
