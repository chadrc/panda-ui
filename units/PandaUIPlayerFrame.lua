function PandaUIUnits:PlayerFrame(vars)
  local menuFunc = function()
    ToggleDropDownMenu(1, nil, PlayerFrameDropDown, "cursor", 0, 0)
  end
  local details =
    self:UnitFrame("player", menuFunc, "HELPFUL RAID", "HARMFUL RAID")

  PandaUICore:SetMovable(
    details,
    {
      point = "CENTER",
      relativePoint = "CENTER",
      xOfs = 0,
      yOfs = -200
    },
    vars,
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
