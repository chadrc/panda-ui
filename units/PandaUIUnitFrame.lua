function PandaUIUnits:GetUnitInfo(unit)
    if not UnitExists(unit) then return nil end

    local powerType, powerToken = UnitPowerType(unit);
    local info = {
        name = UnitFullName(unit),
        class = UnitClass(unit),
        maxHealth = UnitHealthMax(unit),
        health = UnitHealth(unit),
        connected = UnitIsConnected(unit),
        dead = UnitIsDead(unit),
        castingInfo = {UnitCastingInfo(unit)},
        channelingInfo = {UnitChannelInfo(unit)},
        incomingHeals = UnitGetIncomingHeals(unit),
        totalAbsorbs = UnitGetTotalAbsorbs(unit),
        totalHealAbsorbs = UnitGetTotalHealAbsorbs(unit),
        groupRole = UnitGroupRolesAssigned(unit),
        isGhost = UnitIsGhost(unit),
        level = UnitLevel(unit),
        powerType = powerType,
        powerToken = powerToken,
        maxPower = UnitPowerMax(unit),
        power = UnitPower(unit),
        isEnemy = UnitIsEnemy("player", unit),
        isFriend = UnitIsFriend("player", unit)
    };

    return info;
end

function Clone(t)
    local n = {};
    for k, v in pairs(t) do n[k] = v end
    return n
end

local function FadeBy(clr, by)
    local new = Clone(clr);
    new.a = new.a or 1.0;
    new.a = new.a * by;
    return new;
end

local BackgroundAlpha = .5;
local InactiveColor = {r = .5, g = .5, b = .5};
local DefaultBackgroundColor = {r = .5, g = .5, b = .5, a = BackgroundAlpha};
local DefaultCastColor = {r = .8, g = .8, b = .8, a = .75};
local DefaultHealthColor = {r = 0, g = .8, b = 0};
local DefaultPowerColor = {r = 0, g = 0, b = .8};

function PandaUIUnits:UnitFrame(unit, dropDownMenu)
    local function UpdateCastBars(frame)
        frame.refs.cast:SetMinMaxValues(0, frame.maxValue);
        frame.refs.cast:SetValue(frame.value);
    end

    local function UpdateCast(frame)
        if not frame.casting then return end

        frame.value = GetTime() - (frame.startTime / 1000);
        UpdateCastBars(frame);
    end

    local function EndCast(frame, unit)
        frame.casting = false;
        frame.maxValue = 1;
        frame.value = 0;
        UpdateCastBars(frame);
        frame:SetScript("OnUpdate", nil);
    end

    local function InitCastbars(frame, unit, infoFunc)
        local name, text, texture, startTime, endTime, isTradeSkill, castID,
              notInterruptible = infoFunc(unit);

        if name then
            frame:SetScript("OnUpdate", function(frame)
                UpdateCast(frame)
            end);
            frame.casting = true;
            frame.startTime = startTime;
            frame.maxValue = (endTime - startTime) / 1000;
            UpdateCast(frame)
        end
    end

    local InitCast = function(frame, unit)
        InitCastbars(frame, unit, UnitCastingInfo);
    end

    local InitChannel = function(frame, unit)
        InitCastbars(frame, unit, UnitChannelInfo);
    end

    local function Setup(frame)
        local info = PandaUIUnits:GetUnitInfo(unit);

        frame.refs.cast:SetValue(0);
        frame:SetScript("OnUpdate", nil);
        -- Check for casting and channeling on new unit
        InitCast(frame, unit);
        if not frame.casting then InitChannel(frame, unit); end

        if not info or info.dead then
            frame.casting = false;
            frame.channeling = false;
            frame.refs.health:SetValue(1);
            frame.refs.power:SetValue(1);
            frame.refs.health:SetStatusBarColor(InactiveColor);
            frame.refs.power:SetStatusBarColor(InactiveColor);
            frame.details.backgroundColor =
                FadeBy(InactiveColor, BackgroundAlpha);
            frame.details.alpha = .5;
            frame:UpdateStyles();
            return
        end

        frame.details.alpha = 1.0;
        frame.details.backgroundColor = DefaultBackgroundColor;

        frame.refs.health:SetStatusBarColor(DefaultHealthColor);
        frame.refs.power:SetStatusBarColor(DefaultPowerColor);

        frame:UpdateUnit();
    end

    local function Update(frame)
        local info = PandaUIUnits:GetUnitInfo(unit);
        if not info or info.dead then
            frame.refs.health:SetValue(1);
            frame.refs.power:SetValue(1);
            return
        end

        frame.refs.health:SetValue(info.health / info.maxHealth);
        frame.refs.power:SetValue(info.power / info.maxPower);
    end

    return {
        name = "UnitFrame",
        height = PandaUICore:val(50),
        width = PandaUICore:val(150),
        backgroundColor = DefaultBackgroundColor,
        children = {
            PandaUICore:StatusBar({
                name = "CastBar",
                ref = "cast",
                statusBar = {color = DefaultCastColor}
            }), {
                name = "Status",
                childLayout = {direction = "vertical"},
                height = PandaUICore:val(40),
                width = PandaUICore:val(140),
                anchor = PandaUICore:anchor("CENTER"),
                children = {
                    PandaUICore:StatusBar(
                        {
                            name = "Health",
                            ref = "health",
                            layout = {parts = 9},
                            statusBar = {color = DefaultHealthColor}
                        }), PandaUICore:StatusBar(
                        {
                            name = "Power",
                            ref = "power",
                            statusBar = {color = DefaultPowerColor}
                        })
                },
                init = function(frame)
                    local button = CreateFrame("Button",
                                               frame:GetName() .. "UnitButton",
                                               frame, "SecureUnitButtonTemplate")
                    button:SetSize(frame:GetWidth(), frame:GetHeight());
                    button:RegisterForClicks("AnyUp");
                    button:SetPoint("CENTER");
                    SecureUnitButton_OnLoad(button, unit, dropDownMenu);
                    -- button:SetAttribute("*type1", "target");
                    -- button:SetAttribute("shift-type2", "target");
                    -- button:SetAttribute("unit", unit);
                end
            }
        },
        unit = {
            name = unit,
            events = {
                UNIT_HEALTH = Update,
                UNIT_POWER_FREQUENT = Update,
                UNIT_SPELLCAST_START = InitCast,
                UNIT_SPELLCAST_DELAYED = InitCast,
                UNIT_SPELLCAST_STOP = EndCast,
                UNIT_SPELLCAST_FAILED = EndCast,
                UNIT_SPELLCAST_INTERRUPTED = EndCast,
                UNIT_SPELLCAST_CHANNEL_START = InitChannel,
                UNIT_SPELLCAST_CHANNEL_UPDATE = InitChannel,
                UNIT_SPELLCAST_CHANNEL_STOP = EndCast
            }
        },
        events = {},
        scripts = {OnShow = function(frame) frame:SetupUnit(); end},
        init = function(frame)
            function frame:UpdateUnit() Update(frame) end
            function frame:SetupUnit() Setup(frame) end
        end
    };
