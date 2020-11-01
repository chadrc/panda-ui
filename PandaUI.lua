SLASH_PANDAUI1 = "/pandaui";

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

function PandaUIMainFrame_OnLoad()
    PandaUIMainFrame:RegisterEvent("ADDON_LOADED");

    PandaUICore:Initialize();
    PandaUIPlayer:Initialize();
    PandaUIUnits:Initialize();

    SlashCmdList["PANDAUI"] = PandaUI_OnSlash;

    print("Panda UI Load");
end

function PandaUIMainFrame_OnEvent(self, event, ...)
    -- print('event: ', event, arg1);
    local name = ...;
    if event == "ADDON_LOADED" and name == "PandaUI" then
        PandaUICore:HidePandaUI();

        -- local testFrame = PandaUICore:CreateFrame("TestStatus", {
        --     type = "StatusBar",
        --     init = function(frame)
        --         frame:SetStatusBarColor(1.0, 1.0, 0.0)
        --         frame:SetMinMaxValues(0, 100);
        --         frame:SetValue(30);
        --         frame:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8");
        --     end,
        --     anchor = PandaUICore:anchor("CENTER"),
        --     height = PandaUICore:val(20),
        --     width = PandaUICore:val(100),
        --     backgroundColor = {r = 0, g = 0, b = 1.0}
        -- });

        -- testFrame:UpdateStyles();
        -- testFrame:UpdateLayout();
        -- testFrame:Init();
        -- print(PandaUIActionButtonTemplate:GetAttribute("type"));
        -- PandaUIActionButtonTemplate:SetAttribute("type", "spell");
        -- PandaUIActionButtonTemplate:SetAttribute("spell", "Regrowth");
        -- PandaUIActionButtonTemplate:SetAttribute("target", "player");
    end
end
