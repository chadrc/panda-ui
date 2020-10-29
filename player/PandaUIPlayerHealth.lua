function PandaUIPlayer:PlayerHealthFrame()
    local function Update(frame, unit)
        if unit ~= "player" and unit ~= nil then return end

        local max = UnitHealthMax("player");
        local cur = UnitHealth("player");

        local allIncomingHeal = UnitGetIncomingHeals("player") or 0;
        local totalAbsorb = UnitGetTotalAbsorbs("player") or 0;

        if totalAbsorb > 0 then
            local p = totalAbsorb / max;
            frame.refs.absorbPrediction.details.width = PandaUICore:pct(p);
            frame.refs.absorbPrediction.details.hidden = false;
        else
            frame.refs.absorbPrediction.details.hidden = true;
        end
        frame.refs.absorbPrediction:UpdateStyles();

        if allIncomingHeal > 0 then
            -- if over healing, use amount of lost health instead
            if allIncomingHeal + cur > max then
                allIncomingHeal = max - cur;
            end
            local p = allIncomingHeal / max;
            frame.refs.healPrediction.details.width = PandaUICore:pct(p);
            local offset = (cur / max) * frame:GetWidth();
            frame.refs.healPrediction.details.anchor =
                PandaUICore:anchor("RIGHT", "RIGHT", -offset, 0);
            frame.refs.healPrediction.details.hidden = false;
        else
            frame.refs.healPrediction.details.hidden = true;
        end
        frame.refs.healPrediction._debug = true
        frame.refs.healPrediction:UpdateStyles();

        frame:SetMinMaxValues(0, max);
        frame:SetValue(cur);
    end

    local function CheckForStagger(frame)
        local _, playerClass = UnitClass("player");
        local spec = GetSpecialization();

        if playerClass == "MONK" and spec == 1 then
            frame:SetScript("OnUpdate", function()
                local max = UnitHealthMax("player");
                local cur = UnitHealth("player");
                local stagger = UnitStagger("player");

                local overlayDetails = frame.refs.staggerOverlay.details;
                if stagger > 0 then
                    local p = stagger / max;
                    overlayDetails.width = PandaUICore:pct(p);
                    overlayDetails.hidden = false;

                    local offset = (cur / max) * frame:GetWidth();
                    overlayDetails.anchor =
                        PandaUICore:anchor("LEFT", "RIGHT", -offset, 0);
                else
                    overlayDetails.hidden = true;
                end

                frame.refs.staggerOverlay:UpdateStyles();
            end);
        else
            frame:SetScript("OnUpdate", nil);
        end
    end

    return {
        name = "PlayerHealth",
        backgroundColor = {r = 0, g = .8, b = 0, a = .05},
        children = {
            PandaUICore:StatusBar({
                statusBar = {
                    color = {r = 0, g = .8, b = 0, a = 1.0},
                    reverse = true
                },
                init = Update,
                events = {
                    UNIT_HEALTH = function(frame, unit)
                        if unit == "player" then
                            Update(frame);
                        end
                    end,
                    PLAYER_ENTERING_WORLD = function(frame)
                        CheckForStagger(frame);
                        Update(frame);
                    end,
                    UNIT_HEAL_PREDICTION = Update,
                    UNIT_ABSORB_AMOUNT_CHANGED = Update,
                    UNIT_MAXHEALTH = Update,
                    PLAYER_SPECIALIZATION_CHANGED = function(frame, unit)
                        if unit ~= "player" then return end
                        CheckForStagger(frame);
                    end
                },
                children = {
                    {
                        name = "AbsorbPrediction",
                        ref = "absorbPrediction",
                        hidden = true,
                        height = PandaUICore:pct(1),
                        anchor = PandaUICore:anchor("RIGHT"),
                        backgroundColor = {r = 1.0, g = 1.0, b = 1.0, a = .5}
                    }, {
                        name = "HealPrediction",
                        ref = "healPrediction",
                        hidden = true,
                        height = PandaUICore:pct(1),
                        backgroundColor = {r = 0.0, g = .8, b = 0.0, a = .5}
                    }, {
                        name = "StaggerOverlay",
                        ref = "staggerOverlay",
                        hidden = true,
                        height = PandaUICore:pct(1),
                        backgroundColor = {r = 0, g = 0, b = 0, a = .5}
                    }
                }
            })
        }
    }
end
