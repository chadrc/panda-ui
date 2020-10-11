function MakeFrame(type) print("making frame: ", type); end

PandaUICore = {hider = CreateFrame("Frame"), showingBlizzardUI = true};

local framesToHide = {
    {name = "PlayerFrame"}, {name = "StatusTrackingBarManager"}, {
        name = "TargetFrame",
        shouldShow = function() return UnitName("target") ~= nil; end
    }, {
        name = "FocusFrame",
        shouldShow = function() return UnitName("focus") ~= nil; end
    }, {name = "MinimapCluster"}, {name = "MainMenuBarArtFrame"},
    {name = "MicroButtonAndBagsBar"}, {name = "MultiBarRight"},
    {name = "MultiBarLeft"}, {name = "QuestFrame"},
    {name = "ObjectiveTrackerFrame"}, {name = "BuffFrame"}
}

local frameCache = {};

function PandaUICore:HideBlizzardUI(options)
    self.hider:Hide();

    for _, f in ipairs(framesToHide) do
        table.insert(frameCache, {name = f.name});
        _G[f.name]:Hide();
    end

    HidePartyFrame();

    self.showingBlizzardUI = false;
end

function PandaUICore:ShowBlizzardUI(options)
    print('target name: ', UnitName("target"));
    print('focus name: ', UnitName("focus"));

    for _, f in ipairs(framesToHide) do
        print('showing ', f.name);
        if not f.shouldShow or f.shouldShow() then _G[f.name]:Show(); end
    end

    self.showingBlizzardUI = true;
end

function PandaUICore:ToggleBlizzardUI()
    if self.showingBlizzardUI then
        self:HideBlizzardUI();
    else
        self:ShowBlizzardUI();
    end
end
