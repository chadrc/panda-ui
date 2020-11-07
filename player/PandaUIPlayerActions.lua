local ButtonWidth = 35
local ButtonHeight = ButtonWidth
local CellPadding = 5
local Columns = 3
local GridWidth = ButtonWidth * Columns + CellPadding * (Columns - 1)

local BarDetails = {
  {
    bar = "MainActionBar",
    offset = 0,
    mods = ""
  },
  {
    name = "SecondActionBar",
    offset = 12,
    mods = "ctrl-shift"
  },
  {
    name = MultiBarRightButton,
    offset = 24,
    mods = "alt-shift"
  },
  {
    name = MultiBarLeftButton,
    offset = 36,
    mods = "ctrl"
  },
  {
    name = MultiBarBottomRightButton,
    offset = 48,
    mods = "alt"
  },
  {
    name = MultiBarBottomLeftButton,
    offset = 60,
    mods = "shift"
  }
}

PandaUIPlayer.ActionBarDetails = BarDetails

local ActionGridMixin = {}

function ActionGridMixin:GetActionOffset()
  local indexOffset = BarDetails[self.bar].offset

  -- check for bonus offset
  -- only main bar is changed to bonus
  local bonus = GetBonusBarOffset()
  local page = GetActionBarPage()
  -- if displaying main bar and not on main page, override bonus bar
  -- else use bonus if active
  if indexOffset == 0 then
    if page > 1 then
      indexOffset = (page - 1) * NUM_ACTIONBAR_BUTTONS
    elseif bonus > 0 then
      indexOffset =
        (NUM_ACTIONBAR_PAGES + bonus - 1) * NUM_ACTIONBAR_BUTTONS
    end
  end

  return indexOffset
end

function ActionGridMixin:UpdateActionButtons()
  local indexOffset = self:GetActionOffset()
  for i, childFrame in ipairs(self.childFrames) do
    childFrame:Update(self:GetActionOffset())
  end
end

function ActionGridMixin:SetupActionButtons()
  local indexOffset = self:GetActionOffset()
  for i, childFrame in ipairs(self.childFrames) do
    local actionIndex = i + indexOffset
    childFrame.actionIndex = actionIndex

    local texture = GetActionTexture(actionIndex)
    childFrame.refs.icon.details.texture.file = texture
    childFrame.refs.icon:UpdateStyles()
  end

  self:UpdateActionButtons()
end

function ActionGridMixin:CheckRangeChecker()
  if UnitExists("target") and not self.hasTarget then
    -- new target register update event to watch range changes
    self.hasTarget = true
    self:SetScript(
      "OnUpdate",
      function(frame)
        self:UpdateActionButtons(frame)
      end
    )
  elseif not UnitExists("target") then
    -- de-targeted
    self.hasTarget = false
    self:SetScript("OnUpdate", nil)
  end
  self:UpdateActionButtons()
end

function ActionGridMixin:UpdateModifiers(key, pressed)
  local function CheckMod(name, index)
    if string.find(key, name) then
      if pressed == 1 then
        self.mods[index] = string.lower(name)
      else
        self.mods[index] = ""
      end
    end
  end

  -- update state with pressed/relased
  CheckMod("ALT", 1)
  CheckMod("CTRL", 2)
  CheckMod("SHIFT", 3)

  -- use state to determine current mod combination and bar to use
  local downMods = {}
  for _, v in pairs(self.mods) do
    if v ~= "" then
      table.insert(downMods, v)
    end
  end
  local modStr = table.concat(downMods, "-")

  for i, details in ipairs(BarDetails) do
    if modStr == details.mods then
      self.bar = i
    end
  end

  self:SetupActionButtons()
end

function ActionGridMixin:Setup()
  self.bar = 1
  self.mods = {
    "", -- alt
    "", -- ctrl
    "" -- shift
  }
end

function PandaUIPlayer:Actions()
  local buttons = {}
  for i = 1, 12 do
    table.insert(buttons, PandaUIPlayer:ActionButton(i))
  end

  return {
    name = "Actions",
    -- backgroundColor = {r = 1.0, g = 0, b = 0},
    children = {
      {
        name = "Buttons",
        mixin = ActionGridMixin,
        anchor = PandaUICore:anchor("TOP"),
        width = PandaUICore:val(GridWidth),
        childLayout = {
          type = "grid",
          columns = Columns,
          cellWidth = ButtonWidth,
          cellHeight = ButtonHeight,
          cellPadding = CellPadding,
          start = "TOPLEFT"
        },
        children = buttons,
        init = "Setup",
        events = {
          PLAYER_ENTERING_WORLD = "SetupActionButtons",
          UPDATE_SHAPESHIFT_FORM = "SetupActionButtons",
          PLAYER_SPECIALIZATION_CHANGED = "SetupActionButtons",
          ACTIONBAR_UPDATE_STATE = "UpdateActionButtons",
          ACTIONBAR_PAGE_CHANGED = "SetupActionButtons",
          ACTIONBAR_SLOT_CHANGED = "SetupActionButtons",
          PLAYER_TARGET_CHANGED = "CheckRangeChecker",
          MODIFIER_STATE_CHANGED = "UpdateModifiers",
          ACTIONBAR_UPDATE_STATE = "UpdateActionButtons",
          ACTIONBAR_UPDATE_COOLDOWN = "UpdateActionButtons"
        }
      }
    }
  }
end
