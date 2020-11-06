local ButtonWidth = 40
local ButtonHeight = 40
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

function PandaUIPlayer:Actions()
  local buttons = {}
  for i = 1, 12 do
    table.insert(
      buttons,
      {
        name = "ActionButton" .. i,
        -- backgroundColor = {r = 0, g = 0, b = 1},
        children = {
          {name = "Icon", ref = "icon", texture = {}},
          {
            name = "BindingText",
            text = {
              font = "GameFontNormal",
              anchor = PandaUICore:anchor("BOTTOM")
            }
          }
        },
        init = function(frame)
          local button =
            CreateFrame(
            "Button",
            frame:GetName() .. "Button",
            frame,
            "SecureActionButtonTemplate"
          )
          button:RegisterForClicks("AnyUp")
          button:SetSize(frame:GetWidth(), frame:GetHeight())
          button:SetPoint("CENTER")

          frame.actionButton = button

          button:SetAttribute("*type*", "action")

          for _, details in ipairs(BarDetails) do
            local attr = "action*"
            if details.mods ~= "" then
              attr = details.mods .. "-" .. attr
            end
            local offset = i + details.offset
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
      }
    )
  end

  local function GetActionOffset(frame)
    local indexOffset = BarDetails[frame.bar].offset

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

  local function UpdateActionButtons(frame)
    local indexOffset = GetActionOffset(frame)
    for i, childFrame in ipairs(frame.childFrames) do
      local actionIndex = i + indexOffset
      local usable = IsUsableAction(actionIndex)
      local hasTarget = UnitExists("target")

      local valid = IsActionInRange(actionIndex)
      local checksRange = (valid ~= nil)
      local inRange = checksRange and valid

      if usable and (not checksRange or inRange) or not hasTarget then
        childFrame.refs.icon.details.alpha = 1.0
      else
        childFrame.refs.icon.details.alpha = .25
      end

      childFrame.refs.icon:UpdateStyles()
    end
  end

  local function SetupActionButtons(frame)
    local indexOffset = GetActionOffset(frame)
    for i, childFrame in ipairs(frame.childFrames) do
      local actionIndex = i + indexOffset
      childFrame.actionIndex = actionIndex

      local texture = GetActionTexture(actionIndex)
      childFrame.refs.icon.details.texture.file = texture
      childFrame.refs.icon:UpdateStyles()
    end

    UpdateActionButtons(frame)
  end

  return {
    name = "Actions",
    -- backgroundColor = {r = 1.0, g = 0, b = 0},
    children = {
      {
        name = "Buttons",
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
        init = function(frame)
          frame.bar = 1
          frame.mods = {
            "", -- alt
            "", -- ctrl
            "" -- shift
          }
        end,
        events = {
          PLAYER_ENTERING_WORLD = SetupActionButtons,
          UPDATE_SHAPESHIFT_FORM = SetupActionButtons,
          PLAYER_SPECIALIZATION_CHANGED = SetupActionButtons,
          ACTIONBAR_UPDATE_STATE = UpdateActionButtons,
          ACTIONBAR_PAGE_CHANGED = SetupActionButtons,
          ACTIONBAR_SLOT_CHANGED = SetupActionButtons,
          PLAYER_TARGET_CHANGED = function(frame)
            if UnitExists("target") and not frame.hasTarget then
              -- new target register update event to watch range changes
              frame.hasTarget = true
              frame:SetScript(
                "OnUpdate",
                function(frame)
                  UpdateActionButtons(frame)
                end
              )
            elseif not UnitExists("target") then
              -- de-targeted
              frame.hasTarget = false
              frame:SetScript("OnUpdate", nil)
            end
            UpdateActionButtons(frame)
          end,
          MODIFIER_STATE_CHANGED = function(frame, key, pressed)
            local function CheckMod(name, index)
              if string.find(key, name) then
                if pressed == 1 then
                  frame.mods[index] = string.lower(name)
                else
                  frame.mods[index] = ""
                end
              end
            end

            -- update state with pressed/relased
            CheckMod("ALT", 1)
            CheckMod("CTRL", 2)
            CheckMod("SHIFT", 3)

            -- use state to determine current mod combination and bar to use
            local downMods = {}
            for _, v in pairs(frame.mods) do
              if v ~= "" then
                table.insert(downMods, v)
              end
            end
            local modStr = table.concat(downMods, "-")

            PandaUICore:Print(frame.mods)
            for i, details in ipairs(BarDetails) do
              if modStr == details.mods then
                frame.bar = i
              end
            end

            SetupActionButtons(frame)
          end
        }
      }
    }
  }
end
