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

local function RegisterHandlers(list)
    if not list then return end

    for name, handler in pairs(list) do
        if eventHandlers[name] then
            table.insert(eventHandlers[name], handler);
        else
            eventHandlers[name] = {handler};
        end
    end
end

function PandaUIMainFrame_OnLoad()
    print("Panda UI Load");

    -- PandaUIMainFrame:RegisterEvent("PLAYER_FOCUS_CHANGED");
    -- PandaUIMainFrame:RegisterEvent("PLAYER_TARGET_CHANGED");

    PandaUIMainFrame:RegisterEvent("ADDON_LOADED");

    RegisterHandlers(PandaUICore:Initialize());
    RegisterHandlers(PandaUIPlayer:Initialize());

    for event, _ in pairs(eventHandlers) do
        PandaUIMainFrame:RegisterEvent(event, "player")
    end

    SlashCmdList["PANDAUI"] = PandaUI_OnSlash;
end

function PandaUIMainFrame_OnEvent(self, event, ...)
    -- print('event: ', event, arg1);
    local arg1 = ...;
    if event == "ADDON_LOADED" and arg1 == "PandaUI" then
        PandaUICore:HidePandaUI();
    end

    if eventHandlers[event] then
        for _, handler in ipairs(eventHandlers[event]) do handler(...) end
    end
end
