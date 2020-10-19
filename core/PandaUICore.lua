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
    self.rootFrame = CreateFrame("Frame", "PandaUIRootFrame", UIParent,
                                 BackdropTemplateMixin and "BackdropTemplate")
    self.rootFrame:SetSize(self.rootFrame:GetParent():GetWidth(),
                           self.rootFrame:GetParent():GetHeight());
    self.rootFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
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
    local d = details or {};
    local tmp = d.template;
    local t = d.type or "Frame";
    local root = self.rootFrame;
    d.parent = d.parent or root;
    local n = name;
    if n then
        n = d.parent:GetName() .. n;
    else
        n = d.parent:GetName() .. "_ChildFrame_" ..
                tostring(d.parent:GetNumChildren() + 1);
    end

    local frame = CreateFrame(t, n, d.parent,
                              BackdropTemplateMixin and "BackdropTemplate");
    frame.details = d;
    frame.refs = {};

    local childFrames = {};
    if children then
        for i, child in ipairs(children) do
            child.parent = frame;

            local childFrame = PandaUICore:CreateFrame(child.name, child,
                                                       child.children);
            table.insert(childFrames, childFrame);

            for k, v in pairs(childFrame.refs) do frame.refs[k] = v end
            if child.ref then frame.refs[child.ref] = childFrame end
        end
    end
    frame.childFrames = childFrames;

    local eventCount = 0;
    for name, _ in pairs(d.events or {}) do
        frame:RegisterEvent(name);
        eventCount = eventCount + 1;
    end

    if eventCount > 0 then
        frame:SetScript("OnEvent", function(self, event, ...)
            if self.events[event] then self.events[event](self, ...); end
        end)
    end

    frame.events = d.events;

    -- Public interface

    function frame:Init()
        if self.details.init then self.details.init(self); end
        for _, childFrame in pairs(self.childFrames) do childFrame:Init() end
    end

    function frame:UpdateStyles()
        local d = self.details;
        local p = d.parent;
        local width = p:GetWidth();
        local height = p:GetHeight();
        local anchor = PandaUICore:anchor();

        if d.hidden then
            self:Hide();
        else
            self:Show()
        end

        self:SetParent(p);
        self:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", tile = true});
        self:SetBackdropColor(0, 0, 0, 0);

        if d.backgroundColor then
            local c = d.backgroundColor;
            self:SetBackdropColor(c.r, c.g, c.b, c.a);
        end

        width = ExtractValue(d.width, width) or width;
        height = ExtractValue(d.height, height) or height;
        anchor = d.anchor or anchor;

        self:SetSize(width, height);
        self:SetPoint(anchor.base, p, anchor.relative, anchor.offsetX,
                      anchor.offsetY);
    end

    function frame:UpdateLayout()
        local totalParts = 0;
        local childLayout = self.details.childLayout or {};

        -- pre calculate parts
        for i, childFrame in ipairs(self.childFrames) do
            local child = childFrame.details;
            local childParts = 0;

            if child.layout then
                childParts = child.layout.parts or 1;
                child.layout.parts = childParts;
            else
                childParts = 1;
                child.layout = {parts = childParts}
            end

            -- ignore hidden elements
            if not child.hidden then
                totalParts = totalParts + childParts;
            end
        end

        local currentChildOffsetX = 0;
        local currentChildOffsetY = 0;
        for i, child in pairs(self.childFrames) do
            -- layout children according to options
            if childLayout.direction == "horizontal" then
                -- horizontal children have same height as parent
                -- calculate width based on parts
                child.details.height = PandaUICore:val(self:GetHeight());

                local childWidth = frame:GetWidth() *
                                       (child.details.layout.parts / totalParts);
                child.details.width = PandaUICore:val(childWidth);
                child.details.anchor = PandaUICore:anchor("BOTTOMLEFT", nil,
                                                          currentChildOffsetX, 0);

                if not child.details.hidden then
                    currentChildOffsetX = currentChildOffsetX + childWidth;
                end
            elseif childLayout.direction == "vertical" then
                -- vertical children have same width as parent
                -- calculate height based on parts
                child.details.width = PandaUICore:val(self:GetWidth());

                local childHeight = frame:GetHeight() *
                                        (child.details.layout.parts / totalParts);
                child.details.height = PandaUICore:val(childHeight);
                child.details.anchor = PandaUICore:anchor("TOPLEFT", nil, 0,
                                                          -currentChildOffsetY);

                if not child.details.hidden then
                    currentChildOffsetY = currentChildOffsetY + childHeight;
                end
            end

            child:UpdateStyles();
            child:UpdateLayout();
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

