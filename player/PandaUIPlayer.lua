PandaUIPlayer = {};

-- Copied from CombatText Blizzard Addon
local powerEnumFromEnergizeStringLookup =
    {
        MANA = Enum.PowerType.Mana,
        RAGE = Enum.PowerType.Rage,
        FOCUS = Enum.PowerType.Focus,
        ENERGY = Enum.PowerType.Energy,
        COMBO_POINTS = Enum.PowerType.ComboPoints,
        RUNES = Enum.PowerType.Runes,
        RUNIC_POWER = Enum.PowerType.RunicPower,
        SOUL_SHARDS = Enum.PowerType.SoulShards,
        LUNAR_POWER = Enum.PowerType.LunarPower,
        HOLY_POWER = Enum.PowerType.HolyPower,
        ALTERNATE = Enum.PowerType.Alternate,
        MAELSTROM = Enum.PowerType.Maelstrom,
        CHI = Enum.PowerType.Chi,
        ARCANE_CHARGES = Enum.PowerType.ArcaneCharges,
        FURY = Enum.PowerType.Fury,
        PAIN = Enum.PowerType.Pain,
        INSANITY = Enum.PowerType.Insanity
    }

local function MakeSinglePowerInfo(label)
    return {
        label = label,
        token = powerEnumFromEnergizeStringLookup[label],
        color = PowerBarColor[label]
    };
end

local function MakePowerInfo(primary, secondary)
    local info = {primary = MakeSinglePowerInfo(primary)};
    if secondary then info.secondary = MakeSinglePowerInfo(secondary); end

    function info:GetSecondaryLabel()
        if self.secondary then return self.secondary.label end
        return nil;
    end

    function info:GetSecondaryToken()
        if self.secondary then return self.secondary.token end
        return nil;
    end

    function info:GetSecondaryColor()
        if self.secondary then return self.secondary.color end
        return nil;
    end

    return info;
end

local classPowers = {
    MONK = {
        MakePowerInfo("ENERGY"), -- Brewmaster
        MakePowerInfo("MANA"), -- Mistweaver
        MakePowerInfo("ENERGY", "CHI") -- Windwalker
    },
    MAGE = {
        MakePowerInfo("MANA", "ARCANE_CHARGES"), -- Arcane
        MakePowerInfo("MANA"), -- Fire
        MakePowerInfo("MANA") -- Frost
    }
}

local function GetPowerInfo(class, spec)
    local powerInfo = MakePowerInfo("MANA")

    -- temporary check to avoid errors while developing
    -- eventually all should be registered
    if classPowers[class] and classPowers[class][spec] then
        powerInfo = classPowers[class][spec];
    else
        print('Class ', class, ' with spec ', spec,
              ' not configured. Using defaults.')
    end

    return powerInfo;
end

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
                statusBar = {color = {r = 0, g = .8, b = 0, a = 1.0}},
                init = function(frame)
                    frame:SetReverseFill(true);
                    Update(frame);
                end,
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

local function PositionPrediction(frame, max, current)
    if not frame.predictedPowerCost then return end

    local parentWidth = frame:GetParent():GetWidth();

    local predictedPercent = frame.predictedPowerCost / max;
    frame.details.width = PandaUICore:val(predictedPercent * parentWidth);

    local missingPercent = (max - current) / max;
    frame.details.anchor = PandaUICore:anchor("RIGHT", "RIGHT",
                                              -missingPercent * parentWidth, 0);

    frame:UpdateStyles();
end

local function PowerUpdater(powerTokenGetter)
    return function(frame, unit, type)
        if unit == "player" then
            local powerType = powerEnumFromEnergizeStringLookup[type];

            if powerType == powerTokenGetter() then
                local max = UnitPowerMax(unit, powerType);
                local current = UnitPower(unit, powerType);

                frame:SetMinMaxValues(0, max);
                frame:SetValue(current);

                PositionPrediction(frame.refs.costPrediction, max, current);
            end
        end
    end
end

