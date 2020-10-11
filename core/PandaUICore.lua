PandaUICore = {
    hider = CreateFrame("Frame"),
    showingBlizzardUI = true,
    rootFrame = nil
};

local framesToHide = {
    PlayerFrame = {},
    StatusTrackingBarManager = {},
    TargetFrame = {shouldShow = function() return UnitExists("target"); end},
    FocusFrame = {shouldShow = function() return UnitExists("focus"); end},
    MinimapCluster = {},
    MainMenuBarArtFrame = {},
    MicroButtonAndBagsBar = {},
    MultiBarRight = {},
    MultiBarLeft = {},
    QuestFrame = {},
    ObjectiveTrackerFrame = {},
    BuffFrame = {}
}

function PandaUICore:HideBlizzardUI(options)
    self.hider:Hide();

    for name, details in pairs(framesToHide) do
        details.parent = _G[name]:GetParent();
        _G[name]:SetParent(self.hider);
        _G[name]:Hide();
    end

    HidePartyFrame();

    self.showingBlizzardUI = false;
end

function PandaUICore:ShowBlizzardUI(options)
    for name, details in pairs(framesToHide) do
        _G[name]:SetParent(details.parent);
        if not details.shouldShow or details.shouldShow() then
            _G[name]:Show();
        end
    end

    ShowPartyFrame();

    self.showingBlizzardUI = true;
end

function PandaUICore:ToggleBlizzardUI()
    if self.showingBlizzardUI then
        self:HideBlizzardUI();
    else
        self:ShowBlizzardUI();
    end
end

function PandaUICore:Initialize()
    self.rootFrame = CreateFrame("Frame", "PandaUIRootFrame", UIParent)
    self.rootFrame:SetSize(self.rootFrame:GetParent():GetWidth(),
                           self.rootFrame:GetParent():GetHeight());
    self.rootFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        tile = true
    });
    self.rootFrame:SetBackdropColor(1, 0, 0, .1);
    self.rootFrame:SetPoint("CENTER");
end

function PandaUICore:CreateFrame(name, details)
    local t = "Frame";
    local tmp = nil;
    local p = self.rootFrame;
    if details then
        t = details.type or t;
        p = details.p or p;
        tmp = details.template or tmp;
    end

    local n = name;
    if n then
        n = p:GetName() .. n;
    else
        n = p:GetName() .. "_ChildFrame_" .. tostring(p:GetNumChildren() + 1);
    end

    return CreateFrame(t, n, p, tmp);
end
