function PandaUIPlayer:PlayerHealthFrame()
  local details = PandaUIUnits:UnitHealthFrame("player", true)
  details.events.PLAYER_ENTERING_WORLD = function(frame)
    frame:CheckForStagger()
    frame:Update()
  end

  return details
end
