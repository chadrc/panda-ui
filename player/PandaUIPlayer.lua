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
        INSANITY = Enum.PowerType.Insanity,
        -- Added to avoid one off unique behavior
        STAGGER = -1
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
        MakePowerInfo("ENERGY", "STAGGER"), -- Brewmaster
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
    local function Update(frame)
        local max = UnitHealthMax("player");
        local cur = UnitHealth("player");

        frame:SetMinMaxValues(0, max);
        frame:SetValue(cur);
    end

    return {
        name = "PlayerHealth",
        backgroundColor = {r = 0, g = .8, b = 0, a = .2},
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
                    PLAYER_ENTERING_WORLD = Update
                }
            })
        }
    }
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
            end
        end
    end
end

function PandaUIPlayer:PlayerPowerFrame()
    local _, playerClass = UnitClass("player");
    self.spec = GetSpecialization();
    self.playerClass = playerClass;

    self.powerInfo = MakePowerInfo("MANA");

    local CheckForStagger = function()
        -- stagger is not considered a unit power
        -- copying what FrameXML MonkStaggerBar does and update stagger display in update
        -- register if Monk class and Brewmaster spec
        -- else, unregister
        if playerClass == "MONK" and self.spec == 1 then
            self.root:SetScript("OnUpdate", function(self)
                local max = UnitHealthMax("player");
                local cur = UnitStagger("player");

                local maxWidth = self.refs.secondaryPower:GetParent():GetWidth();
                local newWidth = maxWidth * (cur / max);

                self.refs.secondaryPower.details.width =
                    PandaUICore:val(newWidth);
                self.refs.secondaryPower:UpdateStyles();
            end)
        else
            self.root:SetScript("OnUpdate", nil)
        end
    end

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

    -- CheckForStagger();
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
                init = ForceSecondary,
                events = {
                    UNIT_POWER_FREQUENT = SecondaryPower,
                    PLAYER_ENTERING_WORLD = ForceSecondary,
                    UNIT_DISPLAYPOWER = ForceSecondary
                }
            }), PandaUICore:StatusBar({
                name = "PrimaryPower",
                ref = "primaryPower",
                layout = {parts = 2},
                statusBar = {color = self.powerInfo.primary.color},
                init = ForcePrimary,
                events = {
                    UNIT_POWER_FREQUENT = PrimaryPower,
                    PLAYER_ENTERING_WORLD = ForcePrimary,
                    UNIT_DISPLAYPOWER = ForcePrimary
                }
            })
        },
        events = {
            PLAYER_ENTERING_WORLD = function(frame)
                local _, playerClass = UnitClass("player");
                self.spec = GetSpecialization();
                self.playerClass = playerClass;
                self.powerInfo = GetPowerInfo(playerClass, self.spec);
            end,
            ACTIVE_TALENT_GROUP_CHANGED = function(frame)
                local newSpec = GetSpecialization();
                self.spec = newSpec;
                self.powerInfo = GetPowerInfo(playerClass, newSpec);

                CheckForStagger();

                local pClr = self.powerInfo.primary.color;
                frame.refs.primaryPower.texture:SetColorTexture(pClr.r, pClr.g,
                                                                pClr.b, pClr.a);

                frame.refs.secondaryPower.details.hidden =
                    not self.powerInfo.secondary;

                local sClr = self.powerInfo:GetSecondaryColor();
                if sClr then
                    frame.refs.secondaryPower.texture:SetColorTexture(sClr.r,
                                                                      sClr.g,
                                                                      sClr.b,
                                                                      sClr.a);
                end

                frame:UpdateLayout();
            end
        }
    }
end

function PandaUIPlayer:PlayerExpBar()
    local function Update(frame)
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

