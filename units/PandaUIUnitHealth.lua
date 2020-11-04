local UnitHealthFrameMixin = {}

local DefaultHealthColor = {r = 0, g = .8, b = 0}

function UnitHealthFrameMixin:Update()
  local max = UnitHealthMax(self.props.unit)
  local cur = UnitHealth(self.props.unit)

  local allIncomingHeal = UnitGetIncomingHeals(self.props.unit) or 0
  local totalAbsorb = UnitGetTotalAbsorbs(self.props.unit) or 0

  if totalAbsorb > 0 then
    local p = totalAbsorb / max
    self.refs.absorbPrediction.details.width = PandaUICore:pct(p)
    self.refs.absorbPrediction.details.hidden = false
  else
    self.refs.absorbPrediction.details.hidden = true
  end
  self.refs.absorbPrediction:UpdateStyles()

  if allIncomingHeal > 0 then
    -- if over healing, use amount of lost health instead
    if allIncomingHeal + cur > max then
      allIncomingHeal = max - cur
    end
    local p = allIncomingHeal / max
    self.refs.healPrediction.details.width = PandaUICore:pct(p)
    local offset = (cur / max) * self:GetWidth()
    self.refs.healPrediction.details.anchor = PandaUICore:anchor("RIGHT", "RIGHT", -offset, 0)
    self.refs.healPrediction.details.hidden = false
  else
    self.refs.healPrediction.details.hidden = true
  end
  self.refs.healPrediction:UpdateStyles()

  self.refs.status:SetMinMaxValues(0, max)
  self.refs.status:SetValue(cur)
end

function UnitHealthFrameMixin:CheckForStagger(frame)
  local _, class = UnitClass(self.props.unit)
  local spec = GetSpecialization()

  if class == "MONK" and spec == 1 then
    self:SetScript(
      "OnUpdate",
      function()
        local max = UnitHealthMax(self.props.unit)
        local cur = UnitHealth(self.props.unit)
        local stagger = UnitStagger(self.props.unit)

        local overlayDetails = self.refs.staggerOverlay.details
        if stagger > 0 then
          local p = stagger / max
          overlayDetails.width = PandaUICore:pct(p)
          overlayDetails.hidden = false

          local offset = (cur / max) * self:GetWidth()
          overlayDetails.anchor = PandaUICore:anchor("LEFT", "RIGHT", -offset, 0)
        else
          overlayDetails.hidden = true
        end

        self.refs.staggerOverlay:UpdateStyles()
      end
    )
  else
    self:SetScript("OnUpdate", nil)
  end
end

function UnitHealthFrameMixin:MakeInactive()
  self.refs.status:SetStatusColor(PandaUIUnits.InactiveColor)
  self:SetBackgroundColor(PandaUIUnits.InactiveColor)
end

function UnitHealthFrameMixin:MakeActive()
  self.refs.status:SetStatusColor(DefaultHealthColor)
  self:SetBackgroundColor(PandaUICore:FadeBy(DefaultHealthColor, PandaUIUnits.BackgroundAlpha))
end

function PandaUIUnits:UnitHealthFrame(unit, reverseFill)
  local function Update(frame)
    frame:Update()
  end
  return {
    name = unit .. "Health",
    props = {unit = unit},
    mixin = UnitHealthFrameMixin,
    backgroundColor = {r = 0, g = .8, b = 0, a = .05},
    children = {
      PandaUICore:StatusBar(
        {
          ref = "status",
          statusBar = {
            color = {r = 0, g = .8, b = 0, a = 1.0},
            reverse = reverseFill or false
          },
          children = {
            {
              name = "AbsorbPrediction",
              ref = "absorbPrediction",
              hidden = true,
              height = PandaUICore:pct(1),
              anchor = PandaUICore:anchor("RIGHT"),
              backgroundColor = {r = 1.0, g = 1.0, b = 1.0, a = .5}
            },
            {
              name = "HealPrediction",
              ref = "healPrediction",
              hidden = true,
              height = PandaUICore:pct(1),
              backgroundColor = {r = 0.0, g = .8, b = 0.0, a = .5}
            },
            {
              name = "StaggerOverlay",
              ref = "staggerOverlay",
              hidden = true,
              height = PandaUICore:pct(1),
              backgroundColor = {r = 0, g = 0, b = 0, a = .5}
            }
          }
        }
      )
    },
    init = Update,
    unit = {
      name = unit,
      events = {
        UNIT_HEALTH = Update,
        UNIT_HEAL_PREDICTION = Update,
        UNIT_ABSORB_AMOUNT_CHANGED = Update,
        UNIT_MAXHEALTH = Update,
        PLAYER_SPECIALIZATION_CHANGED = function(frame)
          frame:CheckForStagger()
        end
      }
    },
    events = {},
    scripts = {
      OnShow = function(frame)
        frame:CheckForStagger()
        frame:Update()
      end
    }
  }
end
