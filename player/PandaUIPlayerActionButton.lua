local ActionButtonMixin = {}

local function FormatCooldownTime(start, duration)
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

  return string.format(format, remaining)
end

function ActionButtonMixin:Setup()
  local button =
    CreateFrame(
    "Button",
    self:GetName() .. "Button",
    self,
    "SecureActionButtonTemplate"
  )
  button:RegisterForClicks("AnyUp")
  button:RegisterForDrag("LeftButton", "RightButton")
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

  button:SetScript(
    "OnDragStart",
    function(frame)
      PickupAction(frame:GetParent():GetActionIndex())
      frame:GetParent():Update()
    end
  )

  button:SetScript(
    "OnReceiveDrag",
    function(frame)
      PlaceAction(frame:GetParent():GetActionIndex())
      frame:GetParent():Update()
    end
  )

  -- overriding click functionality for drag and drop for now
  -- need to figure out how to get these two to work together
  button:SetScript(
    "OnClick",
    function(frame, button)
      local cursorType, id = GetCursorInfo()
      if cursorType then
        PlaceAction(frame:GetParent():GetActionIndex())
        frame:GetParent():Update()
      end
    end
  )
end

function ActionButtonMixin:GetActionIndex()
  return self.props.index + (self.offset or 0)
end

function ActionButtonMixin:Update(offset)
  offset = offset or self.offset or 0
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

  local start,
    duration,
    enabled,
    modRate,
    name,
    charges,
    maxCharges,
    chargeStart,
    chargeDuration,
    chargeModRate

  if actionType == "spell" then
    name = GetSpellInfo(id) -- debugging, remove later
    start, duration, enabled, modRate = GetSpellCooldown(id)
    charges, maxCharges, chargeStart, chargeDuration, chargeModRate =
      GetSpellCharges(id)
  else
    start, duration, enabled, modRate = GetActionCooldown(actionIndex)
    charges, maxCharges, chargeStart, chargeDuration, chargeModRate =
      GetActionCharges(actionIndex)
  end

  -- pre-emptivly hide both cooldown texts
  -- showing will resolve below
  local cooldownTextDetails = self.refs.bigCooldown.details
  local cooldownAlpha = .25

  if maxCharges and maxCharges > 1 then
    -- check to display charge numbers
    self.refs.charges.details.hidden = false
    self.refs.charges.details.text.text = charges

    -- on cooldown if current charges is less than max
    if charges < maxCharges then
      -- Use big cooldown text if there are no charges
      -- else uses small cooldown and charges
      if charges == 0 then
        self.refs.charges.details.hidden = true
        self.refs.smallCooldown.details.hidden = true
      else
        cooldownAlpha = .75
        self.refs.smallCooldown.details.hidden = false
        self.refs.smallCooldown.details.text.text =
          FormatCooldownTime(chargeStart, chargeDuration)
      end
    else
      self.refs.smallCooldown.details.hidden = true
    end
  else
    self.refs.charges.details.hidden = true
    self.refs.smallCooldown.details.hidden = true
  end

  if start > 0 and enabled == 1 then
    -- print(name, ": ", start, duration, enabled, modRate)
    if duration < 1.5 then
      -- Global cooldown or less, use swipe animation instead of numbers
      self.refs.bigCooldown.details.hidden = true
      self.refs.swipe.details.hidden = false
      self.refs.swipe.details.alpha = 1.0
      if not self.usable then
        self.refs.swipe.details.alpha = cooldownAlpha
      end
      self.refs.swipe:SetCooldown(start, duration, modRate)
    else
      self.refs.swipe.details.hidden = true
      self.refs.bigCooldown.details.hidden = false
      self.refs.icon.details.alpha = cooldownAlpha
      self.refs.bigCooldown.details.text.text =
        FormatCooldownTime(start, duration)
    end
  else
    self.refs.swipe.details.hidden = true
    self.refs.bigCooldown.details.hidden = true

    -- not on cooldown, unfade if usable
    if usable then
      self.refs.icon.details.alpha = 1.0
    end
  end

  self.refs.swipe:UpdateStyles()
  self.refs.charges:UpdateStyles()
  self.refs.icon:UpdateStyles()
  self.refs.smallCooldown:UpdateStyles()
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
        type = "Cooldown",
        name = "CooldownSwipe",
        ref = "swipe",
        template = "CooldownFrameTemplate",
        frameLevel = 10
      },
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
