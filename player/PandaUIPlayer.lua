PandaUIPlayer = {};

function PandaUIPlayer:Initialize()
    self.root = PandaUICore:CreateFrame("PlayerBars", {
        height = PandaUICore:val(150),
        layout = {direction = "horizontal"}
    }, {
        {
            name = "PlayerHealth",
            backgroundColor = {r = 0, g = 1, b = 0, a = 1}
        }, {
            name = "PrimaryResource",
            backgroundColor = {r = 0, g = 0, b = 1, a = 1}
        }
    });

    -- print(self.root.playerHealth:GetName());
end
