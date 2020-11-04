local UnitPowerFrameMixin = {}

function UnitPowerFrameMixin:PositionPrediction(max, current)
  if not self.predictedPowerCost then
    return
  end

  local parentWidth = self.refs.costPrediction:GetParent():GetWidth()

  local predictedPercent = self.predictedPowerCost / max
  self.refs.costPrediction:SetWidth(predictedPercent * parentWidth)

  local missingPercent = (max - current) / max

  self.refs.costPrediction:SetAnchor(PandaUICore:anchor("RIGHT", "RIGHT", -missingPercent * parentWidth, -1))
end

function UnitPowerFrameMixin:Update(unit, type)
  local powerType = PowerTokenByLabel[type]

  if powerType == self.props.powerInfo.token then
    local max = UnitPowerMax(unit, powerType)
    local current = UnitPower(unit, powerType)

    if max == 0 then
      self.refs.status:SetValue(0)
    else
      self.refs.status:SetValue(current / max)
    end

    self:PositionPrediction(max, current)
  end
end

function UnitPowerFrameMixin:MakeInactive()
  self.refs.status:SetStatusColor(PandaUIUnits.InactiveColor)
  self.refs.status:SetValue(1)
end

function UnitPowerFrameMixin:MakeActive()
  self:Setup()
end

function UnitPowerFrameMixin:Setup(powerInfo)
  if powerInfo then
    self.props.powerInfo = powerInfo
  else
    local powerType, powerToken = UnitPowerType(self.props.unit)
    self.props.powerInfo = {
      token = powerType,
      label = powerToken,
      color = PowerBarColor[powerType]
    }
  end

  local pClr = self.props.powerInfo.color
  self.refs.status:SetStatusColor(pClr)
  self.refs.background:SetBackgroundColor(PandaUICore:FadeBy(pClr, .05))

  self:Update(self.props.unit, self.props.powerInfo.label)
end

function UnitPowerFrameMixin:StartPrediction()
  local unit = self.props.unit
  local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo(unit)

  local powerType = self.props.powerInfo.token
  local cost = 0
  local costTable = GetSpellPowerCost(spellID)
  for _, costInfo in pairs(costTable) do
    if (costInfo.type == powerType) then
      cost = costInfo.cost
      break
    end
  end

  if cost ~= 0 then
    self.predictedPowerCost = cost
    self.refs.costPrediction:Show()

    local max = UnitPowerMax(unit, powerType)
    local current = UnitPower(unit, powerType)

    self:PositionPrediction(max, current)
  end
end

function UnitPowerFrameMixin:EndPrediction(unit)
  self.predictedPowerCost = nil

  self.refs.costPrediction:SetWidth(0)
  self.refs.costPrediction:Hide()
end

-- End Mixin

function PandaUIUnits:UnitPowerFrame(unit, powerInfo)
  if not powerInfo then
    local powerType, powerToken = UnitPowerType(unit)
    powerInfo = {
      token = powerType,
      label = powerToken,
      color = PowerBarColor[powerType]
    }
  end

  local function Init(frame)
    frame:Setup()
  end
  local function Update(frame, unit, type)
    frame:Update(unit, type)
  end
  local function StartPrediction(frame)
    frame:StartPrediction()
  end
  local function EndPrediction(frame)
    frame:EndPrediction()
  end

  return {
    name = unit .. "Power",
    props = {powerInfo = powerInfo, unit = unit},
    mixin = UnitPowerFrameMixin,
    children = {
      {
        name = "Background",
        ref = "background",
        backgroundColor = PandaUICore:FadeBy(powerInfo.color, .05)
      },
      PandaUICore:StatusBar(
        {
          name = "PowerStatus",
          ref = "status",
          statusBar = {color = powerInfo.color},
          children = {
            {
              name = "CostPrediction",
              ref = "costPrediction",
              hidden = true,
              anchor = PandaUICore:anchor("RIGHT"),
              height = PandaUICore:pct(1),
              width = PandaUICore:val(50),
              backgroundColor = {r = 0, g = 0, b = 0, a = .5},
              events = {}
            }
          }
        }
      )
    },
    events = {PLAYER_ENTERING_WORLD = Init},
    scripts = {OnShow = Init},
    unit = {
      name = unit,
      events = {
        UNIT_POWER_FREQUENT = Update,
        UNIT_DISPLAYPOWER = Init,
        UNIT_SPELLCAST_START = StartPrediction,
        UNIT_SPELLCAST_STOP = EndPrediction,
        UNIT_SPELLCAST_FAILED = EndPrediction,
        UNIT_SPELLCAST_SUCCEEDED = EndPrediction
      }
    }
  }
end
