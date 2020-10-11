PandaUIPlayer = {};

function PandaUIPlayer:Initialize()
    self.root = PandaUICore:CreateFrame("PlayerBars", {
        height = PandaUICore:val(150),
        layout = {direction = "horizontal"}
        -- backgroundColor = {r = 0, g = 0, b = 1, a = 1}
    }, {
        {
            name = "PlayerHealth",
            -- key = "playerHealth",
            -- width = PandaUICore:pct(50),
            backgroundColor = {r = 0, g = 1, b = 0, a = 1}
        }, {
            name = "PrimaryResource",
            -- key = "priamryResource",
            -- width = PandaUICore:pct(50),
            backgroundColor = {r = 0, g = 0, b = 1, a = 1}
            -- anchor = PandaUICore:anchor("BOTTOMRIGHT")
        }
    });

    -- print(self.root.playerHealth:GetName());
end
