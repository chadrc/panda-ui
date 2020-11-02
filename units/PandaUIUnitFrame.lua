function PandaUIUnits:GetUnitInfo(unit)
    if not UnitExists(unit) then return nil end

    local info = {
        name = UnitFullName(unit),
        class = UnitClass(unit),
        maxHealth = UnitHealthMax(unit),
        health = UnitHealth(unit),
        connected = UnitIsConnected(unit),
        castingInfo = {UnitCastingInfo(unit)},
        channelingInfo = {UnitChannelInfo(unit)},
        incomingHeals = UnitGetIncomingHeals(unit),
        totalAbsorbs = UnitGetTotalAbsorbs(unit),
        totalHealAbsorbs = UnitGetTotalHealAbsorbs(unit),
        groupRole = UnitGroupRolesAssigned(unit),
        isGhost = UnitIsGhost(unit),
        level = UnitLevel(unit),
        powerType = UnitPowerType(unit),
        maxPower = UnitPowerMax(unit),
        power = UnitPower(unit),
        isEnemy = UnitIsEnemy("player", unit),
        isFriend = UnitIsFriend("player", unit)
    };

    return info;
end

function PandaUIUnits:UnitFrame(unit, dropDownMenu)
    local function UpdateCastBars(frame)
        frame.refs.cast:SetMinMaxValues(0, frame.maxValue);
        frame.refs.cast:SetValue(frame.value);
    end

    local function Update(frame)
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

        frame:SetScript("OnUpdate", function(frame) Update(frame) end);
        frame.casting = true;
        frame.startTime = startTime;
        frame.maxValue = (endTime - startTime) / 1000;
        Update(frame)
    end

    local InitCast = function(frame, unit)
        InitCastbars(frame, unit, UnitCastingInfo);
    end

    local InitChannel = function(frame, unit)
        InitCastbars(frame, unit, UnitChannelInfo);
    end

    return {
        name = "UnitFrame",
        height = PandaUICore:val(50),
        width = PandaUICore:val(150),
        backgroundColor = {r = .5, g = .5, b = .5, a = .4},
        children = {
            PandaUICore:StatusBar({
                name = "CastBar",
                ref = "cast",
                statusBar = {color = {r = .8, g = .8, b = .8, a = .75}}
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
                            statusBar = {color = {r = 0, g = .8, b = 0}}
                        }), PandaUICore:StatusBar(
                        {
                            name = "Power",
                            ref = "power",
                            statusBar = {color = {r = 0, g = 0, b = .8}}
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
                UNIT_HEALTH = function(frame)
                    local info = PandaUIUnits:GetUnitInfo(unit);
                    local f = info.health / info.maxHealth;
                    frame.refs.health:SetValue(f);
                end,
                UNIT_POWER_FREQUENT = function(frame)
                    local info = PandaUIUnits:GetUnitInfo(unit);
                    local f = info.power / info.maxPower;
                    frame.refs.power:SetValue(f);
                end,
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
        scripts = {OnShow = function(frame) frame:Update(); end},
        init = function(frame)
            function frame:Update()
                local info = PandaUIUnits:GetUnitInfo(unit);
                if not info then return end

                frame.refs.health:SetValue(info.health / info.maxHealth);
                frame.refs.power:SetValue(info.power / info.maxPower);
            end
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

        if info then
            frame.details.hidden = false;
            frame.details.alpha = 1.0;
            if info.isFriend then
                frame.details.backgroundColor = {r = 0, g = .5, b = 0, a = .4};
            else
                frame.details.backgroundColor = {r = .5, g = 0, b = 0, a = .4};
            end
        elseif playerInCombat then
            -- can't hide frame if in combat
            -- make invisible, will hide on combat exit
            frame.details.alpha = 0;
        else
            frame.details.hidden = true;
        end

        frame:Update();
        frame:UpdateStyles();
    end

    details.events.PLAYER_ENTERING_WORLD = SetupTarget;
    details.events.PLAYER_TARGET_CHANGED = SetupTarget;
    details.events.PLAYER_REGEN_DISABLED =
        function(frame)
            -- entering combat, unhide target frame but make invisible
            -- to be available for updates
            frame.details.hidden = false;
            frame.details.alpha = 0;
            frame:UpdateStyles();
        end;
    details.events.PLAYER_REGEN_ENABLED =
        function(frame)
            -- completly hide frame
            frame.details.hidden = true;
            frame:UpdateStyles();
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