function PandaUIPlayer:PlayerPowerFrame()
    local _, playerClass = UnitClass("player");
    self.spec = GetSpecialization();
    self.playerClass = playerClass;
    self.powerInfo = MakePowerInfo("MANA");

    local SecondaryPower = PowerUpdater(function()
        return self.powerInfo:GetSecondaryToken()
    end);
    local PrimaryPower = PowerUpdater(function()
        return self.powerInfo.primary.token
    end);

    local function ForcePrimary(frame)
        PrimaryPower(frame, "player", self.powerInfo.primary.label)
    end

    local function ForceSecondary(frame)
        SecondaryPower(frame, "player", self.powerInfo:GetSecondaryLabel())
    end

    local function StartPrediction(frame, unit)
        if unit ~= "player" then return end

        local name, text, texture, startTime, endTime, isTradeSkill, castID,
              notInterruptible, spellID = UnitCastingInfo(unit);

        local powerType = self.powerInfo.primary.token;
        local cost = 0;
        local costTable = GetSpellPowerCost(spellID);
        for _, costInfo in pairs(costTable) do
            if (costInfo.type == powerType) then
                cost = costInfo.cost;
                break
            end
        end

        if cost ~= 0 then
            frame.predictedPowerCost = cost;
            frame.details.hidden = false;

            local max = UnitPowerMax(unit, powerType);
            local current = UnitPower(unit, powerType);

            PositionPrediction(frame, max, current);
        end
    end

    local function EndPrediction(frame, unit)
        if unit ~= "player" then return end

        frame.predictedPowerCost = nil;
        frame.details.width = PandaUICore:val(0);
        frame.details.hidden = true;

        frame:UpdateStyles();
    end

    local function Init(frame)
        local newSpec = GetSpecialization();
        self.spec = newSpec;
        self.powerInfo = GetPowerInfo(self.playerClass, newSpec);

        local pClr = self.powerInfo.primary.color;
        frame.refs.primaryPower.texture:SetColorTexture(pClr.r, pClr.g, pClr.b,
                                                        pClr.a);

        frame.refs.secondaryPower.details.hidden = not self.powerInfo.secondary;

        local sClr = self.powerInfo:GetSecondaryColor();
        if sClr then
            frame.refs.secondaryPower.texture:SetColorTexture(sClr.r, sClr.g,
                                                              sClr.b, sClr.a);
        end

        ForcePrimary(frame.refs.primaryPower);
        ForceSecondary(frame.refs.secondaryPower);

        frame:UpdateLayout();
    end

    return {
        name = "Power",
        ref = "power",
        childLayout = {direction = "vertical"},
        children = {
            PandaUICore:StatusBar({
                name = "SecondaryPower",
                ref = "secondaryPower",
                hidden = not self.powerInfo.secondary,
                statusBar = {color = self.powerInfo:GetSecondaryColor()},
                events = {
                    UNIT_POWER_FREQUENT = SecondaryPower,
                    PLAYER_ENTERING_WORLD = ForceSecondary,
                    UNIT_DISPLAYPOWER = ForceSecondary
                },
                children = {
                    {
                        name = "CostPrediction",
                        ref = "costPrediction",
                        hidden = true,
                        anchor = PandaUICore:anchor("RIGHT"),
                        height = PandaUICore:pct(1),
                        width = PandaUICore:val(50),
                        backgroundColor = {r = 0, g = 0, b = 0, a = .5}
                    }
                }
            }), PandaUICore:StatusBar({
                name = "PrimaryPower",
                ref = "primaryPower",
                layout = {parts = 2},
                statusBar = {color = self.powerInfo.primary.color},
                events = {
                    UNIT_POWER_FREQUENT = PrimaryPower,
                    PLAYER_ENTERING_WORLD = ForcePrimary,
                    UNIT_DISPLAYPOWER = ForcePrimary
                },
                children = {
                    {
                        name = "CostPrediction",
                        ref = "costPrediction",
                        hidden = true,
                        anchor = PandaUICore:anchor("RIGHT"),
                        height = PandaUICore:pct(1),
                        width = PandaUICore:val(50),
                        backgroundColor = {r = 0, g = 0, b = 0, a = .5},
                        events = {
                            UNIT_SPELLCAST_START = StartPrediction,
                            UNIT_SPELLCAST_STOP = EndPrediction,
                            UNIT_SPELLCAST_FAILED = EndPrediction,
                            UNIT_SPELLCAST_SUCCEEDED = EndPrediction
                        }
                    }
                }
            })
        },
        events = {
            PLAYER_ENTERING_WORLD = Init,
            ACTIVE_TALENT_GROUP_CHANGED = Init
        }
    }
end

function PandaUIPlayer:PlayerExpBar()
    local function Update(frame)
        if IsPlayerAtEffectiveMaxLevel() then
            frame.details.hidden = true;
            frame:GetParent():UpdateLayout();
            return;
        end

        local current = UnitXP("player");
        local max = UnitXPMax("player");

        frame:SetMinMaxValues(0, max);
        frame:SetValue(current);
    end

    return PandaUICore:StatusBar({
        name = "ExpBar",
        init = function(frame) Update(frame); end,
        events = {PLAYER_ENTERING_WORLD = Update, PLAYER_XP_UPDATE = Update}
    });
