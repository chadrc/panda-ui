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
    return {
        name = "PlayerHealth",
        children = {
            {
                name = "CurrentHealth",
                backgroundColor = {r = 0, g = 1, b = 0},
                anchor = PandaUICore:anchor("RIGHT"),
                events = {
                    UNIT_HEALTH = function(frame, unit)
                        if unit == "player" then
                            local maxHealthWidth = frame:GetParent():GetWidth();
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
    }
end

local function PowerUpdater(powerTokenGetter)
    return function(frame, unit, type)
        if unit == "player" then
            local powerType = powerEnumFromEnergizeStringLookup[type];

            if powerType == powerTokenGetter() then
                local maxWidth = frame:GetParent():GetWidth();
                local max = UnitPowerMax(unit, powerType);
                local current = UnitPower(unit, powerType);
                local newWidth = maxWidth * (current / max);

                frame.details.width = PandaUICore:val(newWidth);

                frame:UpdateStyles();
            end
        end
    end
end

function PandaUIPlayer:PlayerPowerFrame()
    local _, playerClass = UnitClass("player");
    self.spec = GetSpecialization();
    self.playerClass = playerClass;

    self.powerInfo = GetPowerInfo(playerClass, self.spec);

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
            {
                name = "SecondaryPower",
                ref = "secondaryPower",
                hidden = not self.powerInfo.secondary,
                backgroundColor = self.powerInfo:GetSecondaryColor(),
                init = ForceSecondary,
                events = {
                    UNIT_POWER_FREQUENT = SecondaryPower,
                    PLAYER_ENTERING_WORLD = ForceSecondary,
                    UNIT_DISPLAYPOWER = ForceSecondary
                }
            }, {
                name = "PrimaryPower",
                ref = "primaryPower",
                layout = {parts = 2},
                backgroundColor = self.powerInfo.primary.color,
                init = ForcePrimary,
                events = {
                    UNIT_POWER_FREQUENT = PrimaryPower,
                    PLAYER_ENTERING_WORLD = ForcePrimary,
                    UNIT_DISPLAYPOWER = ForcePrimary
                }
            }
        },
        events = {
            ACTIVE_TALENT_GROUP_CHANGED = function(frame)
                local newSpec = GetSpecialization();
                self.spec = newSpec;
                self.powerInfo = GetPowerInfo(playerClass, newSpec);

                CheckForStagger();

                frame.refs.primaryPower.details.backgroundColor =
                    self.powerInfo.primary.color;

                frame.refs.secondaryPower.details.hidden =
                    not self.powerInfo.secondary;
                frame.refs.secondaryPower.details.backgroundColor =
                    self.powerInfo:GetSecondaryColor();

                frame:UpdateLayout();
            end
        }
    }
end

function PandaUIPlayer:Initialize()

    self.root = PandaUICore:CreateFrame("PlayerBars", {
        height = PandaUICore:val(150),
        childLayout = {direction = "horizontal"},
        backgroundColor = {r = 0, g = 0, b = 0, a = .2}
    }, {self:PlayerHealthFrame(), self:PlayerPowerFrame()});

    self.root:UpdateStyles();
    self.root:UpdateLayout();
    self.root:Init();
end

