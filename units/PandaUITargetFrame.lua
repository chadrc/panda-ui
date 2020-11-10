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
        frame:UpdateFilters("HELPFUL RAID", "HARMFUL RAID")
      elseif info.isEnemy then
        frame.backgroundColor = {r = .5, g = 0, b = 0, a = .4}
        frame:UpdateFilters("HELPFUL", "HARMFUL PLAYER")
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

  PandaUICore:SetMovable(
    details,
    {
      point = "CENTER",
      relativePoint = "CENTER",
      xOfs = 0,
      yOfs = 200
    },
    vars,
    "position"
  )

  return details
end
