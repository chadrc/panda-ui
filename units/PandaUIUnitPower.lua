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

local UnitPowerFrameMixin = {};

function UnitPowerFrameMixin:Update(unit, type)
    local powerType = PowerTokenByLabel[type];

    print('power', type, ' - ', self.props.powerInfo.label)
    if powerType == self.props.powerInfo.token then
        local max = UnitPowerMax(unit, powerType);
        local current = UnitPower(unit, powerType);

        print(max, ' - ', current);
        self.refs.status:SetMinMaxValues(0, 1);
        self.refs.status:SetValue(.25);

        -- PositionPrediction(self.refs.costPrediction, max, current);
    end
end

function UnitPowerFrameMixin:Init(powerInfo)
    if powerInfo then self.props.powerInfo = powerInfo; end

    local pClr = self.props.powerInfo.color;
    PandaUICore:Print(pClr);
    self.refs.status:SetStatusBarColor(nil);

    self:Update(self.props.unit, self.props.powerInfo.label);
end

function UnitPowerFrameMixin:StartPrediction(unit)
    local name, text, texture, startTime, endTime, isTradeSkill, castID,
          notInterruptible, spellID = UnitCastingInfo(self.props.unit);

    local powerType = self.props.powerInfo.token;
    local cost = 0;
    local costTable = GetSpellPowerCost(spellID);
    for _, costInfo in pairs(costTable) do
        if (costInfo.type == powerType) then
            cost = costInfo.cost;
            break
        end
    end

    if cost ~= 0 then
        self.predictedPowerCost = cost;
        self.details.hidden = false;

        local max = UnitPowerMax(unit, powerType);
        local current = UnitPower(unit, powerType);

        PositionPrediction(self, max, current);
    end
end

function UnitPowerFrameMixin:EndPrediction(unit)
    print('end predict')
    self.predictedPowerCost = nil;
    self.details.width = PandaUICore:val(0);
    self.details.hidden = true;

    self:UpdateStyles();
end

-- End Mixin

function PandaUIUnits:UnitPowerFrame(unit, powerInfo)
    local function Init(frame) frame:Init() end
    local function Update(frame) frame:Update() end
    local function StartPrediction(frame) frame:StartPrediction() end
    local function EndPrediction(frame) frame:EndPrediction() end

    return {
        name = unit .. "Power",
        props = {powerInfo = powerInfo, unit = unit},
        mixin = UnitPowerFrameMixin,
        children = {
            {
                name = "Background",
                ref = "background",
                backgroundColor = PandaUICore:FadeBy(powerInfo.color, .25)
            }, PandaUICore:StatusBar({
                name = "Status",
                ref = "status",
                statusBar = {color = powerInfo.color},
                children = {
                    {
                        name = "CostPrediction",
                        ref = "costPrediction",
                        hidden = true,
                        anchor = PandaUICore:anchor("RIGHT"),
                        height = PandaUICore:pct(1),
                        width = PandaUICore:val(50),
                        backgroundColor = {r = 0, g = 0, b = 0, a = .5},
                        events = {}
                    }
                }
            })
        },
        events = {PLAYER_ENTERING_WORLD = Init},
        scripts = {OnShow = Init},
        unit = {
            unit = unit,
            events = {
                UNIT_POWER_FREQUENT = Update,
                UNIT_DISPLAYPOWER = Update
                -- UNIT_SPELLCAST_START = StartPrediction,
                -- UNIT_SPELLCAST_STOP = EndPrediction,
                -- UNIT_SPELLCAST_FAILED = EndPrediction,
                -- UNIT_SPELLCAST_SUCCEEDED = EndPrediction
            }
        }
    }
end
