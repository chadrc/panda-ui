SLASH_PANDAUI1 = "/pandaui";

local hasTarget = false;
local hostFocus = false;

function PandaUI_OnSlash(msg)
    if msg == "hide_blizz" then
        PandaUICore:HideBlizzardUI();
    elseif msg == "show_blizz" then
        PandaUICore:ShowBlizzardUI();
    else
        print("Unknown PandaUI command: ", msg);
    end
end

function PandaUIMainFrame_OnLoad()
    print("Panda UI Load");

    -- PandaUIMainFrame:RegisterEvent("PLAYER_FOCUS_CHANGED");
    -- PandaUIMainFrame:RegisterEvent("PLAYER_TARGET_CHANGED");

    PandaUICore:Initialize();
    PandaUIPlayer:Initialize();

    SlashCmdList["PANDAUI"] = PandaUI_OnSlash;
end

function PandaUIMainFrame_OnEvent(self, event, arg1)
    -- if event == "PLAYER_FOCUS_CHANGED" then

    -- elseif event == "PLAYER_TARGET_CHANGED" then

    -- end
end
