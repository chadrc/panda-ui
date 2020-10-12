PandaUIPlayer = {};

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

local classPowers = {
    MONK = {
        {
            -- Brewmaster
            primary = Enum.PowerType.Energy,
            primaryColor = PowerBarColor["ENERGY"],
            secondary = "STAGGER",
            secondaryColor = PowerBarColor["STAGGER"]
        }, {
            -- Mistweaver
            primary = Enum.PowerType.Mana,
            primaryColor = PowerBarColor["MANA"],
            secondary = nil,
            secondaryColor = nil
        }, {
            -- Windwalker
            primary = Enum.PowerType.Energy,
            primaryColor = PowerBarColor["ENERGY"],
            secondary = Enum.PowerType.Chi,
            secondaryColor = PowerBarColor["CHI"]
        }
    }
}

local function GetPowerInfo(class, spec)
    local powerInfo = {
        primary = Enum.PowerType.Mana,
        primaryColor = PowerBarColor["MANA"],
        secondary = nil,
        secondaryColor = nil
    }

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

function PandaUIPlayer:Initialize()
    local _, playerClass = UnitClass("player");
    self.spec = GetSpecialization();
    self.playerClass = playerClass;

    self.powerInfo = GetPowerInfo(playerClass, self.spec);

    self.root = PandaUICore:CreateFrame("PlayerBars", {
        height = PandaUICore:val(150),
        childLayout = {direction = "horizontal"}
    }, {
        {
            name = "PlayerHealth",
            children = {
                {
                    name = "CurrentHealth",
                    backgroundColor = {r = 0, g = 1, b = 0, a = 1},
                    anchor = PandaUICore:anchor("RIGHT"),
                    events = {
                        UNIT_HEALTH = function(s, unit)
                            if unit == "player" then
                                local maxHealthWidth = s:GetParent():GetWidth();
                                local maxHealth = UnitHealthMax(unit);
                                local currentHealth = UnitHealth(unit);
                                local newWidth =
                                    maxHealthWidth * (currentHealth / maxHealth);

                                s.details.width = PandaUICore:val(newWidth);
                                s:UpdateStyles();
                            end
                        end
                    }
                }
            }
        }, {
            name = "Power",
            childLayout = {direction = "vertical"},
            children = {
                {
                    name = "SecondaryPower",
                    hidden = not self.powerInfo.secondary,
                    backgroundColor = self.powerInfo.secondaryColor,
                    events = {
                        UNIT_POWER_FREQUENT = function(s, unit, type)
                            if unit == "player" then
                                local powerType =
                                    powerEnumFromEnergizeStringLookup[type];

                                if powerType == self.powerInfo.secondary then
                                    local maxHealthWidth =
                                        s:GetParent():GetWidth();
                                    local maxHealth =
                                        UnitPowerMax(unit, powerType);
                                    local currentHealth =
                                        UnitPower(unit, powerType);
                                    local newWidth =
                                        maxHealthWidth *
                                            (currentHealth / maxHealth);

                                    s.details.width = PandaUICore:val(newWidth);
                                    s:UpdateStyles();
                                end
                            end
                        end,
                        ACTIVE_TALENT_GROUP_CHANGED = function(s)
                            local newSpec = GetSpecialization();
                            self.spec = newSpec;
                            self.powerInfo = GetPowerInfo(playerClass, newSpec);

                            s.details.hidden = not self.powerInfo.secondary;
                            s.details.backgroundColor =
                                self.powerInfo.secondaryColor;

                            -- s:UpdateStyles();
                            s:GetParent():UpdateLayout();
                        end
                    }
                }, {
                    name = "PrimaryPower",
                    layout = {parts = 2},
                    backgroundColor = self.powerInfo.primaryColor,
                    events = {
                        UNIT_POWER_FREQUENT = function(s, unit, type)
                            if unit == "player" then
                                local powerType =
                                    powerEnumFromEnergizeStringLookup[type];

                                if powerType == self.powerInfo.primary then
                                    local maxHealthWidth =
                                        s:GetParent():GetWidth();
                                    local maxHealth =
                                        UnitPowerMax(unit, powerType);
                                    local currentHealth =
                                        UnitPower(unit, powerType);
                                    local newWidth =
                                        maxHealthWidth *
                                            (currentHealth / maxHealth);

                                    s.details.width = PandaUICore:val(newWidth);
                                    s:UpdateStyles();
                                end
                            end
                        end,
                        ACTIVE_TALENT_GROUP_CHANGED = function(s)
                            local newSpec = GetSpecialization();
                            self.spec = newSpec;
                            local powerInfo = GetPowerInfo(playerClass, newSpec);

                            s.details.backgroundColor = powerInfo.primaryColor;

                            s:UpdateStyles();
                        end
                    }
                }
            }
        }
    });

    self.root:UpdateStyles();
    self.root:UpdateLayout();
end
