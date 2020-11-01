PandaUIUnits = {};

function PandaUIUnits:Initialize()
    if not PandaUISavedVariables.UnitFrames then
        PandaUISavedVariables.UnitFrames =
            {Target = {}, Party = {}, Player = {}}
    end
    local root = PandaUICore:CreateFrame("PandaUIUnits", {
        -- backgroundColor = {r = 0, g = 0, b = 0, a = .2}
    }, {
        PandaUIUnits:TargetFrame(PandaUISavedVariables.UnitFrames),
        PandaUIUnits:PlayerFrame(PandaUISavedVariables.UnitFrames)
    });

    root:UpdateStyles();
    root:UpdateLayout();
    root:Init();
end
