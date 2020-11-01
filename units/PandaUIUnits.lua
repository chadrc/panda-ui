PandaUIUnits = {};

function PandaUIUnits:Initialize()
    local root = PandaUICore:CreateFrame("PandaUIUnits", {
        -- backgroundColor = {r = 0, g = 0, b = 0, a = .2}
    }, {PandaUIUnits:TargetFrame()});

    root:UpdateStyles();
    root:UpdateLayout();
    root:Init();
end
