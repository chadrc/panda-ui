-- Copied from CombatText Blizzard Addon
local PowerTokenByLabel = {
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
        token = PowerTokenByLabel[label],
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
    },
    WARRIOR = {
        MakePowerInfo("RAGE"), -- Arms
        MakePowerInfo("RAGE"), -- Fury
        MakePowerInfo("RAGE") -- Protection
    },
    DRUID = {
        MakePowerInfo("LUNAR_POWER", "MANA"), -- Balance
        MakePowerInfo("MANA"), -- Feral
        MakePowerInfo("MANA"), -- Guardian
        MakePowerInfo("MANA"), -- Restoration
        forms = {
            -- Only needed where different, power type doen't change with Moonkin or Tree forms
            MakePowerInfo("RAGE"), -- Bear
            MakePowerInfo("ENERGY", "COMBO_POINTS") -- Cat
        }
    },
    PALADIN = {
        MakePowerInfo("HOLY_POWER", "MANA"), -- Holy
        MakePowerInfo("HOLY_POWER", "MANA"), -- Protection
        MakePowerInfo("HOLY_POWER", "MANA") -- Retribution
    },
    PRIEST = {
        MakePowerInfo("MANA"), -- Discipline 
        MakePowerInfo("MANA"), -- Holy
        MakePowerInfo("INSANITY", "MANA") -- Shadow
    }
}

function GetPowerInfo(class, spec)
    local powerInfo = MakePowerInfo("MANA")

    -- temporary check to avoid errors while developing
    -- eventually all should be registered
    if classPowers[class] and classPowers[class][spec] then
        local classPower = classPowers[class];
        powerInfo = classPower[spec];

        if classPower.forms then
            local form = GetShapeshiftForm();
            if classPower.forms[form] then
                powerInfo = classPower.forms[form];
            end
        end
    else
        print('Class ', class, ' with spec ', spec,
              ' not configured. Using defaults.')
    end

    return powerInfo;
end

local function PositionPrediction(frame, max, current)
    if not frame.predictedPowerCost then return end

    local parentWidth = frame:GetParent():GetWidth();

    local predictedPercent = frame.predictedPowerCost / max;
    frame.details.width = PandaUICore:val(predictedPercent * parentWidth);

    local missingPercent = (max - current) / max;
    frame.details.anchor = PandaUICore:anchor("RIGHT", "RIGHT",
                                              -missingPercent * parentWidth, -1);

    frame:UpdateStyles();
end

local function PowerUpdater(powerTokenGetter)
    return function(frame, unit, type)
        if unit == "player" then
            local powerType = PowerTokenByLabel[type];

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
        frame.refs.primaryPower:Setup(self.powerInfo.primary);
        -- frame.refs.primaryPower.statusBarTexture:SetColorTexture(pClr.r, pClr.g,
        --                                                          pClr.b, pClr.a);

        frame.refs.secondaryPower.details.hidden = not self.powerInfo.secondary;

        if self.powerInfo.secondary then
            frame.refs.secondaryPower:Setup(self.powerInfo.secondary);
        end
        -- local sClr = self.powerInfo:GetSecondaryColor();
        -- if sClr then
        --     frame.refs.secondaryPower.statusBarTexture:SetColorTexture(sClr.r,
        --                                                                sClr.g,
        --                                                                sClr.b,
        --                                                                sClr.a);
        -- end

        -- ForcePrimary(frame.refs.primaryPower);
        -- ForceSecondary(frame.refs.secondaryPower);

        -- Update to use direct updates for secure frames
        frame:UpdateLayout();
    end

    local hideSecondary = not self.powerInfo.secondary;
    local secondary = self.powerInfo.secondary or MakeSinglePowerInfo("MANA");
    return {
        name = "Power",
        ref = "power",
        childLayout = {direction = "vertical"},
        children = {
            -- PandaUICore:StatusBar({
            --     name = "SecondaryPower",
            --     ref = "secondaryPower",
            --     hidden = not self.powerInfo.secondary,
            --     statusBar = {color = self.powerInfo:GetSecondaryColor()},
            --     events = {
            --         UNIT_POWER_FREQUENT = SecondaryPower,
            --         PLAYER_ENTERING_WORLD = ForceSecondary,
            --         UNIT_DISPLAYPOWER = ForceSecondary
            --     },
            --     children = {
            --         {
            --             name = "CostPrediction",
            --             ref = "costPrediction",
            --             hidden = true,
            --             anchor = PandaUICore:anchor("RIGHT"),
            --             height = PandaUICore:pct(1),
            --             width = PandaUICore:val(50),
            --             backgroundColor = {r = 0, g = 0, b = 0, a = .5}
            --         }
            --     }
            -- }), PandaUICore:StatusBar({
            --     name = "PrimaryPower",
            --     ref = "primaryPower",
            --     layout = {parts = 2},
            --     statusBar = {color = self.powerInfo.primary.color},
            --     events = {
            --         UNIT_POWER_FREQUENT = PrimaryPower,
            --         PLAYER_ENTERING_WORLD = ForcePrimary,
            --         UNIT_DISPLAYPOWER = ForcePrimary
            --     },
            --     children = {
            --         {
            --             name = "CostPrediction",
            --             ref = "costPrediction",
            --             hidden = true,
            --             anchor = PandaUICore:anchor("RIGHT"),
            --             height = PandaUICore:pct(1),
            --             width = PandaUICore:val(50),
            --             backgroundColor = {r = 0, g = 0, b = 0, a = .5},
            --             events = {
            --                 UNIT_SPELLCAST_START = StartPrediction,
            --                 UNIT_SPELLCAST_STOP = EndPrediction,
            --                 UNIT_SPELLCAST_FAILED = EndPrediction,
            --                 UNIT_SPELLCAST_SUCCEEDED = EndPrediction
            --             }
            --         }
            --     }
            -- }), 
            PandaUICore:Merge(PandaUIUnits:UnitPowerFrame("player", secondary),
                              {
                name = "SecondaryPower",
                ref = "secondaryPower",
                hidden = hideSecondary
            }), PandaUICore:Merge(PandaUIUnits:UnitPowerFrame("player",
                                                              self.powerInfo
                                                                  .primary), {
                name = "PrimaryPower",
                ref = "primaryPower",
                layout = {parts = 2}
            })
        },
        events = {
            PLAYER_ENTERING_WORLD = Init,
            ACTIVE_TALENT_GROUP_CHANGED = Init,
            UPDATE_SHAPESHIFT_FORM = Init
        }
    }
end
