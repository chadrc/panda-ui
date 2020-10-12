SLASH_PANDAUI1 = "/pandaui";

local hasTarget = false;
local hostFocus = false;

function PandaUI_OnSlash(msg)
    if msg == "hide_blizz" then
        PandaUICore:HideBlizzardUI();
    elseif msg == "show_blizz" then
        PandaUICore:ShowBlizzardUI();
    elseif msg == "toggle" then
        PandaUICore:ToggleUI();
    else
        print("Unknown PandaUI command: ", msg);
    end
end

local eventHandlers = {};

function PandaUIMainFrame_OnLoad()
    print("Panda UI Load");

    -- PandaUIMainFrame:RegisterEvent("PLAYER_FOCUS_CHANGED");
    -- PandaUIMainFrame:RegisterEvent("PLAYER_TARGET_CHANGED");

    PandaUIMainFrame:RegisterEvent("ADDON_LOADED");

    PandaUICore:Initialize();
    PandaUIPlayer:Initialize();

    for event, _ in pairs(eventHandlers) do
        PandaUIMainFrame:RegisterEvent(event, "player")
    end

    SlashCmdList["PANDAUI"] = PandaUI_OnSlash;
end

function PandaUIMainFrame_OnEvent(self, event, ...)
    -- print('event: ', event, arg1);
    local name = ...;
    if event == "ADDON_LOADED" and name == "PandaUI" then
        PandaUICore:HidePandaUI();
    end
end
