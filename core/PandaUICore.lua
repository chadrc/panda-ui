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
    self.rootFrame:SetPoint("BOTTOMLEFT");
end

-- Private utilites

local function ExtractValue(info, parentValue)
    if info then
        if info.type == "percentage" then
            return parentValue * (info.value / 100);
        else
            return info.value
        end
    end
end

function PandaUICore:CreateFrame(name, details)
    local t = "Frame";
    local tmp = nil;
    local p = self.rootFrame;
    local width = p:GetWidth();
    local height = p:GetHeight();
    local n = name;
    if n then
        n = p:GetName() .. n;
    else
        n = p:GetName() .. "_ChildFrame_" .. tostring(p:GetNumChildren() + 1);
    end

    local frame = CreateFrame(t, n, p, tmp);
    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        tile = true
    });
    frame:SetBackdropColor(0, 0, 0, 0);

    if details then
        t = details.type or t;
        p = details.parent or p;
        tmp = details.template or tmp;

        if details.backgroundColor then
            local c = details.backgroundColor;
            frame:SetBackdropColor(c.r, c.g, c.b, c.a);
        end

        width = ExtractValue(details.width, p:GetWidth()) or p:GetWidth();
        height = ExtractValue(details.height, p:GetHeight()) or p:GetHeight();
    end

    frame:SetSize(width, height);
    frame:SetPoint("BOTTOMLEFT");

    return frame;
end

-- Convenience Utilities

function PandaUICore:val(v) return {type = "value", value = v}; end
function PandaUICore:pct(p) return {type = "percentage", value = p}; end

