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

function PandaUIPlayer:Initialize()
    self.root = PandaUICore:CreateFrame("PlayerBars", {
        height = PandaUICore:val(150),
        layout = {direction = "horizontal"}
    }, {
        {
            name = "PlayerHealth",
            children = {
                {
                    name = "CurrentHealth",
                    ref = "playerHealth",
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
            name = "PrimaryResource",
            children = {
                {
                    name = "PrimaryPower",
                    ref = "primaryPower",
                    backgroundColor = {r = 0, g = 0, b = 1, a = 1},
                    anchor = PandaUICore:anchor("LEFT"),
                    events = {
                        UNIT_POWER_FREQUENT = function(self, unit, type)
                            if unit == "player" then
                                print("power change: ", type);
                                local primaryPowerFrame = self;
                                local maxHealthWidth =
                                    primaryPowerFrame:GetParent():GetWidth();
                                local powerType =
                                    powerEnumFromEnergizeStringLookup[type];
                                local maxHealth = UnitPowerMax(unit, powerType);
                                local currentHealth = UnitPower(unit, powerType);
                                local newWidth =
                                    maxHealthWidth * (currentHealth / maxHealth);

                                primaryPowerFrame:SetWidth(newWidth);
                            end
                        end
                    }
                }
            }
        }
    });

    for k, v in pairs(self.root.refs.playerHealth) do print(k, ' - ', v); end
end
