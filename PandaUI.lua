SLASH_PANDAUI1 = "/pandaui"

function PandaUI_OnSlash(msg)
  local args = PandaUICore:Split(msg)

  local success = false
  local arg1 = args[1]
  local error =
    string.format("Could not execute command %s", tostring(msg))
  if arg1 == "hide_blizz" then
    PandaUICore:HideBlizzardUI()
    success = true
  elseif arg1 == "show_blizz" then
    PandaUICore:ShowBlizzardUI()
    success = true
  elseif arg1 == "toggle" then
    PandaUICore:ToggleUI()
    success = true
  end

  for _, module in pairs(PandaUICore.modules) do
    if module.GetSlashDetails then
      local slashDetails = module:GetSlashDetails()
      if arg1 == slashDetails.subCmd then
        success, error = slashDetails.action(args)
      end
    end
  end

  if not success then
    print(
      string.format(
        "Error: %s",
        tostring(error) or
          string.format("Could not execute command %s", msg)
      )
    )
  end
end

function PandaUIMainFrame_OnLoad()
  PandaUIMainFrame:RegisterEvent("ADDON_LOADED")

  SlashCmdList["PANDAUI"] = PandaUI_OnSlash

  print("Panda UI Load")
end

function PandaUIMainFrame_OnEvent(self, event, ...)
  -- print('event: ', event, arg1);
  local name = ...
  if event == "ADDON_LOADED" and name == "PandaUI" then
    if not PandaUISavedVariables then
      PandaUISavedVariables = {}
    end
    if not PandaUISavedCharacterVariables then
      PandaUISavedCharacterVariables = {}
    end

    PandaUICore:Initialize()
    for _, module in pairs(PandaUICore.modules) do
      if module.Initialize then
        module:Initialize()
      end
    end
    PandaUIPlayer:Initialize()
    -- PandaUIUnits:Initialize()

    PandaUICore:HidePandaUI()
  end
end
