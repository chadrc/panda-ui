SLASH_PANDAUI1 = "/pandaui"

function PandaUI_OnSlash(msg)
  if msg == "hide_blizz" then
    PandaUICore:HideBlizzardUI()
  elseif msg == "show_blizz" then
    PandaUICore:ShowBlizzardUI()
  elseif msg == "toggle" then
    PandaUICore:ToggleUI()
  else
    print("Unknown PandaUI command: ", msg)
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
    PandaUIPlayer:Initialize()
    PandaUIUnits:Initialize()

    PandaUICore:HidePandaUI()
  end
end
