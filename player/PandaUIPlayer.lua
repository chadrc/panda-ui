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

function PandaUIPlayer:Initialize()
    local _, playerClass = UnitClass("player");
    self.spec = GetSpecialization();
    self.playerClass = playerClass;

    local powerInfo = {
        primary = Enum.PowerType.Mana,
        primaryColor = PowerBarColor["MANA"],
        secondary = nil,
        secondaryColor = nil
    }

    -- temporary check to avoid errors while developing
    -- eventually all should be registered
    if classPowers[playerClass] and classPowers[playerClass][self.spec] then
        powerInfo = classPowers[playerClass][self.spec];
    else
        print('Class ', playerClass, ' with spec ', self.spec,
              ' not configured. Using defaults.')
    end

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
                        UNIT_HEALTH = function(self, unit)
                            if unit == "player" then
                                local healthFrame = self;
                                local maxHealthWidth =
                                    healthFrame:GetParent():GetWidth();
                                local maxHealth = UnitHealthMax(unit);
                                local currentHealth = UnitHealth(unit);
                                local newWidth =
                                    maxHealthWidth * (currentHealth / maxHealth);

                                healthFrame:SetWidth(newWidth);
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
                    backgroundColor = powerInfo.secondaryColor,
                    events = {
                        UNIT_POWER_FREQUENT = function(self, unit, type)
                            if unit == "player" then
                                local powerType =
                                    powerEnumFromEnergizeStringLookup[type];

                                if powerType == powerInfo.secondary then
                                    local maxHealthWidth =
                                        self:GetParent():GetWidth();
                                    local maxHealth =
                                        UnitPowerMax(unit, powerType);
                                    local currentHealth =
                                        UnitPower(unit, powerType);
                                    local newWidth =
                                        maxHealthWidth *
                                            (currentHealth / maxHealth);

                                    self:SetWidth(newWidth);
                                end
                            end
                        end
                    }
                }, {
                    name = "PrimaryPower",
                    layout = {parts = 2},
                    backgroundColor = powerInfo.primaryColor,
                    events = {
                        UNIT_POWER_FREQUENT = function(self, unit, type)
                            if unit == "player" then
                                local powerType =
                                    powerEnumFromEnergizeStringLookup[type];

                                if powerType == powerInfo.primary then
                                    local maxHealthWidth =
                                        self:GetParent():GetWidth();
                                    local maxHealth =
                                        UnitPowerMax(unit, powerType);
                                    local currentHealth =
                                        UnitPower(unit, powerType);
                                    local newWidth =
                                        maxHealthWidth *
                                            (currentHealth / maxHealth);

                                    self:SetWidth(newWidth);
                                end
                            end
                        end
                    }
                }
            }
        }
    });
end
