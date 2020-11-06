local AuraSize = 15
local AuraPadding = 2.5

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
      buffFrame.details.hidden = false
      buffFrame.auraIndex = index

      buffFrame.texture:SetTexture(buffTexture)
      buffFrame.details.texture.file = buffTexture

      local stackText = buffFrame.refs.stackText.details.text

      stackText.hidden = not count or count == 0
      stackText.text = count or ""

      buffFrame.refs.stackText:UpdateStyles()
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

function PandaUIUnits:MakeAuraGrid(
  unit,
  name,
  anchor,
  filter,
  maxCount)
  local children = {}
  for i = 1, maxCount do
    table.insert(
      children,
      {
        name = "Buff" .. i,
        -- backgroundColor = {g = 1},
        hidden = true,
        texture = {},
        children = {
          {
            ref = "stackText",
            text = {
              text = "0",
              font = "GameFontNormalOutline",
              anchor = PandaUICore:anchor("CENTER")
            }
          }
        }
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
    height = PandaUICore:val(AuraSize),
    width = PandaUICore:val(AuraSize),
    anchor = PandaUICore:anchor(anchor),
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
