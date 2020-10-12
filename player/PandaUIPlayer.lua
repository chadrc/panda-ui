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

    local PowerUpdater = function(powerTokenGetter)
        return function(frame, unit, type)
            if unit == "player" then
                local powerType = powerEnumFromEnergizeStringLookup[type];

                if powerType == powerTokenGetter() then
                    local maxHealthWidth = frame:GetParent():GetWidth();
                    local maxHealth = UnitPowerMax(unit, powerType);
                    local currentHealth = UnitPower(unit, powerType);
                    local newWidth = maxHealthWidth *
                                         (currentHealth / maxHealth);

                    frame.details.width = PandaUICore:val(newWidth);
                    frame:UpdateStyles();
                end
            end
        end
    end

    local SecondaryPower = PowerUpdater(function()
        return self.powerInfo:GetSecondaryToken()
    end);
    local PrimaryPower = PowerUpdater(function()
        return self.powerInfo.primary.token
    end);

    self.root = PandaUICore:CreateFrame("PlayerBars", {
        height = PandaUICore:val(150),
        childLayout = {direction = "horizontal"}
    }, {
        {
            name = "PlayerHealth",
            children = {
                {
                    name = "CurrentHealth",
                    backgroundColor = {r = 0, g = 1, b = 0},
                    anchor = PandaUICore:anchor("RIGHT"),
                    events = {
                        UNIT_HEALTH = function(frame, unit)
                            if unit == "player" then
                                local maxHealthWidth = s:GetParent():GetWidth();
                                local maxHealth = UnitHealthMax(unit);
                                local currentHealth = UnitHealth(unit);
                                local newWidth =
                                    maxHealthWidth * (currentHealth / maxHealth);

                                frame.details.width = PandaUICore:val(newWidth);
                                frame:UpdateStyles();
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
                    backgroundColor = self.powerInfo:GetSecondaryColor(),
                    init = function(frame)
                        SecondaryPower(frame, "player",
                                       self.powerInfo:GetSecondaryLabel())
                    end,
                    events = {
                        UNIT_POWER_FREQUENT = SecondaryPower,
                        ACTIVE_TALENT_GROUP_CHANGED = function(frame)
                            local newSpec = GetSpecialization();
                            self.spec = newSpec;
                            self.powerInfo = GetPowerInfo(playerClass, newSpec);

                            frame.details.hidden = not self.powerInfo.secondary;
                            frame.details.backgroundColor =
                                self.powerInfo:GetSecondaryColor();

                            frame:GetParent():UpdateLayout();
                        end
                    }
                }, {
                    name = "PrimaryPower",
                    layout = {parts = 2},
                    backgroundColor = self.powerInfo.primary.color,
                    init = function(frame)
                        PrimaryPower(frame, "player",
                                     self.powerInfo.primary.label)
                    end,
                    events = {
                        UNIT_POWER_FREQUENT = PrimaryPower,
                        ACTIVE_TALENT_GROUP_CHANGED = function(frame)
                            local newSpec = GetSpecialization();
                            self.spec = newSpec;
                            local powerInfo = GetPowerInfo(playerClass, newSpec);

                            frame.details.backgroundColor =
                                powerInfo.primaryColor;

                            frame:UpdateStyles();
                        end
                    }
                }
            }
        }
    });

    self.root:UpdateStyles();
    self.root:UpdateLayout();
    self.root:Init();
end
