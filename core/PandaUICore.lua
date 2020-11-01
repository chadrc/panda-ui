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
    DurabilityFrame = {},
    CastingBarFrame = {},
    StanceBarFrame = {}
}

function PandaUICore:ToggleUI()
    if InCombatLockdown() then return end
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
    if InCombatLockdown() then return end
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

    local templates = {};
    if BackdropTemplateMixin then
        table.insert(templates, "BackdropTemplate");
    end
    if tmp then table.insert(templates, tmp); end

    local frame = CreateFrame(t, n, d.parent, table.concat(templates, ","));
    frame.details = d;
    frame.refs = {};
    if d.movable then
        frame:RegisterForDrag("LeftButton");
        frame:SetMovable(d.movable);
    end

    if d.attributes then
        for k, v in pairs(d.attributes) do
            -- print('attr: ', k, " = ", v);
            frame:SetAttribute(k, v);
        end
    end

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

    if d.onEnter then frame:SetScript("OnEnter", d.onEnter); end
    if d.onLeave then frame:SetScript("OnLeave", d.onLeave); end

    if d.scripts then
        for h, s in pairs(d.scripts) do frame:SetScript(h, s); end
    end

    if d.clicks then frame:RegisterForClicks(unpack(d.clicks)); end
    if t == "Button" and d.onClick then
        frame:SetScript("OnClick", d.onClick);
    end

    local allEvents = {};
    for name, h in pairs(d.events or {}) do
        frame:RegisterEvent(name);
        allEvents[name] = h;
    end

    if d.unit then
        for name, h in pairs(d.unit.events or {}) do
            frame:RegisterUnitEvent(name, d.unit.name);
            allEvents[name] = h;
        end
    end

    if table.getn(allEvents) then
        frame:SetScript("OnEvent", function(self, event, ...)
            if allEvents[event] then allEvents[event](self, ...); end
        end)
    end

    frame.events = d.events;

    PandaUICore:ApplyFrameMixin(frame);

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
function PandaUICore:auto() return {type = "auto"}; end
function PandaUICore:val(v) return {type = "value", value = v}; end
function PandaUICore:pct(p) return {type = "percentage", value = p}; end

function PandaUICore:StatusBar(details)
    local orgInit = details.init;
    local statusDetails = details.statusBar or {};

    local d = {};
    for k, v in pairs(details) do d[k] = v; end

    d.name = d.name or "StatusBar";
    d.type = "StatusBar";
    d.init = function(frame)
        local clr = statusDetails.color or {r = 1.0, g = 1.0, b = 1.0, a = 1.0};
        local texture = frame:CreateTexture(frame:GetName() .. "Texture");
        texture:SetTexture("Interface\\Buttons\\WHITE8X8");
        texture:SetColorTexture(clr.r, clr.g, clr.b, clr.a);
        frame.statusBarTexture = texture;
        frame:SetStatusBarTexture(texture);
        frame:SetMinMaxValues(0, 1);
        frame:SetValue(0);
        frame:SetReverseFill(statusDetails.reverse or false);
        if orgInit then orgInit(frame); end
    end

    return d;
end
