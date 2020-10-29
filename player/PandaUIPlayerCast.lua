function PandaUIPlayer:PlayerCastingBar()
    local function UpdateCastBars(frame)
        frame.refs.leftCast:SetMinMaxValues(0, frame.maxValue);
        frame.refs.rightCast:SetMinMaxValues(0, frame.maxValue);
        frame.refs.leftCast:SetValue(frame.value);
        frame.refs.rightCast:SetValue(frame.value);
    end

    local function Update(frame)
        if not frame.casting then return end

        frame.value = GetTime() - (frame.startTime / 1000);
        UpdateCastBars(frame);
    end

    local function EndCast(frame, unit)
        if unit ~= "player" then return end
        frame.casting = false;
        frame.maxValue = 1;
        frame.value = 0;
        UpdateCastBars(frame);
    end

    local function InitCastbars(frame, unit, infoFunc)
        if unit ~= "player" then return end
        local name, text, texture, startTime, endTime, isTradeSkill, castID,
              notInterruptible = infoFunc("player");

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
        name = "CastingBar",
        init = function(frame)
            frame:SetScript("OnUpdate", function(frame)
                Update(frame);
            end)
        end,
        childLayout = {direction = "horizontal"},
        children = {
            PandaUICore:StatusBar({
                ref = "leftCast",
                statusBar = {color = {r = 0, g = .8, b = .8}}
            }), PandaUICore:StatusBar({
                ref = "rightCast",
                statusBar = {color = {r = 0, g = .8, b = .8}, reverse = true}
            })
        },
        events = {
            UNIT_SPELLCAST_START = InitCast,
            UNIT_SPELLCAST_DELAYED = InitCast,
            UNIT_SPELLCAST_STOP = EndCast,
            UNIT_SPELLCAST_FAILED = EndCast,
            UNIT_SPELLCAST_INTERRUPTED = EndCast,
            UNIT_SPELLCAST_CHANNEL_START = InitChannel,
            UNIT_SPELLCAST_CHANNEL_UPDATE = InitChannel,
            UNIT_SPELLCAST_CHANNEL_STOP = EndCast
        }
    }
end