end

function PandaUIPlayer:PlayerCastingBar()
    local function UpdateCast(frame, elapsed)
        frame.value = frame.value + elapsed;
        frame:SetValue(frame.value);
    end

    local function UpdateChannel(frame, elapsed)
        frame.value = frame.value - elapsed;
        frame:SetValue(frame.value);
    end

    local function Update(frame, elapsed)
        if frame.casting then
            UpdateCast(frame, elapsed);
        elseif frame.channeling then
            UpdateChannel(frame, elapsed);
        end
    end

    local function EndCast(frame, unit)
        if unit ~= "player" then return end
        frame.casting = false;
        frame.channeling = false;
        frame:SetMinMaxValues(0, 1);
        frame:SetValue(0);
    end

    return {
        name = "CastingBar",
        children = {
            PandaUICore:StatusBar({
                statusBar = {color = {r = 0, g = .8, b = .8}},
                init = function(frame)
                    frame:SetMinMaxValues(0, 1);
                    frame:SetValue(0);

                    frame:SetScript("OnUpdate", function(frame, elapsed)
                        Update(frame, elapsed);
                    end)
                end,
                events = {
                    UNIT_SPELLCAST_START = function(frame, unit)
                        if unit ~= "player" then return end
                        local name, text, texture, startTime, endTime,
                              isTradeSkill, castID, notInterruptible =
                            UnitCastingInfo("player");

                        frame.casting = true;
                        frame.channeling = false;
                        frame.value = (GetTime() - (startTime / 1000));
                        frame.maxValue = (endTime - startTime) / 1000;
                        frame:SetMinMaxValues(0, frame.maxValue);
                        frame:SetValue(frame.value);
                    end,
                    UNIT_SPELLCAST_DELAYED = function(frame, unit)
                        if unit ~= "player" then return end
                        local name, text, texture, startTime, endTime,
                              isTradeSkill, castID, notInterruptible =
                            UnitCastingInfo("player");

                        frame.value = (GetTime() - (startTime / 1000));
                        frame.maxValue = (endTime - startTime) / 1000;
                        frame:SetMinMaxValues(0, frame.maxValue);
                        frame:SetValue(frame.value);
                    end,
                    UNIT_SPELLCAST_STOP = EndCast,
                    UNIT_SPELLCAST_FAILED = EndCast,
                    UNIT_SPELLCAST_INTERRUPTED = EndCast,
                    UNIT_SPELLCAST_CHANNEL_START = function(frame, unit)
                        if unit ~= "player" then return end

                        local name, text, texture, startTime, endTime,
                              isTradeSkill, notInterruptible, spellID =
                            UnitChannelInfo("player");

                        frame.channeling = true;
                        frame.casting = false;
                        frame.value = (endTime / 1000) - GetTime();
                        frame.maxValue = (endTime - startTime) / 1000;
                        frame:SetMinMaxValues(0, frame.maxValue);
                        frame:SetValue(frame.value);
                    end,
                    UNIT_SPELLCAST_CHANNEL_UPDATE = function(frame, unit)
                        if unit ~= "player" then return end

                        local name, text, texture, startTime, endTime,
                              isTradeSkill, notInterruptible, spellID =
                            UnitChannelInfo("player");

                        frame.value = (endTime / 1000) - GetTime();
                        frame.maxValue = (endTime - startTime) / 1000;
                        frame:SetMinMaxValues(0, frame.maxValue);
                        frame:SetValue(frame.value);
                    end,
                    UNIT_SPELLCAST_CHANNEL_STOP = EndCast
                }
            })
        }
    }
end

function PandaUIPlayer:Initialize()
    self.root = PandaUICore:CreateFrame("PlayerBars", {
        height = PandaUICore:val(150),
        childLayout = {direction = "vertical"},
        backgroundColor = {r = 0, g = 0, b = 0, a = .5}
    }, {
        self:PlayerCastingBar(), {
            layout = {parts = 6},
            childLayout = {direction = "horizontal"},
            children = {self:PlayerHealthFrame(), self:PlayerPowerFrame()}
        }, self:PlayerExpBar()
    });

    self.root:UpdateStyles();
    self.root:UpdateLayout();
    self.root:Init();
end

