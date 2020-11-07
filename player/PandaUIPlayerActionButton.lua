local ActionButtonMixin = {}

function ActionButtonMixin:Setup()
  local button =
    CreateFrame(
    "Button",
    self:GetName() .. "Button",
    self,
    "SecureActionButtonTemplate"
  )
  button:RegisterForClicks("AnyUp")
  button:SetSize(self:GetWidth(), self:GetHeight())
  button:SetPoint("CENTER")

  self.actionButton = button

  button:SetAttribute("*type*", "action")

  for _, details in ipairs(PandaUIPlayer.ActionBarDetails) do
    local attr = "action*"
    if details.mods ~= "" then
      attr = details.mods .. "-" .. attr
    end
    local offset = self.props.index + details.offset
    -- print(attr, " - ", offset)
    button:SetAttribute(attr, offset)
  end

  button:SetScript(
    "OnEnter",
    function(frame)
      -- GameTooltip_SetDefaultAnchor(GameTooltip, frame);
      GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT")
      GameTooltip:SetAction(frame:GetParent().actionIndex)
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

function ActionButtonMixin:Update(offset)
  offset = offset or 0
  self.offset = offset
  local actionIndex = self.props.index + offset

  -- Gather information
  local actionType, id = GetActionInfo(actionIndex)
  local usable = IsUsableAction(actionIndex)
  local hasTarget = UnitExists("target")

  local valid = IsActionInRange(actionIndex)
  local checksRange = (valid ~= nil)
  local inRange = checksRange and valid

  -- Update usability
  -- Fade if not usable based on range and general action state
  if usable and (not checksRange or inRange) or not hasTarget then
    self.usable = true
    self.refs.icon.details.alpha = 1.0
  else
    self.usable = false
    self.refs.icon.details.alpha = .25
  end

  self.refs.icon:UpdateStyles()

  self:UpdateTexts()
end

function ActionButtonMixin:UpdateTexts()
  local actionIndex = self.props.index + self.offset
  local actionType, id = GetActionInfo(actionIndex)

  local start, duration, enabled, modRate, name
  if actionType == "spell" then
    name = GetSpellInfo(id) -- debugging, remove later
    start, duration, enabled, modRate = GetSpellCooldown(id)
  else
    start, duration, enabled, modRate = GetActionCooldown(actionIndex)
  end

  if start > 0 and duration > 1.5 and enabled == 1 then
    -- print(name, ": ", start, duration, enabled, modRate)
    local endTime = start + duration
    local remaining = endTime - GetTime()

    local format = "%i"
    if remaining < 10 then
      format = "%.1f"
    elseif remaining >= 100 then
      -- show current minute for longer cooldowns
      remaining = math.ceil(remaining / 60)
      format = "%im"
    end

    self.refs.icon.details.alpha = .25
    self.refs.bigCooldown.details.text.text =
      string.format(format, remaining)
    self.refs.bigCooldown.details.hidden = false
  else
    self.refs.bigCooldown.details.hidden = true

    -- not on cooldown, unfade if usable
    if usable then
      self.refs.icon.details.alpha = 1.0
    end
  end

  self.refs.icon:UpdateStyles()
  self.refs.bigCooldown:UpdateStyles()
end

function PandaUIPlayer:ActionButton(slot)
  return {
    name = "ActionButton" .. slot,
    mixin = ActionButtonMixin,
    props = {
      index = slot
    },
    -- backgroundColor = {r = 0, g = 0, b = 1},
    children = {
      {name = "Icon", ref = "icon", texture = {}},
      {
        name = "BigCooldown",
        ref = "bigCooldown",
        hidden = true,
        text = {
          font = "GameFontNormalOutline22",
          anchor = PandaUICore:anchor("CENTER"),
          text = "00"
        }
      },
      {
        name = "SmallCooldown",
        ref = "smallCooldown",
        hidden = true,
        text = {
          font = "GameFontNormalOutline",
          anchor = PandaUICore:anchor("TOPLEFT", "TOPLEFT", 1, -2),
          text = "00"
        }
      },
      {
        name = "Charges",
        ref = "charges",
        hidden = true,
        text = {
          font = "GameFontNormalOutline",
          anchor = PandaUICore:anchor(
            "BOTTOMRIGHT",
            "BOTTOMRIGHT",
            0,
            2
          ),
          text = "00"
        }
      }
    },
    events = {},
    scripts = {
      OnUpdate = "UpdateTexts"
    },
    init = "Setup"
  }
end
