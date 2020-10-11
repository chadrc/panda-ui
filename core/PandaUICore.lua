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
    ObjectiveTrackerFrame = {},
    BuffFrame = {}
}

function PandaUICore:ToggleUI()
    if self.showingBlizzardUI then
        self:HideBlizzardUI();
        self.rootFrame:Show();
    else
        self:ShowBlizzardUI();
        self.rootFrame:Hide();
    end
end

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

    if children then
        -- cache children for layout after creation
        local childFrames = {};
        for _, child in ipairs(children) do
            child.parent = frame;
            local childFrame = PandaUICore:CreateFrame(child.name, child);
            if child.key then frame[child.key] = childFrame; end
            table.insert(childFrames, childFrame);
        end

        local layout = d.layout or {};

        if layout.direction == "horizontal" then
            -- horizontal children have same height as parent
            -- and share horizontal space evenly
            local width = frame:GetWidth() / table.getn(childFrames);
            local height = frame:GetHeight();
            for i, child in ipairs(childFrames) do
                child:SetSize(width, height);
                child:ClearAllPoints();
                child:SetPoint("BOTTOMLEFT", (i - 1) * width, 0);
            end
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

