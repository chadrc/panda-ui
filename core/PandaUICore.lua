PandaUICore = {
    hider = CreateFrame("Frame"),
    showingBlizzardUI = true,
    rootFrame = nil
};

-- no-ops to prevent errors
function PandaUICore.hider:OnStatusBarsUpdated() end

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
    ObjectiveTrackerFrame = {},
    BuffFrame = {},
    DurabilityFrame = {}
}

function PandaUICore:ToggleUI()
    if self.showingBlizzardUI then
        self:HideBlizzardUI();
        self:ShowPandaUI();
    else
        self:ShowBlizzardUI();
        self:HidePandaUI();
    end
end

function PandaUICore:HidePandaUI() self.rootFrame:Hide(); end

function PandaUICore:ShowPandaUI() self.rootFrame:Show(); end

function PandaUICore:TogglePandaUI()
    if self.rootFrame:IsShown() then
        PandaUICore:HidePandaUI();
    else
        PandaUICore:ShowPandaUI();
    end
end

function PandaUICore:HideBlizzardUI(options)
    self.hider:Hide();

    for name, details in pairs(framesToHide) do
        details.parent = _G[name]:GetParent();
        _G[name]:SetParent(self.hider);
        _G[name]:Hide();
    end

    -- HidePartyFrame();

    self.showingBlizzardUI = false;
end

function PandaUICore:ShowBlizzardUI(options)
    for name, details in pairs(framesToHide) do
        _G[name]:SetParent(details.parent);
        if not details.shouldShow or details.shouldShow() then
            _G[name]:Show();
        end
    end

    -- ShowPartyFrame();

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
    self.rootFrame:SetBackdropColor(0, 0, 0, 0);
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

function PandaUICore:CreateFrame(name, details, children)
    local t = "Frame";
    local tmp = nil;
    local p = self.rootFrame;
    local width = p:GetWidth();
    local height = p:GetHeight();
    local anchor = PandaUICore:anchor();
    local d = details or {};
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

    t = d.type or t;
    p = d.parent or p;
    tmp = d.template or tmp;

    if d.backgroundColor then
        local c = d.backgroundColor;
        frame:SetBackdropColor(c.r, c.g, c.b, c.a);
    end

    width = ExtractValue(d.width, p:GetWidth()) or p:GetWidth();
    height = ExtractValue(d.height, p:GetHeight()) or p:GetHeight();
    anchor = d.anchor or anchor;

    frame:SetSize(width, height);
    frame:SetPoint(anchor.base, p, anchor.relative, anchor.offsetX,
                   anchor.offsetY);

    local layout = d.layout or {};
    if children then
        -- horizontal children have same height as parent
        -- and share horizontal space evenly
        local childFrames = {};
        local childWidth = frame:GetWidth() / table.getn(children);
        local childHeight = frame:GetHeight();

        for i, child in ipairs(children) do
            child.parent = frame;

            if layout.direction == "horizontal" then
                child.width = PandaUICore:val(childWidth);
                child.height = PandaUICore:val(childHeight);
                child.anchor = PandaUICore:anchor("BOTTOMLEFT", nil,
                                                  (i - 1) * childWidth, 0);
            end

            local childFrame = PandaUICore:CreateFrame(child.name, child,
                                                       child.children);
            if child.key then frame[child.key] = childFrame; end
            table.insert(childFrames, childFrame);
        end
    end

    return frame;
end

-- Convenience Utilities

function PandaUICore:anchor(base, relative, offsetX, offsetY)
    return {
        base = base or "BOTTOMLEFT",
        relative = relative or base or "BOTTOMLEFT",
        offsetX = offsetX or 0,
        offsetY = offsetY or 0
    }
end
function PandaUICore:val(v) return {type = "value", value = v}; end
function PandaUICore:pct(p) return {type = "percentage", value = p}; end