end

local function SetMovable(details, default, vars, saveVar)
    local point = vars[saveVar] or default;
    details.anchor = PandaUICore:anchor(point.point, point.relativePoint,
                                        point.xOfs, point.yOfs);
    details.movable = true;
    details.scripts.OnMouseDown = function(frame) frame:StartMoving(); end
    details.scripts.OnMouseUp = function(frame)
        frame:StopMovingOrSizing();
        local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(1);
        vars[saveVar] = {
            point = point,
            relativeTo = relativeTo,
            relativePoint = relativePoint,
            xOfs = xOfs,
            yOfs = yOfs
        };

        frame.details.anchor = PandaUICore:anchor(point, relativePoint, xOfs,
                                                  yOfs);
    end
end

function PandaUIUnits:TargetFrame(vars)
    local dropdown = TargetFrameDropDown;
    local menuFunc = TargetFrameDropDown_Initialize;
    UIDropDownMenu_SetInitializeFunction(dropdown, menuFunc);
    UIDropDownMenu_SetDisplayMode(dropdown, "MENU");

    local showmenu = function()
        ToggleDropDownMenu(1, nil, dropdown, "cursor", 0, 0);
    end
    local details = self:UnitFrame("target", showmenu);
    details.hidden = true;

    local function SetupTarget(frame)
        local info = PandaUIUnits:GetUnitInfo("target");
        local playerInCombat = InCombatLockdown();

        frame:SetupUnit();

        if info then
            if not playerInCombat then frame.details.hidden = false; end

            if info.isFriend then
                frame.details.backgroundColor = {r = 0, g = .5, b = 0, a = .4};
            else
                frame.details.backgroundColor = {r = .5, g = 0, b = 0, a = .4};
            end
        elseif not playerInCombat then
            frame.details.hidden = true;
        end

        frame:UpdateStyles();
    end

    details.events.PLAYER_ENTERING_WORLD = SetupTarget;
    details.events.PLAYER_TARGET_CHANGED = SetupTarget;
    details.events.PLAYER_REGEN_DISABLED =
        function(frame)
            -- entering combat, unhide target frame but make invisible
            -- to be available for updates
            -- frame.details.alpha = .25;
            -- frame:UpdateStyles();
        end;
    details.events.PLAYER_REGEN_ENABLED =
        function(frame)
            -- completly hide frame
            -- frame:UpdateStyles();
            if not UnitExists(unit) and not InCombatLockdown() then
                frame.details.hidden = true;
                frame:UpdateStyles();
            end
        end;

    SetMovable(details, {
        point = "CENTER",
        relativePoint = "CENTER",
        xOfs = 0,
        yOfs = 200
    }, vars.Target, "position");

    return details;
end

function PandaUIUnits:PlayerFrame(vars)
    local menuFunc = function()
        ToggleDropDownMenu(1, nil, PlayerFrameDropDown, "cursor", 0, 0);
    end
    local details = self:UnitFrame("player", menuFunc);
    details.anchor = point;
    SetMovable(details, {
        point = "CENTER",
        relativePoint = "CENTER",
        xOfs = 0,
        yOfs = -200
    }, vars.Player, "position");

    return details;
end
