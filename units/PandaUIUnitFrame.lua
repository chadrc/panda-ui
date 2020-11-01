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

function PandaUIUnits:UnitFrame(unit)
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
        print("init cast")
        InitCastbars(frame, unit, UnitCastingInfo);
    end

    local InitChannel = function(frame, unit)
        InitCastbars(frame, unit, UnitChannelInfo);
    end

    return {
        name = "UnitFrame",
        height = PandaUICore:val(50),
        width = PandaUICore:val(150),
        backgroundColor = {r = .5, g = .0, b = 0, a = .25},
        anchor = PandaUICore:anchor("TOP"),
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
                }
            }
        },
        unit = {
            name = unit,
            events = {
                UNIT_HEALTH = function(frame)
                    print("health")
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

function PandaUIUnits:TargetFrame()
    local details = self:UnitFrame("target");
    details.hidden = true;

    local function SetupTarget(frame)
        if UnitExists("target") then
            frame.details.hidden = false;
        else
            frame.details.hidden = true;
        end

        frame:Update();
        frame:UpdateStyles();
    end

    details.events.PLAYER_ENTERING_WORLD = SetupTarget;
    details.events.PLAYER_TARGET_CHANGED = SetupTarget;

    return details;
end
