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
    local d = details or {};
    local tmp = d.template;
    local t = d.type or "Frame";
    local p = d.parent or self.rootFrame;
    local width = p:GetWidth();
    local height = p:GetHeight();
    local anchor = PandaUICore:anchor();
    local n = name;
    if n then
        n = p:GetName() .. n;
    else
        n = p:GetName() .. "_ChildFrame_" .. tostring(p:GetNumChildren() + 1);
    end

    local frame = CreateFrame(t, n, p, tmp);
    if details.hidden then frame:Hide(); end
    frame:SetParent(p);
    frame.refs = {};
    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        tile = true
    });
    frame:SetBackdropColor(0, 0, 0, 0);

    if d.backgroundColor then
        local c = d.backgroundColor;
        frame:SetBackdropColor(c.r, c.g, c.b, c.a);
    end

    width = ExtractValue(d.width, width) or width;
    height = ExtractValue(d.height, height) or height;
    anchor = d.anchor or anchor;

    frame:SetSize(width, height);
    frame:SetPoint(anchor.base, p, anchor.relative, anchor.offsetX,
                   anchor.offsetY);

    if children then
        local totalParts = 0;
        local childLayout = d.childLayout or {};
        -- pre calculate parts
        if childLayout then
            for i, child in ipairs(children) do
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
        end

        local currentChildOffsetX = 0;
        local currentChildOffsetY = 0;
        for i, child in ipairs(children) do
            child.parent = frame;

            if childLayout.direction == "horizontal" then
                -- horizontal children have same height as parent
                -- calculate width based on parts
                local childWidth = frame:GetWidth() *
                                       (child.layout.parts / totalParts);
                child.width = PandaUICore:val(childWidth);
                child.anchor = PandaUICore:anchor("BOTTOMLEFT", nil,
                                                  currentChildOffsetX, 0);
                if not child.hidden then
                    currentChildOffsetX = currentChildOffsetX + childWidth;
                end
            elseif childLayout.direction == "vertical" then
                -- vertical children have same width as parent
                -- calculate height based on parts
                local childHeight = frame:GetHeight() *
                                        (child.layout.parts / totalParts);
                child.height = PandaUICore:val(childHeight);
                child.anchor = PandaUICore:anchor("TOPLEFT", nil, 0,
                                                  -currentChildOffsetY);

                if not child.hidden then
                    currentChildOffsetY = currentChildOffsetY + childHeight;
                end
            end

            local childFrame = PandaUICore:CreateFrame(child.name, child,
                                                       child.children);
            for k, v in pairs(childFrame.refs) do frame.refs[k] = v end
            if child.ref then frame.refs[child.ref] = childFrame end
        end
    end

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

